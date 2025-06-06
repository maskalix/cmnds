#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
MANAGE_CONFIG="$SCRIPT_DIR/cmnds-config"
MAIN_FOLDER=$(bash "$MANAGE_CONFIG" read REVPRO)

CONFIG_FILE="$MAIN_FOLDER/site-configs.conf"
CONF_DIR="$MAIN_FOLDER/conf"
LOG_DIR="$MAIN_FOLDER/logs"
NGINX_CONF="/etc/nginx/nginx.conf"
AUTH_PROXY_CONF="/etc/nginx/includes/authentik-proxy.conf"
ERROR_PAGE=$(bash "$MANAGE_CONFIG" read ERROR_PAGE)
CERTS_SUB=$(bash "$MANAGE_CONFIG" read CERTS_SUB)

# Function to create log files
create_log_files() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_DIR/${1}_access.log" "$LOG_DIR/${1}_error.log"
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
      
    # Set forward_scheme based on presence of 's:' prefix
    if [[ "$container" == *s:* ]]; then
        forward_scheme="https"
    else
        forward_scheme="http"
    fi
    
    # Now, clean prefixes like a:, s:, w: ONLY before server part
    # Remove all a:, s:, w: prefixes from the beginning until reaching server:port
    cleaned_container="$container"
    while [[ "$cleaned_container" =~ ^[asw]: ]]; do
        cleaned_container="${cleaned_container:2}"
    done
    
    # Extract server and port properly
    server="${cleaned_container%:*}" # server = everything before last :
    port="${cleaned_container##*:}"  # port = everything after last :

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
    http2 on;
    listen [::]:443 ssl;
    server_name $domain;

    access_log $LOG_DIR/${domain}_access.log;
    error_log $LOG_DIR/${domain}_error.log;

    # SSL configuration
    ssl_certificate $CERTS_SUB/$certificate/$certificate.crt;
    ssl_certificate_key $CERTS_SUB/$certificate/$certificate.key;
    ssl_trusted_certificate $CERTS_SUB/$certificate/$certificate.issuer.crt;

    # Configuration files
    include /etc/nginx/includes/letsencrypt.conf;
    include /etc/nginx/includes/general.conf;
    include /etc/nginx/includes/security.conf;
            
    # Proxy variables
    set \$forward_scheme $forward_scheme;
    set \$server $server;
    set \$port $port;
    set \$upstream \$forward_scheme://\$server:\$port;
    
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
        proxy_pass \$upstream;
        include /etc/nginx/includes/proxy.conf;
EOF
        # Include local-only access control if the [L] flag is set
        if [[ "$local_only" == "true" ]]; then
            cat >> "$conf_file" <<EOF
        # Access control rules
        include /etc/nginx/includes/local.conf;
EOF
        fi

        # Closing location block and including error handling
        cat >> "$conf_file" <<EOF
        # Error handling
        include /etc/nginx/includes/error.conf;
    }
}
EOF
    fi

    # Create log files for the domain
    create_log_files "$domain"
    echo "🕸️  $domain"
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
    echo "🔃 Reloading Nginx..."

    # Check the Nginx configuration syntax before reloading
    docker exec -t reverseproxy nginx -t
    if [ $? -ne 0 ]; then
        echo "⚠️ Nginx configuration test failed, please check the errors above."
        return 1
    fi

    # Reload Nginx, specifying the config file explicitly if necessary
    docker exec -t reverseproxy nginx -s reload || echo "⚠️ Failed to reload Nginx, please check the container status and logs."
    echo "✅ Nginx reloaded."
}

# Function to restart Nginx inside the Docker container
restart_nginx() {
    docker container restart reverseproxy
    echo "✅ Nginx restarted."
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
        echo "Generating configs for domains:"
        echo "-----------------------"
        while IFS=$'\t ' read -r domain container certificate; do
            # Skip lines starting with #
            [[ "$domain" =~ ^#.*$ ]] && continue
            generate_nginx_conf "$domain" "$container" "$certificate"
        done < "$CONFIG_FILE"
        echo "-----------------------"
        echo "✅ Configs generated"
        ;;
    reload)
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
    regenerate)
        clean_directories
        # Generate configurations from the configuration file
        echo "Generating configs for domains:"
        echo "-----------------------"
        while IFS=$'\t ' read -r domain container certificate; do
            # Skip lines starting with #
            [[ "$domain" =~ ^#.*$ ]] && continue
            generate_nginx_conf "$domain" "$container" "$certificate"
        done < "$CONFIG_FILE"
        echo "-----------------------"
        echo "✅ Configs generated"
        reload_nginx
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
        echo "Usage: $0 {generate|clean|reload|restart|regenerate|add|edit|list}"
        exit 1
        ;;
esac
