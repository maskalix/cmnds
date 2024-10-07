#!/bin/bash

# Default values
DAYS=365
CA_FLAG=0
DOMAIN_LIST=()
YEARS=0

# Function to display help message
usage() {
    echo "Usage: $0 [-d domain.tld] [-d *.domain.tld] [--CA] [--days N] [--years Y]"
    echo "  -d domain     : specify domain names for certificate (multiple domains allowed)"
    echo "  --CA          : generate a CA certificate"
    echo "  --days N      : number of days the certificate will be valid (default: 365)"
    echo "  --years Y     : number of years the certificate will be valid (overrides --days)"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d) DOMAIN_LIST+=("$2"); shift ;;
        --CA) CA_FLAG=1 ;;
        --days) DAYS="$2"; shift ;;
        --years) YEARS="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Check if at least one domain is provided
if [ "${#DOMAIN_LIST[@]}" -eq 0 ]; then
    echo "Error: At least one domain (-d) must be specified."
    usage
fi

# Calculate days if years is provided
if [ "$YEARS" -gt 0 ]; then
    DAYS=$((YEARS * 365))
fi

# Set the first domain as the main domain for filenames
MAIN_DOMAIN="${DOMAIN_LIST[0]}"
CERT_DIR="/etc/letsencrypt/live/$MAIN_DOMAIN"
KEY_FILE="$CERT_DIR/privkey.pem"
CERT_FILE="$CERT_DIR/fullchain.pem"
CONFIG_FILE="$CERT_DIR/openssl.cnf"

# Create directories if they don't exist
mkdir -p "$CERT_DIR"

# Generate Elliptic Curve key
echo "Generating EC key..."
openssl ecparam -genkey -name prime256v1 -out "$KEY_FILE"

# Create OpenSSL config file for SAN (Subject Alternative Name)
echo "Creating OpenSSL configuration..."
cat > "$CONFIG_FILE" <<EOL
[ req ]
distinguished_name = req_distinguished_name
req_extensions     = req_ext
prompt             = no

[ req_distinguished_name ]
CN = $MAIN_DOMAIN

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
EOL

# Add domains to the SAN section
i=1
for domain in "${DOMAIN_LIST[@]}"; do
    echo "DNS.$i = $domain" >> "$CONFIG_FILE"
    i=$((i+1))
done

# Add v3_ca extension if --CA is specified
if [ "$CA_FLAG" -eq 1 ]; then
    cat >> "$CONFIG_FILE" <<EOL

[ v3_ca ]
basicConstraints = critical,CA:TRUE
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOL
else
    # For server certificates (non-CA), we need the correct key usage and extended key usage
    cat >> "$CONFIG_FILE" <<EOL

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
EOL
fi

# Generate the certificate request and sign the certificate
if [ "$CA_FLAG" -eq 1 ]; then
    echo "Generating a CA certificate..."
    openssl req -x509 -new -key "$KEY_FILE" -days "$DAYS" -out "$CERT_FILE" -config "$CONFIG_FILE" -extensions v3_ca
else
    echo "Generating self-signed certificate..."
    openssl req -new -key "$KEY_FILE" -out "$CERT_DIR/ec.csr" -config "$CONFIG_FILE"
    openssl x509 -req -in "$CERT_DIR/ec.csr" -signkey "$KEY_FILE" -days "$DAYS" -out "$CERT_FILE" -extfile "$CONFIG_FILE" -extensions v3_req
    rm "$CERT_DIR/ec.csr"
fi

echo "Certificate generated and saved in $CERT_DIR."
