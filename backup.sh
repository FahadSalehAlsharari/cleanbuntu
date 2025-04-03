#!/bin/bash

# Author: Fahad Alsharari 
# Website: https://FahadAlsharari.sa
# Contact: admin@FahadAlsharari.sa

# Configuration backup function
backup_configs() {
    start_timer
    show_header
    
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "نسخ احتياطي للإعدادات:" || echo "Configuration Backup:")${NC}"
    
    # Confirm before proceeding
    if ! confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل تريد المتابعة في إنشاء نسخة احتياطية للإعدادات؟" || echo "Do you want to proceed with configuration backup?")"; then
        backup_restore_menu
        return
    fi
    
    # Create backup directory if it doesn't exist
    if [ ! -d "$BACKUP_PATH" ]; then
        mkdir -p "$BACKUP_PATH"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم إنشاء مجلد النسخ الاحتياطي: $BACKUP_PATH" || echo "Created backup directory: $BACKUP_PATH")"
    fi
    
    # Generate backup filename with timestamp
    local backup_date=$(date +"%Y%m%d-%H%M%S")
    local backup_file="${BACKUP_PATH}/config-backup-${backup_date}.tar.gz"
    
    # Files to backup - build array dynamically
    local backup_files=("${HOME}/.bashrc" "${HOME}/.profile" "${HOME}/.config" "${HOME}/.local/share/applications")
    
    # Add Firefox profile if enabled
    [ "$BACKUP_FIREFOX" -eq 1 ] && [ -d "${HOME}/.mozilla" ] && backup_files+=("${HOME}/.mozilla")
    
    # Add Chrome profile if enabled
    [ "$BACKUP_CHROME" -eq 1 ] && [ -d "${HOME}/.config/google-chrome" ] && backup_files+=("${HOME}/.config/google-chrome")
    
    # Check file existence before backup
    local files_to_backup=()
    for file in "${backup_files[@]}"; do
        [ -e "$file" ] && files_to_backup+=("$file")
    done
    
    # Show what will be backed up
    echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "سيتم نسخ الملفات والمجلدات التالية احتياطيًا:" || echo "The following files and folders will be backed up:")${NC}"
    for file in "${files_to_backup[@]}"; do
        echo -e "  $file"
    done
    
    # Create the backup
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "إنشاء نسخة احتياطية..." || echo "Creating backup...")${NC}"
    
    if [ ${#files_to_backup[@]} -eq 0 ]; then
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "لا توجد ملفات للنسخ الاحتياطي!" || echo "No files to backup!")"
        backup_restore_menu
        return
    fi
    
    # Create tar archive with progress indicator if possible
    if command_exists pv; then
        # Calculate total size
        local total_size=$(du -sc "${files_to_backup[@]}" 2>/dev/null | tail -n1 | cut -f1)
        tar -cf - "${files_to_backup[@]}" 2>/dev/null | pv -s "${total_size}k" | gzip > "${backup_file}"
    else
        # Fallback without progress
        tar -czf "${backup_file}" "${files_to_backup[@]}" 2>/dev/null
    fi
    
    # Check if backup was successful
    if [ -f "${backup_file}" ]; then
        local backup_size=$(du -h "${backup_file}" 2>/dev/null | cut -f1)
        log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم إنشاء النسخة الاحتياطية في: ${backup_file}" || echo "Backup created at: ${backup_file}")"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "حجم النسخة الاحتياطية: ${backup_size}" || echo "Backup size: ${backup_size}")"
        
        # Create a backup log
        local backup_log="${BACKUP_PATH}/backup-log.txt"
        {
            echo "Backup created on $(date)" 
            echo "Backup file: ${backup_file}" 
            echo "Backup size: ${backup_size}" 
            echo "Files included:" 
            for file in "${files_to_backup[@]}"; do
                echo "  - $file" 
            done
            echo "------------------------"
        } >> "$backup_log"
    else
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل إنشاء النسخة الاحتياطية." || echo "Failed to create backup.")"
    fi
    
    stop_timer
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الوقت المستغرق:" || echo "Time taken:") $(get_elapsed_time) $([ "$LANGUAGE" == "ar" ] && echo "ثانية" || echo "seconds")${NC}"
    
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى القائمة السابقة..." || echo "Press any key to return to the previous menu...")${NC}"
    read -n 1 -s
    backup_restore_menu
}

# Restore from backup function
restore_backup() {
    start_timer
    show_header
    
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "استعادة من نسخة احتياطية:" || echo "Restore from Backup:")${NC}"
    
    # Check if backup directory exists
    if [ ! -d "$BACKUP_PATH" ]; then
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "مجلد النسخ الاحتياطي غير موجود: $BACKUP_PATH" || echo "Backup directory does not exist: $BACKUP_PATH")"
        sleep 3
        backup_restore_menu
        return
    fi
    
    # Check if there are backup files
    local backup_files=($(find "$BACKUP_PATH" -name "config-backup-*.tar.gz" | sort -r))
    
    if [ ${#backup_files[@]} -eq 0 ]; then
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على ملفات النسخ الاحتياطي في $BACKUP_PATH" || echo "No backup files found in $BACKUP_PATH")"
        sleep 3
        backup_restore_menu
        return
    fi
    
    # List available backups
    echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "النسخ الاحتياطية المتاحة:" || echo "Available backups:")${NC}"
    for i in "${!backup_files[@]}"; do
        local backup_file="${backup_files[$i]}"
        local backup_date=$(echo "$backup_file" | grep -oE "[0-9]{8}-[0-9]{6}" || echo "Unknown")
        local backup_size=$(du -h "$backup_file" 2>/dev/null | cut -f1 || echo "Unknown")
        local formatted_date=""
        
        # Format date if possible
        if [[ "$backup_date" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
            formatted_date=$(date -d "${backup_date:0:8} ${backup_date:9:2}:${backup_date:11:2}:${backup_date:13:2}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$backup_date")
        else
            formatted_date="$backup_date"
        fi
        
        echo -e "  ${CYAN}$((i+1))${NC}. ${formatted_date} (${backup_size})"
    done
    
    # Ask user to select a backup
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اختر نسخة احتياطية للاستعادة (1-${#backup_files[@]}):" || echo "Choose a backup to restore (1-${#backup_files[@]}):")${NC}"
    read -r -p "> " backup_choice
    
    # Validate choice
    if ! [[ "$backup_choice" =~ ^[0-9]+$ ]] || [ "$backup_choice" -lt 1 ] || [ "$backup_choice" -gt "${#backup_files[@]}" ]; then
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "اختيار غير صالح." || echo "Invalid choice.")"
        sleep 2
        restore_backup
        return
    fi
    
    local selected_backup="${backup_files[$((backup_choice-1))]}"
    
    # Show backup contents
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "محتويات النسخة الاحتياطية:" || echo "Backup contents:")${NC}"
    tar -tvf "$selected_backup" 2>/dev/null | head -n 10
    
    if [ "$(tar -tvf "$selected_backup" 2>/dev/null | wc -l)" -gt 10 ]; then
        echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "... وأكثر من ذلك" || echo "... and more")${NC}"
    fi
    
    # Ask for confirmation
    echo -e "\n${RED}${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "تحذير: ستتم الكتابة فوق الملفات الحالية بمحتويات النسخة الاحتياطية." || echo "Warning: Current files will be overwritten with backup contents.")${NC}"
    
    if ! confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل أنت متأكد من أنك تريد الاستمرار في الاستعادة؟" || echo "Are you sure you want to proceed with restoration?")"; then
        backup_restore_menu
        return
    fi
    
    # Restore options
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "خيارات الاستعادة:" || echo "Restore options:")${NC}"
    echo -e "1. $([ "$LANGUAGE" == "ar" ] && echo "استعادة جميع الإعدادات" || echo "Restore all settings")"
    echo -e "2. $([ "$LANGUAGE" == "ar" ] && echo "استعادة الإعدادات الانتقائية" || echo "Restore selective settings")"
    echo -e "3. $([ "$LANGUAGE" == "ar" ] && echo "إلغاء" || echo "Cancel")"
    
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر خيارًا: " || echo "Choose an option: ")" restore_option
    
    # Create a temporary directory for extraction
    local temp_dir=$(mktemp -d)
    
    case $restore_option in
        1)
            # Full restore - more efficient
            echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "استعادة جميع الإعدادات..." || echo "Restoring all settings...")${NC}"
            
            # Extract to temp directory
            if tar -xzf "$selected_backup" -C "$temp_dir" 2>/dev/null; then
                # Use rsync for more efficient restore
                if command_exists rsync; then
                    # For each top-level directory in the backup
                    find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
                        local target_dir="${HOME}/$(basename "$dir")"
                        rsync -a --info=progress2 "$dir/" "$target_dir/" 2>/dev/null
                    done
                    
                    # For each top-level file in the backup
                    find "$temp_dir" -mindepth 1 -maxdepth 1 -type f | while read -r file; do
                        cp -f "$file" "${HOME}/" 2>/dev/null
                    done
                else
                    # Fallback to cp if rsync not available
                    find "$temp_dir" -mindepth 1 -maxdepth 1 | while read -r item; do
                        cp -rf "$item" "${HOME}/" 2>/dev/null
                    done
                fi
                
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "تمت الاستعادة بنجاح." || echo "Restore completed successfully.")"
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشلت عملية الاستعادة." || echo "Restore operation failed.")"
            fi
            ;;
        2)
            # Selective restore
            echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "استعادة الإعدادات الانتقائية..." || echo "Selective restoration...")${NC}"
            
            # Extract to temp directory
            if tar -xzf "$selected_backup" -C "$temp_dir" 2>/dev/null; then
                # List available items for restoration
                echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "العناصر المتاحة للاستعادة:" || echo "Items available for restoration:")${NC}"
                
                local items=()
                local i=1
                
                # Get all top-level items in one operation
                while read -r item; do
                    local item_name=$(basename "$item")
                    items+=("$item")
                    if [ -d "$item" ]; then
                        echo -e "${CYAN}$i${NC}. $item_name/"
                    else
                        echo -e "${CYAN}$i${NC}. $item_name"
                    fi
                    ((i++))
                done < <(find "$temp_dir" -mindepth 1 -maxdepth 1)
                
                # Ask for selection
                echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "أدخل أرقام العناصر للاستعادة (مفصولة بمسافات):" || echo "Enter item numbers to restore (separated by spaces):")${NC}"
                read -r selections
                
                # Process selections
                for selection in $selections; do
                    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#items[@]}" ]; then
                        local item="${items[$((selection-1))]}"
                        local item_name=$(basename "$item")
                        
                        if [ -d "$item" ]; then
                            # Directory - use rsync if available
                            local target_dir="${HOME}/$item_name"
                            if command_exists rsync; then
                                rsync -a --info=progress2 "$item/" "$target_dir/" 2>/dev/null
                            else
                                mkdir -p "$target_dir" 2>/dev/null
                                cp -rf "$item/"* "$target_dir/" 2>/dev/null
                            fi
                            log_info "$([ "$LANGUAGE" == "ar" ] && echo "تمت استعادة المجلد:" || echo "Restored directory:") $item_name"
                        else
                            # File
                            cp -f "$item" "${HOME}/" 2>/dev/null
                            log_info "$([ "$LANGUAGE" == "ar" ] && echo "تمت استعادة الملف:" || echo "Restored file:") $item_name"
                        fi
                    else
                        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "تم تجاهل الاختيار غير الصالح:" || echo "Ignored invalid selection:") $selection"
                    fi
                done
                
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "اكتملت عملية الاستعادة الانتقائية." || echo "Selective restore completed.")"
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشلت عملية الاستعادة." || echo "Restore operation failed.")"
            fi
            ;;
        *)
            log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم إلغاء عملية الاستعادة." || echo "Restore operation cancelled.")"
            ;;
    esac
    
    # Clean up temp directory
    rm -rf "$temp_dir" 2>/dev/null
    
    stop_timer
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الوقت المستغرق:" || echo "Time taken:") $(get_elapsed_time) $([ "$LANGUAGE" == "ar" ] && echo "ثانية" || echo "seconds")${NC}"
    
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى القائمة السابقة..." || echo "Press any key to return to the previous menu...")${NC}"
    read -n 1 -s
    backup_restore_menu
}

# Create a new backup of user data
backup_user_data() {
    start_timer
    show_header
    
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "نسخ احتياطي لبيانات المستخدم:" || echo "User Data Backup:")${NC}"
    
    # Confirm before proceeding
    if ! confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل تريد المتابعة في إنشاء نسخة احتياطية لبيانات المستخدم؟" || echo "Do you want to proceed with user data backup?")"; then
        backup_restore_menu
        return
    fi
    
    # Prepare destination
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "اختر وجهة النسخ الاحتياطي:" || echo "Choose backup destination:")${NC}"
    echo -e "1. $([ "$LANGUAGE" == "ar" ] && echo "المجلد الافتراضي للنسخ الاحتياطي ($BACKUP_PATH)" || echo "Default backup directory ($BACKUP_PATH)")"
    echo -e "2. $([ "$LANGUAGE" == "ar" ] && echo "مجلد مخصص" || echo "Custom directory")"
    echo -e "3. $([ "$LANGUAGE" == "ar" ] && echo "جهاز USB خارجي" || echo "External USB device")"
    
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر وجهة (1-3): " || echo "Choose destination (1-3): ")" dest_choice
    
    local backup_dest=""
    
    case $dest_choice in
        1)
            backup_dest="$BACKUP_PATH"
            ;;
        2)
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "أدخل مسار المجلد المخصص:" || echo "Enter custom directory path:")${NC}"
            read -r custom_path
            
            backup_dest=$(sanitize_input "$custom_path")
            if [ ! -d "$backup_dest" ]; then
                if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "المجلد غير موجود. هل تريد إنشاءه؟" || echo "Directory does not exist. Create it?")"; then
                    mkdir -p "$backup_dest"
                else
                    backup_restore_menu
                    return
                fi
            fi
            ;;
        3)
            # Find USB devices
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "البحث عن أجهزة USB الخارجية..." || echo "Finding external USB devices...")${NC}"
            
            local usb_devices=()
            local usb_mountpoints=()
            
            if command_exists lsblk; then
                while read -r device mountpoint; do
                    if [[ "$device" == sd* ]] && [ -n "$mountpoint" ] && [ "$mountpoint" != "/" ]; then
                        usb_devices+=("$device")
                        usb_mountpoints+=("$mountpoint")
                    fi
                done < <(lsblk -rno NAME,MOUNTPOINT | grep -v boot)
            elif [ -d "/media/${USER}" ]; then
                # Fallback for systems with predictable mount points
                for mountpoint in /media/${USER}/*; do
                    if [ -d "$mountpoint" ]; then
                        usb_devices+=("unknown")
                        usb_mountpoints+=("$mountpoint")
                    fi
                done
            fi
            
            if [ ${#usb_mountpoints[@]} -eq 0 ]; then
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على أجهزة USB قابلة للكتابة. الرجاء توصيل جهاز USB وتثبيته أولاً." || echo "No writable USB devices found. Please connect and mount a USB device first.")"
                sleep 3
                backup_restore_menu
                return
            fi
            
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "أجهزة USB المتاحة:" || echo "Available USB devices:")${NC}"
            for i in "${!usb_mountpoints[@]}"; do
                local device="${usb_devices[$i]}"
                local mountpoint="${usb_mountpoints[$i]}"
                local free_space=$(df -h "$mountpoint" | awk 'NR==2 {print $4}')
                
                echo -e "${CYAN}$((i+1))${NC}. $mountpoint ($([ "$LANGUAGE" == "ar" ] && echo "المساحة المتاحة:" || echo "Free space:") $free_space)"
            done
            
            echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اختر جهاز USB (1-${#usb_mountpoints[@]}):" || echo "Choose USB device (1-${#usb_mountpoints[@]}):")${NC}"
            read -r -p "> " usb_choice
            
            if ! [[ "$usb_choice" =~ ^[0-9]+$ ]] || [ "$usb_choice" -lt 1 ] || [ "$usb_choice" -gt "${#usb_mountpoints[@]}" ]; then
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "اختيار غير صالح." || echo "Invalid choice.")"
                sleep 2
                backup_user_data
                return
            fi
            
            backup_dest="${usb_mountpoints[$((usb_choice-1))]}/cleanbuntu-backup"
            mkdir -p "$backup_dest"
            ;;
        *)
            log_error "$([ "$LANGUAGE" == "ar" ] && echo "اختيار غير صالح." || echo "Invalid choice.")"
            sleep 2
            backup_user_data
            return
            ;;
    esac
    
    # Create backup directory if it doesn't exist
    if [ ! -d "$backup_dest" ]; then
        mkdir -p "$backup_dest"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم إنشاء مجلد النسخ الاحتياطي: $backup_dest" || echo "Created backup directory: $backup_dest")"
    fi
    
    # Select data to backup
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "اختر البيانات للنسخ الاحتياطي:" || echo "Select data to backup:")${NC}"
    echo -e "1. $([ "$LANGUAGE" == "ar" ] && echo "المستندات" || echo "Documents")"
    echo -e "2. $([ "$LANGUAGE" == "ar" ] && echo "الصور" || echo "Pictures")"
    echo -e "3. $([ "$LANGUAGE" == "ar" ] && echo "الموسيقى" || echo "Music")"
    echo -e "4. $([ "$LANGUAGE" == "ar" ] && echo "الفيديوهات" || echo "Videos")"
    echo -e "5. $([ "$LANGUAGE" == "ar" ] && echo "سطح المكتب" || echo "Desktop")"
    echo -e "6. $([ "$LANGUAGE" == "ar" ] && echo "التنزيلات" || echo "Downloads")"
    echo -e "7. $([ "$LANGUAGE" == "ar" ] && echo "جميع البيانات المذكورة أعلاه" || echo "All of the above")"
    echo -e "8. $([ "$LANGUAGE" == "ar" ] && echo "مجلد مخصص" || echo "Custom folder")"
    
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر البيانات للنسخ الاحتياطي (1-8): " || echo "Select data to backup (1-8): ")" data_choice
    
    local backup_dirs=()
    local backup_name=""
    
    case $data_choice in
        1) 
            backup_dirs+=("${HOME}/Documents")
            backup_name="documents"
            ;;
        2) 
            backup_dirs+=("${HOME}/Pictures")
            backup_name="pictures"
            ;;
        3) 
            backup_dirs+=("${HOME}/Music")
            backup_name="music"
            ;;
        4) 
            backup_dirs+=("${HOME}/Videos")
            backup_name="videos"
            ;;
        5) 
            backup_dirs+=("${HOME}/Desktop")
            backup_name="desktop"
            ;;
        6) 
            backup_dirs+=("${HOME}/Downloads")
            backup_name="downloads"
            ;;
        7) 
            backup_dirs=(
                "${HOME}/Documents"
                "${HOME}/Pictures"
                "${HOME}/Music"
                "${HOME}/Videos"
                "${HOME}/Desktop"
                "${HOME}/Downloads"
            )
            backup_name="all-user-data"
            ;;
        8)
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "أدخل مسار المجلد المخصص:" || echo "Enter custom folder path:")${NC}"
            read -r custom_folder
            
            custom_folder=$(sanitize_input "$custom_folder")
            if [ -d "$custom_folder" ]; then
                backup_dirs+=("$custom_folder")
                backup_name="custom-folder-$(basename "$custom_folder")"
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "المجلد غير موجود: $custom_folder" || echo "Directory does not exist: $custom_folder")"
                sleep 2
                backup_user_data
                return
            fi
            ;;
        *)
            log_error "$([ "$LANGUAGE" == "ar" ] && echo "اختيار غير صالح." || echo "Invalid choice.")"
            sleep 2
            backup_user_data
            return
            ;;
    esac
    
    # Generate backup filename with timestamp
    local backup_date=$(date +"%Y%m%d-%H%M%S")
    local backup_file="${backup_dest}/${backup_name}-backup-${backup_date}.tar.gz"
    
    # Show what will be backed up
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "سيتم نسخ المجلدات التالية احتياطيًا:" || echo "The following directories will be backed up:")${NC}"
    local total_size=0
    
    for dir in "${backup_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local dir_size=$(du -s "$dir" 2>/dev/null | cut -f1)
            total_size=$((total_size + dir_size))
            
            # Convert to human-readable size
            local human_size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo -e "  $dir ($human_size)"
        fi
    done
    
    # Convert total size to human-readable
    local human_total_size=$(echo $total_size | awk '{printf "%.1f GB", $1/1024/1024}')
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "إجمالي الحجم التقريبي:" || echo "Total approximate size:") ${human_total_size}${NC}"
    
    # Check destination free space
    local dest_free_space=$(df -k "$backup_dest" | awk 'NR==2 {print $4}')
    
    if [ $dest_free_space -lt $((total_size * 2)) ]; then
        local human_free_space=$(df -h "$backup_dest" | awk 'NR==2 {print $4}')
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "قد لا توجد مساحة كافية في الوجهة. المساحة المتاحة: $human_free_space" || echo "May not have enough space at destination. Free space: $human_free_space")"
        
        if ! confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "المتابعة على أي حال؟" || echo "Continue anyway?")"; then
            backup_restore_menu
            return
        fi
    fi
    
    # Compression options
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "خيارات الضغط:" || echo "Compression options:")${NC}"
    echo -e "1. $([ "$LANGUAGE" == "ar" ] && echo "سريع (أقل ضغط)" || echo "Fast (less compression)")"
    echo -e "2. $([ "$LANGUAGE" == "ar" ] && echo "متوازن" || echo "Balanced")"
    echo -e "3. $([ "$LANGUAGE" == "ar" ] && echo "أقصى ضغط (أبطأ)" || echo "Maximum compression (slower)")"
    
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر مستوى الضغط (1-3): " || echo "Choose compression level (1-3): ")" comp_choice
    
    local compression_level=6  # Default balanced compression
    
    case $comp_choice in
        1) compression_level=1 ;;  # Fast
        2) compression_level=6 ;;  # Balanced
        3) compression_level=9 ;;  # Maximum
        *) compression_level=6 ;;  # Default to balanced
    esac
    
    # Create the backup
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "إنشاء نسخة احتياطية... هذا قد يستغرق بعض الوقت." || echo "Creating backup... This may take some time.")${NC}"
    
    # Build the commands
    local tar_args="-z${compression_level}cf"
    local exclude_args=""
    
    # Add common exclusions for user backups
    exclude_args+=" --exclude='*/node_modules/*'"
    exclude_args+=" --exclude='*/.git/*'"
    exclude_args+=" --exclude='*/Cache/*'"
    exclude_args+=" --exclude='*/cache/*'"
    exclude_args+=" --exclude='*/.cache/*'"
    exclude_args+=" --exclude='*/tmp/*'"
    exclude_args+=" --exclude='*/.Trash/*'"
    
    # Create backup with progress indicator if possible
    if command_exists pv; then
        echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "جارٍ إنشاء النسخة الاحتياطية مع مؤشر التقدم..." || echo "Creating backup with progress indicator...")${NC}"
        
        # Build complete command
        local cmd="tar $tar_args - $exclude_args ${backup_dirs[@]} 2>/dev/null | pv -s ${total_size}k > \"${backup_file}\""
        
        # Execute the command
        eval "$cmd"
    else
        echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "جارٍ إنشاء النسخة الاحتياطية..." || echo "Creating backup...")${NC}"
        
        # Simple command without progress
        tar $tar_args "$backup_file" $exclude_args "${backup_dirs[@]}" 2>/dev/null
    fi
    
    # Check if backup was successful
    if [ -f "${backup_file}" ]; then
        local backup_size=$(du -h "${backup_file}" 2>/dev/null | cut -f1)
        log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم إنشاء النسخة الاحتياطية في: ${backup_file}" || echo "Backup created at: ${backup_file}")"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "حجم النسخة الاحتياطية: ${backup_size}" || echo "Backup size: ${backup_size}")"
        
        # Create a backup log
        local backup_log="${backup_dest}/user-backup-log.txt"
        {
            echo "User Data Backup created on $(date)" 
            echo "Backup file: ${backup_file}" 
            echo "Backup size: ${backup_size}" 
            echo "Directories included:" 
            for dir in "${backup_dirs[@]}"; do
                echo "  - $dir" 
            done
            echo "------------------------"
        } >> "$backup_log"
        
        # Ask if user wants to verify backup
        if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل ترغب في التحقق من النسخة الاحتياطية؟" || echo "Do you want to verify the backup?")"; then
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "التحقق من النسخة الاحتياطية..." || echo "Verifying backup...")${NC}"
            
            if tar -tf "$backup_file" &>/dev/null; then
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم التحقق من النسخة الاحتياطية بنجاح." || echo "Backup verified successfully.")"
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل التحقق من النسخة الاحتياطية. قد تكون النسخة الاحتياطية تالفة." || echo "Backup verification failed. The backup may be corrupted.")"
            fi
        fi
    else
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل إنشاء النسخة الاحتياطية." || echo "Failed to create backup.")"
    fi
    
    stop_timer
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الوقت المستغرق:" || echo "Time taken:") $(get_elapsed_time) $([ "$LANGUAGE" == "ar" ] && echo "ثانية" || echo "seconds")${NC}"
    
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى القائمة السابقة..." || echo "Press any key to return to the previous menu...")${NC}"
    read -n 1 -s
    backup_restore_menu
}

# Restore user data from backup
restore_user_data() {
    start_timer
    show_header
    
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "استعادة بيانات المستخدم:" || echo "Restore User Data:")${NC}"
    
    # Choose backup source
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "اختر مصدر النسخة الاحتياطية:" || echo "Choose backup source:")${NC}"
    echo -e "1. $([ "$LANGUAGE" == "ar" ] && echo "المجلد الافتراضي للنسخ الاحتياطي ($BACKUP_PATH)" || echo "Default backup directory ($BACKUP_PATH)")"
    echo -e "2. $([ "$LANGUAGE" == "ar" ] && echo "مجلد مخصص" || echo "Custom directory")"
    echo -e "3. $([ "$LANGUAGE" == "ar" ] && echo "جهاز USB خارجي" || echo "External USB device")"
    
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر مصدرًا (1-3): " || echo "Choose source (1-3): ")" source_choice
    
    local backup_source=""
    
    case $source_choice in
        1)
            backup_source="$BACKUP_PATH"
            ;;
        2)
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "أدخل مسار المجلد المخصص:" || echo "Enter custom directory path:")${NC}"
            read -r custom_path
            
            backup_source=$(sanitize_input "$custom_path")
            if [ ! -d "$backup_source" ]; then
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "المجلد غير موجود: $backup_source" || echo "Directory does not exist: $backup_source")"
                sleep 2
                backup_restore_menu
                return
            fi
            ;;
        3)
            # Find USB devices
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "البحث عن أجهزة USB الخارجية..." || echo "Finding external USB devices...")${NC}"
            
            local usb_devices=()
            local usb_mountpoints=()
            
            if command_exists lsblk; then
                while read -r device mountpoint; do
                    if [[ "$device" == sd* ]] && [ -n "$mountpoint" ] && [ "$mountpoint" != "/" ]; then
                        usb_devices+=("$device")
                        usb_mountpoints+=("$mountpoint")
                    fi
                done < <(lsblk -rno NAME,MOUNTPOINT | grep -v boot)
            elif [ -d "/media/${USER}" ]; then
                # Fallback for systems with predictable mount points
                for mountpoint in /media/${USER}/*; do
                    if [ -d "$mountpoint" ]; then
                        usb_devices+=("unknown")
                        usb_mountpoints+=("$mountpoint")
                    fi
                done
            fi
            
            if [ ${#usb_mountpoints[@]} -eq 0 ]; then
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على أجهزة USB. الرجاء توصيل جهاز USB وتثبيته أولاً." || echo "No USB devices found. Please connect and mount a USB device first.")"
                sleep 3
                backup_restore_menu
                return
            fi
            
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "أجهزة USB المتاحة:" || echo "Available USB devices:")${NC}"
            for i in "${!usb_mountpoints[@]}"; do
                local device="${usb_devices[$i]}"
                local mountpoint="${usb_mountpoints[$i]}"
                
                echo -e "${CYAN}$((i+1))${NC}. $mountpoint"
            done
            
            echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اختر جهاز USB (1-${#usb_mountpoints[@]}):" || echo "Choose USB device (1-${#usb_mountpoints[@]}):")${NC}"
            read -r -p "> " usb_choice
            
            if ! [[ "$usb_choice" =~ ^[0-9]+$ ]] || [ "$usb_choice" -lt 1 ] || [ "$usb_choice" -gt "${#usb_mountpoints[@]}" ]; then
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "اختيار غير صالح." || echo "Invalid choice.")"
                sleep 2
                restore_user_data
                return
            fi
            
            backup_source="${usb_mountpoints[$((usb_choice-1))]}"
            
            # Check for cleanbuntu-backup directory
            if [ -d "$backup_source/cleanbuntu-backup" ]; then
                backup_source="$backup_source/cleanbuntu-backup"
            fi
            ;;
        *)
            log_error "$([ "$LANGUAGE" == "ar" ] && echo "اختيار غير صالح." || echo "Invalid choice.")"
            sleep 2
            restore_user_data
            return
            ;;
    esac
    
    # Find backup files in the source directory
    local backup_pattern="*-backup-*.tar.gz"
    local backup_files=($(find "$backup_source" -maxdepth 1 -name "$backup_pattern" | sort -r))
    
    if [ ${#backup_files[@]} -eq 0 ]; then
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على ملفات النسخ الاحتياطي في $backup_source" || echo "No backup files found in $backup_source")"
        sleep 3
        backup_restore_menu
        return
    fi
    
    # List available backups
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "النسخ الاحتياطية المتاحة:" || echo "Available backups:")${NC}"
    for i in "${!backup_files[@]}"; do
        local backup_file="${backup_files[$i]}"
        local backup_name=$(basename "$backup_file")
        local backup_date=$(echo "$backup_name" | grep -oE "[0-9]{8}-[0-9]{6}" || echo "Unknown")
        local backup_size=$(du -h "$backup_file" 2>/dev/null | cut -f1 || echo "Unknown")
        local formatted_date=""
        
        # Format date if possible
        if [[ "$backup_date" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
            formatted_date=$(date -d "${backup_date:0:8} ${backup_date:9:2}:${backup_date:11:2}:${backup_date:13:2}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$backup_date")
        else
            formatted_date="$backup_date"
        fi
        
        echo -e "  ${CYAN}$((i+1))${NC}. ${backup_name%%-backup-*} - ${formatted_date} (${backup_size})"
    done
    
    # Ask user to select a backup
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اختر نسخة احتياطية للاستعادة (1-${#backup_files[@]}):" || echo "Choose a backup to restore (1-${#backup_files[@]}):")${NC}"
    read -r -p "> " backup_choice
    
    # Validate choice
    if ! [[ "$backup_choice" =~ ^[0-9]+$ ]] || [ "$backup_choice" -lt 1 ] || [ "$backup_choice" -gt "${#backup_files[@]}" ]; then
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "اختيار غير صالح." || echo "Invalid choice.")"
        sleep 2
        restore_user_data
        return
    fi
    
    local selected_backup="${backup_files[$((backup_choice-1))]}"
    
    # Show backup contents
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "محتويات النسخة الاحتياطية:" || echo "Backup contents:")${NC}"
    tar -tvf "$selected_backup" 2>/dev/null | head -n 15 | awk '{print $6}'
    
    if [ "$(tar -tvf "$selected_backup" 2>/dev/null | wc -l)" -gt 15 ]; then
        echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "... وأكثر من ذلك" || echo "... and more")${NC}"
    fi
    
    # Choose restore destination
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "اختر وجهة الاستعادة:" || echo "Choose restore destination:")${NC}"
    echo -e "1. $([ "$LANGUAGE" == "ar" ] && echo "المجلد الأصلي (سيتم الكتابة فوق الملفات الموجودة)" || echo "Original location (will overwrite existing files)")"
    echo -e "2. $([ "$LANGUAGE" == "ar" ] && echo "مجلد مؤقت (للمراجعة أولاً)" || echo "Temporary folder (to review first)")"
    echo -e "3. $([ "$LANGUAGE" == "ar" ] && echo "مجلد مخصص" || echo "Custom folder")"
    
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر وجهة (1-3): " || echo "Choose destination (1-3): ")" dest_choice
    
    local restore_dest=""
    
    case $dest_choice in
        1)
            restore_dest="$HOME"
            
            # Warning for overwriting
            echo -e "\n${RED}${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "تحذير: ستتم الكتابة فوق الملفات الحالية بمحتويات النسخة الاحتياطية." || echo "Warning: Current files will be overwritten with backup contents.")${NC}"
            
            if ! confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل أنت متأكد من أنك تريد الاستمرار؟" || echo "Are you sure you want to proceed?")"; then
                restore_user_data
                return
            fi
            ;;
        2)
            # Create temp directory
            restore_dest=$(mktemp -d)
            echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "سيتم الاستعادة إلى: $restore_dest" || echo "Will restore to: $restore_dest")${NC}"
            ;;
        3)
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "أدخل مسار المجلد المخصص:" || echo "Enter custom directory path:")${NC}"
            read -r custom_path
            
            restore_dest=$(sanitize_input "$custom_path")
            if [ ! -d "$restore_dest" ]; then
                if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "المجلد غير موجود. هل تريد إنشاءه؟" || echo "Directory does not exist. Create it?")"; then
                    mkdir -p "$restore_dest"
                else
                    restore_user_data
                    return
                fi
            fi
            ;;
        *)
            log_error "$([ "$LANGUAGE" == "ar" ] && echo "اختيار غير صالح." || echo "Invalid choice.")"
            sleep 2
            restore_user_data
            return
            ;;
    esac
    
    # Perform the restoration
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "جارٍ استعادة البيانات..." || echo "Restoring data...")${NC}"
    
    # Extract with progress if possible
    if command_exists pv; then
        # Get backup size
        local backup_size=$(stat -c%s "$selected_backup")
        
        pv -p -s "$backup_size" "$selected_backup" | tar -xzf - -C "$restore_dest" 2>/dev/null
    else
        # Simple extraction without progress
        tar -xzf "$selected_backup" -C "$restore_dest" 2>/dev/null
    fi
    
    # Check if restore was successful
    if [ $? -eq 0 ]; then
        log_success "$([ "$LANGUAGE" == "ar" ] && echo "تمت استعادة البيانات بنجاح إلى: $restore_dest" || echo "Data restored successfully to: $restore_dest")"
        
        # Open restored folder
        if [ "$dest_choice" -ne 1 ] && confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل تريد فتح المجلد المستعاد؟" || echo "Do you want to open the restored folder?")"; then
            if command_exists xdg-open; then
                xdg-open "$restore_dest" &
            elif command_exists open; then
                open "$restore_dest"
            else
                log_warning "$([ "$LANGUAGE" == "ar" ] && echo "تعذر فتح المجلد تلقائيًا. المسار: $restore_dest" || echo "Could not open folder automatically. Path: $restore_dest")"
            fi
        fi
    else
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشلت عملية الاستعادة." || echo "Restore operation failed.")"
    fi
    
    stop_timer
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الوقت المستغرق:" || echo "Time taken:") $(get_elapsed_time) $([ "$LANGUAGE" == "ar" ] && echo "ثانية" || echo "seconds")${NC}"
    
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى القائمة السابقة..." || echo "Press any key to return to the previous menu...")${NC}"
    read -n 1 -s
    backup_restore_menu
}