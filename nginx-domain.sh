#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

usage() {
  echo "Usage: $0 domain.com [web_root_path] [php_fpm_socket]"
  echo "  domain.com      - Domain name to configure"
  echo "  web_root_path   - (Optional) Document root path, defaults to current directory"
  echo "  php_fpm_socket  - (Optional) PHP-FPM socket path, default /run/php/php8.3-fpm.sock"
  exit 1
}

if [ -z "$1" ]; then
  usage
fi

DOMAIN="$1"
WEB_PATH="/var/www"
DEFAULT_WEB_ROOT="$WEB_PATH/webShop"
PHP_FPM_SOCKET="${3:-/run/php/php8.3-fpm.sock}"

SSL_CERTIFICATE="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
SSL_CERTIFICATE_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"
SSL_TRUSTED_CERTIFICATE="/etc/letsencrypt/live/$DOMAIN/chain.pem"
DH_PARAMS="/etc/letsencrypt/ssl-dhparams.pem"
NGINX_SSL_SETTINGS="/etc/nginx/snippets/options-ssl-nginx.conf"
NGINX_ERROR_PAGES="/etc/nginx/snippets/errorPages.conf"
NGINX_CONF_DIR="/etc/nginx/conf.d"
CONF_FILE="$NGINX_CONF_DIR/$DOMAIN.conf"

if [ -f "$CONF_FILE" ]; then
  echo "❌ Config file $CONF_FILE already exists. Exiting."
  exit 1
fi

if [ ! -S "$PHP_FPM_SOCKET" ]; then
  echo "❌ PHP-FPM socket not found at $PHP_FPM_SOCKET. Exiting."
  exit 1
fi

if [ ! -f "$DH_PARAMS" ]; then
echo "🔧 Generate Diffie-Hellman parameters"
  openssl dhparam -out "$DH_PARAMS" 2048
else
  echo "❌ Diffie-Hellman file already exists. Skipping"
fi

if [ ! -d "$WEB_PATH/errorPages" ]; then
    echo "🔧 Copy the errorPages to web path"
    cp -R utils/nginx/errorPages $WEB_PATH/errorPages
    chown -R www-data:www-data "$WEB_PATH/errorPages"
else
    echo "❌ errorPages already exists. Skipping"
fi

if [ ! -f "$NGINX_ERROR_PAGES" ]; then
    echo "🔧 Create the global errorPages"
    tee "$NGINX_ERROR_PAGES" > /dev/null <<EOF

# Global error handler
error_page 400 401 403 404 405 408 429 500 501 502 503 504 /error.php;

location = /error.php {
    fastcgi_pass unix:$PHP_FPM_SOCKET;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $WEB_PATH/errorPages/error.php;
    fastcgi_param QUERY_STRING error=\$status;
}
EOF
else
    echo "❌ errorPages nginx config already exists. Skipping"
fi

if [ ! -f "$NGINX_SSL_SETTINGS" ]; then
    echo "🔧 Creating the optimal SSL settings config file"
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
else
    echo "❌ SSL optimal settings config already exists. Skipping"
fi

echo "🔧 Creating Nginx config for $DOMAIN with root $WEB_ROOT..."
cat > "$CONF_FILE" <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    root $DEFAULT_WEB_ROOT;
    index index.php index.html;

    include $NGINX_ERROR_PAGES;

    location / {
        return 301 https://\$host\$request_uri;
    }

    location ~ /\.well-known/acme-challenge {
        allow all;
        root $DEFAULT_WEB_ROOT;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    root $DEFAULT_WEB_ROOT;
    index index.php index.html;

    ssl_certificate $SSL_CERTIFICATE;
    ssl_certificate_key $SSL_CERTIFICATE_KEY;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

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

if [ ! -d "$DEFAULT_WEB_ROOT" ]; then
    echo "📁 Creating web root directory at $DEFAULT_WEB_ROOT..."
    mkdir -p "$DEFAULT_WEB_ROOT"
    echo "<h1>$DOMAIN is set up correctly!</h1>" > "$DEFAULT_WEB_ROOT/index.php"
    chown -R www-data:www-data "$DEFAULT_WEB_ROOT"
    chmod -R 755 "$DEFAULT_WEB_ROOT"
else
    echo "❌ WEB Root folder "$DEFAULT_WEB_ROOT" already exists. Skipping"
fi

echo "🔍 Checking if $DOMAIN is reachable on HTTP port 80..."
if curl -s --connect-timeout 5 "http://$DOMAIN" > /dev/null; then
  if [ ! -f $SSL_CERTIFICATE ] && [ ! -f $SSL_CERTIFICATE_KEY ]; then
      echo "✅ Domain is reachable, attempting to obtain SSL certificate with Certbot..."
      systemctl stop nginx
      certbot certonly --standalone -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN" --redirect

      echo "✅ SSL certificate obtained and configured."
  fi
else
  echo "⚠️ Domain $DOMAIN is NOT reachable on port 80. Please check DNS and firewall settings."
  echo "⚠️ Run certbot manually after domain is reachable:"
  echo "  sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
fi

echo "🔄 Restarting Nginx..."
systemctl restart nginx

echo "✅ Setup complete for $DOMAIN"
