#!/bin/bash

# Prompt for username and email
read -p "Enter the username for the SSH key (e.g., your_username): " USERNAME
read -p "Enter your email address (for key comment): " EMAIL

# Define key path based on the username
if [ "$USERNAME" == "root" ]; then
    KEY_PATH="/root/.ssh/id_rsa"
else
    KEY_PATH="/home/$USERNAME/.ssh/id_rsa"
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Generate SSH key pair if it doesn't exist
if [ ! -f "$KEY_PATH" ]; then
    echo "Generating new SSH key pair..."
    
    # Create the .ssh directory if it does not exist
    if [ "$USERNAME" != "root" ]; then
        sudo mkdir -p /home/$USERNAME/.ssh
        sudo chown $USERNAME:$USERNAME /home/$USERNAME/.ssh
    else
        mkdir -p /root/.ssh
    fi
    
    ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$KEY_PATH" -N ""
else
    echo "SSH key pair already exists at $KEY_PATH."
fi

# Display public key
PUBLIC_KEY=$(cat "${KEY_PATH}.pub")

# Output the paths to the key files
echo "SSH key pair generated and stored at:"
echo "Private key: $KEY_PATH"
echo "Public key: ${KEY_PATH}.pub"

# Output the public key
echo ""
echo "Public key content:"
echo "$PUBLIC_KEY"
echo ""

# Add public key to authorized_keys
if [ "$USERNAME" != "root" ]; then
    AUTH_KEYS_PATH="/home/$USERNAME/.ssh/authorized_keys"
else
    AUTH_KEYS_PATH="/root/.ssh/authorized_keys"
fi

# Create authorized_keys if it does not exist
if [ ! -f "$AUTH_KEYS_PATH" ]; then
    touch "$AUTH_KEYS_PATH"
    chmod 600 "$AUTH_KEYS_PATH"
    chown $USERNAME:$USERNAME "$AUTH_KEYS_PATH"
fi

# Append the public key to authorized_keys
if ! grep -q "$PUBLIC_KEY" "$AUTH_KEYS_PATH"; then
    echo "$PUBLIC_KEY" >> "$AUTH_KEYS_PATH"
    echo "Public key added to $AUTH_KEYS_PATH."
else
    echo "Public key is already present in $AUTH_KEYS_PATH."
fi

# Provide instructions for copying the key files to the PC
echo ""
echo "To use these keys on the PC (client machine), you need to transfer the following files:"
echo "    $KEY_PATH"
echo "    ${KEY_PATH}.pub"
echo "Securely transfer these files to your client machine."

echo "On the PC, place the private key in the ~/.ssh/ directory and set the correct permissions:"
echo "    mkdir -p ~/.ssh"
echo "    cp /path/to/id_rsa ~/.ssh/id_rsa"
echo "    chmod 600 ~/.ssh/id_rsa"
echo ""
echo "Make sure to keep your private key secure and never share it."

echo "Done."

echo "!!! REMEMBER !!!"
echo "-> ! check for conflicting files in /etc/ssh/sshd_config.d/"
echo "-> ! for PuTTY convert the private key using PuTTYgen to whatever format"
echo "-> ! Root login:"
echo "PermitRootLogin yes"
echo "-> ! recommended (SSH key login):"
echo "PubkeyAuthentication yes"
echo "PasswordAuthentication no"
echo "UsePAM no"
