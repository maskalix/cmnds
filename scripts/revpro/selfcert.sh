#!/bin/bash

# Check for the required arguments
if [[ $# -lt 5 ]]; then
    echo "Usage: $0 -d <domain.tld> -d <*.domain.tld> --years <validity_years> --country <country_code> --state <state> --organization <organization_name>"
    exit 1
fi

# Initialize variables
DOMAIN=""
WILDCARD_DOMAIN=""
YEARS=""
COUNTRY=""
STATE=""
ORGANIZATION=""
DOMAINS=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d)
            # Capture multiple domains
            if [[ -n "$2" ]]; then
                DOMAINS+=("$2")
                shift
            fi
            shift
            ;;
        --years)
            YEARS="$2"
            shift 2
            ;;
        --country)
            COUNTRY="$2"
            shift 2
            ;;
        --state)
            STATE="$2"
            shift 2
            ;;
        --organization)
            ORGANIZATION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check that at least one domain has been specified
if [[ ${#DOMAINS[@]} -eq 0 ]]; then
    echo "Error: No domains specified."
    exit 1
fi

# Set Variables
LE_DIR="/etc/letsencrypt/live/${DOMAINS[0]}"
ROOT_CA_KEY="/etc/letsencrypt/rootCA.key"
ROOT_CA_CRT="/etc/letsencrypt/rootCA.crt"
DAYS_ROOT=1024
DAYS_SERVER=$((YEARS * 365))

# Create directories if they do not exist
mkdir -p "$LE_DIR"
mkdir -p "/etc/letsencrypt"

# Step 1: Create Root Key
if [[ ! -f "$ROOT_CA_KEY" ]]; then
    echo "Creating Root Key..."
    openssl genrsa -des3 -out "$ROOT_CA_KEY" 4096
fi

# Step 2: Create and Self-Sign the Root Certificate
if [[ ! -f "$ROOT_CA_CRT" ]]; then
    echo "Creating and Self-Signing Root Certificate..."
    openssl req -x509 -new -nodes -key "$ROOT_CA_KEY" -sha256 -days "$DAYS_ROOT" -out "$ROOT_CA_CRT" \
        -subj "/C=$COUNTRY/ST=$STATE/O=$ORGANIZATION/CN=Root CA"
fi

# Function to create combined server certificate
create_combined_cert() {
    local KEY="$LE_DIR/privkey.pem"
    local CSR="$LE_DIR/certificate.csr"
    local CRT="$LE_DIR/fullchain.pem"
    
    # Step 3: Create the Certificate Key
    echo "Creating Certificate Key for ${DOMAINS[*]}..."
    openssl genrsa -out "$KEY" 2048

    # Step 4: Create the Signing Request (CSR) with SAN
    echo "Creating Signing Request (CSR) for ${DOMAINS[*]}..."
    
    # Prepare SAN string
    SAN_STRING="subjectAltName="
    for domain in "${DOMAINS[@]}"; do
        SAN_STRING+="DNS:$domain,"
    done
    # Remove the last comma
    SAN_STRING="${SAN_STRING%,}"

    # Create the CSR
    openssl req -new -key "$KEY" -subj "/C=$COUNTRY/ST=$STATE/O=$ORGANIZATION/CN=${DOMAINS[0]}" \
        -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\n$SAN_STRING")) -out "$CSR"

    # Step 5: Verify the CSR's Content
    echo "Verifying CSR content for ${DOMAINS[*]}..."
    openssl req -in "$CSR" -noout -text

    # Step 6: Generate the Certificate using the CSR and Root CA
    echo "Generating Certificate for ${DOMAINS[*]}..."
    openssl x509 -req -in "$CSR" -CA "$ROOT_CA_CRT" -CAkey "$ROOT_CA_KEY" -CAcreateserial -out "$CRT" -days "$DAYS_SERVER" -sha256

    # Step 7: Verify the Certificate's Content
    echo "Verifying Certificate content for ${DOMAINS[*]}..."
    openssl x509 -in "$CRT" -text -noout

    echo "Combined Certificate for ${DOMAINS[*]} created successfully!"
}

# Create a combined certificate for the specified domains
create_combined_cert

echo "All tasks completed."
