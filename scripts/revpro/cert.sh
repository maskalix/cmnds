#!/bin/bash

# Color codes
RESET="\e[0m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
CYAN="\e[36m"

# Usage message function
usage() {
    echo -e "${YELLOW}Usage: $0 -d domain.tld [-e|-i|-s|-a|-v|-g]${RESET}"
    echo -e "${CYAN}    -d domain     : Specify the domain (required)${RESET}"
    echo -e "${CYAN}    -e            : Show certificate expiry date${RESET}"
    echo -e "${CYAN}    -i            : Show certificate issuer information${RESET}"
    echo -e "${CYAN}    -s            : Show certificate subject information${RESET}"
    echo -e "${CYAN}    -a            : Show all certificate details${RESET}"
    echo -e "${CYAN}    -v            : Verify the certificate chain integrity${RESET}"
    echo -e "${CYAN}    -g            : Check if the site is reachable over SSL (no ERR_SSL_* errors)${RESET}"
    exit 1
}

# Function to check if the domain is reachable over SSL
check_connection() {
    # Capture the output of the openssl command
    output=$(echo | openssl s_client -connect "$1:443" -servername "$1" -timeout 5 2>&1)
    # Check if the connection was successful
    echo "$output" | grep -q "CONNECTED"
    return $?
}

# Function to check SSL connection without ERR_SSL_* errors
check_ssl_no_error() {
    # Capture the output from the connection check
    output=$(check_connection "$1")
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Success: SSL connection to $1 is established without ERR_SSL_* errors.${RESET}"
    else
        echo -e "${RED}❌ Error: Could not establish an SSL connection to $1.${RESET}"
        echo -e "${CYAN}Details:${RESET}"
        echo "$output"
        exit 1
    fi
}

# Function to get the certificate details
get_cert_info() {
    openssl s_client -connect "$1:443" -servername "$1" 2>/dev/null | openssl x509 -noout "$2"
}

# Function to verify certificate chain
verify_cert() {
    echo | openssl s_client -connect "$1:443" -servername "$1" 2>/dev/null | openssl x509 > /tmp/cert.pem
    openssl verify /tmp/cert.pem
    rm /tmp/cert.pem
}

# Check if no arguments provided
if [ $# -eq 0 ]; then
    usage
fi

# Default values
domain=""
show_expiry=false
show_issuer=false
show_subject=false
show_all=false
verify_cert_flag=false
ssl_check_flag=false

# Parse command line arguments
while getopts "d:eisavg" opt; do
    case "$opt" in
        d) domain="$OPTARG" ;;
        e) show_expiry=true ;;
        i) show_issuer=true ;;
        s) show_subject=true ;;
        a) show_all=true ;;
        v) verify_cert_flag=true ;;
        g) ssl_check_flag=true ;;
        *) usage ;;
    esac
done

# Check if domain is provided
if [ -z "$domain" ]; then
    usage
fi

# Check if the SSL connection is successful only if -g is set
if [ "$ssl_check_flag" = true ]; then
    check_ssl_no_error "$domain"
    echo ""
else
    # If -g is not set, just attempt to retrieve the certificate info without checking the connection
    echo -e "${BLUE}🔍 Fetching SSL certificate information for $domain...${RESET}"

    # Show certificate expiry (-e)
    if [ "$show_expiry" = true ]; then
        echo -e "${BLUE}🔍 Certificate expiry date for $domain:${RESET}"
        get_cert_info "$domain" "-dates"
        echo ""
    fi

    # Show certificate issuer (-i)
    if [ "$show_issuer" = true ]; then
        echo -e "${BLUE}🔍 Certificate issuer for $domain:${RESET}"
        get_cert_info "$domain" "-issuer"
        echo ""
    fi

    # Show certificate subject (-s)
    if [ "$show_subject" = true ]; then
        echo -e "${BLUE}🔍 Certificate subject for $domain:${RESET}"
        get_cert_info "$domain" "-subject"
        echo ""
    fi

    # Show all certificate details (-a)
    if [ "$show_all" = true ]; then
        echo -e "${BLUE}🔍 Full certificate details for $domain:${RESET}"
        get_cert_info "$domain" "-text"
        echo ""
    fi

    # Verify certificate chain (-v)
    if [ "$verify_cert_flag" = true ]; then
        echo -e "${BLUE}🔍 Verifying certificate chain for $domain:${RESET}"
        verify_cert "$domain"
        echo ""
    fi
fi
