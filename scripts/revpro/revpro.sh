#!/bin/bash

CONFIG_FILE="/revpro/site-configs.yaml"
CONF_DIR="/revpro/conf"
CERT_DIR="/revpro/certs"
LOG_DIR="/revpro/logs"

# Function to generate Nginx configuration file with header
generate_nginx_conf() {
    local domain=$1
    local container=$2
    local certificate=$3
    local conf_file="$CONF_DIR/$domain.conf"
    
    mkdir -p "$(dirname "$conf_file")"

    cat > "$conf_file" <<EOF
############
# $domain
# autogenerated using cmnds revpro
############

server {
    listen 80;
    server_name $domain;

    # Redirect HTTP to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $domain;

    access_log $LOG_DIR/${domain}_access.log;
    error_log $LOG_DIR/${domain}_error.log;

    # SSL settings
    ssl_certificate /cert/live/$certificate/fullchain.pem;
    ssl_certificate_key /cert/live/$certificate/privkey.pem;
    include /etc/nginx/ssl-ciphers.conf;
    include /etc/nginx/letsencrypt-acme-challenge.conf;

    location / {
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        proxy_http_version 1.1;
        proxy_pass http://$container;
    }
}
EOF

    echo "Configuration for $domain written to $conf_file"
}

# Function to clean up old Nginx configurations
cleanup_old_configs() {
    local valid_domains=$(yq e '.sites[].domain' "$CONFIG_FILE")

    # Loop through existing configuration files
    find "$CONF_DIR" -type f -name "*.conf" | while read -r conf_file; do
        domain=$(basename "$conf_file" .conf)
        if ! echo "$valid_domains" | grep -q "^$domain$"; then
            echo "Removing old configuration for $domain"
            rm "$conf_file"
        fi
    done
}

# Function to add a site configuration directly from command-line arguments
add_site_config() {
    local domain=$1
    local container=$2
    local certificate=$3

    # Create configuration file directly
    generate_nginx_conf "$domain" "$container" "$certificate"

    # Reload Nginx to apply changes
    reload_nginx
}

# Function to reload Nginx inside the Docker container
reload_nginx() {
    echo "Reloading Nginx..."
    docker compose exec -T reverseproxy nginx -s reload
    echo "Nginx reloaded."
}

# Main script logic
case "$1" in
    generate)
        # Generate configurations from YAML file
        yq e '.sites[] | [.domain, .container, .certificate] | @tsv' "$CONFIG_FILE" | while IFS=$'\t' read -r domain container certificate; do
            generate_nginx_conf "$domain" "$container" "$certificate"
        done
        ;;
    reload)
        # Clean up old configurations
        cleanup_old_configs
        
        # Generate configurations from YAML file
        yq e '.sites[] | [.domain, .container, .certificate] | @tsv' "$CONFIG_FILE" | while IFS=$'\t' read -r domain container certificate; do
            generate_nginx_conf "$domain" "$container" "$certificate"
        done

        # Reload Nginx to apply changes
        reload_nginx
        ;;
    add)
        # Add new site configuration from command-line arguments
        if [ "$#" -ne 4 ]; then
            echo "Usage: $0 add domain/container:PORT reversed.domain.tld -c domain.tld"
            exit 1
        fi
        
        domain_container=$2
        domain=${domain_container%%/*}
        container=${domain_container#*/}
        certificate=$4

        add_site_config "$domain" "$container" "$certificate"
        ;;
    *)
        echo "Usage: $0 {generate|reload|add}"
        exit 1
        ;;
esac
