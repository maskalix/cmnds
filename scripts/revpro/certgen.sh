#!/bin/bash
# version as of 2307
MAIN_FOLDER=$(bash cmnds-config read CERTS)
SUB_FOLDER=$(bash cmnds-config read CERTS_SUB)

# Check for the required arguments
if [[ $# -lt 5 ]]; then
    echo "Usage: $0 -d <domain.tld> -d <*.domain.tld> --years <validity_years> --country <country_code> --state <state> --organization <organization_name> [--alt <alt_domain> ...]"
    exit 1
fi

# Initialize variables
DOMAIN=""
WILDCARD_DOMAIN=""
YEARS=""
COUNTRY=""
STATE=""
ORGANIZATION=""
ALT_DOMAINS=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d)
            if [[ -z "$DOMAIN" ]]; then
                DOMAIN="$2"
            else
                WILDCARD_DOMAIN="$2"
            fi
            shift 2
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
        --alt)
            ALT_DOMAINS+=("$2")
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set Variables
LE_DIR="$SUB_FOLDER/$DOMAIN"
ROOT_CA_KEY="$MAIN_FOLDER/rootCA.key"
ROOT_CA_CRT="$MAIN_FOLDER/rootCA.crt"
DAYS_ROOT=1024
DAYS_SERVER=$((YEARS * 365))

# Create directories if they do not exist
mkdir -p "$LE_DIR"
mkdir -p "$MAIN_FOLDER"

# Step 1: Create Root Key
if [[ ! -f "$ROOT_CA_KEY" ]]; then
    echo "Creating Root Key..."
    openssl genrsa -aes256 -out "$ROOT_CA_KEY" 4096
fi

# Step 2: Create and Self-Sign the Root Certificate
if [[ ! -f "$ROOT_CA_CRT" ]]; then
    echo "Creating and Self-Signing Root Certificate..."
    openssl req -x509 -new -nodes -key "$ROOT_CA_KEY" -sha256 -days "$DAYS_ROOT" -out "$ROOT_CA_CRT" \
        -subj "/C=$COUNTRY/ST=$STATE/O=$ORGANIZATION/CN=revpro CA"
fi

# Function to create combined server certificate
create_combined_cert() {
    local DOMAIN="$1"
    local WILDCARD="$2"
    local KEY="$LE_DIR/privkey.pem"
    local CSR="$LE_DIR/certificate.csr"
    local CRT="$LE_DIR/fullchain.pem"

    # Step 3: Create the Certificate Key
    echo "Creating Certificate Key for $DOMAIN..."
    openssl genrsa -out "$KEY" 4096

    # Step 4: Create the Signing Request (CSR) with SAN
    echo "Creating Signing Request (CSR) for $DOMAIN and $WILDCARD..."
    
    # Prepare SAN entries
    SAN_ENTRIES=("$DOMAIN" "$WILDCARD")
    for alt in "${ALT_DOMAINS[@]}"; do
        SAN_ENTRIES+=("$alt")
    done

    # Create a custom configuration for the CSR
    CONFIG_FILE="$LE_DIR/csr_config.cnf"
    {
        echo "[req]"
        echo "default_bits       = 4096"
        echo "distinguished_name = req_distinguished_name"
        echo "req_extensions     = req_ext"
        echo "prompt             = no"
        echo "[req_distinguished_name]"
        echo "C = $COUNTRY"
        echo "ST = $STATE"
        echo "O = $ORGANIZATION"
        echo "CN = $DOMAIN"
        echo "[req_ext]"
        echo "subjectAltName = @alt_names"
        echo "[alt_names]"
        for i in "${!SAN_ENTRIES[@]}"; do
            echo "DNS.$((i + 1)) = ${SAN_ENTRIES[$i]}"
        done
    } > "$CONFIG_FILE"
    openssl req -new -key "$KEY" -out "$CSR" -sha256 -config "$CONFIG_FILE"

    # Step 5: Verify the CSR's Content
    echo "Verifying CSR content for $DOMAIN..."
    openssl req -in "$CSR" -noout -text

    # Step 6: Generate the Certificate using the CSR and Root CA
    echo "Generating Certificate for $DOMAIN..."
    openssl x509 -req -in "$CSR" -CA "$ROOT_CA_CRT" -CAkey "$ROOT_CA_KEY" -CAcreateserial -out "$CRT" -days "$DAYS_SERVER" -sha256 -extfile "$CONFIG_FILE" -extensions req_ext

    # Step 7: Verify the Certificate's Content
    echo "Verifying Certificate content for $DOMAIN..."
    openssl x509 -in "$CRT" -text -noout

    echo "Combined Certificate for $DOMAIN and $WILDCARD created successfully!"
}

# Create a combined certificate for the specified domains
create_combined_cert "$DOMAIN" "$WILDCARD_DOMAIN"

echo "All tasks completed."
