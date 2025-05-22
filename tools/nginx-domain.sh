#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

usage() {
  echo "Usage: $0 domain.com [web_root_path] [php_fpm_socket]"
    echo "  domain.com domain2.com  - Domain name to configure"
    echo "  --webshop_path          - (Optional) Document root path, defaults to current directory"
    echo "  --php_fpm_socket        - (Optional) PHP-FPM socket path, default /run/php/php8.3-fpm.sock"
    echo "  --phpmyadmin            - subdomain for phpmyadmin ex: pma.domain.com"
    echo "  -h|--help               - display this help information"
  exit 1
}

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
APP_DIR="$(realpath "${SCRIPT_DIR}/..")"

# Default values
WWW_PATH="/var/www"
WEBSHOP_PATH="$WWW_PATH/webShop"
WEBROOT_PATH="$WEBSHOP_PATH/webroot"
ERROR_PAGES_PATH="$WWW_PATH/errorPages"

NGINX_CONF_DIR="/etc/nginx/conf.d"
NGINX_DEFAULT_SERVER="$NGINX_CONF_DIR/default.conf"

NGINX_SSL_SETTINGS="/etc/nginx/snippets/options-ssl-nginx.conf"
NGINX_ERROR_PAGES="/etc/nginx/snippets/errorPages.conf"

DH_PARAMS="/etc/letsencrypt/ssl-dhparams.pem"
SSL_DUMMY_CERT="/etc/ssl/certs/dummy.crt"
SSL_DUMMY_KEY="/etc/ssl/private/dummy.key"

PHP_FPM_SOCKET="/run/php/php8.3-fpm.sock"
PHPMYADMIN_VER="5.2.2"
PMA_DOMAIN=""

DOMAINS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --webshop_path)
      WEBSHOP_PATH="$2"
      shift 2
      ;;
    --php-socket)
      PHP_FPM_SOCKET="$2"
      shift 2
      ;;
    --phpmyadmin)
      PMA_DOMAIN="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      DOMAINS+=("$1")
      shift
      ;;
  esac
done

if [ ${#DOMAINS[@]} -eq 0 ]; then
  usage
fi

if [ ! -d "$WEBSHOP_PATH" ]; then
    echo "📁 Creating web root directory at $WEBSHOP_PATH..."
    mkdir -p "$WEBSHOP_PATH"
    echo "<h1>$DOMAIN is set up correctly!</h1>" > "$WEBSHOP_PATH/index.php"
    chown -R www-data:www-data "$WEBSHOP_PATH"
    chmod -R 755 "$WEBSHOP_PATH"
else
    echo "❌ WEB Root folder "$WEBSHOP_PATH" already exists. Skipping"
fi

if [ ! -d "$ERROR_PAGES_PATH" ]; then
    echo "📁 Create errorPages in $ERROR_PAGES_PATH"
    #mkdir -p "$ERROR_PAGES_PATH"
    cp -R "$APP_DIR/utils/nginx/errorPages/" "$ERROR_PAGES_PATH"
    chown -R www-data:www-data "$ERROR_PAGES_PATH"
    chmod -R 755 "$ERROR_PAGES_PATH"
fi

# Prerequisites setup (only once)
if [ ! -f "$DH_PARAMS" ]; then
  echo "🔧 Generating Diffie-Hellman parameters..."
  openssl dhparam -out "$DH_PARAMS" 2048
fi

if [ ! -f "$SSL_DUMMY_CERT" ] && [ ! -f "$SSL_DUMMY_KEY" ]; then
    echo -e "🔧 Generate the dummy self-signed certificates"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$SSL_DUMMY_KEY" \
      -out "$SSL_DUMMY_CERT" \
      -subj "/CN=localhost"
fi

if [ ! -f "$NGINX_SSL_SETTINGS" ]; then
  echo "🔧 Creating SSL settings..."
  tee "$NGINX_SSL_SETTINGS" > /dev/null <<EOF
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;
ssl_ciphers "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
ssl_stapling off;
ssl_stapling_verify off;
resolver 1.1.1.1 8.8.8.8 valid=300s;
resolver_timeout 5s;
EOF
fi

if [ ! -f "$NGINX_ERROR_PAGES" ]; then
  echo "🔧 Creating error pages config..."
  tee "$NGINX_ERROR_PAGES" > /dev/null <<EOF
error_page 400 401 403 404 405 408 429 500 501 502 503 504 /error.php;
location = /error.php {
  fastcgi_pass unix:$PHP_FPM_SOCKET;
  include fastcgi_params;
  fastcgi_param SCRIPT_FILENAME $ERROR_PAGES_PATH/error.php;
  fastcgi_param QUERY_STRING error=\$status;
}
EOF
fi

if [ ! -f "$NGINX_DEFAULT_SERVER" ]; then
    echo -e "\n🌐 Setting up default server."
    tee "$NGINX_DEFAULT_SERVER" > /dev/null <<EOF
server {
    listen 80 default_server http2;
    listen [::]:80 default_server http2;

    listen 443 default_server ssl http2;
    listen [::]:443 default_server ssl http2;

    server_name _;

    include $NGINX_ERROR_PAGES;

    ssl_certificate "$SSL_DUMMY_CERT";
    ssl_certificate_key "$SSL_DUMMY_KEY";

    return 444;
}
EOF
fi

# Loop over domains
for DOMAIN in "${DOMAINS[@]}"; do
  echo -e "\n🌐 Setting up $DOMAIN..."

  CONF_FILE="$NGINX_CONF_DIR/$DOMAIN.conf"
  SSL_CERTIFICATE="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
  SSL_CERTIFICATE_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

  if [ -f "$CONF_FILE" ]; then
    echo "❌ Config file for $DOMAIN already exists. Skipping."
    continue
  fi

  cat > "$CONF_FILE" <<EOF
server {
  listen 80 http2;
  listen [::]:80 http2;

  server_name $DOMAIN www.$DOMAIN;
  root $WEBROOT_PATH;

  include $NGINX_ERROR_PAGES;

  location / {
    return 301 https://\$host\$request_uri;
  }

  location ~ \/\.well-known\/acme-challenge {
    allow all;
    root $WEBROOT_PATH;
  }
}

server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;

  server_name $DOMAIN www.$DOMAIN;
  root $WEBROOT_PATH;

  ssl_certificate $SSL_CERTIFICATE;
  ssl_certificate_key $SSL_CERTIFICATE_KEY;
  ssl_dhparam $DH_PARAMS;
  include $NGINX_SSL_SETTINGS;

  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
  add_header X-Content-Type-Options nosniff;
  add_header X-Frame-Options DENY;

  include $NGINX_ERROR_PAGES;

  location / {
    try_files \$uri \$uri/ /index.php?\$args;
  }

  location ~ \.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:$PHP_FPM_SOCKET;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include fastcgi_params;
  }

  location ~ /\.ht {
    deny all;
  }
}
EOF

    # Only get certificate if not already existing
    if [ ! -f "$SSL_CERTIFICATE" ] && [ ! -f "$SSL_CERTIFICATE_KEY" ]; then
        echo "🔐 Obtaining SSL cert for $DOMAIN..."
        systemctl stop nginx
        certbot certonly --standalone -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m admin@$DOMAIN --redirect
        else
        echo -e "✅ SSL cert for $DOMAIN already exists. Skipping certbot.\n"
    fi

done

if [ -n "$PMA_DOMAIN" ]; then

    PMA_ROOT="/var/www/$PMA_DOMAIN"
    PMA_ZIP_URL="https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VER/phpMyAdmin-$PHPMYADMIN_VER-all-languages.zip"
    PMA_CONF="/etc/nginx/conf.d/$PMA_DOMAIN.conf"
    PMA_USER="admin"
    PMA_PASS=$(openssl rand -base64 12)
    PMA_SSL_CERTIFICATE="/etc/letsencrypt/live/$PMA_DOMAIN/fullchain.pem"
    PMA_SSL_CERTIFICATE_KEY="/etc/letsencrypt/live/$PMA_DOMAIN/privkey.pem"

    if [ ! -d "$PMA_ROOT" ]; then
    echo "🔧 Downloading phpMyAdmin"
    mkdir -p "$PMA_ROOT"
    wget -q "$PMA_ZIP_URL" -O /tmp/phpmyadmin.zip
    unzip -q /tmp/phpmyadmin.zip -d /tmp/
    mv /tmp/phpMyAdmin-$PHPMYADMIN_VER-all-languages/* "$PMA_ROOT"
    rm -R /tmp/phpmyadmin.zip "/tmp/phpMyAdmin-$PHPMYADMIN_VER-all-languages"
    chown -R www-data:www-data "$PMA_ROOT"
    chmod -R 755 "$PMA_ROOT"
    else
    echo "❌ $PMA_ROOT already exists. Skipping phpMyAdmin install."
    fi

    echo "🔐 Setting up password protection..."
    echo "$PMA_USER:$(openssl passwd -apr1 "$PMA_PASS")" > /etc/nginx/.htpasswd_pma
    echo "🔑 phpMyAdmin credentials: $PMA_USER / $PMA_PASS"

    if [ ! -f "$PMA_CONF" ]; then
        echo "🔧 Generating Nginx config for $PMA_DOMAIN..."
        cat > "$PMA_CONF" <<EOF
server {
    listen 80 http2;
    listen [::]:80 http2;
    server_name $PMA_DOMAIN;

    location / {
        return 301 https://\$host\$request_uri;
    }

    location ~ /\.well-known/acme-challenge {
        allow all;
        root $PMA_ROOT;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $PMA_DOMAIN;

    root $PMA_ROOT;
    index index.php index.html;

    ssl_certificate $PMA_SSL_CERTIFICATE;
    ssl_certificate_key $PMA_SSL_CERTIFICATE_KEY;
    ssl_dhparam $DH_PARAMS;
    include $NGINX_SSL_SETTINGS;

    include $NGINX_ERROR_PAGES;

    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd_pma;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_FPM_SOCKET;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    fi

    if [ ! -f "$PMA_SSL_CERTIFICATE" ] && [ ! -f "$PMA_SSL_CERTIFICATE_KEY" ]; then
      echo "📡 Attempting to obtain SSL certificate for $PMA_DOMAIN..."
      certbot certonly --standalone -d "$PMA_DOMAIN" --non-interactive --agree-tos -m admin@$PMA_DOMAIN --quiet
    fi
fi

echo "🔄 Restarting Nginx..."
systemctl restart nginx

echo "✅ All done. Domains configured: ${DOMAINS[*]}"
