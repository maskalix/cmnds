#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m' # Green color
RED='\033[0;31m'   # Red color
NC='\033[0m'       # No color (reset)

mcd() {
    if [ ! -d "$1" ]; then
        if mkdir -p "$1"; then
            # Print message in green text
            echo -e "${GREEN}Directory $1 created${NC}"
            if cd "$1"; then
                echo "Changed directory to: $PWD"
                cd "$PWD/$1"
            else
                echo -e "${RED}Failed to change directory to $1${NC}"
                return 1
            fi
        else
            echo -e "${RED}Failed to create directory $1${NC}"
            return 1
        fi
    else
        # Print message in red text
        echo -e "${RED}Directory $1 already exists${NC}"
        if cd "$PWD/$1"; then
            echo "Changed directory to: $PWD"
        else
            echo -e "${RED}Failed to change directory to $1${NC}"
            return 1
        fi
    fi
}

# Call the function with provided arguments
if [ -z "$1" ]; then
    echo "Usage: mcd <directory>"
    exit 1
fi

if mcd "$1"; then
    exit 0
else
    exit 1
fi
