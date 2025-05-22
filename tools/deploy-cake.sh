#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
APP_DIR="$(realpath "${SCRIPT_DIR}/..")"
CAKEPHP_WEBROOT="$APP_DIR/webroot"
WEBROOT_PATH="/var/www/webShop/webroot"  # Example target path for the symlink

#--------------------------------------------------------------------
# 🐘 Change permissions on CakePHP folders and files
#--------------------------------------------------------------------
chown -R www-data:www-data "$APP_DIR"
chmod -R 755 "$APP_DIR"

#--------------------------------------------------------------------
# 🐘 Deploy cake webroot folder as softlink to /var/www/webShop/webroot
#--------------------------------------------------------------------
echo "🔗 Creating CakePHP webroot symlink at $WEBROOT_PATH..."
if [ -L "$WEBROOT_PATH" ] || [ -e "$WEBROOT_PATH" ]; then
    echo "⚠️ $WEBROOT_PATH already exists, skipping symlink"
else
    ln -s "$CAKEPHP_WEBROOT" "$WEBROOT_PATH"
    chown -R www-data:www-data "$WEBROOT_PATH"
    chmod -R 755 "$WEBROOT_PATH"
    echo "✅ Symlink created: $CAKEPHP_WEBROOT → $WEBROOT_PATH"
fi

