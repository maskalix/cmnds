#!/bin/bash

# Check for the -d flag for directory input
while getopts "d:" opt; do
  case $opt in
    d) SAVE_DIR=$OPTARG ;;
    *) echo "Usage: $0 [-d save_directory] domain.tld1,domain.tld2,..."
       exit 1
       ;;
  esac
done

# Shift past the flags
shift $((OPTIND - 1))

# Prompt for directory if not provided by -d flag
if [ -z "$SAVE_DIR" ]; then
  read -p "Enter directory to save certificates: " SAVE_DIR
fi

# Create save directory if it doesn't exist
mkdir -p "$SAVE_DIR"

# Check if domains were provided
if [ -z "$1" ]; then
  echo "Please provide a comma-separated list of domains (e.g., domain.tld1,domain.tld2)"
  exit 1
fi

# Convert comma-separated domains into an array
IFS=',' read -ra DOMAINS <<< "$1"

# Get system's hostname
HOSTNAME=$(hostname)

# Prompt for custom values if needed
read -p "Enter country code (C) [default: CZ]: " C
C=${C:-CZ}

read -p "Enter state (ST) [default: Pilsen]: " ST
ST=${ST:-Pilsen}

read -p "Enter locality (L) [default: Pilsen]: " L
L=${L:-Pilsen}

# Use the system's hostname for Organization (O)
O=$HOSTNAME

# Prepare SAN entries for CSR config
SAN_ENTRIES=""
COUNTER=1
for DOMAIN in "${DOMAINS[@]}"; do
  SAN_ENTRIES+="DNS.$COUNTER = $DOMAIN\n"
  ((COUNTER++))
  SAN_ENTRIES+="DNS.$COUNTER = *.$DOMAIN\n"
  ((COUNTER++))
done

# Create CSR configuration file
CSR_CONF=$(mktemp)
cat <<EOF > "$CSR_CONF"
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = $C
ST = $ST
L = $L
O = $O
CN = ${DOMAINS[0]}

[req_ext]
subjectAltName = @alt_names

[alt_names]
$SAN_ENTRIES
EOF

# Generate private key and certificate signing request
openssl req -new -nodes -newkey rsa:2048 -keyout "$SAVE_DIR/privkey.pem" -out "$SAVE_DIR/cert.csr" -config "$CSR_CONF"

# Self-sign the certificate using the CSR
openssl x509 -req -in "$SAVE_DIR/cert.csr" -signkey "$SAVE_DIR/privkey.pem" -out "$SAVE_DIR/cert.pem" -days 365 -extensions req_ext -extfile "$CSR_CONF"

# Create full chain file (in this case, it just contains the self-signed cert)
cp "$SAVE_DIR/cert.pem" "$SAVE_DIR/fullchain.pem"

# Clean up the CSR configuration file
rm -f "$CSR_CONF"

# Notify the user
echo "Certificate and key have been saved to $SAVE_DIR."
echo "Files created: cert.pem, fullchain.pem, privkey.pem"
