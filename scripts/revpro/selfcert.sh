#!/bin/bash

# Usage: ./selfcert.sh -d domain.tld -d *.domain.tld --CA --years Y
# Description: This script generates a CA certificate and uses it to sign
#              HTTPS certificates for specified domains.

# Default values
CA_DIR="/revpro/ca"
DAYS=365
GENERATE_CA=false
DOMAINS=()

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d) 
            shift
            DOMAINS+=("$1")
            ;;
        --CA) 
            GENERATE_CA=true
            ;;
        --years) 
            shift
            DAYS=$((365 * "$1"))
            ;;
        *) 
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
    shift
done

# Check if at least one domain is provided
if [ ${#DOMAINS[@]} -eq 0 ]; then
    echo "Error: At least one domain must be specified with -d"
    exit 1
fi

# Create the CA directory if it does not exist
mkdir -p "$CA_DIR"

# Step 1: Generate CA Certificate if requested
if [ "$GENERATE_CA" = true ]; then
    echo "Generating CA key..."
    openssl ecparam -name prime256v1 -genkey -noout -out "$CA_DIR/ca.key"

    echo "Creating CA certificate..."
    openssl req -x509 -new -nodes -key "$CA_DIR/ca.key" -sha256 -days $DAYS \
        -subj "/C=CZ/ST=Czech Republic/L=Pilsen/O=$HOSTNAME" \
        -out "$CA_DIR/ca.pem" \
        -extensions v3_ca -config <(cat /etc/ssl/openssl.cnf <(printf "[v3_ca]\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth"))

    echo "CA certificate generated at $CA_DIR/ca.pem"
fi

# Step 2: Generate Domain Certificate
echo "Generating EC key for domain certificates..."
mkdir -p /etc/letsencrypt/live/${DOMAINS[0]}
openssl ecparam -name prime256v1 -genkey -noout -out "/etc/letsencrypt/live/${DOMAINS[0]}/privkey.pem"

echo "Creating certificate signing request (CSR)..."
openssl req -new -key "/etc/letsencrypt/live/${DOMAINS[0]}/privkey.pem" -out "/etc/letsencrypt/live/${DOMAINS[0]}/domain.csr" \
    -subj "/C=CZ/ST=Czech Republic/L=Pilsen/O=$HOSTNAME" \
    -extensions req_ext -config <(cat /etc/ssl/openssl.cnf <(printf "[req_ext]\nsubjectAltName=DNS:%s\n" "${DOMAINS[*]}"))

echo "Signing domain certificate with CA..."
openssl x509 -req -in "/etc/letsencrypt/live/${DOMAINS[0]}/domain.csr" -CA "$CA_DIR/ca.pem" -CAkey "$CA_DIR/ca.key" -CAcreateserial \
    -out "/etc/letsencrypt/live/${DOMAINS[0]}/fullchain.pem" -days $DAYS -sha256 \
    -extfile <(printf "keyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\nsubjectAltName=DNS:%s\n" "${DOMAINS[*]}")

echo "Domain certificate generated and saved at /etc/letsencrypt/live/${DOMAINS[0]}/fullchain.pem"
echo "Private key saved at /etc/letsencrypt/live/${DOMAINS[0]}/privkey.pem"
