#!/bin/bash

CONFIG_FILE="/revpro/site-configs.conf"
CONF_DIR="/revpro/conf"
LOG_DIR="/revpro/logs"
NGINX_CONF="/etc/nginx/nginx.conf"

# Function to create log files
create_log_files() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi

    if [ -f "$LOG_DIR/${1}_access.log" ]; then
        echo "Access log file $LOG_DIR/${1}_access.log already exists."
    else
        touch "$LOG_DIR/${1}_access.log"
        echo "Created access log file $LOG_DIR/${1}_access.log"
    fi

    if [ -f "$LOG_DIR/${1}_error.log" ]; then
        echo "Error log file $LOG_DIR/${1}_error.log already exists."
    else
        touch "$LOG_DIR/${1}_error.log"
        echo "Created error log file $LOG_DIR/${1}_error.log"
    fi
}

# Function to generate Nginx configuration file with header
generate_nginx_conf() {
    local domain=$1
    local container=$2
    local certificate=$3
    local conf_file="$CONF_DIR/$domain.conf"

    mkdir -p "$(dirname "$conf_file")"

    # Determine if the container is using https or http
    if [[ "$container" == https://* ]]; then
        proxy_scheme="https"
    else
        proxy_scheme="http"
    fi

    cat > "$conf_file" <<EOF
############
# $domain
# autogenerated using >> cmnds revpro
# DON'T EDIT DIRECTLY, revpro OVERWRITES THIS FILE!!!
# github.com/maskalix/cmnds
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
    listen 443 ssl;
    server_name $domain;

    access_log $LOG_DIR/${domain}_access.log;
    error_log $LOG_DIR/${domain}_error.log;

    # SSL settings
    ssl_certificate /etc/letsencrypt/live/$certificate/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$certificate/privkey.pem;

    # Include optional configuration files
    include /etc/nginx/ssl-ciphers.conf;
    include /etc/nginx/letsencrypt-acme-challenge.conf;

    location / {
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        proxy_http_version 1.1;
        proxy_pass $proxy_scheme://$container;
    }
}
EOF

    echo "Configuration for $domain written to $conf_file"

    # Create log files for the domain
    create_log_files "$domain"
}

# Function to clean up old Nginx configurations
cleanup_old_configs() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file not found at $CONFIG_FILE"
        return
    fi

    local valid_domains=$(awk '{print $1}' "$CONFIG_FILE")

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
    
    # Check the Nginx configuration syntax before reloading
    docker compose exec -T reverseproxy nginx -t
    if [ $? -ne 0 ]; then
        echo "Nginx configuration test failed, please check the errors above."
        return 1
    fi

    # Reload Nginx, specifying the config file explicitly if necessary
    docker compose exec -T reverseproxy nginx -c /etc/nginx/nginx.conf -s reload || echo "Failed to reload Nginx, please check the container status and logs."
}

restart_nginx() {
    docker container restart reverseproxy
    echo "Nginx restarted"
}

# Function to list all domains from the configuration file
list_domains() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file not found at $CONFIG_FILE"
        exit 1
    fi

    echo "Listing all domains from $CONFIG_FILE:"
    awk '{print $1}' "$CONFIG_FILE"
}

# Function to open the configuration file in a text editor
edit_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file not found at $CONFIG_FILE"
        exit 1
    fi

    nano "$CONFIG_FILE"
}

# Main script logic
case "$1" in
    generate)
        # Check if CONFIG_FILE exists before attempting to parse it
        if [ ! -f "$CONFIG_FILE" ]; then
            echo "Configuration file not found at $CONFIG_FILE"
            exit 1
        fi

        # Generate configurations from the configuration file
        while IFS=$'\t ' read -r domain container certificate; do
            # Skip lines starting with #
            [[ "$domain" =~ ^#.*$ ]] && continue
            generate_nginx_conf "$domain" "$container" "$certificate"
        done < "$CONFIG_FILE"
        ;;
    reload)
        # Clean up old configurations
        cleanup_old_configs
        
        # Check if CONFIG_FILE exists before attempting to parse it
        if [ ! -f "$CONFIG_FILE" ]; then
            echo "Configuration file not found at $CONFIG_FILE"
            exit 1
        fi

        # Generate configurations from the configuration file
        while IFS=$'\t ' read -r domain container certificate; do
            # Skip lines starting with #
            [[ "$domain" =~ ^#.*$ ]] && continue
            generate_nginx_conf "$domain" "$container" "$certificate"
        done < "$CONFIG_FILE"

        # Reload Nginx to apply changes
        reload_nginx
        ;;
    add)
        # Add new site configuration from command-line arguments
        if [[ "$#" -ne 4 ]]; then
            echo "Usage: $0 add address:port domain.tld certdomain.tld"
            exit 1
        fi
        
        address=$2
        domain=$3
        certificate=$4

        add_site_config "$domain" "$address" "$certificate"
        ;;
    list)
        # List all domains from the configuration file
        list_domains
        ;;
    edit)
        # Open the configuration file in nano
        edit_config
        ;;
    restart)
        restart_nginx
        ;;
    *)
        echo "Usage: $0 {generate|reload|add|list|edit|restart}"
        exit 1
        ;;
esac
