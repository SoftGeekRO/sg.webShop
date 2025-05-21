#!/bin/bash

set -e

# Auto-tune Nginx and PHP-FPM based on system specs

CPU_CORES=$(nproc)
TOTAL_MEM_MB=$(free -m | awk '/^Mem:/ { print $2 }')

NGINX_CONF="/etc/nginx/nginx.conf"
PHP_FPM_CONF="/etc/php/8.3/fpm/php-fpm.conf"
POOL_CONF="/etc/php/8.3/fpm/pool.d/www.conf"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

update_nginx_conf() {
  echo "🔧 Tuning Nginx..."

  # Backup
  cp "$NGINX_CONF" "$NGINX_CONF.bak"

  # Set worker_processes and events block
  sed -i "s/^\s*worker_processes.*/worker_processes $CPU_CORES;/" "$NGINX_CONF"

  # Add or update worker_rlimit_nofile
  if grep -q "worker_rlimit_nofile" "$NGINX_CONF"; then
    sed -i "s/^\s*worker_rlimit_nofile.*/worker_rlimit_nofile 65535;/" "$NGINX_CONF"
  else
    sed -i "/^worker_processes/a worker_rlimit_nofile 65535;" "$NGINX_CONF"
  fi

  # Tune events block
  if grep -q "events {" "$NGINX_CONF"; then
    sed -i "/events {/,/}/ s/^\s*worker_connections.*/    worker_connections 4096;/" "$NGINX_CONF"
  fi

  # Ensure server_tokens off; is set inside http block
  if grep -q "http {" "$NGINX_CONF"; then
    if grep -Eq "^\s*#?\s*server_tokens\s+" "$NGINX_CONF"; then
      # Uncomment and set to off
      sed -i "s/^\s*#\?\s*server_tokens\s\+\S\+;/ \tserver_tokens off;/" "$NGINX_CONF"
    fi
  else
    echo "⚠️ Could not find http block in $NGINX_CONF"
  fi
}


setup_gzip_conf() {
  echo "🔧 Setting up gzip config in separate file..."

  GZIP_CONF_FILE="/etc/nginx/conf.d/gzip.conf"

  # Remove any old gzip directives from nginx.conf to avoid conflicts
  sed -i '/^\s*#\?\s*gzip[_a-z]*\b.*/Id' "$NGINX_CONF"

  # Just inform about skipping include since it's already present
  echo "ℹ️ Assuming nginx.conf already includes /etc/nginx/conf.d/*.conf, skipping include directive"

  # Create gzip.conf only if it doesn't exist
  if [ ! -f "$GZIP_CONF_FILE" ]; then
    cat <<'EOF' > "$GZIP_CONF_FILE"
gzip on;
gzip_disable "msie6";
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types
    text/plain
    text/css
    application/json
    application/javascript
    text/xml
    application/xml
    application/xml+rss
    text/javascript;
EOF
    echo "✅ Created $GZIP_CONF_FILE"
  else
    echo "ℹ️  $GZIP_CONF_FILE already exists, skipped creation"
  fi
}

update_php_fpm_conf() {
  echo "🔧 Tuning PHP-FPM..."

  cp "$PHP_FPM_CONF" "$PHP_FPM_CONF.bak"

  # pm.max_children = Total RAM / 30MB (rough estimate)
  MAX_CHILDREN=$((TOTAL_MEM_MB / 30))

  sed -i "s/^\s*pm.max_children.*/pm.max_children = $MAX_CHILDREN/" "$POOL_CONF" || echo "pm.max_children = $MAX_CHILDREN" >> "$POOL_CONF"
  sed -i "s/^\s*pm.start_servers.*/pm.start_servers = 4/" "$POOL_CONF" || echo "pm.start_servers = 4" >> "$POOL_CONF"
  sed -i "s/^\s*pm.min_spare_servers.*/pm.min_spare_servers = 2/" "$POOL_CONF" || echo "pm.min_spare_servers = 2" >> "$POOL_CONF"
  sed -i "s/^\s*pm.max_spare_servers.*/pm.max_spare_servers = 6/" "$POOL_CONF" || echo "pm.max_spare_servers = 6" >> "$POOL_CONF"
}

update_nginx_conf
setup_gzip_conf
update_php_fpm_conf

echo "✅ Tuning complete. Restarting services..."
systemctl restart php8.3-fpm
systemctl restart nginx

echo "✅ Nginx and PHP-FPM tuning complete!"
echo "⚙️  Detected: ${CPU_CORES} CPU cores, ${TOTAL_MEM_MB}MB RAM"
echo "📁 PHP-FPM tuned config: $POOL_CONF"
echo "📁 Nginx config updated: $NGINX_CONF"
