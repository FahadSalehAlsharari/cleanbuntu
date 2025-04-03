#!/bin/bash

# Author: Fahad Alsharari 
# Website: https://FahadAlsharari.sa
# Contact: admin@FahadAlsharari.sa

# Configuration version
CONFIG_VERSION="2.0"

# Default configuration values
LANGUAGE="en"
BACKUP_PATH="${HOME}/Documents/cleanbuntu-backups"
TMP_FILE_AGE=7
CLEAN_CACHE=1
CLEAN_BROWSER_CACHE=1
BACKUP_FIREFOX=1
BACKUP_CHROME=1
EMPTY_TRASH=1
DEBUG_MODE=0
PACKAGE_MANAGER="apt-get"

# Config file path
CONFIG_FILE="${HOME}/.config/cleanbuntu/settings.conf"

# Function to initialize the configuration
init_config() {
    # Create config directory if it doesn't exist
    if [ ! -d "${HOME}/.config/cleanbuntu" ]; then
        mkdir -p "${HOME}/.config/cleanbuntu"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم إنشاء دليل الإعدادات." || echo "Created configuration directory.")"
    fi
    
    # Create config file if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "إنشاء ملف الإعدادات الافتراضي..." || echo "Creating default configuration file...")"
        
        cat > "$CONFIG_FILE" << EOF
# Cleanbuntu Configuration File (v${CONFIG_VERSION})
# Created: $(date)

# Language (en/ar)
LANGUAGE="$LANGUAGE"

# Backup directory path
BACKUP_PATH="$BACKUP_PATH"

# Age of temporary files to remove (in days)
TMP_FILE_AGE=$TMP_FILE_AGE

# Cleanup options (1=enabled, 0=disabled)
CLEAN_CACHE=$CLEAN_CACHE
CLEAN_BROWSER_CACHE=$CLEAN_BROWSER_CACHE
BACKUP_FIREFOX=$BACKUP_FIREFOX
BACKUP_CHROME=$BACKUP_CHROME
EMPTY_TRASH=$EMPTY_TRASH

# Debug mode (1=enabled, 0=disabled)
DEBUG_MODE=$DEBUG_MODE
EOF
    fi
    
    # Make sure backup directory exists
    if [ ! -d "$BACKUP_PATH" ]; then
        mkdir -p "$BACKUP_PATH"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم إنشاء دليل النسخ الاحتياطي." || echo "Created backup directory.")"
    fi
    
    # Load configuration
    load_config
}

# Function to load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تحميل الإعدادات..." || echo "Loading settings...")"
        
        # Use source to load settings
        source "$CONFIG_FILE"
        
        # Verify essential settings
        verify_config
    else
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "ملف الإعدادات غير موجود. سيتم استخدام الإعدادات الافتراضية." || echo "Configuration file not found. Using default settings.")"
    fi
    
    # Export settings for other scripts
    export LANGUAGE
    export BACKUP_PATH
    export TMP_FILE_AGE
    export CLEAN_CACHE
    export CLEAN_BROWSER_CACHE
    export BACKUP_FIREFOX
    export BACKUP_CHROME
    export EMPTY_TRASH
    export DEBUG_MODE
    export PACKAGE_MANAGER
}

# Function to verify and fix configuration
verify_config() {
    # Verify LANGUAGE
    if [ -z "$LANGUAGE" ] || [[ ! "$LANGUAGE" =~ ^(en|ar)$ ]]; then
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "إعداد اللغة غير صالح. استخدام الإنجليزية كإعداد افتراضي." || echo "Invalid language setting. Using English as default.")"
        LANGUAGE="en"
    fi
    
    # Verify BACKUP_PATH
    if [ -z "$BACKUP_PATH" ]; then
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "مسار النسخ الاحتياطي غير صالح. استخدام المسار الافتراضي." || echo "Invalid backup path. Using default path.")"
        BACKUP_PATH="${HOME}/Documents/cleanbuntu-backups"
    fi
    
    # Verify TMP_FILE_AGE
    if [ -z "$TMP_FILE_AGE" ] || ! [[ "$TMP_FILE_AGE" =~ ^[0-9]+$ ]]; then
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "عمر الملف المؤقت غير صالح. استخدام القيمة الافتراضية." || echo "Invalid temporary file age. Using default value.")"
        TMP_FILE_AGE=7
    fi
    
    # Verify boolean settings
    for setting in CLEAN_CACHE CLEAN_BROWSER_CACHE BACKUP_FIREFOX BACKUP_CHROME EMPTY_TRASH DEBUG_MODE; do
        local value=${!setting}
        if [ -z "$value" ] || ! [[ "$value" =~ ^[0-1]$ ]]; then
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "إعداد $setting غير صالح. استخدام القيمة الافتراضية." || echo "Invalid $setting setting. Using default value.")"
            declare "$setting=1"
        fi
    done
    
    # Create backup directory if it doesn't exist
    if [ ! -d "$BACKUP_PATH" ]; then
        mkdir -p "$BACKUP_PATH"
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم إنشاء دليل النسخ الاحتياطي." || echo "Created backup directory.")"
    fi
}

# Function to save configuration changes
save_config() {
    log_info "$([ "$LANGUAGE" == "ar" ] && echo "حفظ الإعدادات..." || echo "Saving settings...")"
    
    # Backup original config file
    if [ -f "$CONFIG_FILE" ]; then
        backup_file "$CONFIG_FILE"
    fi
    
    # Write new configuration
    cat > "$CONFIG_FILE" << EOF
# Cleanbuntu Configuration File (v${CONFIG_VERSION})
# Updated: $(date)

# Language (en/ar)
LANGUAGE="$LANGUAGE"

# Backup directory path
BACKUP_PATH="$BACKUP_PATH"

# Age of temporary files to remove (in days)
TMP_FILE_AGE=$TMP_FILE_AGE

# Cleanup options (1=enabled, 0=disabled)
CLEAN_CACHE=$CLEAN_CACHE
CLEAN_BROWSER_CACHE=$CLEAN_BROWSER_CACHE
BACKUP_FIREFOX=$BACKUP_FIREFOX
BACKUP_CHROME=$BACKUP_CHROME
EMPTY_TRASH=$EMPTY_TRASH

# Debug mode (1=enabled, 0=disabled)
DEBUG_MODE=$DEBUG_MODE
EOF
    
    log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم حفظ الإعدادات بنجاح." || echo "Settings saved successfully.")"
}

# Function to change settings interactively
change_settings() {
    show_header
    
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "تغيير الإعدادات:" || echo "Change Settings:")${NC}"
    
    # Display current settings
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الإعدادات الحالية:" || echo "Current Settings:")${NC}"
    echo -e "1. $([ "$LANGUAGE" == "ar" ] && echo "اللغة:" || echo "Language:") $([ "$LANGUAGE" == "ar" ] && echo "العربية" || echo "English")"
    echo -e "2. $([ "$LANGUAGE" == "ar" ] && echo "مسار النسخ الاحتياطي:" || echo "Backup Path:") $BACKUP_PATH"
    echo -e "3. $([ "$LANGUAGE" == "ar" ] && echo "عمر الملفات المؤقتة للإزالة:" || echo "Temporary File Age:") $TMP_FILE_AGE $([ "$LANGUAGE" == "ar" ] && echo "أيام" || echo "days")"
    echo -e "4. $([ "$LANGUAGE" == "ar" ] && echo "تنظيف ذاكرة التخزين المؤقت:" || echo "Clean Cache:") $([ "$CLEAN_CACHE" -eq 1 ] && echo "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "ممكّن" || echo "Enabled")${NC}" || echo "${RED}$([ "$LANGUAGE" == "ar" ] && echo "معطل" || echo "Disabled")${NC}")"
    echo -e "5. $([ "$LANGUAGE" == "ar" ] && echo "تنظيف ذاكرة التخزين المؤقت للمتصفح:" || echo "Clean Browser Cache:") $([ "$CLEAN_BROWSER_CACHE" -eq 1 ] && echo "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "ممكّن" || echo "Enabled")${NC}" || echo "${RED}$([ "$LANGUAGE" == "ar" ] && echo "معطل" || echo "Disabled")${NC}")"
    echo -e "6. $([ "$LANGUAGE" == "ar" ] && echo "نسخ إعدادات Firefox احتياطيًا:" || echo "Backup Firefox Settings:") $([ "$BACKUP_FIREFOX" -eq 1 ] && echo "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "ممكّن" || echo "Enabled")${NC}" || echo "${RED}$([ "$LANGUAGE" == "ar" ] && echo "معطل" || echo "Disabled")${NC}")"
    echo -e "7. $([ "$LANGUAGE" == "ar" ] && echo "نسخ إعدادات Chrome احتياطيًا:" || echo "Backup Chrome Settings:") $([ "$BACKUP_CHROME" -eq 1 ] && echo "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "ممكّن" || echo "Enabled")${NC}" || echo "${RED}$([ "$LANGUAGE" == "ar" ] && echo "معطل" || echo "Disabled")${NC}")"
    echo -e "8. $([ "$LANGUAGE" == "ar" ] && echo "تفريغ سلة المهملات:" || echo "Empty Trash:") $([ "$EMPTY_TRASH" -eq 1 ] && echo "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "ممكّن" || echo "Enabled")${NC}" || echo "${RED}$([ "$LANGUAGE" == "ar" ] && echo "معطل" || echo "Disabled")${NC}")"
    echo -e "9. $([ "$LANGUAGE" == "ar" ] && echo "وضع التصحيح:" || echo "Debug Mode:") $([ "$DEBUG_MODE" -eq 1 ] && echo "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "ممكّن" || echo "Enabled")${NC}" || echo "${RED}$([ "$LANGUAGE" == "ar" ] && echo "معطل" || echo "Disabled")${NC}")"
    echo -e "0. $([ "$LANGUAGE" == "ar" ] && echo "العودة إلى القائمة الرئيسية" || echo "Return to Main Menu")"
    
    echo
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر الإعداد الذي ترغب في تغييره (0-9): " || echo "Choose setting to change (0-9): ")" choice
    
    case $choice in
        1)  # Change language
            echo
            echo -e "1. English"
            echo -e "2. العربية (Arabic)"
            read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر اللغة (1-2): " || echo "Choose language (1-2): ")" lang_choice
            case $lang_choice in
                1) LANGUAGE="en" ;;
                2) LANGUAGE="ar" ;;
                *) log_warning "$([ "$LANGUAGE" == "ar" ] && echo "اختيار غير صالح." || echo "Invalid choice.")" ;;
            esac
            ;;
        2)  # Change backup path
            echo
            read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "أدخل مسار النسخ الاحتياطي الجديد: " || echo "Enter new backup path: ")" path
            
            # Validate and clean path
            local new_path=$(sanitize_input "$path")
            
            # Resolve path and check if valid
            if [ -n "$new_path" ]; then
                new_path=$(validate_path "$new_path")
                if [ $? -eq 0 ]; then
                    BACKUP_PATH="$new_path"
                    # Create directory if it doesn't exist
                    if [ ! -d "$BACKUP_PATH" ]; then
                        mkdir -p "$BACKUP_PATH" 2>/dev/null
                        if [ $? -ne 0 ]; then
                            log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل في إنشاء دليل النسخ الاحتياطي." || echo "Failed to create backup directory.")"
                        else
                            log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم إنشاء دليل النسخ الاحتياطي." || echo "Created backup directory.")"
                        fi
                    fi
                fi
            fi
            ;;
        3)  # Change temporary file age
            echo
            read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "أدخل عمر الملفات المؤقتة للإزالة (بالأيام): " || echo "Enter temporary file age to remove (days): ")" age
            if [[ "$age" =~ ^[0-9]+$ ]]; then
                TMP_FILE_AGE=$age
            else
                log_warning "$([ "$LANGUAGE" == "ar" ] && echo "قيمة غير صالحة. يجب أن تكون رقمًا صحيحًا." || echo "Invalid value. Must be an integer.")"
            fi
            ;;
        4)  # Toggle clean cache
            CLEAN_CACHE=$(( 1 - CLEAN_CACHE ))
            ;;
        5)  # Toggle clean browser cache
            CLEAN_BROWSER_CACHE=$(( 1 - CLEAN_BROWSER_CACHE ))
            ;;
        6)  # Toggle backup Firefox
            BACKUP_FIREFOX=$(( 1 - BACKUP_FIREFOX ))
            ;;
        7)  # Toggle backup Chrome
            BACKUP_CHROME=$(( 1 - BACKUP_CHROME ))
            ;;
        8)  # Toggle empty trash
            EMPTY_TRASH=$(( 1 - EMPTY_TRASH ))
            ;;
        9)  # Toggle debug mode
            DEBUG_MODE=$(( 1 - DEBUG_MODE ))
            ;;
        0)  # Return to main menu
            save_config
            show_menu
            return
            ;;
        *)
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "اختيار غير صالح." || echo "Invalid choice.")"
            ;;
    esac
    
    # Save the changes
    save_config
    
    # Show settings menu again
    change_settings
}

# Advanced settings menu
advanced_settings() {
    show_header
    
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "الإعدادات المتقدمة:" || echo "Advanced Settings:")${NC}"
    
    # Display advanced settings options
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الخيارات المتقدمة:" || echo "Advanced Options:")${NC}"
    echo -e "1. $([ "$LANGUAGE" == "ar" ] && echo "إعادة ضبط جميع الإعدادات إلى القيم الافتراضية" || echo "Reset all settings to default values")"
    echo -e "2. $([ "$LANGUAGE" == "ar" ] && echo "استيراد الإعدادات من ملف" || echo "Import settings from file")"
    echo -e "3. $([ "$LANGUAGE" == "ar" ] && echo "تصدير الإعدادات إلى ملف" || echo "Export settings to file")"
    echo -e "4. $([ "$LANGUAGE" == "ar" ] && echo "فتح دليل الإعدادات" || echo "Open settings directory")"
    echo -e "0. $([ "$LANGUAGE" == "ar" ] && echo "العودة إلى الإعدادات" || echo "Return to Settings")"
    
    echo
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر خيارًا (0-4): " || echo "Choose an option (0-4): ")" choice
    
    case $choice in
        1)  # Reset all settings
            if confirm_action "$([ "$LANGUAGE" == "ar" ] && echo "هل أنت متأكد من أنك تريد إعادة ضبط جميع الإعدادات؟" || echo "Are you sure you want to reset all settings?")"; then
                # Create backup of current config
                backup_file "$CONFIG_FILE"
                
                # Remove current config file
                rm -f "$CONFIG_FILE"
                
                # Reset variables to defaults
                LANGUAGE="en"
                BACKUP_PATH="${HOME}/Documents/cleanbuntu-backups"
                TMP_FILE_AGE=7
                CLEAN_CACHE=1
                CLEAN_BROWSER_CACHE=1
                BACKUP_FIREFOX=1
                BACKUP_CHROME=1
                EMPTY_TRASH=1
                DEBUG_MODE=0
                
                # Create new config file
                init_config
                
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "تمت إعادة ضبط جميع الإعدادات إلى القيم الافتراضية." || echo "All settings have been reset to default values.")"
            fi
            ;;
        2)  # Import settings
            echo
            read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "أدخل مسار ملف الإعدادات للاستيراد: " || echo "Enter path to settings file to import: ")" import_file
            
            import_file=$(sanitize_input "$import_file")
            
            if [ -f "$import_file" ]; then
                # Create backup of current config
                backup_file "$CONFIG_FILE"
                
                # Copy the import file
                cp "$import_file" "$CONFIG_FILE"
                
                # Reload settings
                load_config
                
                log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم استيراد الإعدادات بنجاح." || echo "Settings imported successfully.")"
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "ملف الإعدادات غير موجود: $import_file" || echo "Settings file does not exist: $import_file")"
            fi
            ;;
        3)  # Export settings
            echo
            read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "أدخل مسار لتصدير ملف الإعدادات: " || echo "Enter path to export settings file: ")" export_file
            
            export_file=$(sanitize_input "$export_file")
            
            if [ -n "$export_file" ]; then
                # Create export directory if needed
                export_dir=$(dirname "$export_file")
                if [ ! -d "$export_dir" ]; then
                    mkdir -p "$export_dir"
                fi
                
                # Copy the config file
                cp "$CONFIG_FILE" "$export_file"
                
                if [ $? -eq 0 ]; then
                    log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم تصدير الإعدادات بنجاح إلى: $export_file" || echo "Settings exported successfully to: $export_file")"
                else
                    log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل في تصدير الإعدادات إلى: $export_file" || echo "Failed to export settings to: $export_file")"
                fi
            else
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "مسار غير صالح." || echo "Invalid path.")"
            fi
            ;;
        4)  # Open settings directory
            if command_exists xdg-open; then
                xdg-open "${HOME}/.config/cleanbuntu" &
            elif command_exists open; then
                open "${HOME}/.config/cleanbuntu"
            else
                log_warning "$([ "$LANGUAGE" == "ar" ] && echo "تعذر فتح دليل الإعدادات. المسار: ${HOME}/.config/cleanbuntu" || echo "Could not open settings directory. Path: ${HOME}/.config/cleanbuntu")"
            fi
            ;;
        0)  # Return to settings menu
            change_settings
            return
            ;;
        *)
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "اختيار غير صالح." || echo "Invalid choice.")"
            ;;
    esac
    
    # Return to advanced settings menu
    advanced_settings
}