#!/bin/bash
# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
GRAY='\033[1;33m'
BLUE='\e[1;34m'
WHITE='\033[0;97m'
# Reset color
NC='\033[0m'

script_path=$(realpath "$0")
script_path_without_cmnds=${script_path/cmnds\/cmnds.sh/}

list_commands() {
    COMMANDS_DIR="${script_path_without_cmnds}commands/"
    # Initialize the command list variable
    command_list=""
    # Loop through each file in the directory
    for file in "$COMMANDS_DIR"/*; do
        # Check if the file is a markdown file
        if [[ "$file" == *".md" ]]; then
            continue  # Skip markdown files
        fi
        # Extract the command name from the file path
        command_name=$(basename "$file")
        # Add the command name to the list
        command_list+="\n$command_name"
    done
    # Echo the command list as a table
    echo -e "Command Name\n------------$command_list"
}

# Function to display help message
show_help() {
    echo -e "Usage: ${WHITE}cmnds${NC}${BLUE} [option]${NC}"
    echo "Options:"
    echo -e "${YELLOW}-a${NC} : List all commands"
    echo -e "${YELLOW}-u${NC} : Update CMNDS"
    echo -e "${YELLOW}-d${NC} : Deploy CMNDS commands"
}

# Function to run cmnds-update
run_update() {
    echo "Running update..."
    cmnds-update
}

# Function to get version number and path of the script
get_version() {
    if [ -f "${script_path_without_cmnds}version" ]; then
        version="($(cat ${script_path_without_cmnds}version))"
    else
        version="(unknown)"
    fi
    echo -e "${GREEN}   ________  ____   ______  _____\n  / ____/  |/  / | / / __ \/ ___/\n / /   / /|_/ /  |/ / / / /\__ \ \n/ /___/ /  / / /|  / /_/ /___/ /\n\____/_/  /_/_/ |_/_____//____/${NC}"
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
while getopts "auh" opt; do
    case $opt in
        a)  
            list_commands
            exit 0
            ;;
        u)  
            run_update
            exit 0
            ;;
        h)  
            get_version
            show_help
            exit 0
            ;;
        d)
            cmnds-deploy
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# If an unknown argument is provided
if [ $OPTIND -eq 1 ]; then
    echo "Invalid option. Use '-h' for help."
    exit 1
fi
