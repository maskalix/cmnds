#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
MANAGE_CONFIG="$SCRIPT_DIR/cmnds-config"
MAIN_FOLDER=$(bash "$MANAGE_CONFIG" read REVPRO)

CONFIG_FILE="$MAIN_FOLDER/site-configs.conf"
CONF_DIR="$MAIN_FOLDER/conf"
LOG_DIR="$MAIN_FOLDER/logs"
NGINX_CONF="/etc/nginx/nginx.conf"
AUTH_PROXY_CONF="/etc/nginx/authentik-proxy.conf"

# Function to create log files
create_log_files() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi

    if [ -f "$LOG_DIR/${1}_access.log" ]; then
        access_log_status="✅"
    else
        touch "$LOG_DIR/${1}_access.log"
        access_log_status="❌"
    fi

    if [ -f "$LOG_DIR/${1}_error.log" ]; then
        error_log_status="✅"
    else
        touch "$LOG_DIR/${1}_error.log"
        error_log_status="❌"
    fi
}

# Function to generate Nginx configuration file with header
generate_nginx_conf() {
    local domain=$1
    local container=$2
    local certificate=$3
    local conf_file="$CONF_DIR/$domain.conf"
    local local_only="false"

    # Check if the domain starts with [L]
    if [[ "$domain" == "[L]"* ]]; then
        local_only="true"
        domain="${domain:3}" # Remove the [L] prefix from the domain
    fi

    mkdir -p "$(dirname "$conf_file")"

    # Define proxy variables
    if [[ "$container" == s:* && "$container" != *:a:* ]]; then
        forward_scheme="https"
        server="${container#s:}"
        port="${server##*:}"
        server="${server%%:*}"
    elif [[ "$container" == a:* && "$container" != *:s:* ]]; then
        forward_scheme="http"
        server="${container#a:}"
        port="${server##*:}"
        server="${server%%:*}"
    elif [[ "$container" == *:a:* || "$container" == a:s:* || "$container" == s:a:* ]]; then
        forward_scheme="https"
        server="${container#*:}"
        port="${server##*:}"
        server="${server%%:*}"
    else
        forward_scheme="http"
        server="${container%%:*}"
        port="${container##*:}"
    fi

    # Create configuration file
    cat > "$conf_file" <<EOF
############
# $domain
# autogenerated using >> cmnds revpro
# DON'T EDIT DIRECTLY, revpro OVERWRITES THIS FILE!!!
# github.com/maskalix/cmnds
############

# server listen 80 should be located inside nginx.conf as redirect for all domains... use HTTPS ;)
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

    # Define proxy variables
    set \$forward_scheme $forward_scheme;
    set \$server $server;
    set \$port $port;
EOF

    # Include authentik proxy if required
    if [[ "$container" == a:* || "$container" == a:s:* || "$container" == s:a:* ]]; then
        cat >> "$conf_file" <<EOF
    include $AUTH_PROXY_CONF;
}
EOF
    else
        # Default location block
        cat >> "$conf_file" <<EOF
    location / {
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        proxy_http_version 1.1;
        proxy_pass $forward_scheme://$server:$port;
EOF

        # Include local-only access control if the [L] flag is set
        if [[ "$local_only" == "true" ]]; then
            cat >> "$conf_file" <<EOF
        # Include access control rules from external file
        include /etc/nginx/local;
EOF
        fi

        # Closing location block and including error handling
        cat >> "$conf_file" <<EOF
        # Include error handling
        include /etc/nginx/includes/error_pages.conf;
    }
}
EOF
    fi

    # Create log files for the domain
    create_log_files "$domain"

    if [ -f "$conf_file" ]; then
        conf_status="✅"
    else
        conf_status="❌"
    fi

    echo "| $access_log_status | $error_log_status | $conf_status | $domain"
}

# Function to clean up old Nginx configurations and logs
clean_directories() {
    echo "Cleaning up configuration and log directories..."
    rm -rf "$CONF_DIR"/* "$LOG_DIR"/*
    mkdir -p "$CONF_DIR" "$LOG_DIR"
    echo "Configuration and log directories cleaned and recreated."
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
    echo "$domain    $container    $certificate" >> $CONFIG_FILE
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

# Function to restart Nginx inside the Docker container
restart_nginx() {
    docker container restart reverseproxy
    echo "Nginx restarted."
}

# Function to list all domains from the configuration file
list_domains() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file not found at $CONFIG_FILE"
        exit 1
    fi

    echo "Listing all domains from $CONFIG_FILE (ignoring comments):"
    awk '!/^#/ {print $1}' "$CONFIG_FILE"
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
        echo "| AC | ER | CF | Domain"
        echo "-----------------------"
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
        echo "Domain | Conf | Acc-log | Err-log"
        while IFS=$'\t ' read -r domain container certificate; do
            # Skip lines starting with #
            [[ "$domain" =~ ^#.*$ ]] && continue
            generate_nginx_conf "$domain" "$container" "$certificate"
        done < "$CONFIG_FILE"

        # Reload Nginx to apply changes
        reload_nginx
        ;;
    clean)
        # Clean the configuration and log directories
        clean_directories
        ;;
    restart)
        restart_nginx
        ;;
    add)
        # Add new site configuration from command-line arguments
        if [[ "$#" -ne 4 ]]; then
            echo "Usage: $0 add <domain> <container> <certificate>"
            exit 1
        fi
        add_site_config "$2" "$3" "$4"
        ;;
    edit)
        # Open config file for editing
        edit_config
        ;;
    list)
        # List all domains from the configuration file
        list_domains
        ;;
    *)
        echo "Usage: $0 {generate|clean|reload|restart|add|edit|list}"
        exit 1
        ;;
esac
