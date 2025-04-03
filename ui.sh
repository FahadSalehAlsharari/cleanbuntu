#!/bin/bash

# Author: Fahad Alsharari 
# Website: https://FahadAlsharari.sa
# Contact: admin@FahadAlsharari.sa
# Function to show header
show_header() {
    clear
    local version="2.0.0"

    echo -e "${BOLD}${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${BOLD}${GREEN}┃                  ${CYAN}CLEANBUNTU DESKTOP MAINTENANCE TOOLKIT${GREEN}                  ┃${NC}"
    echo -e "${BOLD}${GREEN}┃                              ${YELLOW}Version $version${GREEN}                              ┃${NC}"
    echo -e "${BOLD}${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

    # Show Arabic header if Arabic is selected
    if [ "$LANGUAGE" == "ar" ]; then
        echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━ أداة صيانة سطح المكتب لنظام أوبونتو ━━━━━━━━━━━━━${NC}"
    else
        echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━ Ubuntu Desktop Maintenance Toolkit ━━━━━━━━━━━━━${NC}"
    fi

    # Show a random quote
    echo -e "${YELLOW}$(get_random_quote)${NC}"
    echo -e "${SEPARATOR}"

    # Show current date and time in BOLD WHITE
    echo -e "${BOLD}${NC}$(date +"%Y-%m-%d %H:%M:%S")${NC}"
    echo
}

# Function to show main menu with icons
show_menu() {
    show_header

    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "القائمة الرئيسية:" || echo "Main Menu:")${NC}"
    echo # Add an empty line for better spacing

    # --- Icons added next to each option ---
    echo -e "1. 🖥️  $([ "$LANGUAGE" == "ar" ] && echo "معلومات النظام" || echo "System Information")"
    echo -e "2. ⚙️  $([ "$LANGUAGE" == "ar" ] && echo "حالة الخدمات" || echo "Services Status")"
    echo -e "3. ✨ $([ "$LANGUAGE" == "ar" ] && echo "تنظيف النظام" || echo "System Cleanup")"
    echo -e "4. ⬆️  $([ "$LANGUAGE" == "ar" ] && echo "تحديث النظام" || echo "System Update")"
    echo -e "5. 💾 $([ "$LANGUAGE" == "ar" ] && echo "النسخ الاحتياطي والاستعادة" || echo "Backup & Restore")"
    echo -e "6. 🛠️  $([ "$LANGUAGE" == "ar" ] && echo "استكشاف الأخطاء وإصلاحها" || echo "Troubleshooting")"
    echo -e "7. 🔧 $([ "$LANGUAGE" == "ar" ] && echo "الإعدادات" || echo "Settings")"
    echo -e "0. 🚪 $([ "$LANGUAGE" == "ar" ] && echo "خروج" || echo "Exit")"
    # --- End of icon additions ---

    echo
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر خيارًا (0-7): " || echo "Choose an option (0-7): ")" menu_choice

    case $menu_choice in
        1) system_info ;;
        2) check_services ;;
        3) perform_cleanup ;;
        4) system_update ;;
        5) backup_restore_menu ;;
        6) show_troubleshooting_menu ;;
        7) change_settings ;;
        0)
           echo -e "\n${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "شكرًا لاستخدام أداة صيانة سطح المكتب! مع السلامة!" || echo "Thank you for using Desktop Maintenance Toolkit! Goodbye!")${NC}"
           cleanup_and_exit
           ;;
        *)
           log_warning "$([ "$LANGUAGE" == "ar" ] && echo "خيار غير صالح. الرجاء المحاولة مرة أخرى." || echo "Invalid option. Please try again.")"
           sleep 2
           show_menu
           ;;
    esac
}

# Function to show the backup and restore menu
backup_restore_menu() {
    show_header

    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "قائمة النسخ الاحتياطي والاستعادة:" || echo "Backup & Restore Menu:")${NC}"
    echo # Add an empty line for better spacing

    echo -e "1. 💾 $([ "$LANGUAGE" == "ar" ] && echo "نسخ احتياطي للإعدادات" || echo "Backup Configuration")"
    echo -e "2. 🔄 $([ "$LANGUAGE" == "ar" ] && echo "استعادة من نسخة احتياطية" || echo "Restore from Backup")"
    echo -e "3. 📂 $([ "$LANGUAGE" == "ar" ] && echo "إدارة النسخ الاحتياطية" || echo "Manage Backups")"
    echo -e "0. ↩️  $([ "$LANGUAGE" == "ar" ] && echo "العودة إلى القائمة الرئيسية" || echo "Return to Main Menu")"


    echo
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر خيارًا (0-3): " || echo "Choose an option (0-3): ")" backup_choice

    case $backup_choice in
        1) backup_configs ;;
        2) restore_backup ;;
        3) manage_backups ;;
        0) show_menu ;;
        *)
           log_warning "$([ "$LANGUAGE" == "ar" ] && echo "خيار غير صالح. الرجاء المحاولة مرة أخرى." || echo "Invalid option. Please try again.")"
           sleep 2
           backup_restore_menu
           ;;
    esac
}

# Function to manage backups
manage_backups() {
    show_header

    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "إدارة النسخ الاحتياطية:" || echo "Manage Backups:")${NC}"

    # Check if backup directory exists
    if [ ! -d "$BACKUP_PATH" ]; then
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "مجلد النسخ الاحتياطي غير موجود: $BACKUP_PATH" || echo "Backup directory does not exist: $BACKUP_PATH")"
        sleep 3
        backup_restore_menu
        return
    fi

    # List all backups
    local backup_files=($(find "$BACKUP_PATH" -name "config-backup-*.tar.gz" | sort -r))
    local backup_count=${#backup_files[@]}

    if [ $backup_count -eq 0 ]; then
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على نسخ احتياطية." || echo "No backups found.")"
        sleep 2
        backup_restore_menu
        return
    fi

    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "النسخ الاحتياطية المتاحة:" || echo "Available backups:")${NC}"
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "إجمالي النسخ الاحتياطية:" || echo "Total backups:") ${backup_count}${NC}"

    # Get backup directory size
    local backup_size=$(du -sh "$BACKUP_PATH" 2>/dev/null | cut -f1)
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "إجمالي الحجم المستخدم:" || echo "Total size used:") ${backup_size}${NC}"

    # List recent backups
    echo -e "\n${CYAN}$([ "$LANGUAGE" == "ar" ] && echo "النسخ الاحتياطية الأخيرة:" || echo "Recent backups:")${NC}"
    local count=0
    for backup in "${backup_files[@]}"; do
        ((count++))
        local backup_date=$(echo "$backup" | grep -oE "[0-9]{8}-[0-9]{6}" || echo "Unknown")
        local backup_size=$(du -h "$backup" 2>/dev/null | cut -f1)
        local formatted_date=""

        # Format date if possible
        if [[ "$backup_date" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
            formatted_date=$(date -d "${backup_date:0:8} ${backup_date:9:2}:${backup_date:11:2}:${backup_date:13:2}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$backup_date")
        else
            formatted_date="$backup_date"
        fi

        echo -e "${count}. ${formatted_date} (${backup_size})"

        # Only show first 5 backups
        if [ $count -ge 5 ]; then
            break
        fi
    done

    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "خيارات:" || echo "Options:")${NC}"
    echo -e "1. 🗑️  $([ "$LANGUAGE" == "ar" ] && echo "حذف جميع النسخ الاحتياطية" || echo "Delete All Backups")"
    echo -e "2. ⏳ $([ "$LANGUAGE" == "ar" ] && echo "حذف النسخ الاحتياطية القديمة (أقدم من 30 يومًا)" || echo "Delete Old Backups (older than 30 days)")"
    echo -e "3. ❌ $([ "$LANGUAGE" == "ar" ] && echo "حذف نسخة احتياطية محددة" || echo "Delete Specific Backup")"
    echo -e "4. 📁 $([ "$LANGUAGE" == "ar" ] && echo "فتح مجلد النسخ الاحتياطية" || echo "Open Backup Directory")"
    echo -e "0. ↩️  $([ "$LANGUAGE" == "ar" ] && echo "العودة" || echo "Back")"


    echo
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر خيارًا (0-4): " || echo "Choose an option (0-4): ")" choice

    case $choice in
        1)  # Delete all backups
            if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل أنت متأكد من أنك تريد حذف جميع النسخ الاحتياطية؟" || echo "Are you sure you want to delete ALL backups?")"; then
                rm -f "${BACKUP_PATH}/config-backup-"*.tar.gz
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم حذف جميع النسخ الاحتياطية." || echo "All backups deleted.")"
            fi
            ;;
        2)  # Delete old backups
            local now=$(date +%s)
            local deleted=0

            for backup in "${backup_files[@]}"; do
                local backup_date=$(echo "$backup" | grep -oE "[0-9]{8}-[0-9]{6}" || echo "")
                if [ -n "$backup_date" ]; then
                    local backup_timestamp=$(date -d "${backup_date:0:8} ${backup_date:9:2}:${backup_date:11:2}:${backup_date:13:2}" +%s 2>/dev/null || echo "0")
                    if [ $backup_timestamp -gt 0 ] && [ $(( (now - backup_timestamp) / 86400 )) -gt 30 ]; then
                        rm -f "$backup"
                        ((deleted++))
                    fi
                fi
            done

            log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم حذف $deleted نسخة احتياطية قديمة." || echo "Deleted $deleted old backups.")"
            ;;
        3)  # Delete specific backup
            echo
            read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "أدخل رقم النسخة الاحتياطية للحذف (1-$backup_count): " || echo "Enter backup number to delete (1-$backup_count): ")" backup_num

            if [[ "$backup_num" =~ ^[0-9]+$ ]] && [ "$backup_num" -ge 1 ] && [ "$backup_num" -le $backup_count ]; then
                local backup_to_delete="${backup_files[$((backup_num-1))]}"
                if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل أنت متأكد من أنك تريد حذف هذه النسخة الاحتياطية؟" || echo "Are you sure you want to delete this backup?")"; then
                    rm -f "$backup_to_delete"
                    log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم حذف النسخة الاحتياطية." || echo "Backup deleted.")"
                fi
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "رقم غير صالح." || echo "Invalid number.")"
            fi
            ;;
        4)  # Open backup directory
            if command_exists xdg-open; then
                xdg-open "$BACKUP_PATH" &
            elif command_exists open; then # macOS compatibility
                open "$BACKUP_PATH"
            else
                log_warning "$([ "$LANGUAGE" == "ar" ] && echo "تعذر فتح مجلد النسخ الاحتياطية. المسار: $BACKUP_PATH" || echo "Could not open backup directory. Path: $BACKUP_PATH")"
            fi
            ;;
        0)  # Return to backup/restore menu
            backup_restore_menu
            return
            ;;
        *)
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "خيار غير صالح." || echo "Invalid option.")"
            ;;
    esac

    sleep 2
    manage_backups
}

# Function to show the troubleshooting menu
show_troubleshooting_menu() {
    show_header

    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "قائمة استكشاف الأخطاء وإصلاحها:" || echo "Troubleshooting Menu:")${NC}"
    echo # Add an empty line for better spacing

    echo -e "1. 🐌 $([ "$LANGUAGE" == "ar" ] && echo "تشخيص بطء النظام" || echo "Diagnose System Slowness")"
    echo -e "2. 💾 $([ "$LANGUAGE" == "ar" ] && echo "فحص صحة القرص" || echo "Check Disk Health")"
    echo -e "3. 🔐 $([ "$LANGUAGE" == "ar" ] && echo "إصلاح أذونات الملفات المعطلة" || echo "Fix Broken File Permissions")"
    echo -e "4. 🌐 $([ "$LANGUAGE" == "ar" ] && echo "إعادة تعيين إعدادات الشبكة" || echo "Reset Network Settings")"
    echo -e "5. 👢 $([ "$LANGUAGE" == "ar" ] && echo "إصلاح سجل إقلاع GRUB" || echo "Fix GRUB Boot Record")"
    echo -e "6. 📜 $([ "$LANGUAGE" == "ar" ] && echo "مسح سجل النظام" || echo "View System Logs")"
    echo -e "0. ↩️  $([ "$LANGUAGE" == "ar" ] && echo "العودة إلى القائمة الرئيسية" || echo "Return to Main Menu")"


    echo
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر خيارًا (0-6): " || echo "Choose an option (0-6): ")" trouble_choice

    case $trouble_choice in
        1) diagnose_system_slowness ;;
        2) check_disk_health_menu ;;
        3) fix_permissions_menu ;;
        4) reset_network_settings ;;
        5) fix_grub_menu ;;
        6) view_system_logs ;;
        0) show_menu ;;
        *)
           log_warning "$([ "$LANGUAGE" == "ar" ] && echo "خيار غير صالح. الرجاء المحاولة مرة أخرى." || echo "Invalid option. Please try again.")"
           sleep 2
           show_troubleshooting_menu
           ;;
    esac
}

# Check disk health menu
check_disk_health_menu() {
    show_header

    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "فحص صحة القرص:" || echo "Check Disk Health:")${NC}"

    # Check if smartctl is installed
    if ! command_exists smartctl; then
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "أداة smartctl غير مثبتة. هذه الأداة مطلوبة لفحص صحة القرص." || echo "smartctl tool is not installed. This tool is required for disk health check.")"

        # Offer to install smartmontools
        if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل تريد تثبيت smartmontools?" || echo "Do you want to install smartmontools?")"; then
            if check_sudo; then
                if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
                    apt-get update
                    apt-get install -y smartmontools
                elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
                    dnf install -y smartmontools
                elif [ "$PACKAGE_MANAGER" == "yum" ]; then
                    yum install -y smartmontools
                elif [ "$PACKAGE_MANAGER" == "pacman" ]; then
                    pacman -S --noconfirm smartmontools
                else
                    log_error "$([ "$LANGUAGE" == "ar" ] && echo "لا يمكن تثبيت smartmontools تلقائيًا. يرجى تثبيته يدويًا." || echo "Cannot install smartmontools automatically. Please install it manually.")"
                    sleep 3
                    show_troubleshooting_menu
                    return
                fi
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "صلاحيات الجذر مطلوبة لتثبيت smartmontools." || echo "Root privileges required to install smartmontools.")"
                sleep 3
                show_troubleshooting_menu
                return
            fi
        else
            show_troubleshooting_menu
            return
        fi
    fi

    # List all disks
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الأقراص المتوفرة:" || echo "Available disks:")${NC}"

    # Get list of disks (more compatible approach)
    local disks=()
    local disk_descriptions=()

    if [ -d "/dev" ]; then
        # Different approaches for listing disks
        if command_exists lsblk; then
            # Use lsblk if available
            local i=0
            while read -r disk_name disk_size; do
                disks+=("/dev/$disk_name")
                disk_descriptions+=("$disk_name ($disk_size)")
                echo -e "$((i+1)). /dev/$disk_name - $disk_size"
                ((i++))
            done < <(lsblk -d -o NAME,SIZE -n | grep -v "sr[0-9]" | grep -v "loop[0-9]")
        else
            # Fallback method
            local disk_pattern="sd[a-z]" # Consider adding nvme* patterns too
            local i=0
            for disk in /dev/$disk_pattern /dev/nvme[0-9]n[0-9]; do
                if [ -b "$disk" ]; then
                    local disk_name=$(basename "$disk")
                    local disk_size_bytes=$(blockdev --getsize64 "$disk" 2>/dev/null || echo 0)
                    local disk_size=$(awk -v size="$disk_size_bytes" 'BEGIN {printf "%.1f GB", size/1024/1024/1024}')
                    disks+=("$disk")
                    disk_descriptions+=("$disk_name ($disk_size)")
                    echo -e "$((i+1)). $disk - $disk_size"
                    ((i++))
                fi
            done
        fi
    fi

    if [ ${#disks[@]} -eq 0 ]; then
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على أقراص." || echo "No disks found.")"
        sleep 3
        show_troubleshooting_menu
        return
    fi

    echo
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر قرصًا للفحص (1-${#disks[@]}) أو 0 للعودة: " || echo "Choose a disk to check (1-${#disks[@]}) or 0 to go back: ")" disk_choice

    if [ "$disk_choice" -eq 0 ]; then
        show_troubleshooting_menu
        return
    fi

    if [[ "$disk_choice" =~ ^[0-9]+$ ]] && [ "$disk_choice" -ge 1 ] && [ "$disk_choice" -le ${#disks[@]} ]; then
        local selected_disk="${disks[$((disk_choice-1))]}"

        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "فحص القرص: $selected_disk" || echo "Checking disk: $selected_disk")${NC}"

        if ! check_sudo; then
            log_error "$([ "$LANGUAGE" == "ar" ] && echo "صلاحيات الجذر مطلوبة لفحص صحة القرص." || echo "Root privileges required to check disk health.")"
            sleep 3
            check_disk_health_menu
            return
        fi

        # Run SMART tests
        echo -e "\n${CYAN}$([ "$LANGUAGE" == "ar" ] && echo "معلومات القرص:" || echo "Disk Information:")${NC}"
        sudo smartctl -i "$selected_disk"

        echo -e "\n${CYAN}$([ "$LANGUAGE" == "ar" ] && echo "حالة صحة القرص:" || echo "Disk Health Status:")${NC}"
        sudo smartctl -H "$selected_disk"

        echo -e "\n${CYAN}$([ "$LANGUAGE" == "ar" ] && echo "بيانات SMART (أهم السمات):" || echo "SMART Data (Key Attributes):")${NC}"
        # Display key attributes often related to failure
        sudo smartctl -A "$selected_disk" | grep -E '^(ID#|  5|  9| 10|184|187|188|196|197|198|199|201)' | head -n 20

        echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى قائمة استكشاف الأخطاء وإصلاحها..." || echo "Press any key to return to troubleshooting menu...")${NC}"
        read -n 1 -s
        show_troubleshooting_menu
    else
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "خيار غير صالح." || echo "Invalid option.")"
        sleep 2
        check_disk_health_menu
    fi
}

# Function to fix file permissions menu
fix_permissions_menu() {
    show_header

    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "إصلاح أذونات الملفات:" || echo "Fix File Permissions:")${NC}"
    echo # Add an empty line for better spacing

    echo -e "1. 🏠 $([ "$LANGUAGE" == "ar" ] && echo "إصلاح أذونات المجلد الرئيسي" || echo "Fix Home Directory Permissions")"
    echo -e "2. 📁 $([ "$LANGUAGE" == "ar" ] && echo "إصلاح أذونات مجلد محدد" || echo "Fix Specific Directory Permissions")"
    echo -e "0. ↩️  $([ "$LANGUAGE" == "ar" ] && echo "العودة" || echo "Back")"


    echo
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر خيارًا (0-2): " || echo "Choose an option (0-2): ")" choice

    case $choice in
        1)  # Fix home directory permissions
            if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل أنت متأكد من أنك تريد إصلاح أذونات المجلد الرئيسي؟ هذا قد يستغرق بعض الوقت." || echo "Are you sure you want to fix home directory permissions? This might take some time.")"; then
                echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "إصلاح أذونات المجلد الرئيسي..." || echo "Fixing home directory permissions...")${NC}"

                # Set correct ownership first (important!)
                run_with_privileges "chown -R $(whoami):$(whoami) $HOME"

                # Set correct base permissions
                chmod 755 "$HOME"

                # Fix common directories (more robust check)
                find "$HOME" -maxdepth 1 -mindepth 1 -type d -print0 | while IFS= read -r -d $'\0' dir; do
                    chmod 755 "$dir"
                done

                # Fix hidden configuration files and directories (more precise)
                find "$HOME" -maxdepth 1 -name ".*" -type f -print0 | xargs -0 chmod 644 2>/dev/null || true
                find "$HOME" -maxdepth 1 -name ".*" -type d -print0 | xargs -0 chmod 755 2>/dev/null || true

                # Fix permissions inside common config dirs (example)
                # Be careful with recursive changes, target specific known issues if possible
                # Example: chmod 600 "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ed25519" 2>/dev/null || true
                # Example: chmod 644 "$HOME/.ssh/known_hosts" "$HOME/.ssh/config" 2>/dev/null || true

                log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم إصلاح أذونات المجلد الرئيسي." || echo "Home directory permissions fixed.")"
            fi
            ;;
        2)  # Fix specific directory permissions
            echo
            read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "أدخل مسار المجلد: " || echo "Enter directory path: ")" dir_path

            dir_path=$(sanitize_input "$dir_path")
            # Expand tilde
            eval dir_path="$dir_path"

            if [ -d "$dir_path" ]; then
                if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل أنت متأكد من أنك تريد إصلاح أذونات $dir_path؟" || echo "Are you sure you want to fix permissions for $dir_path?")"; then
                    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "إصلاح أذونات $dir_path..." || echo "Fixing permissions for $dir_path...")${NC}"

                    # Determine owner
                    local owner=$(whoami)
                    if [[ "$dir_path" == /media/* || "$dir_path" == /mnt/* ]]; then
                        # For mounted devices, don't change ownership unless forced
                        echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "يبدو أن هذا مسار وسائط خارجية. لن يتم تغيير المالك افتراضيًا." || echo "This looks like an external media path. Ownership will not be changed by default.")${NC}"
                        # Optionally ask if user wants to change ownership anyway
                    else
                        run_with_privileges "chown -R $owner:$owner \"$dir_path\""
                    fi

                    # Set directory permissions (using find for better control)
                    find "$dir_path" -type d -print0 | xargs -0 chmod 755 2>/dev/null || true

                    # Set file permissions
                    find "$dir_path" -type f -print0 | xargs -0 chmod 644 2>/dev/null || true

                    # Make scripts executable (common scenario)
                    find "$dir_path" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.pl" \) -print0 | xargs -0 chmod +x 2>/dev/null || true

                    log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم إصلاح أذونات $dir_path." || echo "Permissions fixed for $dir_path.")"
                fi
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "المجلد غير موجود: $dir_path" || echo "Directory does not exist: $dir_path")"
            fi
            ;;
        0)  # Return to troubleshooting menu
            show_troubleshooting_menu
            return
            ;;
        *)
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "خيار غير صالح." || echo "Invalid option.")"
            ;;
    esac

    sleep 2
    fix_permissions_menu
}

# Reset network settings function
reset_network_settings() {
    show_header

    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "إعادة تعيين إعدادات الشبكة:" || echo "Reset Network Settings:")${NC}"

    if ! check_sudo; then
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "صلاحيات الجذر مطلوبة لإعادة تعيين إعدادات الشبكة." || echo "Root privileges required to reset network settings.")"
        sleep 3
        show_troubleshooting_menu
        return
    fi

    if ! confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل أنت متأكد من أنك تريد إعادة تعيين إعدادات الشبكة؟ سيؤدي ذلك إلى قطع اتصال الشبكة الحالي مؤقتًا." || echo "Are you sure you want to reset network settings? This will temporarily disconnect your network connection.")"; then
        show_troubleshooting_menu
        return
    fi

    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "إعادة تعيين إعدادات الشبكة..." || echo "Resetting network settings...")${NC}"

    # Restart Network Manager (most common)
    if command_exists systemctl && systemctl is-active --quiet NetworkManager; then
        run_with_privileges "systemctl restart NetworkManager"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تمت إعادة تشغيل NetworkManager." || echo "NetworkManager restarted.")"
    elif command_exists service && service --status-all 2>&1 | grep -q "network-manager"; then
        run_with_privileges "service network-manager restart"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تمت إعادة تشغيل network-manager." || echo "network-manager restarted.")"
    else
         log_warning "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على NetworkManager." || echo "NetworkManager not found.")"
    fi

    # Restart networking service (Debian/Ubuntu specific)
    if command_exists systemctl && systemctl list-unit-files | grep -q networking.service; then
        run_with_privileges "systemctl restart networking"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تمت إعادة تشغيل خدمة networking." || echo "Networking service restarted.")"
    elif command_exists service && service --status-all 2>&1 | grep -q "networking"; then
        run_with_privileges "service networking restart"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تمت إعادة تشغيل خدمة networking." || echo "Networking service restarted.")"
    fi

    # Clear DNS cache (systemd-resolved)
    if command_exists systemd-resolve && systemctl is-active --quiet systemd-resolved; then
        run_with_privileges "systemd-resolve --flush-caches"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم مسح ذاكرة التخزين المؤقت لـ systemd-resolved DNS." || echo "systemd-resolved DNS cache flushed.")"
    fi

    # Renew DHCP lease (if dhclient is used)
    if command_exists dhclient; then
        # Get the primary network interface more reliably
        local primary_iface=$(ip route get 1.1.1.1 | grep -oP 'dev\s+\K\S+' | head -n 1)
        if [ -n "$primary_iface" ]; then
            log_info "$([ "$LANGUAGE" == "ar" ] && echo "تجديد عنوان DHCP لـ $primary_iface..." || echo "Renewing DHCP address for $primary_iface...")"
            run_with_privileges "dhclient -r $primary_iface && dhclient $primary_iface"
            log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم تجديد عنوان DHCP لـ $primary_iface." || echo "DHCP address renewed for $primary_iface.")"
        else
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "تعذر تحديد واجهة الشبكة الرئيسية لتجديد DHCP." || echo "Could not determine primary network interface for DHCP renewal.")"
        fi
    fi

    log_success "$([ "$LANGUAGE" == "ar" ] && echo "تمت إعادة تعيين إعدادات الشبكة (قد تحتاج إلى إعادة الاتصال يدويًا)." || echo "Network settings reset (you might need to reconnect manually).")"

    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى قائمة استكشاف الأخطاء وإصلاحها..." || echo "Press any key to return to troubleshooting menu...")${NC}"
    read -n 1 -s
    show_troubleshooting_menu
}

# Fix GRUB menu
fix_grub_menu() {
    show_header

    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "إصلاح سجل إقلاع GRUB:" || echo "Fix GRUB Boot Record:")${NC}"

    if ! check_sudo; then
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "صلاحيات الجذر مطلوبة لإصلاح GRUB." || echo "Root privileges required to fix GRUB.")"
        sleep 3
        show_troubleshooting_menu
        return
    fi

    # Check if needed packages are installed (adapt command based on distro)
    local grub_install_cmd="grub-install"
    local update_grub_cmd="update-grub"
    local grub_package="grub-pc" # Default for Debian/Ubuntu

    if command_exists dnf || command_exists yum; then
        grub_install_cmd="grub2-install"
        update_grub_cmd="grub2-mkconfig -o /boot/grub2/grub.cfg"
        grub_package="grub2-tools" # Example for Fedora/RHEL
        # Check for EFI
        [ -d /sys/firmware/efi ] && grub_package="grub2-efi-x64 $grub_package"
    elif command_exists pacman; then
        grub_install_cmd="grub-install"
        update_grub_cmd="grub-mkconfig -o /boot/grub/grub.cfg"
        grub_package="grub"
    fi


    if ! command_exists "$grub_install_cmd" || ! command_exists "$(echo $update_grub_cmd | cut -d' ' -f1)"; then
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "أدوات GRUB غير مثبتة. هذه الأدوات مطلوبة لإصلاح GRUB." || echo "GRUB tools are not installed. These tools are required to fix GRUB.")"

        # Offer to install grub packages
        if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل تريد تثبيت أدوات GRUB ($grub_package)؟" || echo "Do you want to install GRUB tools ($grub_package)?")"; then
            if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
                 # Handle grub-pc vs grub-efi based on system
                 if [ -d /sys/firmware/efi ]; then grub_package="grub-efi-amd64-signed shim-signed"; else grub_package="grub-pc"; fi
                 run_with_privileges "apt-get update && apt-get install -y $grub_package"
            elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
                run_with_privileges "dnf install -y $grub_package"
            elif [ "$PACKAGE_MANAGER" == "yum" ]; then
                run_with_privileges "yum install -y $grub_package"
            elif [ "$PACKAGE_MANAGER" == "pacman" ]; then
                run_with_privileges "pacman -S --noconfirm $grub_package"
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "لا يمكن تثبيت أدوات GRUB تلقائيًا. يرجى تثبيتها يدويًا." || echo "Cannot install GRUB tools automatically. Please install them manually.")"
                sleep 3
                show_troubleshooting_menu
                return
            fi
            # Re-check commands after installation attempt
             if ! command_exists "$grub_install_cmd" || ! command_exists "$(echo $update_grub_cmd | cut -d' ' -f1)"; then
                 log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل تثبيت أدوات GRUB. لا يمكن المتابعة." || echo "Failed to install GRUB tools. Cannot proceed.")"
                 sleep 3
                 show_troubleshooting_menu
                 return
             fi
        else
            show_troubleshooting_menu
            return
        fi
    fi

    # List available disks
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الأقراص المتوفرة (التي يمكن تثبيت GRUB عليها):" || echo "Available disks (suitable for GRUB installation):")${NC}"

    local disks=()
    local i=0

    if command_exists lsblk; then
        # More reliable way to list block devices suitable for bootloader
        while read -r disk_name disk_size disk_type; do
             # Filter out partitions, CD/DVD drives, loop devices
            if [[ "$disk_type" == "disk" ]]; then
                disks+=("/dev/$disk_name")
                echo -e "$((i+1)). /dev/$disk_name - $disk_size"
                ((i++))
            fi
        done < <(lsblk -d -o NAME,SIZE,TYPE -n | grep -v "sr[0-9]" | grep -v "loop")
    else
        # Fallback method (less reliable)
        for disk in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
            if [ -b "$disk" ]; then
                disks+=("$disk")
                local disk_size=$(blockdev --getsize64 "$disk" 2>/dev/null | awk '{printf "%.1f GB", $1/1024/1024/1024}')
                echo -e "$((i+1)). $disk - $disk_size"
                ((i++))
            fi
        done
    fi

    if [ ${#disks[@]} -eq 0 ]; then
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على أقراص مناسبة لتثبيت GRUB." || echo "No suitable disks found for GRUB installation.")"
        sleep 3
        show_troubleshooting_menu
        return
    fi

    echo
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر قرصًا لتثبيت GRUB عليه (1-${#disks[@]}) أو 0 للعودة: " || echo "Choose a disk to install GRUB to (1-${#disks[@]}) or 0 to go back: ")" disk_choice

    if [ "$disk_choice" -eq 0 ]; then
        show_troubleshooting_menu
        return
    fi

    if [[ "$disk_choice" =~ ^[0-9]+$ ]] && [ "$disk_choice" -ge 1 ] && [ "$disk_choice" -le ${#disks[@]} ]; then
        local selected_disk="${disks[$((disk_choice-1))]}"

        if ! confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل أنت متأكد من أنك تريد تثبيت GRUB على ${BOLD}${selected_disk}${NC}؟ هذا قد يؤثر على قدرة النظام على الإقلاع إذا تم التثبيت على قرص خاطئ." || echo "Are you sure you want to install GRUB to ${BOLD}${selected_disk}${NC}? This could affect system bootability if installed to the wrong disk.")"; then
            show_troubleshooting_menu
            return
        fi

        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تثبيت GRUB على $selected_disk..." || echo "Installing GRUB to $selected_disk...")${NC}"

        # Install GRUB to the selected disk
        if run_with_privileges "$grub_install_cmd $selected_disk"; then
            log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم تثبيت GRUB على $selected_disk بنجاح." || echo "GRUB installed successfully to $selected_disk.")"

            # Update GRUB configuration
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تحديث تكوين GRUB..." || echo "Updating GRUB configuration...")${NC}"
            if run_with_privileges "$update_grub_cmd"; then
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم تحديث تكوين GRUB بنجاح." || echo "GRUB configuration updated successfully.")"
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل تحديث تكوين GRUB." || echo "Failed to update GRUB configuration.")"
            fi
        else
            log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل تثبيت GRUB على $selected_disk." || echo "Failed to install GRUB to $selected_disk.")"
        fi
    else
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "خيار غير صالح." || echo "Invalid option.")"
        sleep 2
        fix_grub_menu
        return
    fi

    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى قائمة استكشاف الأخطاء وإصلاحها..." || echo "Press any key to return to troubleshooting menu...")${NC}"
    read -n 1 -s
    show_troubleshooting_menu
}

# Function to view system logs
view_system_logs() {
    show_header

    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "عرض سجلات النظام:" || echo "View System Logs:")${NC}"
    echo # Add an empty line for better spacing

    echo -e "1. 📜 $([ "$LANGUAGE" == "ar" ] && echo "سجل النظام (syslog/journalctl)" || echo "System Log (syslog/journalctl)")"
    echo -e "2. 🔥 $([ "$LANGUAGE" == "ar" ] && echo "سجل النواة (kernel)" || echo "Kernel Log (kern.log/dmesg)")"
    echo -e "3. 🔑 $([ "$LANGUAGE" == "ar" ] && echo "سجل المصادقة (auth.log)" || echo "Authentication Log (auth.log)")"
    echo -e "4. 📦 $([ "$LANGUAGE" == "ar" ] && echo "سجل مدير حزم البرامج (dpkg/dnf/pacman)" || echo "Package Manager Log (dpkg/dnf/pacman)")"
    echo -e "5. 🖥️ $([ "$LANGUAGE" == "ar" ] && echo "سجل Xorg (Xorg.0.log)" || echo "Xorg Log (Xorg.0.log)")"
    echo -e "6. 🛠️ $([ "$LANGUAGE" == "ar" ] && echo "سجل هذه الأداة" || echo "This Tool's Log")"
    echo -e "0. ↩️  $([ "$LANGUAGE" == "ar" ] && echo "العودة" || echo "Back")"


    echo
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر سجلًا للعرض (0-6): " || echo "Choose a log to view (0-6): ")" log_choice

    local log_file=""
    local log_command=""
    local log_title=""
    local pager="less" # Default pager

    # Check if less is available, otherwise use cat
    if ! command_exists less; then
        pager="cat"
    fi

    case $log_choice in
        1)  # System log (journalctl preferred)
            log_title=$([ "$LANGUAGE" == "ar" ] && echo "سجل النظام" || echo "System Log")
            if command_exists journalctl; then
                log_command="journalctl -n 500 --no-pager" # Show last 500 lines
                # Optionally use 'journalctl -f' for live view
            elif [ -f "/var/log/syslog" ]; then
                log_file="/var/log/syslog"
            elif [ -f "/var/log/messages" ]; then # Fallback for RHEL/CentOS
                log_file="/var/log/messages"
            else
                 log_warning "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على سجل النظام." || echo "System log not found.")"; sleep 2; view_system_logs; return
            fi
            ;;
        2)  # Kernel log (dmesg preferred)
             log_title=$([ "$LANGUAGE" == "ar" ] && echo "سجل النواة" || echo "Kernel Log")
            if command_exists dmesg; then
                 log_command="dmesg --level=err,warn -T" # Show errors and warnings with timestamps
            elif [ -f "/var/log/kern.log" ]; then
                log_file="/var/log/kern.log"
            else
                 log_warning "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على سجل النواة." || echo "Kernel log not found.")"; sleep 2; view_system_logs; return
            fi
            ;;
        3)  # Auth log
            log_title=$([ "$LANGUAGE" == "ar" ] && echo "سجل المصادقة" || echo "Authentication Log")
            if [ -f "/var/log/auth.log" ]; then # Debian/Ubuntu
                log_file="/var/log/auth.log"
            elif [ -f "/var/log/secure" ]; then # RHEL/CentOS/Fedora
                 log_file="/var/log/secure"
            else
                 log_warning "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على سجل المصادقة." || echo "Authentication log not found.")"; sleep 2; view_system_logs; return
            fi
            ;;
        4)  # Package Manager log
            log_title=$([ "$LANGUAGE" == "ar" ] && echo "سجل مدير الحزم" || echo "Package Manager Log")
            case "$PACKAGE_MANAGER" in
                "apt-get") log_file="/var/log/apt/history.log" ;;
                "dnf") log_file="/var/log/dnf.log" ;;
                "yum") log_file="/var/log/yum.log" ;;
                "pacman") log_file="/var/log/pacman.log" ;;
                *) log_warning "$([ "$LANGUAGE" == "ar" ] && echo "مدير حزم غير معروف أو ليس له ملف سجل قياسي." || echo "Unknown package manager or no standard log file.")"; sleep 2; view_system_logs; return ;;
            esac
             if [ ! -f "$log_file" ]; then
                 log_warning "$([ "$LANGUAGE" == "ar" ] && echo "ملف سجل مدير الحزم غير موجود: $log_file" || echo "Package manager log file not found: $log_file")"; sleep 2; view_system_logs; return
             fi
            ;;
        5)  # Xorg log
            log_title="Xorg Log"
            # Find the correct Xorg log file
            if [ -f "/var/log/Xorg.0.log" ]; then
                log_file="/var/log/Xorg.0.log"
            elif [ -f "$HOME/.local/share/xorg/Xorg.0.log" ]; then # Wayland sessions might put it here
                 log_file="$HOME/.local/share/xorg/Xorg.0.log"
            else
                 log_warning "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على سجل Xorg." || echo "Xorg log not found.")"; sleep 2; view_system_logs; return
            fi
            ;;
        6)  # Tool log
            log_title=$([ "$LANGUAGE" == "ar" ] && echo "سجل هذه الأداة" || echo "This Tool's Log")
            if [ -f "$LOG_FILE" ]; then
                log_file="$LOG_FILE"
            else
                log_warning "$([ "$LANGUAGE" == "ar" ] && echo "ملف سجل الأداة غير موجود بعد." || echo "Tool log file does not exist yet.")"; sleep 2; view_system_logs; return
            fi
            ;;
        0)  # Return to troubleshooting menu
            show_troubleshooting_menu
            return
            ;;
        *)
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "خيار غير صالح." || echo "Invalid option.")"
            sleep 2
            view_system_logs
            return
            ;;
    esac

    # View the selected log
    show_header
    echo -e "${BOLD}${log_title}:${NC}\n"

    # Function to display log content using pager
    display_log() {
        local cmd="$1"
        # Use sudo if needed and not viewing the tool's own log
        if check_sudo || [[ "$log_file" == "$LOG_FILE" ]]; then
             eval "$cmd" | "$pager"
        else
             sudo bash -c "$cmd" | "$pager" 2>/dev/null || echo -e "${RED}$([ "$LANGUAGE" == "ar" ] && echo "خطأ في القراءة: صلاحيات غير كافية أو خطأ آخر." || echo "Read error: insufficient permissions or other error.")${NC}"
        fi
    }

    if [ -n "$log_command" ]; then
        display_log "$log_command"
    elif [ -n "$log_file" ]; then
        if [ -f "$log_file" ]; then
             display_log "tail -n 500 '$log_file'" # Show last 500 lines by default
        else
            echo -e "${RED}$([ "$LANGUAGE" == "ar" ] && echo "ملف السجل المحدد غير موجود: $log_file" || echo "Selected log file does not exist: $log_file")${NC}"
        fi
    fi

    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى قائمة السجلات..." || echo "Press any key to return to the logs menu...")${NC}"
    read -n 1 -s
    view_system_logs
}

# Function to perform quick health check
perform_quick_health_check() {
    show_header

    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "الفحص السريع لصحة النظام:" || echo "Quick System Health Check:")${NC}"

    # Check CPU usage
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "استخدام وحدة المعالجة المركزية:" || echo "CPU Usage:")${NC}"
    # Get CPU usage more reliably using top
    local cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print $1}')
    local cpu_usage=$(awk -v idle="$cpu_idle" 'BEGIN { printf "%.0f", 100 - idle }')
    local cpu_status=""

    if (( $(echo "$cpu_usage < 70" | bc -l) )); then
        cpu_status="${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "جيد" || echo "Good")${NC}"
    elif (( $(echo "$cpu_usage < 90" | bc -l) )); then
        cpu_status="${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "متوسط" || echo "Moderate")${NC}"
    else
        cpu_status="${RED}$([ "$LANGUAGE" == "ar" ] && echo "مرتفع" || echo "High")${NC}"
    fi

    echo -e "$([ "$LANGUAGE" == "ar" ] && echo "استخدام وحدة المعالجة المركزية:" || echo "CPU Usage:") ${cpu_usage}% ($cpu_status)"
    echo -e "$(create_progress_bar "$cpu_usage")"


    # Check RAM usage
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "استخدام الذاكرة:" || echo "Memory Usage:")${NC}"
    local mem_info=$(free -m)
    local total_mem=$(echo "$mem_info" | awk '/Mem:/ {print $2}')
    local used_mem=$(echo "$mem_info" | awk '/Mem:/ {print $3}')
    local mem_percent=0
    [ "$total_mem" -gt 0 ] && mem_percent=$(( used_mem * 100 / total_mem ))

    local mem_status=""
    if [ "$mem_percent" -lt 70 ]; then
        mem_status="${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "جيد" || echo "Good")${NC}"
    elif [ "$mem_percent" -lt 90 ]; then
        mem_status="${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "متوسط" || echo "Moderate")${NC}"
    else
        mem_status="${RED}$([ "$LANGUAGE" == "ar" ] && echo "مرتفع" || echo "High")${NC}"
    fi

    echo -e "$([ "$LANGUAGE" == "ar" ] && echo "استخدام الذاكرة:" || echo "Memory Usage:") ${used_mem}MB / ${total_mem}MB (${mem_percent}%) ($mem_status)"
    echo -e "$(create_progress_bar "$mem_percent")"

    # Check disk usage for / and /home if separate
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "استخدام القرص:" || echo "Disk Usage:")${NC}"
    df -h | grep -E '^/dev/|^Filesystem' | while read -r line; do
        if [[ "$line" =~ ^Filesystem ]]; then
             echo "$line" # Print header
             continue
        fi
        local mount_point=$(echo "$line" | awk '{print $NF}')
        local disk_percent=$(echo "$line" | awk '{print $5}' | tr -d '%')
        local disk_status=""

        if [ "$disk_percent" -lt 70 ]; then
            disk_status="${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "جيد" || echo "Good")${NC}"
        elif [ "$disk_percent" -lt 90 ]; then
            disk_status="${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "متوسط" || echo "Moderate")${NC}"
        else
            disk_status="${RED}$([ "$LANGUAGE" == "ar" ] && echo "مرتفع" || echo "High")${NC}"
        fi
         echo -e "$line ($disk_status)"
         echo -e "$(create_progress_bar "$disk_percent")"
    done


    # Check for updates (using the specific package manager)
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "التحقق من التحديثات المتاحة:" || echo "Checking for available updates:")${NC}"
    local updates=0
    local security_updates=0

    if ! check_internet; then
        echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تعذر التحقق من التحديثات: لا يوجد اتصال بالإنترنت." || echo "Could not check for updates: No internet connection.")${NC}"
    else
        case "$PACKAGE_MANAGER" in
            "apt-get")
                run_with_privileges "apt-get update -qq" > /dev/null 2>&1
                updates=$(apt-get -s upgrade | grep -c "^Inst")
                security_updates=$(apt-get -s upgrade | grep -c "^Inst.*security")
                ;;
            "dnf")
                updates=$(dnf check-update -q | wc -l)
                security_updates=$(dnf updateinfo list security -q | wc -l)
                 # Subtract header line if present
                 [ $security_updates -gt 0 ] && security_updates=$((security_updates - 1))
                ;;
             "yum")
                 updates=$(yum check-update -q | grep -v '^$' | wc -l)
                 security_updates=$(yum updateinfo list security -q | grep -v '^$' | wc -l)
                 # Subtract header line if present
                 [ $security_updates -gt 0 ] && security_updates=$((security_updates - 1))
                 ;;
            "pacman")
                 run_with_privileges "pacman -Sy" > /dev/null 2>&1
                 updates=$(pacman -Qu | wc -l)
                 # Pacman doesn't easily differentiate security updates
                 security_updates="N/A"
                 ;;
             *) updates="N/A"; security_updates="N/A" ;;
        esac

        echo -e "$([ "$LANGUAGE" == "ar" ] && echo "التحديثات المتاحة:" || echo "Available updates:") ${updates}"
        echo -e "$([ "$LANGUAGE" == "ar" ] && echo "تحديثات الأمان:" || echo "Security updates:") ${security_updates}"

        if [[ "$security_updates" != "N/A" && "$security_updates" -gt 0 ]]; then
            echo -e "${RED}${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "يوصى بتثبيت تحديثات الأمان فورًا!" || echo "Security updates recommended to install immediately!")${NC}"
        elif [[ "$updates" != "N/A" && "$updates" -gt 0 ]]; then
             echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "يوصى بتشغيل تحديث النظام." || echo "Running a system update is recommended.")${NC}"
        fi
    fi


    # Check system load
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "حمل النظام:" || echo "System Load:")${NC}"
    local load_avg=$(cat /proc/loadavg | cut -d " " -f 1-3)
    local cpu_cores=$(grep -c processor /proc/cpuinfo)
    local load1=$(echo "$load_avg" | cut -d " " -f 1)

    local load_status=""
    # Compare load average to number of cores
    if (( $(echo "$load1 < $cpu_cores * 0.7" | bc -l) )); then
        load_status="${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "جيد" || echo "Good")${NC}"
    elif (( $(echo "$load1 < $cpu_cores * 1.0" | bc -l) )); then
        load_status="${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "متوسط" || echo "Moderate")${NC}"
    else
        load_status="${RED}$([ "$LANGUAGE" == "ar" ] && echo "مرتفع" || echo "High")${NC}"
    fi

    echo -e "$([ "$LANGUAGE" == "ar" ] && echo "حمل النظام (1، 5، 15 دقيقة):" || echo "Load Average (1, 5, 15 min):") ${load_avg} ($load_status)"
    echo -e "$([ "$LANGUAGE" == "ar" ] && echo "عدد أنوية وحدة المعالجة المركزية:" || echo "CPU Cores:") ${cpu_cores}"

    # Show system uptime
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "مدة تشغيل النظام:" || echo "System Uptime:")${NC}"
    echo -e "$(uptime -p)"

    # Final assessment
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "التقييم النهائي:" || echo "Final Assessment:")${NC}"

    local issues=0
    local issue_summary=""

    if [ "$mem_percent" -gt 90 ]; then ((issues++)); issue_summary+=$([ "$LANGUAGE" == "ar" ] && echo "- استخدام ذاكرة مرتفع جدًا " || echo "- Very high memory usage "); fi
    # Check root disk usage specifically
    local root_disk_percent=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$root_disk_percent" -gt 90 ]; then ((issues++)); issue_summary+=$([ "$LANGUAGE" == "ar" ] && echo "- مساحة قرص الجذر منخفضة جدًا " || echo "- Root disk space critically low "); fi
    if (( $(echo "$load1 > $cpu_cores * 1.5" | bc -l) )); then ((issues++)); issue_summary+=$([ "$LANGUAGE" == "ar" ] && echo "- حمل النظام مرتفع جدًا " || echo "- System load very high "); fi
    if [[ "$security_updates" != "N/A" && "$security_updates" -gt 0 ]]; then ((issues++)); issue_summary+=$([ "$LANGUAGE" == "ar" ] && echo "- تحديثات أمان معلقة " || echo "- Pending security updates "); fi

    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "النظام يبدو في حالة جيدة!" || echo "System appears to be healthy!")${NC}"
    elif [ $issues -eq 1 ]; then
        echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تم اكتشاف مشكلة واحدة:" || echo "One issue detected:") ${issue_summary}${NC}"
        echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "يوصى بمراجعة المشكلة واتخاذ إجراء إذا لزم الأمر." || echo "Reviewing the issue and taking action if necessary is recommended.")${NC}"
    else
        echo -e "${RED}$([ "$LANGUAGE" == "ar" ] && echo "تم اكتشاف $issues مشكلات:" || echo "$issues issues detected:") ${issue_summary}${NC}"
        echo -e "${RED}${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "يوصى بشدة باتخاذ إجراء لمعالجة هذه المشكلات." || echo "Action is strongly recommended to address these issues.")${NC}"
    fi

    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى القائمة الرئيسية..." || echo "Press any key to return to the main menu...")${NC}"
    read -n 1 -s
    show_menu
}


