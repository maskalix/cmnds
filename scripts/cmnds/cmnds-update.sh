#!/bin/bash

# Function to display section headers
display_header() {
    echo -e "\033[1;33m$1:\033[0m"
}

# Check if /cmnds-temp directory exists
if [ -d "/cmnds-temp" ]; then
    echo "Removing existing /cmnds-temp directory..."
    rm -rf /cmnds-temp
fi

# Create /cmnds-temp directory
mkdir /cmnds-temp
cd /cmnds-temp

# Download and execute install script
display_header "Downloading and executing install script"
wget --no-cache https://raw.githubusercontent.com/maskalix/cmnds/main/install.sh && chmod +x install.sh && ./install.sh

# Remove /cmnds-temp directory
display_header "Cleaning up"
rm -rf /cmnds-temp
