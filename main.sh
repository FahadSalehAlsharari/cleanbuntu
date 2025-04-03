#!/bin/bash

# Meta information
readonly VERSION="2.0.0"
readonly AUTHOR="Fahad Alsharari"
readonly WEBSITE="https://FahadAlsharari.sa"
readonly CONTACT="admin@FahadAlsharari.sa"

# Import required modules
if [ -L "${BASH_SOURCE[0]}" ]; then
    # Handle symlink
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
else
    # Regular file
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Source dependencies from the correct location
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/ui.sh"
source "${SCRIPT_DIR}/system.sh"
source "${SCRIPT_DIR}/maintenance.sh"
source "${SCRIPT_DIR}/backup.sh"

# Main function
main() {
    # Initialize log
    init_log
    
    # Check command line arguments
    [ $# -gt 0 ] && parse_args "$@"
    
    # Initialize configuration
    init_config
    
    # Set up lock file
    create_lock || exit 1
    
    # Set up signal trapping
    trap cleanup_and_exit INT TERM EXIT
    
    # Check root privileges
    check_root
    
    # Check internet connectivity
    check_internet
    
    # Check system requirements
    check_system_requirements
    
    # Show main menu
    show_menu
}

# Parse command line arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --config|-c)
                init_config
                change_settings
                exit 0
                ;;
            --version|-v)
                echo "Cleanbuntu - Desktop Maintenance Toolkit v${VERSION}"
                echo "Author: ${AUTHOR} (${WEBSITE})"
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --health|-H)
                init_config
                perform_quick_health_check
                exit 0
                ;;
            --update|-u)
                init_config
                system_update
                exit 0
                ;;
            --clean|-C)
                init_config
                perform_cleanup
                exit 0
                ;;
            --backup|-b)
                init_config
                backup_configs
                exit 0
                ;;
            --restore|-r)
                init_config
                restore_backup
                exit 0
                ;;
            *)
                log_error "$([ "$LANGUAGE" == "ar" ] && echo "خيار غير معروف:" || echo "Unknown option:") $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# Show help information
show_help() {
    echo "Cleanbuntu - Desktop Maintenance Toolkit v${VERSION}"
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo
    echo "OPTIONS:"
    echo "  --config, -c    Configure settings and language"
    echo "  --health, -H    Perform a quick system health check"
    echo "  --update, -u    Update system packages"
    echo "  --clean, -C     Clean up system"
    echo "  --backup, -b    Backup system configurations"
    echo "  --restore, -r   Restore from backup"
    echo "  --version, -v   Show version information"
    echo "  --help, -h      Show this help message"
    echo
    echo "This toolkit must be run with sudo privileges for certain operations."
    echo "Visit ${WEBSITE} for more information."
}

# Run main function with all arguments
main "$@"