#!/bin/bash
docker compose down
docker compose up -d

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print "hello" in green
echo -e "${GREEN}Docker recomposed${NC}"
