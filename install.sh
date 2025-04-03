#!/bin/bash

# Cleanbuntu Installation Script (Robust Version)
# Author: Fahad Alsharari # Website: https://FahadAlsharari.sa

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat pipe errors as command errors
set -o pipefail

# --- الألوان ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- التحقق من الأوامر الأساسية ---
echo -e "${BLUE}التحقق من وجود الأوامر الأساسية...${NC}"
for cmd in getent cut mkdir cp chmod chown ln rm cat dirname readlink realpath; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}${BOLD}خطأ:${NC} الأمر المطلوب '$cmd' غير موجود. لا يمكن المتابعة."
        exit 1
    fi
done
echo -e "${GREEN}الأوامر الأساسية موجودة.${NC}"

# --- تحديد المستخدم الحقيقي ومساره الرئيسي ---
# Detect the real user even when run with sudo
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(whoami)"
fi
# استخدام getent للحصول على المسار الرئيسي بشكل موثوق
# Use getent to reliably get the real user's home directory
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
if [ -z "$REAL_HOME" ] || [ ! -d "$REAL_HOME" ]; then
    echo -e "${RED}${BOLD}خطأ:${NC} لم يتم العثور على المجلد الرئيسي للمستخدم '$REAL_USER'."
    exit 1
fi

# --- مسارات التثبيت ---
# Installation paths
INSTALL_DIR="$REAL_HOME/.desktop-maintainer"
CONFIG_DIR="$REAL_HOME/.config/cleanbuntu"
LOG_DIR="$REAL_HOME/Documents/cleanbuntu-logs"
BACKUP_DIR="$REAL_HOME/Documents/cleanbuntu-backups"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"
BIN_PATH="/usr/local/bin/cleanbuntu"

# --- تحديد مسار السكربت المصدر ---
# Get the source script directory reliably, handling symlinks
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

# --- التحقق من وجود الملفات المصدر الأساسية ---
echo -e "${BLUE}التحقق من وجود ملفات البرنامج المصدر...${NC}"
ESSENTIAL_FILES=( "main.sh" "utils.sh" "config.sh" "ui.sh" "system.sh" "maintenance.sh" "backup.sh" )
for file in "${ESSENTIAL_FILES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$file" ]; then
        echo -e "${RED}${BOLD}خطأ:${NC} الملف الأساسي المطلوب للتثبيت غير موجود: ${BOLD}$SCRIPT_DIR/$file${NC}"
        echo -e "${YELLOW}تأكد من تشغيل السكربت من المجلد الصحيح الذي يحتوي على جميع ملفات البرنامج.${NC}"
        exit 1
    fi
done
echo -e "${GREEN}ملفات البرنامج المصدر موجودة.${NC}"


# --- رسالة الترحيب والتحقق من صلاحيات الجذر ---
# Welcome message and root check
echo
echo -e "${GREEN}=== Cleanbuntu Installation ===${NC}"
echo -e "Installing Desktop Maintenance Toolkit..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}${BOLD}خطأ:${NC} هذا السكربت يحتاج إلى صلاحيات الجذر (sudo) للتثبيت."
    echo -e "الرجاء التنفيذ كالتالي: ${GREEN}sudo $0${NC}"
    exit 1
fi

# --- اختيار اللغة ---
# Language selection
echo
echo -e "${BLUE}Please select your preferred language / الرجاء اختيار اللغة المفضلة:${NC}"
echo -e "1. English"
echo -e "2. العربية (Arabic)"
echo

read -r -p "Enter choice [1-2] (Default: 1): " lang_choice

case $lang_choice in
    2)
        echo -e "تم اختيار اللغة العربية"
        SELECTED_LANG="ar"
        ;;
    *)
        echo -e "English language selected"
        SELECTED_LANG="en"
        ;;
esac

# --- عملية التثبيت ---
# Installation process
echo
echo -e "${YELLOW}بدء عملية التثبيت...${NC}"

# 1. إنشاء مجلدات التثبيت والإعدادات والسجلات
echo -e "- إنشاء المجلدات اللازمة..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/lib" # Ensure lib directory exists
mkdir -p "$CONFIG_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR" # Create default backup dir

# 2. نسخ ملفات البرنامج
echo -e "- نسخ ملفات البرنامج إلى ${INSTALL_DIR}..."
# Copy essential files first
cp -f "$SCRIPT_DIR/main.sh" "$INSTALL_DIR/"
cp -f "$SCRIPT_DIR/utils.sh" "$INSTALL_DIR/"
cp -f "$SCRIPT_DIR/config.sh" "$INSTALL_DIR/"
cp -f "$SCRIPT_DIR/ui.sh" "$INSTALL_DIR/"
cp -f "$SCRIPT_DIR/system.sh" "$INSTALL_DIR/"
cp -f "$SCRIPT_DIR/maintenance.sh" "$INSTALL_DIR/"
cp -f "$SCRIPT_DIR/backup.sh" "$INSTALL_DIR/"
# Copy install/uninstall scripts if they exist in source (optional)
cp -f "$SCRIPT_DIR/install.sh" "$INSTALL_DIR/" 2>/dev/null || true
cp -f "$SCRIPT_DIR/uninstall.sh" "$INSTALL_DIR/" 2>/dev/null || true

# 3. تعيين الأذونات والملكية
echo -e "- تعيين الأذونات والملكية..."
chmod +x "$INSTALL_DIR/"*.sh # Make all scripts executable
# Set ownership recursively for all created directories and files
chown -R "$REAL_USER":"$REAL_USER" "$INSTALL_DIR" "$CONFIG_DIR" "$LOG_DIR" "$BACKUP_DIR"
# Verify ownership setting (optional but good for debugging)
if [ "$(stat -c '%U' "$INSTALL_DIR")" != "$REAL_USER" ]; then
     echo -e "${YELLOW}تحذير: قد تكون هناك مشكلة في تعيين ملكية ${INSTALL_DIR}${NC}"
fi

# 4. إنشاء الرابط الرمزي
echo -e "- إنشاء الرابط الرمزي في ${BIN_PATH}..."
# Remove existing link first to avoid errors if it points elsewhere
rm -f "$BIN_PATH"
# Create the link
ln -s "$INSTALL_DIR/main.sh" "$BIN_PATH"
# Verify link creation
if [ ! -L "$BIN_PATH" ] || [ "$(readlink -f "$BIN_PATH")" != "$INSTALL_DIR/main.sh" ]; then
    echo -e "${RED}${BOLD}خطأ:${NC} فشل في إنشاء الرابط الرمزي بشكل صحيح في ${BIN_PATH}"
    echo -e "${YELLOW}تأكد من أن لديك صلاحيات للكتابة في /usr/local/bin${NC}"
    # Clean up potentially partially created link
    rm -f "$BIN_PATH"
    exit 1
fi
chmod +x "$BIN_PATH"

# 5. إنشاء ملف الإعدادات الافتراضي
echo -e "- إنشاء ملف الإعدادات الافتراضي (${SETTINGS_FILE})..."
# Use cat with redirection, error handled by set -e
cat > "$SETTINGS_FILE" << EOF
# Cleanbuntu Configuration File
LANGUAGE="$SELECTED_LANG"
BACKUP_PATH="$BACKUP_DIR"
TMP_FILE_AGE=7
CLEAN_CACHE=1
CLEAN_BROWSER_CACHE=1
BACKUP_FIREFOX=1
BACKUP_CHROME=1
EMPTY_TRASH=1
DEBUG_MODE=0
EOF
# Set ownership for the settings file
chown "$REAL_USER":"$REAL_USER" "$SETTINGS_FILE"
if [ $? -ne 0 ]; then
     echo -e "${YELLOW}تحذير: قد تكون هناك مشكلة في تعيين ملكية ملف الإعدادات ${SETTINGS_FILE}${NC}"
fi

# --- رسالة الإكمال ---
# Completion message
echo
# Show installation complete message in the selected language
if [ "$SELECTED_LANG" == "ar" ]; then
    echo -e "${GREEN}${BOLD}تم الانتهاء من التثبيت بنجاح!${NC}"
    echo -e "يمكنك الآن تشغيل البرنامج باستخدام: ${GREEN}cleanbuntu${NC}"
    echo -e "أو مع الخيارات: ${GREEN}cleanbuntu --help${NC}"
    echo
    echo -e "${YELLOW}ملاحظة:${NC} قد يتطلب التشغيل الأول صلاحيات المدير (sudo) لبعض العمليات."
else
    echo -e "${GREEN}${BOLD}Installation completed successfully!${NC}"
    echo -e "You can now run the toolkit using: ${GREEN}cleanbuntu${NC}"
    echo -e "Or with options: ${GREEN}cleanbuntu --help${NC}"
    echo
    echo -e "${YELLOW}Note:${NC} The first run may require sudo for certain operations."
fi

exit 0
