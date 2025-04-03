#!/bin/bash

# Author: Fahad Alsharari (enhanced by Claude)
# Website: https://FahadAlsharari.sa
# Contact: admin@FahadAlsharari.sa

# Optimized unified cleanup function
perform_cleanup() {
    start_timer
    show_header
    
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "تنظيف النظام:" || echo "System Cleanup:")${NC}"
    
    # Confirm before proceeding
    if ! confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل تريد المتابعة في تنظيف النظام؟" || echo "Do you want to proceed with system cleanup?")"; then
        show_menu
        return
    fi
    
    # Get initial disk usage
    local initial_usage=$(df -BM / | awk 'NR==2 {print $3}' | tr -d 'M')
    local total_freed=0
    
    # Determine package manager and perform cleanup accordingly
    if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        # Run apt cleanup (for Debian/Ubuntu)
        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تنظيف حزم APT..." || echo "Cleaning APT packages...")${NC}"
        
        # Show current package cache size
        local apt_cache_size_before=$(du -sh /var/cache/apt/archives/ 2>/dev/null | cut -f1 || echo "Unknown")
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "حجم ذاكرة التخزين المؤقت للحزم الحالية:" || echo "Current package cache size:") ${apt_cache_size_before}"
        
        # APT cleanup in one operation
        {
            # Remove unused packages
            run_with_privileges "apt-get autoremove -y"
            # Clean apt cache
            run_with_privileges "apt-get autoclean -y"
            # Clean package archives
            run_with_privileges "apt-get clean -y"
        } &>/dev/null
        
        # Show freed space
        local apt_cache_size_after=$(du -sh /var/cache/apt/archives/ 2>/dev/null | cut -f1 || echo "Unknown")
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم تنظيف حزم APT. حجم ذاكرة التخزين المؤقت الجديد:" || echo "APT packages cleaned. New cache size:") ${apt_cache_size_after}"
    
    elif [ "$PACKAGE_MANAGER" == "dnf" ] || [ "$PACKAGE_MANAGER" == "yum" ]; then
        # Run DNF/YUM cleanup (for Fedora/CentOS/RHEL)
        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تنظيف حزم $PACKAGE_MANAGER..." || echo "Cleaning $PACKAGE_MANAGER packages...")${NC}"
        
        # Show current package cache size
        local rpm_cache_dir="/var/cache/$PACKAGE_MANAGER"
        local rpm_cache_size_before=$(du -sh "$rpm_cache_dir" 2>/dev/null | cut -f1 || echo "Unknown")
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "حجم ذاكرة التخزين المؤقت للحزم الحالية:" || echo "Current package cache size:") ${rpm_cache_size_before}"
        
        # Package manager cleanup
        {
            if [ "$PACKAGE_MANAGER" == "dnf" ]; then
                run_with_privileges "dnf clean all"
                run_with_privileges "dnf autoremove -y"
            else
                run_with_privileges "yum clean all"
                run_with_privileges "yum autoremove -y"
            fi
        } &>/dev/null
        
        # Show freed space
        local rpm_cache_size_after=$(du -sh "$rpm_cache_dir" 2>/dev/null | cut -f1 || echo "Unknown")
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم تنظيف حزم $PACKAGE_MANAGER. حجم ذاكرة التخزين المؤقت الجديد:" || echo "$PACKAGE_MANAGER packages cleaned. New cache size:") ${rpm_cache_size_after}"
    
    elif [ "$PACKAGE_MANAGER" == "pacman" ]; then
        # Run pacman cleanup (for Arch)
        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تنظيف حزم pacman..." || echo "Cleaning pacman packages...")${NC}"
        
        # Show current package cache size
        local pacman_cache_dir="/var/cache/pacman/pkg"
        local pacman_cache_size_before=$(du -sh "$pacman_cache_dir" 2>/dev/null | cut -f1 || echo "Unknown")
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "حجم ذاكرة التخزين المؤقت للحزم الحالية:" || echo "Current package cache size:") ${pacman_cache_size_before}"
        
        # Package manager cleanup
        {
            run_with_privileges "pacman -Sc --noconfirm"
            
            # Remove orphaned packages
            if command_exists paru; then
                run_with_privileges "paru -c"
            elif command_exists yay; then
                run_with_privileges "yay -c"
            fi
        } &>/dev/null
        
        # Show freed space
        local pacman_cache_size_after=$(du -sh "$pacman_cache_dir" 2>/dev/null | cut -f1 || echo "Unknown")
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم تنظيف حزم pacman. حجم ذاكرة التخزين المؤقت الجديد:" || echo "pacman packages cleaned. New cache size:") ${pacman_cache_size_after}"
    fi
    
    # Clean cache directories if enabled
    if [ "$CLEAN_CACHE" -eq 1 ]; then
        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تنظيف ذاكرة التخزين المؤقت..." || echo "Cleaning cache directories...")${NC}"
        
        # Clean ~/.cache
        if [ -d "${HOME}/.cache" ]; then
            local cache_size_before=$(du -sh "${HOME}/.cache" 2>/dev/null | cut -f1)
            log_info "$([ "$LANGUAGE" == "ar" ] && echo "حجم ذاكرة التخزين المؤقت قبل التنظيف: $cache_size_before" || echo "Cache size before cleaning: $cache_size_before")"
            
            # Clean cache files but exclude important directories
            find "${HOME}/.cache" -type f -not -path "*/important_dir/*" -delete 2>/dev/null
            find "${HOME}/.cache" -type d -empty -delete 2>/dev/null
            
            local cache_size_after=$(du -sh "${HOME}/.cache" 2>/dev/null | cut -f1)
            log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم تنظيف ~/.cache. الحجم بعد التنظيف: $cache_size_after" || echo "Cleaned ~/.cache. Size after cleaning: $cache_size_after")"
        fi
        
        # Clean ~/.thumbnails
        if [ -d "${HOME}/.thumbnails" ]; then
            local thumbnails_size_before=$(du -sh "${HOME}/.thumbnails" 2>/dev/null | cut -f1)
            log_info "$([ "$LANGUAGE" == "ar" ] && echo "حجم الصور المصغرة قبل التنظيف: $thumbnails_size_before" || echo "Thumbnails size before cleaning: $thumbnails_size_before")"
            
            find "${HOME}/.thumbnails" -type f -delete 2>/dev/null
            
            local thumbnails_size_after=$(du -sh "${HOME}/.thumbnails" 2>/dev/null | cut -f1)
            log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم تنظيف ~/.thumbnails. الحجم بعد التنظيف: $thumbnails_size_after" || echo "Cleaned ~/.thumbnails. Size after cleaning: $thumbnails_size_after")"
        fi
    fi
    
    # Clean browser cache if enabled
    if [ "$CLEAN_BROWSER_CACHE" -eq 1 ]; then
        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تنظيف ذاكرة التخزين المؤقت للمتصفح..." || echo "Cleaning browser cache...")${NC}"
        
        # Unified browser cache cleaning function
        clean_browser_cache() {
            local browser_name="$1"
            local browser_path="$2"
            local cache_patterns=("$3")
            
            if [ -d "$browser_path" ]; then
                local size_before=$(du -sh "$browser_path" 2>/dev/null | cut -f1)
                log_info "$([ "$LANGUAGE" == "ar" ] && echo "حجم ملفات $browser_name قبل التنظيف: $size_before" || echo "$browser_name files size before cleaning: $size_before")"
                
                # Clean cache directories
                for pattern in "${cache_patterns[@]}"; do
                    find "$browser_path" -name "$pattern" -type d -exec rm -rf {} \; 2>/dev/null
                done
                
                local size_after=$(du -sh "$browser_path" 2>/dev/null | cut -f1)
                log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم تنظيف ذاكرة التخزين المؤقت لـ $browser_name. الحجم بعد التنظيف: $size_after" || echo "Cleaned $browser_name cache. Size after cleaning: $size_after")"
            fi
        }
        
        # Clean Firefox cache
        clean_browser_cache "Firefox" "${HOME}/.mozilla/firefox" "Cache*" "cache2" "thumbnails" "cookies.sqlite"
        
        # Clean Chrome cache
        clean_browser_cache "Chrome" "${HOME}/.config/google-chrome" "Cache" "Media Cache" "GPUCache"
        
        # Clean Chromium cache
        clean_browser_cache "Chromium" "${HOME}/.config/chromium" "Cache" "Media Cache" "GPUCache"
        
        # Clean Opera cache (additional browser)
        clean_browser_cache "Opera" "${HOME}/.config/opera" "Cache" "GPUCache"
        
        # Clean Brave cache (additional browser)
        clean_browser_cache "Brave" "${HOME}/.config/BraveSoftware/Brave-Browser" "Cache" "GPUCache"
    fi
    
    # Empty trash if enabled
    if [ "$EMPTY_TRASH" -eq 1 ]; then
        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تفريغ سلة المهملات..." || echo "Emptying trash...")${NC}"
        
        if [ -d "${HOME}/.local/share/Trash" ]; then
            local trash_size_before=$(du -sh "${HOME}/.local/share/Trash" 2>/dev/null | cut -f1)
            log_info "$([ "$LANGUAGE" == "ar" ] && echo "حجم سلة المهملات قبل التنظيف: $trash_size_before" || echo "Trash size before cleaning: $trash_size_before")"
            
            # Empty trash in one step
            rm -rf "${HOME}/.local/share/Trash/files"/* "${HOME}/.local/share/Trash/info"/* 2>/dev/null
            
            local trash_size_after=$(du -sh "${HOME}/.local/share/Trash" 2>/dev/null | cut -f1)
            log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم تفريغ سلة المهملات. الحجم بعد التنظيف: $trash_size_after" || echo "Emptied trash. Size after cleaning: $trash_size_after")"
        fi
    fi
    
    # Clean temporary files
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تنظيف الملفات المؤقتة القديمة..." || echo "Cleaning old temporary files...")${NC}"
    
    # Clean /tmp in one operation
    if [ -d "/tmp" ]; then
        local tmp_size_before=$(du -sh /tmp 2>/dev/null | cut -f1)
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "حجم /tmp قبل التنظيف: $tmp_size_before" || echo "/tmp size before cleaning: $tmp_size_before")"
        
        # Only clean files owned by current user or with sudo
        if check_sudo; then
            # Clean temp files with sudo
            find /tmp -type f -atime +"${TMP_FILE_AGE}" -delete 2>/dev/null
            find /tmp -type d -empty -delete 2>/dev/null
        else
            # Clean only user's temp files
            find /tmp -user $(whoami) -type f -atime +"${TMP_FILE_AGE}" -delete 2>/dev/null
            find /tmp -user $(whoami) -type d -empty -delete 2>/dev/null
        fi
        
        local tmp_size_after=$(du -sh /tmp 2>/dev/null | cut -f1)
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم تنظيف الملفات المؤقتة القديمة. الحجم بعد التنظيف: $tmp_size_after" || echo "Cleaned old temporary files. Size after cleaning: $tmp_size_after")"
    fi
    
    # Clean user's temp directory if it exists
    if [ -d "${HOME}/tmp" ]; then
        find "${HOME}/tmp" -type f -atime +"${TMP_FILE_AGE}" -delete 2>/dev/null
        find "${HOME}/tmp" -type d -empty -delete 2>/dev/null
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم تنظيف ~/tmp" || echo "Cleaned ~/tmp")"
    fi
    
    # Clean old logs
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تنظيف ملفات السجل القديمة..." || echo "Cleaning old log files...")${NC}"
    
    # Clean log files in one operation with sudo
    if check_sudo; then
        {
            find /var/log -type f -name "*.gz" -delete 2>/dev/null
            find /var/log -type f -name "*.old" -delete 2>/dev/null
            find /var/log -type f -name "*.1" -delete 2>/dev/null
            
            # Truncate large log files
            for log_file in /var/log/syslog /var/log/kern.log /var/log/auth.log /var/log/dpkg.log; do
                if [ -f "$log_file" ] && [ "$(stat -c %s "$log_file" 2>/dev/null || echo 0)" -gt 1048576 ]; then
                    echo "" > "$log_file" 2>/dev/null
                fi
            done
        } &>/dev/null
        
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم تنظيف ملفات السجل القديمة." || echo "Cleaned old log files.")"
    else
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "صلاحيات sudo مطلوبة لتنظيف ملفات السجل." || echo "sudo privileges required to clean log files.")"
    fi
    
    # Clean package management caches
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تنظيف ذاكرة التخزين المؤقت لإدارة الحزم..." || echo "Cleaning package management caches...")${NC}"
    
    # Clean flatpak unused runtimes
    if command_exists flatpak; then
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تنظيف بيانات Flatpak غير المستخدمة..." || echo "Cleaning unused Flatpak data...")"
        flatpak uninstall --unused -y &>/dev/null
    fi
    
    # Clean snap cache
    if command_exists snap; then
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تنظيف إصدارات Snap القديمة..." || echo "Cleaning old Snap versions...")"
        snap list --all | awk '/disabled/{print $1, $3}' | while read -r snapname revision; do
            sudo snap remove "$snapname" --revision="$revision" &>/dev/null
        done
    fi
    
    # Calculate space freed
    local final_usage=$(df -BM / | awk 'NR==2 {print $3}' | tr -d 'M')
    local freed_space=$((initial_usage - final_usage))
    
    if [ "$freed_space" -gt 0 ]; then
        echo -e "\n${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "تم تحرير مساحة قدرها:" || echo "Total space freed:") ${freed_space} MB${NC}"
    else
        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "لم يتم تحرير مساحة كبيرة." || echo "No significant space was freed.")${NC}"
    fi
    
    stop_timer
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الوقت المستغرق:" || echo "Time taken:") $(get_elapsed_time) $([ "$LANGUAGE" == "ar" ] && echo "ثانية" || echo "seconds")${NC}"
    
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى القائمة الرئيسية..." || echo "Press any key to return to the main menu...")${NC}"
    read -n 1 -s
    show_menu
}

# System update function (cross-distro compatible)
system_update() {
    start_timer
    show_header
    
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "تحديث النظام:" || echo "System Update:")${NC}"
    
    # Check internet connectivity
    check_internet
    
    # Confirm before proceeding
    if ! confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل تريد المتابعة في تحديث النظام؟" || echo "Do you want to proceed with system update?")"; then
        show_menu
        return
    fi
    
    # Use the appropriate package manager for updates
    case "$PACKAGE_MANAGER" in
        apt-get)
            # Debian/Ubuntu update
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تحديث قوائم الحزم..." || echo "Updating package lists...")${NC}"
            if run_with_privileges "apt-get update"; then
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم تحديث قوائم الحزم بنجاح." || echo "Successfully updated package lists.")"
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل تحديث قوائم الحزم." || echo "Failed to update package lists.")"
            fi
            
            # Get update counts
            local update_info=$(apt-get upgrade -s 2>/dev/null)
            local security_updates=$(echo "$update_info" | grep -c "security")
            local general_updates=$(echo "$update_info" | grep -c "^Inst" | expr - $security_updates 2>/dev/null || echo "0")
            
            echo -e "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "التحديثات المتاحة:" || echo "Available updates:")"
            echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "تحديثات الأمان:" || echo "Security updates:") ${security_updates}"
            echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "تحديثات عامة:" || echo "General updates:") ${general_updates}${NC}"
            
            # Perform the upgrades
            if [ "$security_updates" -gt 0 ] || [ "$general_updates" -gt 0 ]; then
                # Upgrade packages
                echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "ترقية الحزم..." || echo "Upgrading packages...")${NC}"
                if run_with_privileges "apt-get upgrade -y"; then
                    log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم ترقية الحزم بنجاح." || echo "Successfully upgraded packages.")"
                else
                    log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل ترقية الحزم." || echo "Failed to upgrade packages.")"
                fi
                
                # Check if dist-upgrade is needed
                local dist_upgrade_count=$(apt-get dist-upgrade -s 2>/dev/null | grep -c "^Inst" || echo "0")
                if [ "$dist_upgrade_count" -gt 0 ]; then
                    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "هناك $dist_upgrade_count تحديثات إضافية متاحة. هل ترغب في تثبيتها؟" || echo "There are $dist_upgrade_count additional updates available. Would you like to install them?")${NC}"
                    if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "تشغيل dist-upgrade؟" || echo "Run dist-upgrade?")"; then
                        run_with_privileges "apt-get dist-upgrade -y"
                        log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم تشغيل dist-upgrade بنجاح." || echo "Successfully ran dist-upgrade.")"
                    fi
                fi
            else
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "النظام محدث بالكامل." || echo "System is fully up to date.")"
            fi
            ;;
            
        dnf)
            # Fedora/RHEL update
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تحديث النظام باستخدام DNF..." || echo "Updating system using DNF...")${NC}"
            
            # Get update info
            local updates_available=$(run_with_privileges "dnf check-update -q | wc -l")
            
            if [ "$updates_available" -gt 0 ]; then
                echo -e "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "التحديثات المتاحة:" || echo "Available updates:") ${updates_available}${NC}"
                
                if run_with_privileges "dnf upgrade -y"; then
                    log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم تحديث النظام بنجاح." || echo "Successfully updated system.")"
                else
                    log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل تحديث النظام." || echo "Failed to update system.")"
                fi
            else
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "النظام محدث بالكامل." || echo "System is fully up to date.")"
            fi
            ;;
            
        yum)
            # CentOS/older RHEL update
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تحديث النظام باستخدام YUM..." || echo "Updating system using YUM...")${NC}"
            
            if run_with_privileges "yum update -y"; then
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم تحديث النظام بنجاح." || echo "Successfully updated system.")"
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل تحديث النظام." || echo "Failed to update system.")"
            fi
            ;;
            
        pacman)
            # Arch Linux update
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تحديث النظام باستخدام Pacman..." || echo "Updating system using Pacman...")${NC}"
            
            # First sync the database
            if run_with_privileges "pacman -Sy"; then
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم تحديث قواعد البيانات بنجاح." || echo "Successfully synchronized databases.")"
                
                # Get number of updates
                local updates_available=$(pacman -Qu | wc -l)
                
                if [ "$updates_available" -gt 0 ]; then
                    echo -e "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "التحديثات المتاحة:" || echo "Available updates:") ${updates_available}${NC}"
                    
                    if run_with_privileges "pacman -Su --noconfirm"; then
                        log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم تحديث النظام بنجاح." || echo "Successfully updated system.")"
                    else
                        log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل تحديث النظام." || echo "Failed to update system.")"
                    fi
                else
                    log_success "$([ "$LANGUAGE" == "ar" ] && echo "النظام محدث بالكامل." || echo "System is fully up to date.")"
                fi
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل تحديث قواعد البيانات." || echo "Failed to synchronize databases.")"
            fi
            ;;
            
        *)
            log_error "$([ "$LANGUAGE" == "ar" ] && echo "مدير الحزم غير معروف. تعذر تحديث النظام." || echo "Unknown package manager. Cannot update system.")"
            sleep 3
            show_menu
            return
            ;;
    esac
    
    # Update other package managers
    # Update Flatpak packages if flatpak is installed
    if command_exists flatpak; then
        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تحديث حزم Flatpak..." || echo "Updating Flatpak packages...")${NC}"
        if flatpak update -y 2>/dev/null; then
            log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم تحديث حزم Flatpak بنجاح." || echo "Successfully updated Flatpak packages.")"
        else
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "فشل تحديث بعض حزم Flatpak." || echo "Failed to update some Flatpak packages.")"
        fi
    fi
    
    # Update Snap packages if snap is installed
    if command_exists snap; then
        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "تحديث حزم Snap..." || echo "Updating Snap packages...")${NC}"
        if run_with_privileges "snap refresh"; then
            log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم تحديث حزم Snap بنجاح." || echo "Successfully updated Snap packages.")"
        else
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "فشل تحديث بعض حزم Snap." || echo "Failed to update some Snap packages.")"
        fi
    fi
    
    # Check for reboot required
    local reboot_required=0
    
    # Different distributions have different ways to check if reboot is required
    if [ -f /var/run/reboot-required ] || [ -f /var/run/reboot-required.pkgs ]; then
        # Debian/Ubuntu
        reboot_required=1
    elif [ -f /usr/bin/needs-restarting ] && command_exists needs-restarting; then
        # RHEL/CentOS/Fedora
        needs-restarting -r >/dev/null
        if [ $? -eq 1 ]; then
            reboot_required=1
        fi
    elif [ -f /boot/vmlinuz-linux ] && command_exists mkinitcpio; then
        # Arch Linux - check if the kernel was updated
        # Get current and running kernel version
        local current_kernel=$(pacman -Q linux | cut -d ' ' -f 2)
        local running_kernel=$(uname -r | cut -d '-' -f 1)
        
        if [ "$current_kernel" != "$running_kernel" ]; then
            reboot_required=1
        fi
    fi
    
    if [ $reboot_required -eq 1 ]; then
        echo -e "\n${RED}${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "تنبيه: يلزم إعادة تشغيل النظام لإكمال التحديثات." || echo "Alert: A system reboot is required to complete updates.")${NC}"
        echo -e "$([ "$LANGUAGE" == "ar" ] && echo "يوصى بإعادة تشغيل النظام في أقرب وقت ممكن." || echo "It is recommended to reboot the system at your earliest convenience.")"
        
        if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل ترغب في إعادة تشغيل النظام الآن؟" || echo "Would you like to reboot the system now?")"; then
            echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "إعادة تشغيل النظام الآن..." || echo "Rebooting system now...")${NC}"
            # Clean up before reboot
            remove_lock
            log_info "$([ "$LANGUAGE" == "ar" ] && echo "إعادة تشغيل النظام بعد التحديث." || echo "Rebooting system after update.")"
            # Reboot with a delay to allow user to read messages
            run_with_privileges "shutdown -r +1 'System update complete, rebooting in 1 minute'" &
            exit 0
        fi
    fi
    
    stop_timer
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الوقت المستغرق:" || echo "Time taken:") $(get_elapsed_time) $([ "$LANGUAGE" == "ar" ] && echo "ثانية" || echo "seconds")${NC}"
    
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى القائمة الرئيسية..." || echo "Press any key to return to the main menu...")${NC}"
    read -n 1 -s
    show_menu
}