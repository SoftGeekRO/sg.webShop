#!/bin/bash

set -e

ACTION=$1

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (e.g. sudo $0 install)"
  exit 1
fi

if [[ -z "$ACTION" ]]; then
  echo "❓ Usage: sudo $0 [install|uninstall]"
  exit 1
fi

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    CODENAME=$VERSION_CODENAME
    ARCH=$(uname -m)
  else
    echo "❌ Cannot detect operating system"
    exit 1
  fi
}

install_database() {
  echo "🔧 Installing database engine..."
  if [[ "$ARCH" == "armv7l" ]]; then
    echo "📦 Installing MySQL (ARMv7 fallback)..."
    apt install -y mysql-server
  else
    echo "📦 Installing MariaDB 11.7..."
    curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash
    apt update
    apt install -y mariadb-server
  fi
  systemctl enable mariadb || systemctl enable mysql
  systemctl start mariadb || systemctl start mysql
}

if [[ "$ACTION" == "install" ]]; then
  echo "🚀 Starting SoftGeek stack installation (Debian-compatible deploy)..."

  detect_os

  apt update && apt upgrade -y

  echo "🔧 Installing dependencies..."
  apt install -y apt-transport-https lsb-release ca-certificates curl gnupg2 software-properties-common gnupg

  # ----------------------------
  # 🐘 PHP 8.2 from Sury
  # ----------------------------
  echo "🔧 Installing PHP 8.3..."
  apt install -y php8.3-fpm php8.3-cli php8.3-mysql php8.3-mbstring php8.3-intl php8.3-curl php8.3-xml php8.3-zip php8.3-bcmath php8.3-gd php8.3-opcache

  # ----------------------------
  # 🎼 Composer
  # ----------------------------
  echo "🔧 Installing Composer..."
  EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
  if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
      echo '❌ ERROR: Invalid composer installer checksum'
      rm composer-setup.php
      exit 1
  fi
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rm composer-setup.php

  # ----------------------------
  # 🧶 Node.js + npm
  # ----------------------------
  echo "🔧 Installing Node.js 22.x and npm..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt install -y nodejs

  # ----------------------------
  # 📦 Webpack + SASS
  # ----------------------------
  echo "🔧 Installing Webpack and SASS globally via npm..."
  npm install -g webpack@5 webpack-cli@5 sass@1.89.0

  install_database

  # ----------------------------
  # 🧠 Memcached
  # ----------------------------
  echo "🔧 Installing Memcached..."
  apt install -y memcached libmemcached-tools
  systemctl enable memcached
  systemctl start memcached

  # ----------------------------
  # 🌐 Nginx + Certbot
  # ----------------------------
  echo "🔧 Installing Nginx (Debian default) and Certbot..."
  apt install -y nginx certbot python3-certbot-nginx
  systemctl enable nginx
  systemctl start nginx

  echo "✅ Installation complete!"

elif [[ "$ACTION" == "uninstall" ]]; then
  echo "🧹 Uninstalling SoftGeek stack..."

  # Stop services
  systemctl stop nginx || true
  systemctl stop memcached || true
  systemctl stop mariadb || systemctl stop mysql || true

  # PHP
  echo "🧹 Removing PHP 8.3..."
  apt purge -y php8.3* && apt autoremove -y

  # Composer
  echo "🧹 Removing Composer..."
  rm -f /usr/local/bin/composer

  # Node.js, npm, Webpack, Sass
  echo "🧹 Removing Node.js and global npm packages..."
  npm uninstall -g webpack webpack-cli sass || true
  apt purge -y nodejs npm && apt autoremove -y

  # MariaDB
  echo "🧹 Removing MariaDB/MySQL..."
  apt purge -y mariadb-server mariadb-client mysql-server mysql-client && apt autoremove -y
  rm -rf /etc/mysql /var/lib/mysql

  # Memcached
  echo "🧹 Removing Memcached..."
  apt purge -y memcached libmemcached-tools && apt autoremove -y

  # Nginx + Certbot
  echo "🧹 Removing Nginx and Certbot..."
  apt purge -y nginx nginx-common certbot python3-certbot-nginx && apt autoremove -y
  rm -rf /etc/nginx /etc/letsencrypt

  echo "✅ Uninstallation complete."

else
  echo "❌ Unknown action: $ACTION"
  echo "Usage: sudo $0 [install|uninstall]"
  exit 1
fi
