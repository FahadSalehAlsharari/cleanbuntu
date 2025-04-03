#!/bin/bash

# Author: Fahad Alsharari 
# Website: https://FahadAlsharari.sa
# Contact: admin@FahadAlsharari.sa

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Define additional styles
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
LIGHT_YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
DARK_GRAY='\033[1;30m'
UNDERLINE='\033[4m'
REVERSE='\033[7m'

# Separator line
SEPARATOR="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Lock file
LOCK_FILE="/tmp/cleanbuntu.lock"

# Log directory and file
LOG_PATH="${HOME}/Documents/cleanbuntu-logs"
LOG_FILE=""

# Timer variables
TIMER_START=0
TIMER_END=0

# Maximum log file size in bytes (5MB)
MAX_LOG_SIZE=$((5 * 1024 * 1024))

# Cache for command existence checks
declare -A COMMAND_EXISTS_CACHE

# Function to initialize log
init_log() {
    # Create log directory if it doesn't exist
    [ -d "$LOG_PATH" ] || mkdir -p "$LOG_PATH"

    # Clean old logs if directory is getting too big (keep last 10 logs)
    log_file_count=$(ls -1 "$LOG_PATH" 2>/dev/null | wc -l)
    if [ "$log_file_count" -gt 10 ]; then
        ls -1t "$LOG_PATH" | tail -n +11 | xargs -I {} rm -f "$LOG_PATH/{}" 2>/dev/null
    fi

    # Set log file with timestamp
    LOG_FILE="${LOG_PATH}/cleanbuntu-$(date +"%Y%m%d-%H%M%S").log"

    # Create log file
    touch "$LOG_FILE"

    log_message "INFO" "===== Cleanbuntu log started at $(date) ====="
    log_message "INFO" "System: $(uname -a)"
    log_message "INFO" "User: $(whoami)"
}

# Unified logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local stack=""
    local color=""
    local console_prefix=""

    # Check if log file exists
    if [ ! -f "$LOG_FILE" ]; then
        # Try to re-create log file if missing
        if [ ! -d "$LOG_PATH" ]; then
            mkdir -p "$LOG_PATH" 2>/dev/null
        fi
        touch "$LOG_FILE" 2>/dev/null || return 1
    fi

    # Check if log file is too big
    if [ -f "$LOG_FILE" ] && [ "$(stat -c %s "$LOG_FILE" 2>/dev/null || echo 0)" -gt "$MAX_LOG_SIZE" ]; then
        local backup_log="${LOG_FILE}.1"
        mv "$LOG_FILE" "$backup_log" 2>/dev/null
        touch "$LOG_FILE" 2>/dev/null
        echo "Log file reached maximum size, rotated to $backup_log" >> "$LOG_FILE"
    fi

    # Add stack trace if in debug mode and level is ERROR or CRITICAL
    if [ "$DEBUG_MODE" -eq 1 ] && [[ "$level" =~ ^(ERROR|CRITICAL)$ ]]; then
        local i=0
        while caller $i > /dev/null; do
            local func_info=$(caller $i)
            stack="$stack\n    at line ${func_info}"
            ((i++))
        done
        message="$message$stack"
    fi

    # Set color based on log level
    case "$level" in
        "DEBUG")    color="${DARK_GRAY}"; console_prefix="[DEBUG]" ;;
        "INFO")     color="${BLUE}"; console_prefix="[INFO]" ;;
        "SUCCESS")  color="${GREEN}"; console_prefix="[SUCCESS]" ;;
        "WARNING")  color="${YELLOW}"; console_prefix="[WARNING]" ;;
        "ERROR")    color="${RED}"; console_prefix="[ERROR]" ;;
        "CRITICAL") color="${LIGHT_RED}"; console_prefix="[CRITICAL]" ;;
        *)          color="${NC}"; console_prefix="[LOG]" ;;
    esac

    # Append to log file
    echo -e "${timestamp} [${level}] ${message}" >> "$LOG_FILE"

    # Print to console if not in DEBUG mode or DEBUG mode is enabled
    if [ "$level" != "DEBUG" ] || [ "$DEBUG_MODE" -eq 1 ]; then
        echo -e "${color}${console_prefix}${NC} $message"
    fi
}

# Helper log functions
log_debug() { log_message "DEBUG" "$1"; }
log_info() { log_message "INFO" "$1"; }
log_success() { log_message "SUCCESS" "$1"; }
log_warning() { log_message "WARNING" "$1"; }
log_error() { log_message "ERROR" "$1"; }
log_critical() { log_message "CRITICAL" "$1"; }

# Function to create lock file
create_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [ -n "$pid" ] && ps -p "$pid" &>/dev/null; then
            log_error "$([ "$LANGUAGE" == "ar" ] && echo "البرنامج قيد التشغيل بالفعل (PID: $pid)." || echo "Program is already running (PID: $pid).")"
            return 1
        else
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "تم العثور على ملف قفل قديم. سيتم إزالته." || echo "Stale lock file found. Removing it.")"
            remove_lock
        fi
    fi

    echo $$ > "$LOCK_FILE"
    log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم إنشاء ملف القفل (PID: $$)." || echo "Lock file created (PID: $$).")"
    return 0
}

# Function to remove lock file
remove_lock() {
    [ -f "$LOCK_FILE" ] && rm -f "$LOCK_FILE"
    log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم إزالة ملف القفل." || echo "Lock file removed.")"
}

# Function to handle cleanup before exit
cleanup_and_exit() {
    log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم استلام إشارة للخروج. التنظيف..." || echo "Exit signal received. Cleaning up...")"
    remove_lock
    log_info "$([ "$LANGUAGE" == "ar" ] && echo "===== انتهى تشغيل أداة الصيانة في $(date) =====" || echo "===== Maintenance Toolkit finished at $(date) =====")"
    exit 0
}

# Function to confirm user action
confirm_action() {
    local prompt="$1"
    local response=""

    while true; do
        read -r -p "${prompt} ($([ "$LANGUAGE" == "ar" ] && echo "نعم/لا" || echo "y/n")): " response
        case "${response,,}" in
            y|yes|نعم) return 0 ;;
            n|no|لا) return 1 ;;
            *) echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "الرجاء الإجابة بـ 'نعم' أو 'لا'." || echo "Please answer 'y' or 'n'.")${NC}" ;;
        esac
    done
}

# Check if command exists (with caching)
command_exists() {
    local cmd="$1"

    # Check if result is already cached
    if [[ -n "${COMMAND_EXISTS_CACHE[$cmd]}" ]]; then
        return ${COMMAND_EXISTS_CACHE[$cmd]}
    fi

    # Check command existence
    command -v "$cmd" &>/dev/null
    local result=$?

    # Cache the result
    COMMAND_EXISTS_CACHE[$cmd]=$result
    return $result
}

# Function to check if a package is installed
package_installed() {
    if command_exists dpkg; then
        dpkg -l "$1" 2>/dev/null | grep -q "^ii"
        return $?
    elif command_exists rpm; then
        rpm -q "$1" &>/dev/null
        return $?
    elif command_exists pacman; then
        pacman -Q "$1" &>/dev/null
        return $?
    else
        return 1 # Cannot determine
    fi
}

# Timer functions
start_timer() { TIMER_START=$(date +%s); }
stop_timer() { TIMER_END=$(date +%s); }
get_elapsed_time() {
    if [ "$TIMER_END" -gt 0 ] && [ "$TIMER_START" -gt 0 ]; then
        echo $(( TIMER_END - TIMER_START ))
    else
        echo "0"
    fi
}

# Create unified progress bar
create_progress_bar() {
    local percentage=$1
    local bar_length=40
    # Ensure percentage is within bounds 0-100
    [[ "$percentage" -lt 0 ]] && percentage=0
    [[ "$percentage" -gt 100 ]] && percentage=100

    local filled_length=$(( percentage * bar_length / 100 ))
    local empty_length=$(( bar_length - filled_length ))

    local bar="["

    # Determine color based on percentage
    local bar_color=$GREEN
    if [ "$percentage" -gt 90 ]; then
        bar_color=$RED
    elif [ "$percentage" -gt 70 ]; then
        bar_color=$YELLOW
    fi

    # Create filled and empty parts
    # --- التغيير هنا: استبدال '█' بـ '=' ---
    local filled=$(printf '%*s' "$filled_length" | tr ' ' '=')
    local empty=$(printf '%*s' "$empty_length")
    bar="${bar}${bar_color}${filled}${NC}${empty}"

    bar="${bar}]"
    # Ensure percentage is printed correctly even if input was float
    printf "%s %d%%\n" "$bar" "$percentage"
}


# Function to display a spinner during long operations
show_spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='-\|/'

    # Don't show spinner if not in a terminal
    if ! tty -s; then
        wait $pid
        return
    fi

    echo -ne "${message} "

    # Run spinner only while the process is running
    while ps -p $pid &>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]" "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
    done
    printf "    \b\b\b\b"

    echo -e "${GREEN}$([ "$LANGUAGE" == "ar" ] && echo "تم!" || echo "Done!")${NC}"
}

# Input sanitization and validation
sanitize_input() {
    # Remove potentially harmful characters, allow paths and spaces
    echo "$1" | sed -e 's/[;&|<>`$(){}\[\]*!]/ /g'
}


# Optimized function to validate file paths
validate_path() {
    local path="$1"

    # Expand ~ to $HOME
    path="${path/#\~/$HOME}"

    # Check if path starts with / (absolute) or ./ (relative)
    # Allow relative paths from current dir as well
    # if [[ ! "$path" =~ ^(/|\./) && "$path" != "." ]]; then
    #     path="./$path"
    # fi

    # Resolve the actual path using realpath if available
    local resolved_path=""
    if command_exists realpath; then
        resolved_path=$(realpath -m "$path" 2>/dev/null) # -m allows non-existent paths
    else
        # Basic resolution if realpath isn't available
        if [[ "$path" == /* ]]; then
            resolved_path="$path"
        else
            resolved_path="$PWD/$path"
        fi
        # Basic normalization (remove .. , .) - might not be perfect
         resolved_path=$(echo "$resolved_path" | sed -E 's#/\./#/#g; s#/[^/]+/\.\./#/#g')
    fi


    if [ -z "$resolved_path" ]; then
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "مسار غير صالح أو تعذر تحديده: $path" || echo "Invalid or could not resolve path: $path")"
        return 1
    fi

    # System directories to protect (be careful with this list)
    local system_dirs=("/bin" "/boot" "/dev" "/etc" "/lib" "/lib32" "/lib64" "/proc" "/sbin" "/sys" "/usr" "/var") # Added /usr and /var

    for dir in "${system_dirs[@]}"; do
        # Check if the resolved path IS exactly a system dir or IS INSIDE a system dir
        if [[ "$resolved_path" == "$dir" || "$resolved_path" == "$dir/"* ]]; then
            # Allow paths within /var/log or /var/tmp maybe? Be specific.
            if [[ "$resolved_path" != "/var/log"* && "$resolved_path" != "/var/tmp"* ]]; then
                 log_error "$([ "$LANGUAGE" == "ar" ] && echo "لا يمكن استخدام دلائل النظام المحمية: $resolved_path" || echo "Protected system directories cannot be used: $resolved_path")"
                 return 1
            fi
        fi
    done

    echo "$resolved_path"
    return 0
}


# Function to safely execute commands with error handling
safe_execute() {
    local command="$1"
    local error_message="$2"
    local temp_error_file=$(mktemp)

    log_debug "Executing: $command"

    # Execute the command
    eval "$command" 2>"$temp_error_file"
    local status=$?

    if [ $status -ne 0 ]; then
        local error=$(cat "$temp_error_file")
        log_error "${error_message}: ${error}"
        rm -f "$temp_error_file"
        return 1
    fi

    rm -f "$temp_error_file"
    return 0
}

# Check if running with sudo privileges
check_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Safely prompt for sudo
prompt_sudo() {
    if check_sudo; then
        return 0
    fi

    echo -e "${YELLOW}$([ "$LANGUAGE" == "ar" ] && echo "هذه العملية تتطلب صلاحيات الجذر." || echo "This operation requires root privileges.")${NC}"
    sudo -v
    if [ $? -ne 0 ]; then
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل في الحصول على صلاحيات الجذر." || echo "Failed to obtain root privileges.")"
        return 1
    fi
    return 0
}

# Run command with appropriate privileges
run_with_privileges() {
    local command="$1"

    if check_sudo; then
        # Already root, execute directly
        eval "$command"
    elif command_exists sudo; then
         # Use sudo
        sudo bash -c "$command" # Use bash -c for complex commands
    else
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "مطلوب sudo لتنفيذ: $command" || echo "sudo required to execute: $command")"
        return 1
    fi
}


# Get random motivational message
get_random_quote() {
    local quotes_en=(
        "Regular maintenance extends your system's life."
        "Regular cleaning keeps your system performing well."
        "Always backup before making major changes."
        "Security is not a product, but a process."
        "The simplest solutions are often the best."
        "Keep your system updated for security and performance."
        "A clean system is a happy system!"
    )
     local quotes_ar=(
        "الصيانة المنتظمة تطيل عمر نظامك."
        "التنظيف المنتظم يحافظ على أداء النظام."
        "قم بعمل نسخة احتياطية دائمًا قبل إجراء تغييرات كبيرة."
        "الأمن ليس منتجًا، بل هو عملية."
        "أبسط الحلول غالبًا ما تكون الأفضل."
        "حافظ على تحديث نظامك للأمان والأداء."
        "النظام النظيف هو نظام سعيد!"
    )

    if [ "$LANGUAGE" == "ar" ]; then
         local random_index=$((RANDOM % ${#quotes_ar[@]}))
         echo "${quotes_ar[$random_index]}"
    else
         local random_index=$((RANDOM % ${#quotes_en[@]}))
         echo "${quotes_en[$random_index]}"
    fi

}

# Check internet connectivity (cross-distro compatible)
check_internet() {
    log_info "$([ "$LANGUAGE" == "ar" ] && echo "التحقق من اتصال الإنترنت..." || echo "Checking internet connectivity...")"

    local domains=("google.com" "debian.org" "cloudflare.com" "kernel.org") # Added more diverse domains
    local connected=0
    local connected_domain=""

    # Check if curl or wget exists first
    local http_client=""
    if command_exists curl; then
        http_client="curl -s --head --connect-timeout 2 --max-time 4"
    elif command_exists wget; then
         http_client="wget --spider --quiet --timeout=2 --tries=1"
    fi

    if [ -n "$http_client" ]; then
        for domain in "${domains[@]}"; do
            if eval "$http_client https://$domain" >/dev/null 2>&1; then
                connected=1
                connected_domain="$domain"
                break
            fi
        done

        if [ $connected -eq 1 ]; then
            log_success "$([ "$LANGUAGE" == "ar" ] && echo "متصل بالإنترنت (تم الوصول إلى $connected_domain)." || echo "Internet connected (reached $connected_domain).")"
            # Optionally add speed test here if needed
            return 0
        else
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "لا يوجد اتصال بالإنترنت." || echo "No internet connection.")"
            return 1
        fi
    else
        # Fall back to ping if curl/wget are not available
        for domain in "${domains[@]}"; do
            # Use -W 1 for 1 second timeout, adjust count if needed
            if ping -c 1 -W 1 "$domain" &>/dev/null; then
                connected=1
                connected_domain="$domain"
                break
            fi
        done

        if [ $connected -eq 1 ]; then
            log_success "$([ "$LANGUAGE" == "ar" ] && echo "متصل بالإنترنت (تم الوصول إلى $connected_domain عبر ping)." || echo "Internet connected (reached $connected_domain via ping).")"
            return 0
        else
            log_warning "$([ "$LANGUAGE" == "ar" ] && echo "لا يوجد اتصال بالإنترنت (فشل ping)." || echo "No internet connection (ping failed).")"
            return 1
        fi
    fi
}


# Check system requirements (cross-distro compatible)
check_system_requirements() {
    log_info "$([ "$LANGUAGE" == "ar" ] && echo "التحقق من متطلبات النظام..." || echo "Checking system requirements...")"

    local missing_deps=()

    # Check for required commands (essential for operation)
    local required_commands=("grep" "awk" "sed" "find" "tar" "df" "du" "date" "cut" "tr" "head" "tail" "basename" "dirname" "readlink" "stat" "free" "uname" "hostname" "id" "getent" "ps" "cat")

    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "تعذر العثور على الأوامر المطلوبة:" || echo "Required commands not found:") ${missing_deps[*]}"
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "الرجاء تثبيت الحزم المفقودة قبل المتابعة." || echo "Please install missing packages before continuing.")"
        return 1
    fi

    # Detect Linux distribution and package manager
    if [ -z "$PACKAGE_MANAGER" ]; then # Avoid re-detecting if already set
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            distro="${ID:-unknown}"
            log_info "Detected distribution: $distro ($VERSION_ID)"
        else
            log_warning "Could not determine Linux distribution from /etc/os-release."
            distro="unknown"
        fi

        # Check for package manager
        if command_exists apt-get; then
            PACKAGE_MANAGER="apt-get"
        elif command_exists dnf; then
            PACKAGE_MANAGER="dnf"
        elif command_exists yum; then
            PACKAGE_MANAGER="yum"
        elif command_exists pacman; then
            PACKAGE_MANAGER="pacman"
        else
            log_warning "Could not determine package manager. Some features like update/install may not work."
            PACKAGE_MANAGER="unknown"
        fi
        export PACKAGE_MANAGER # Export for other scripts
        log_info "Using package manager: $PACKAGE_MANAGER"
    fi


    log_success "$([ "$LANGUAGE" == "ar" ] && echo "تم التحقق من متطلبات النظام بنجاح." || echo "System requirements verified successfully.")"
    return 0
}


# Function to get system information for testing distro-specific code
get_distro_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "ID=$ID"
        echo "VERSION_ID=$VERSION_ID"
        echo "NAME=$NAME"
    else
        echo "ID=unknown"
        echo "VERSION_ID=unknown"
        echo "NAME=Unknown Distribution"
    fi
}


# Backup a file before modifying it
backup_file() {
    local file="$1"
    local backup_file="${file}.bak.$(date +%Y%m%d%H%M%S)"

    if [ ! -f "$file" ]; then
        log_warning "$([ "$LANGUAGE" == "ar" ] && echo "الملف غير موجود للنسخ الاحتياطي: $file" || echo "File not found for backup: $file")"
        return 1
    fi

    cp -a "$file" "$backup_file" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_info "$([ "$LANGUAGE" == "ar" ] && echo "تم إنشاء نسخة احتياطية من الملف: $backup_file" || echo "Created backup of file: $backup_file")"
        return 0
    else
        log_error "$([ "$LANGUAGE" == "ar" ] && echo "فشل في إنشاء نسخة احتياطية: $file" || echo "Failed to create backup: $file")"
        return 1
    fi
}

# Function to translate battery status to Arabic
translate_battery_status() {
    local status="$1"

    case "$status" in
        "Charging")     echo "جاري الشحن" ;;
        "Discharging")  echo "تفريغ" ;;
        "Full")         echo "مشحونة بالكامل" ;;
        "Unknown")      echo "غير معروف" ;;
        *)              echo "$status" ;; # Return original if not matched
    esac
}

