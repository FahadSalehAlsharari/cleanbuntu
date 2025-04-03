#!/bin/bash

# Cleanbuntu Uninstallation Script
# Author: Fahad Alsharari 
# Website: https://FahadAlsharari.sa

# --- الألوان ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

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

# --- المسارات المراد إزالتها ---
# Paths to remove
INSTALL_DIR="$REAL_HOME/.desktop-maintainer"
CONFIG_DIR="$REAL_HOME/.config/cleanbuntu"
LOG_DIR="$REAL_HOME/Documents/cleanbuntu-logs"
BACKUP_DIR="$REAL_HOME/Documents/cleanbuntu-backups" # مجلد النسخ الاحتياطي الافتراضي (Default backup directory)
BIN_PATH="/usr/local/bin/cleanbuntu"

# --- التحقق من صلاحيات الجذر ---
# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}${BOLD}خطأ:${NC} يجب تشغيل هذا السكربت بصلاحيات الجذر (sudo) لإزالة الرابط الرمزي."
    echo -e "الرجاء التنفيذ كالتالي: ${GREEN}sudo $0${NC}"
    exit 1
fi

# --- رسالة تحذير وتأكيد ---
# Warning message and confirmation
echo -e "${YELLOW}${BOLD}تحذير:${NC} سيقوم هذا السكربت بإزالة برنامج Cleanbuntu وجميع ملفاته."
echo -e "المسارات التي سيتم حذفها (إذا كانت موجودة):"
echo -e "  - الرابط الرمزي: ${BIN_PATH}"
echo -e "  - مجلد التثبيت: ${INSTALL_DIR}"
echo -e "  - مجلد الإعدادات: ${CONFIG_DIR}"
echo -e "  - مجلد السجلات: ${LOG_DIR}"
echo -e "سيتم سؤالك أيضًا عن حذف مجلد النسخ الاحتياطية: ${BACKUP_DIR}"
echo

# Ask for confirmation
read -r -p "هل أنت متأكد من رغبتك في المتابعة؟ (نعم/لا): " confirm
if [[ ! "${confirm,,}" =~ ^(yes|y|نعم)$ ]]; then
    echo "تم إلغاء عملية الإزالة."
    exit 0
fi

# --- بدء عملية الإزالة ---
# Start uninstallation process
echo
echo -e "${YELLOW}بدء عملية إلغاء التثبيت...${NC}"

# 1. إزالة الرابط الرمزي
# 1. Remove symbolic link
echo -n "إزالة الرابط الرمزي (${BIN_PATH})... "
if [ -L "$BIN_PATH" ]; then
    rm -f "$BIN_PATH"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}تم.${NC}"
    else
        echo -e "${RED}فشل.${NC}" # Failed
    fi
else
    echo -e "${YELLOW}غير موجود.${NC}" # Not found
fi

# 2. إزالة مجلد التثبيت
# 2. Remove installation directory
echo -n "إزالة مجلد التثبيت (${INSTALL_DIR})... "
if [ -d "$INSTALL_DIR" ]; then
    # استخدام rm -rf بحذر شديد!
    # Use rm -rf very carefully!
    rm -rf "$INSTALL_DIR"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}تم.${NC}"
    else
        echo -e "${RED}فشل.${NC}" # Failed
    fi
else
    echo -e "${YELLOW}غير موجود.${NC}" # Not found
fi

# 3. إزالة مجلد الإعدادات
# 3. Remove configuration directory
echo -n "إزالة مجلد الإعدادات (${CONFIG_DIR})... "
if [ -d "$CONFIG_DIR" ]; then
    rm -rf "$CONFIG_DIR"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}تم.${NC}"
    else
        echo -e "${RED}فشل.${NC}" # Failed
    fi
else
    echo -e "${YELLOW}غير موجود.${NC}" # Not found
fi

# 4. إزالة مجلد السجلات
# 4. Remove log directory
echo -n "إزالة مجلد السجلات (${LOG_DIR})... "
if [ -d "$LOG_DIR" ]; then
    rm -rf "$LOG_DIR"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}تم.${NC}"
    else
        echo -e "${RED}فشل.${NC}" # Failed
    fi
else
    echo -e "${YELLOW}غير موجود.${NC}" # Not found
fi

# 5. السؤال عن حذف مجلد النسخ الاحتياطية
# 5. Ask about removing backup directory
echo
if [ -d "$BACKUP_DIR" ]; then
    read -r -p "هل ترغب أيضًا في حذف مجلد النسخ الاحتياطية (${BACKUP_DIR})؟ (نعم/لا): " confirm_backup
    if [[ "${confirm_backup,,}" =~ ^(yes|y|نعم)$ ]]; then
        echo -n "إزالة مجلد النسخ الاحتياطية (${BACKUP_DIR})... "
        rm -rf "$BACKUP_DIR"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}تم.${NC}"
        else
            echo -e "${RED}فشل.${NC}" # Failed
        fi
    else
        echo "تم الإبقاء على مجلد النسخ الاحتياطية." # Kept backup directory
    fi
else
    echo "مجلد النسخ الاحتياطية (${BACKUP_DIR}) غير موجود." # Backup directory not found
fi

# --- رسالة الإكمال ---
# Completion message
echo
echo -e "${GREEN}${BOLD}اكتملت عملية إلغاء تثبيت Cleanbuntu بنجاح.${NC}"
echo "قد تحتاج إلى إعادة تشغيل الطرفية (Terminal) لتحديث المسارات."

exit 0
