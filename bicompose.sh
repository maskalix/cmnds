#!/bin/bash

docker compose up --build

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print "hello" in green
echo -e "${GREEN}Docker compose ${YELLOW}with build${NC}"
