#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$0")
CONF_FILE="$SCRIPT_DIR/csr_config.conf"

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

# Function to prompt for CSR field values
function prompt_for_csr_values() {
  read -p "Enter Country (C) [e.g., US]: " C
  read -p "Enter State (ST) [e.g., California]: " ST
  read -p "Enter Locality (L) [e.g., San Francisco]: " L
  read -p "Enter Organization (O) [e.g., YourCompany]: " O

  # Default values if not provided
  C=${C:-US}
  ST=${ST:-"California"}
  L=${L:-"San Francisco"}
  O=${O:-"YourCompany"}
  
  # Save the values to the configuration file
  cat <<EOF > "$CONF_FILE"
C=$C
ST=$ST
L=$L
O=$O
EOF
  echo "CSR configuration saved to $CONF_FILE."
}

# Load the configuration file if it exists
if [[ -f "$CONF_FILE" ]]; then
  source "$CONF_FILE"
  echo "Loaded CSR configuration from $CONF_FILE."
  echo "Country: $C, State: $ST, Locality: $L, Organization: $O"
  read -p "Do you want to update these values? (y/N): " UPDATE_CONF
  if [[ "$UPDATE_CONF" =~ ^[Yy]$ ]]; then
    prompt_for_csr_values
  fi
else
  # Prompt for CSR values if the config file does not exist
  prompt_for_csr_values
fi

# Ask the user if they want a wildcard certificate
read -p "Do you want a wildcard certificate for the provided domains? (y/N): " WILDCARD

# Prepare SAN entries for CSR config
SAN_ENTRIES=""
COUNTER=1

for DOMAIN in "${DOMAINS[@]}"; do
  # If the user requested a wildcard certificate
  if [[ "$WILDCARD" =~ ^[Yy]$ ]]; then
    SAN_ENTRIES+="DNS.$COUNTER = *.$DOMAIN\n"
  else
    SAN_ENTRIES+="DNS.$COUNTER = $DOMAIN\n"
  fi
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

# Convert PEM to CRT for the certificate
openssl x509 -outform der -in "$SAVE_DIR/cert.pem" -out "$SAVE_DIR/cert.crt"
echo "PEM certificate has been converted to CRT format: cert.crt"

# Ask if the user wants to generate a root certificate
read -p "Do you want to generate a root certificate (for adding to trusted store)? (y/N): " GEN_ROOTCERT

if [[ "$GEN_ROOTCERT" =~ ^[Yy]$ ]]; then
  # Generate a root certificate
  openssl req -x509 -new -nodes -keyout "$SAVE_DIR/rootCA.key" -out "$SAVE_DIR/rootCA.pem" -days 1024 -subj "/C=$C/ST=$ST/L=$L/O=$O/CN=${DOMAINS[0]}"
  echo "Root certificate (rootCA.pem) has been generated and saved to $SAVE_DIR."
  
  # Convert PEM to CRT for the root certificate
  openssl x509 -outform der -in "$SAVE_DIR/rootCA.pem" -out "$SAVE_DIR/rootCA.crt"
  echo "Root PEM certificate has been converted to CRT format: rootCA.crt"
fi
