#!/bin/bash
# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
GRAY='\033[1;33m'
BLUE='\e[1;34m'
WHITE='\033[0;97m'
# Reset color
NC='\033[0m'
# Function to display help message
show_help() {
    echo "Usage: cmnds [option]"
    echo "Options:"
    echo "  -h  : Display help message"
    echo "  -u  : Update CMNDS"
}

# Function to list all scripts in the same directory as cmnds.sh
list_commands() {
    echo "Available commands:"
    for file in $(dirname "$0")/*.sh; do
        if [ "$file" != "$0" ]; then
            echo "$(basename "$file" .sh)"
        fi
    done
}

# Function to run cmnds-update
run_update() {
    echo "Running update..."
    cmnds-update
}

# Function to get version number and path of the script
get_version() {
    script_path=$(realpath "$0")
    script_path_without_cmnds=${script_path/cmnds\/cmnds.sh/}
    if [ -f "${script_path_without_cmnds}version" ]; then
        version="($(cat ${script_path_without_cmnds}version))"
    else
        version="(unknown)"
    fi
    echo -e "${GREEN}   ________  ____   ______  _____\n  / ____/  |/  / | / / __ \/ ___/\n / /   / /|_/ /  |/ / / / /\__ \\\n/ /___/ /  / / /|  / /_/ /___/ /\n\____/_/  /_/_/ |_/_____//____/${NC}"
    echo -e "${GREEN}Simply commands to ease using Linux server${NC}"
    echo -e "${GREEN}>> created by Martin Skalicky"
    echo -e ">> GitHub → @maskalix${NC}"
    echo -e "${BLUE}alpha${NC}${WHITE} $version${NC}\n"
}

# If no arguments are provided, print version number and show help message
if [ $# -eq 0 ]; then
    get_version
    show_help
    exit 0
fi

# Parse command-line options
while getopts ":hu" opt; do
    case $opt in
        h)  show_help
            exit 0
            ;;
        u)  run_update
            exit 0
            ;;
        :)  echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# If an unknown argument is provided
if [ $OPTIND -eq 1 ]; then
    echo "Invalid option. Use '-h' for help."
    exit 1
fi
