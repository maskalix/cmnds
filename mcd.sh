#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m' # Green color
RED='\033[0;31m'   # Red color
NC='\033[0m'       # No color (reset)

mcd() {
    if [ ! -d "$1" ]; then
        # Print message in green text
        echo -e "${GREEN}Directory $1 created${NC}"
        mkdir -p "$1" && cd "$1" || return 1
    else
        # Print message in red text
        echo -e "${RED}Directory $1 already exists${NC}"
    fi
}

# Call the function with provided arguments
mcd "$1"

