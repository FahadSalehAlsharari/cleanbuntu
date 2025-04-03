#!/bin/bash

# Author: Fahad Alsharari 
# Website: https://FahadAlsharari.sa
# Contact: admin@FahadAlsharari.sa

# Function to display system information
system_info() {
    start_timer
    show_header
    
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "معلومات النظام:" || echo "System Information:")${NC}"
    
    # Get all system information at once to avoid repeated commands
    local kernel=$(uname -r)
    local os_name=""
    local hostname=$(hostname)
    local uptime=$(uptime -p 2>/dev/null || echo "Unknown")
    local load_avg=$(cat /proc/loadavg 2>/dev/null | awk '{print $1 ", " $2 ", " $3}' || echo "Unknown")
    local cpu_model=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -n 1 | cut -d':' -f2 | sed 's/^[ \t]*//' || echo "Unknown")
    local cpu_cores=$(grep -c "processor" /proc/cpuinfo 2>/dev/null || echo "Unknown")
    local cpu_temp="Unknown"
    local ram_info=$(free -m)
    local ram_total=$(echo "$ram_info" | awk '/Mem:/ {print $2}')
    local ram_used=$(echo "$ram_info" | awk '/Mem:/ {print $3}')
    local disk_info=$(df -h / 2>/dev/null)
    local disk_total=$(echo "$disk_info" | awk 'NR==2 {print $2}')
    local disk_used=$(echo "$disk_info" | awk 'NR==2 {print $3}')
    local disk_avail=$(echo "$disk_info" | awk 'NR==2 {print $4}')
    local disk_usage=$(echo "$disk_info" | awk 'NR==2 {print $5}' | tr -d '%')
    local ip_address=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "Unknown")
    local gateway="Unknown"
    local distro_info=""
    
    # Detect OS information (cross-distro compatible)
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        os_name="${NAME} ${VERSION_ID}"
        distro_info="$ID"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        os_name="${DISTRIB_DESCRIPTION}"
        distro_info="$DISTRIB_ID"
    elif command_exists lsb_release; then
        os_name=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
        distro_info=$(lsb_release -i 2>/dev/null | cut -f2 || echo "")
    else
        os_name="Linux $(uname -r)"
    fi
    
    # Try different methods to get CPU temperature
    if command_exists sensors; then
        cpu_temp=$(sensors 2>/dev/null | grep -m 1 -oE "Core 0.*?\+[0-9.]*°C" | grep -oE "[0-9.]+°C" || echo "Unknown")
    elif [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        cpu_temp="$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 'Unknown')"
    fi
    
    # Try to get gateway if ip command exists
    if command_exists ip; then
        gateway=$(ip route | grep default | awk '{print $3}' 2>/dev/null || echo "Unknown")
    fi
    
    # Get GPU info if lspci exists
    local gpu_info="Unknown"
    if command_exists lspci; then
        gpu_info=$(lspci | grep -i 'vga\|3d\|2d' 2>/dev/null | head -n 1 | sed 's/.*: //g' || echo "Unknown")
    fi
    
    # Calculate RAM usage percentage
    local ram_usage=0
    if [ "$ram_total" -gt 0 ]; then
        ram_usage=$(( ram_used * 100 / ram_total ))
    fi
    
    # Display system info in organized sections
    echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "النظام:" || echo "System:")${NC}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "نواة لينكس:" || echo "Kernel:") ${kernel}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "نظام التشغيل:" || echo "OS:") ${os_name}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "اسم المضيف:" || echo "Hostname:") ${hostname}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "وقت التشغيل:" || echo "Uptime:") ${uptime}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "متوسط التحميل:" || echo "Load Average:") ${load_avg}"
    
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "وحدة المعالجة المركزية:" || echo "CPU:")${NC}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "الطراز:" || echo "Model:") ${cpu_model}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "عدد الأنوية:" || echo "Cores:") ${cpu_cores}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "درجة الحرارة:" || echo "Temperature:") ${cpu_temp}"
    
    # RAM usage with progress bar
    local ram_bar=$(create_progress_bar "$ram_usage")
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الذاكرة:" || echo "Memory:")${NC}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "المستخدم:" || echo "Used:") ${ram_used} MB / ${ram_total} MB \(${ram_usage}%\)"
    echo -e "  ${ram_bar}"
    
    # Disk usage with progress bar
    local disk_bar=$(create_progress_bar "$disk_usage")
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "استخدام القرص (/):" || echo "Disk Usage (/):")${NC}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "المستخدم:" || echo "Used:") ${disk_used} / ${disk_total} (${disk_usage}%)"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "المتاح:" || echo "Available:") ${disk_avail}"
    echo -e "  ${disk_bar}"
    
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الشبكة:" || echo "Network:")${NC}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "عنوان IP:" || echo "IP Address:") ${ip_address}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "البوابة الافتراضية:" || echo "Default Gateway:") ${gateway}"
    
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الرسومات:" || echo "Graphics:")${NC}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "بطاقة الرسومات:" || echo "Graphics Card:") ${gpu_info}"
    
    # Check if system is a laptop by looking for battery
    if [ -d "/sys/class/power_supply/BAT0" ] || [ -d "/sys/class/power_supply/BAT1" ]; then
        local battery_path=$([ -d "/sys/class/power_supply/BAT0" ] && echo "/sys/class/power_supply/BAT0" || echo "/sys/class/power_supply/BAT1")
        
        if [ -f "$battery_path/capacity" ] && [ -f "$battery_path/status" ]; then
            local battery_level=$(cat "$battery_path/capacity" 2>/dev/null || echo "Unknown")
            local battery_status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
            local battery_bar=$(create_progress_bar "$battery_level")
            
            echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "البطارية:" || echo "Battery:")${NC}"
            echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "المستوى:" || echo "Level:") ${battery_level}% ($([ "$LANGUAGE" == "ar" ] && translate_battery_status "$battery_status" || echo "$battery_status"))"
            echo -e "  ${battery_bar}"
        fi
    fi
    
    # Distribution-specific information
    if [ -n "$distro_info" ]; then
        echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "معلومات التوزيعة:" || echo "Distribution Information:")${NC}"
        
        case "$distro_info" in
            ubuntu|Ubuntu)
                if [ -f "/etc/lsb-release" ]; then
                    local ubuntu_version=$(grep DISTRIB_RELEASE /etc/lsb-release | cut -d= -f2)
                    local ubuntu_support_status="Unknown"
                    
                    # Check Ubuntu support status based on version
                    case "$ubuntu_version" in
                        16.04|18.04|20.04|22.04|24.04)
                            ubuntu_support_status=$([ "$LANGUAGE" == "ar" ] && echo "مدعوم طويل الأمد (LTS)" || echo "Long Term Support (LTS)")
                            ;;
                        *)
                            # Check if release is still supported
                            if command_exists ubuntu-support-status; then
                                if ubuntu-support-status 2>/dev/null | grep -q "no longer supported"; then
                                    ubuntu_support_status=$([ "$LANGUAGE" == "ar" ] && echo "لم يعد مدعومًا" || echo "No longer supported")
                                else
                                    ubuntu_support_status=$([ "$LANGUAGE" == "ar" ] && echo "مدعوم" || echo "Supported")
                                fi
                            fi
                            ;;
                    esac
                    
                    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "إصدار أوبونتو:" || echo "Ubuntu Version:") ${ubuntu_version}"
                    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "حالة الدعم:" || echo "Support Status:") ${ubuntu_support_status}"
                fi
                ;;
            fedora|Fedora)
                if [ -f "/etc/fedora-release" ]; then
                    local fedora_version=$(cat /etc/fedora-release | grep -o '[0-9]\+')
                    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "إصدار فيدورا:" || echo "Fedora Version:") ${fedora_version}"
                fi
                ;;
            debian|Debian)
                if [ -f "/etc/debian_version" ]; then
                    local debian_version=$(cat /etc/debian_version)
                    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "إصدار ديبيان:" || echo "Debian Version:") ${debian_version}"
                fi
                ;;
            arch|Arch)
                echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "توزيعة:" || echo "Distribution:") Arch Linux (Rolling Release)"
                ;;
            *)
                echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "توزيعة:" || echo "Distribution:") ${distro_info}"
                ;;
        esac
    fi
    
    stop_timer
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الوقت المستغرق:" || echo "Time taken:") $(get_elapsed_time) $([ "$LANGUAGE" == "ar" ] && echo "ثانية" || echo "seconds")${NC}"
    
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى القائمة الرئيسية..." || echo "Press any key to return to the main menu...")${NC}"
    read -n 1 -s
    show_menu
}

# Function to check desktop services status
check_services() {
    start_timer
    show_header
    
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "حالة الخدمات:" || echo "Services Status:")${NC}"
    
    # Check for service management tools
    local service_tool=""
    if command_exists systemctl; then
        service_tool="systemctl"
    elif command_exists service; then
        service_tool="service"
    else
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "لم يتم العثور على أداة إدارة الخدمات المدعومة." || echo "No supported service management tool found.")"
        sleep 3
        show_menu
        return
    fi
    
    # List of desktop services to check (common across distributions)
    local services=(
        "NetworkManager" 
        "bluetooth" 
        "cups" 
        "gdm" 
        "lightdm" 
        "sddm"
        "pipewire" 
        "pulseaudio"
        "avahi-daemon"
        "ModemManager"
        "snapd"
        "ufw"
        "systemd-timesyncd"
    )
    
    # Add distribution-specific services
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian)
                services+=("apparmor" "bolt" "packagekit" "thermald")
                ;;
            fedora|centos|rhel)
                services+=("firewalld" "packagekit" "thermald" "dnf-makecache.timer")
                ;;
            arch)
                services+=("firewalld" "packagekit" "docker" "libvirtd")
                ;;
        esac
    fi
    
    # Initialize counters
    local active_count=0
    local inactive_count=0
    local disabled_count=0
    
    # Process all services based on the service tool
    for service in "${services[@]}"; do
        local status=""
        local enabled=""
        local status_text=""
        local status_color=""
        local enabled_text=""
        local enabled_color=""
        
        if [ "$service_tool" = "systemctl" ]; then
            # Check if service exists
            if systemctl list-unit-files "${service}.service" &>/dev/null; then
                status=$(systemctl is-active "${service}.service" 2>/dev/null)
                enabled=$(systemctl is-enabled "${service}.service" 2>/dev/null || echo "unknown")
                
                # Service description
                local description=$(systemctl show -p Description "${service}.service" 2>/dev/null | sed 's/Description=//')
            else
                status="not-found"
                enabled="not-found"
                description=""
            fi
        elif [ "$service_tool" = "service" ]; then
            # More basic check with service command
            if service --status-all 2>&1 | grep -q "$service"; then
                if service "$service" status &>/dev/null; then
                    status="active"
                else
                    status="inactive"
                fi
                
                # Basic check for enabled status (not as accurate)
                if [ -f "/etc/init.d/$service" ]; then
                    enabled="enabled"
                else
                    enabled="unknown"
                fi
                
                description="$service service"
            else
                status="not-found"
                enabled="not-found"
                description=""
            fi
        fi
        
        # Set status text and color
        case "$status" in
            active)
                status_text=$([ "$LANGUAGE" == "ar" ] && echo "نشط" || echo "Active")
                status_color="${GREEN}"
                ((active_count++))
                ;;
            inactive)
                status_text=$([ "$LANGUAGE" == "ar" ] && echo "غير نشط" || echo "Inactive")
                status_color="${RED}"
                ((inactive_count++))
                ;;
            not-found)
                status_text=$([ "$LANGUAGE" == "ar" ] && echo "غير مثبت" || echo "Not installed")
                status_color="${YELLOW}"
                continue
                ;;
            *)
                status_text=$([ "$LANGUAGE" == "ar" ] && echo "غير معروف" || echo "Unknown")
                status_color="${YELLOW}"
                ;;
        esac
        
        # Set enabled text and color
        case "$enabled" in
            enabled)
                enabled_text=$([ "$LANGUAGE" == "ar" ] && echo "ممكّن" || echo "Enabled")
                enabled_color="${GREEN}"
                ;;
            disabled)
                enabled_text=$([ "$LANGUAGE" == "ar" ] && echo "معطّل" || echo "Disabled")
                enabled_color="${RED}"
                ((disabled_count++))
                ;;
            not-found)
                enabled_text=$([ "$LANGUAGE" == "ar" ] && echo "غير مثبت" || echo "Not installed")
                enabled_color="${YELLOW}"
                ;;
            *)
                enabled_text=$([ "$LANGUAGE" == "ar" ] && echo "غير معروف" || echo "Unknown")
                enabled_color="${YELLOW}"
                ;;
        esac
        
        # Display service status
        echo -e "  ${service}: ${status_color}${status_text}${NC} (${enabled_color}${enabled_text}${NC})"
        
        # Display description if available
        if [ -n "$description" ]; then
            echo -e "    $([ "$LANGUAGE" == "ar" ] && echo "الوصف:" || echo "Description:") ${description}"
        fi
        
        # Add a small separator between services
        echo -e "  ------------"
    done
    
    # Display summary
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "ملخص الخدمات:" || echo "Services Summary:")${NC}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "خدمات نشطة:" || echo "Active services:") ${GREEN}${active_count}${NC}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "خدمات غير نشطة:" || echo "Inactive services:") ${RED}${inactive_count}${NC}"
    echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "خدمات معطلة:" || echo "Disabled services:") ${RED}${disabled_count}${NC}"
    
    # Show recommendations if needed
    if [ "$inactive_count" -gt 0 ] || [ "$disabled_count" -gt 0 ]; then
        echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "توصيات:" || echo "Recommendations:")${NC}"
        
        if [ "$inactive_count" -gt 0 ]; then
            echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "• بعض الخدمات غير نشطة، قد ترغب في تشغيلها إذا كنت بحاجة إليها." || echo "• Some services are inactive, you might want to start them if you need them.")"
        fi
        
        if [ "$disabled_count" -gt 0 ]; then
            echo -e "  $([ "$LANGUAGE" == "ar" ] && echo "• بعض الخدمات معطلة، قد ترغب في تمكينها إذا كنت بحاجة إليها." || echo "• Some services are disabled, you might want to enable them if you need them.")"
        fi
    fi
    
    # Service management options
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "هل تريد إدارة أي من هذه الخدمات؟" || echo "Do you want to manage any of these services?")${NC}"
    echo -e "1. $([ "$LANGUAGE" == "ar" ] && echo "إيقاف/تشغيل خدمة" || echo "Stop/Start a service")"
    echo -e "2. $([ "$LANGUAGE" == "ar" ] && echo "تمكين/تعطيل خدمة" || echo "Enable/Disable a service")"
    echo -e "3. $([ "$LANGUAGE" == "ar" ] && echo "العودة إلى القائمة الرئيسية" || echo "Return to main menu")"
    
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر خيارًا: " || echo "Choose an option: ")" manage_option
    
    case $manage_option in
        1|2)
            echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "أدخل اسم الخدمة:" || echo "Enter the service name:")${NC}"
            read -r service_name
            
            if [ "$service_tool" = "systemctl" ]; then
                if systemctl list-unit-files "${service_name}.service" &>/dev/null; then
                    if [ "$manage_option" -eq 1 ]; then
                        local current_status=$(systemctl is-active "${service_name}.service" 2>/dev/null)
                        
                        if [ "$current_status" = "active" ]; then
                            echo -e "$([ "$LANGUAGE" == "ar" ] && echo "إيقاف الخدمة:" || echo "Stopping service:") ${service_name}..."
                            run_with_privileges "systemctl stop ${service_name}.service"
                        else
                            echo -e "$([ "$LANGUAGE" == "ar" ] && echo "تشغيل الخدمة:" || echo "Starting service:") ${service_name}..."
                            run_with_privileges "systemctl start ${service_name}.service"
                        fi
                    else # manage_option = 2
                        local current_status=$(systemctl is-enabled "${service_name}.service" 2>/dev/null || echo "unknown")
                        
                        if [ "$current_status" = "enabled" ]; then
                            echo -e "$([ "$LANGUAGE" == "ar" ] && echo "تعطيل الخدمة:" || echo "Disabling service:") ${service_name}..."
                            run_with_privileges "systemctl disable ${service_name}.service"
                        else
                            echo -e "$([ "$LANGUAGE" == "ar" ] && echo "تمكين الخدمة:" || echo "Enabling service:") ${service_name}..."
                            run_with_privileges "systemctl enable ${service_name}.service"
                        fi
                    fi
                else
                    log_error "$([ "$LANGUAGE" == "ar" ] && echo "الخدمة غير موجودة:" || echo "Service does not exist:") ${service_name}"
                fi
            elif [ "$service_tool" = "service" ]; then
                if [ -f "/etc/init.d/$service_name" ] || [ -f "/lib/systemd/system/${service_name}.service" ]; then
                    if [ "$manage_option" -eq 1 ]; then
                        if service "$service_name" status &>/dev/null; then
                            echo -e "$([ "$LANGUAGE" == "ar" ] && echo "إيقاف الخدمة:" || echo "Stopping service:") ${service_name}..."
                            run_with_privileges "service $service_name stop"
                        else
                            echo -e "$([ "$LANGUAGE" == "ar" ] && echo "تشغيل الخدمة:" || echo "Starting service:") ${service_name}..."
                            run_with_privileges "service $service_name start"
                        fi
                    else
                        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "تمكين/تعطيل الخدمات غير متاح مع أمر 'service'." || echo "Enabling/disabling services is not available with 'service' command.")"
                    fi
                else
                    log_error "$([ "$LANGUAGE" == "ar" ] && echo "الخدمة غير موجودة:" || echo "Service does not exist:") ${service_name}"
                fi
            fi
            
            sleep 2
            check_services
            ;;
        *)
            show_menu
            ;;
    esac
    
    stop_timer
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الوقت المستغرق:" || echo "Time taken:") $(get_elapsed_time) $([ "$LANGUAGE" == "ar" ] && echo "ثانية" || echo "seconds")${NC}"
    
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "اضغط على أي مفتاح للعودة إلى القائمة الرئيسية..." || echo "Press any key to return to the main menu...")${NC}"
    read -n 1 -s
    show_menu
}

# Function to diagnose system slowness
diagnose_system_slowness() {
    start_timer
    show_header
    
    echo -e "${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "تشخيص بطء النظام:" || echo "System Slowness Diagnosis:")${NC}"
    
    # Check CPU usage more efficiently
    echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "فحص استخدام وحدة المعالجة المركزية..." || echo "Checking CPU usage...")${NC}"
    if command_exists ps; then
        echo -e "$([ "$LANGUAGE" == "ar" ] && echo "العمليات التي تستخدم معظم وحدة المعالجة المركزية:" || echo "Processes using most CPU:")"
        ps -eo pid,ppid,cmd,%cpu --sort=-%cpu 2>/dev/null | head -n 6
    fi
    
    # Check memory usage
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "فحص استخدام الذاكرة..." || echo "Checking memory usage...")${NC}"
    if command_exists ps; then
        echo -e "$([ "$LANGUAGE" == "ar" ] && echo "العمليات التي تستخدم معظم الذاكرة:" || echo "Processes using most memory:")"
        ps -eo pid,ppid,cmd,%mem --sort=-%mem 2>/dev/null | head -n 6
    fi
    
    # Check startup applications
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "فحص عمليات بدء التشغيل..." || echo "Checking startup applications...")${NC}"
    
    local autostart_count=0
    if [ -d "${HOME}/.config/autostart" ]; then
        autostart_count=$(ls -1 "${HOME}/.config/autostart"/*.desktop 2>/dev/null | wc -l)
        echo -e "$([ "$LANGUAGE" == "ar" ] && echo "تطبيقات بدء التشغيل: $autostart_count" || echo "Startup applications: $autostart_count")"
        
        if [ "$autostart_count" -gt 5 ]; then
            echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "لديك العديد من تطبيقات بدء التشغيل. قد يؤدي ذلك إلى إبطاء زمن التمهيد." || echo "You have many startup applications. This may slow down boot time.")${NC}"
            
            # List startup applications
            echo -e "\n$([ "$LANGUAGE" == "ar" ] && echo "قائمة تطبيقات بدء التشغيل:" || echo "List of startup applications:")"
            for app in "${HOME}/.config/autostart"/*.desktop; do
                local app_name=$(grep -m 1 "^Name=" "$app" 2>/dev/null | cut -d= -f2 || basename "$app" .desktop)
                echo -e "  - ${app_name}"
            done
        fi
    elif [ -d "/etc/xdg/autostart" ]; then
        autostart_count=$(ls -1 "/etc/xdg/autostart"/*.desktop 2>/dev/null | wc -l)
        echo -e "$([ "$LANGUAGE" == "ar" ] && echo "تطبيقات بدء التشغيل النظام: $autostart_count" || echo "System startup applications: $autostart_count")"
    fi
    
    # Swap usage check
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "فحص مساحة التبديل (SWAP)..." || echo "Checking swap usage...")${NC}"
    local swap_info=$(free -m | grep Swap)
    local swap_total=$(echo "$swap_info" | awk '{print $2}')
    local swap_used=$(echo "$swap_info" | awk '{print $3}')
    
    if [ "$swap_total" -gt 0 ]; then
        local swap_percent=$(( 100 * swap_used / swap_total ))
        echo -e "$([ "$LANGUAGE" == "ar" ] && echo "استخدام مساحة التبديل: $swap_used MB من $swap_total MB ($swap_percent%)" || echo "Swap usage: $swap_used MB of $swap_total MB ($swap_percent%)")"
        
        if [ "$swap_percent" -gt 80 ]; then
            echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "استخدام مساحة التبديل مرتفع. قد يشير هذا إلى نقص الذاكرة." || echo "Swap usage is high. This may indicate memory shortage.")${NC}"
        fi
    else
        echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "لم يتم تكوين مساحة التبديل." || echo "Swap is not configured.")${NC}"
    fi
    
    # Check for disk I/O issues
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "فحص أداء القرص..." || echo "Checking disk performance...")${NC}"
    if command_exists iostat; then
        iostat -xd 1 1
    elif command_exists vmstat; then
        echo -e "$([ "$LANGUAGE" == "ar" ] && echo "إحصائيات الذاكرة الافتراضية:" || echo "Virtual memory statistics:")"
        vmstat 1 1
    fi
    
    # Check system load
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "فحص حمل النظام..." || echo "Checking system load...")${NC}"
    local load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    local cores=$(grep -c "processor" /proc/cpuinfo)
    echo -e "$([ "$LANGUAGE" == "ar" ] && echo "حمل النظام (1، 5، 15 دقيقة): $load" || echo "System load (1, 5, 15 minutes): $load")"
    echo -e "$([ "$LANGUAGE" == "ar" ] && echo "عدد أنوية وحدة المعالجة المركزية: $cores" || echo "Number of CPU cores: $cores")"
    
    # Calculate per-core load
    local load1=$(echo "$load" | awk '{print $1}')
    local load_per_core=$(echo "scale=2; $load1 / $cores" | bc 2>/dev/null || echo "Unknown")
    
    if [ -n "$load_per_core" ] && [ "$load_per_core" != "Unknown" ]; then
        echo -e "$([ "$LANGUAGE" == "ar" ] && echo "الحمل لكل نواة: $load_per_core" || echo "Load per core: $load_per_core")"
        
        if (( $(echo "$load_per_core > 1.0" | bc -l) )); then
            echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "حمل النظام مرتفع مقارنة بعدد الأنوية." || echo "System load is high relative to the number of cores.")${NC}"
        else
            echo -e "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "حمل النظام طبيعي مقارنة بعدد الأنوية." || echo "System load is normal relative to the number of cores.")${NC}"
            echo -e "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "حمل النظام طبيعي مقارنة بعدد الأنوية." || echo "System load is normal relative to the number of cores.")${NC}"
        fi
    fi
    
    # Recommendations section
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "توصيات لتحسين أداء النظام:" || echo "Recommendations to improve system performance:")${NC}"
    echo -e "1. $([ "$LANGUAGE" == "ar" ] && echo "تشغيل وظيفة تنظيف النظام لتحرير مساحة القرص والذاكرة" || echo "Run System Cleanup to free up disk space and memory")"
    echo -e "2. $([ "$LANGUAGE" == "ar" ] && echo "تقليل عدد تطبيقات بدء التشغيل من خلال تطبيق 'تطبيقات بدء التشغيل'" || echo "Reduce startup applications using the 'Startup Applications' utility")"
    echo -e "3. $([ "$LANGUAGE" == "ar" ] && echo "تحديث برامج تشغيل الرسومات للحصول على أداء أفضل" || echo "Update graphics drivers for better performance")"
    echo -e "4. $([ "$LANGUAGE" == "ar" ] && echo "النظر في إضافة المزيد من ذاكرة الوصول العشوائي (RAM) إذا كان متاحًا" || echo "Consider adding more RAM if available")"
    
    # Option to execute recommended actions
    echo -e "\n${BOLD}$([ "$LANGUAGE" == "ar" ] && echo "هل ترغب في تنفيذ الإجراءات الموصى بها؟" || echo "Would you like to perform recommended actions?")${NC}"
    echo -e "1. $([ "$LANGUAGE" == "ar" ] && echo "تشغيل وظيفة تنظيف النظام" || echo "Run System Cleanup")"
    echo -e "2. $([ "$LANGUAGE" == "ar" ] && echo "فتح تطبيق 'تطبيقات بدء التشغيل'" || echo "Open Startup Applications")"
    echo -e "3. $([ "$LANGUAGE" == "ar" ] && echo "العودة إلى القائمة السابقة" || echo "Return to previous menu")"
    
    read -r -p "$([ "$LANGUAGE" == "ar" ] && echo "اختر إجراءً (1-3): " || echo "Choose an action (1-3): ")" action_choice
    
    case $action_choice in
        1) 
            perform_cleanup
            ;;
        2)
            if command_exists gnome-session-properties; then
                gnome-session-properties &
            elif command_exists mate-session-properties; then
                mate-session-properties &
            elif [ -d "${HOME}/.config/autostart" ]; then
                # If no GUI tool is available, open the autostart directory
                if command_exists xdg-open; then
                    xdg-open "${HOME}/.config/autostart" &
                elif command_exists open; then
                    open "${HOME}/.config/autostart"
                else
                    log_warning "$([ "$LANGUAGE" == "ar" ] && echo "تعذر العثور على أداة تطبيقات بدء التشغيل." || echo "Startup Applications tool not found.")"
                    log_info "$([ "$LANGUAGE" == "ar" ] && echo "يمكنك تعديل ملفات بدء التشغيل يدويًا في: ${HOME}/.config/autostart" || echo "You can manually edit startup files in: ${HOME}/.config/autostart")"
                fi
            else
                log_warning "$([ "$LANGUAGE" == "ar" ] && echo "تعذر العثور على أداة تطبيقات بدء التشغيل." || echo "Startup Applications tool not found.")"
            fi
            sleep 3
            show_troubleshooting_menu
            ;;
        *)
            show_troubleshooting_menu
            ;;
    esac
    
    stop_timer
    echo -e "\n${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الوقت المستغرق:" || echo "Time taken:") $(get_elapsed_time) $([ "$LANGUAGE" == "ar" ] && echo "ثانية" || echo "seconds")${NC}"
    
    show_troubleshooting_menu
}