#!/bin/bash

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
GRAY='\033[1;33m'
BLUE='\e[1;34m'
WHITE='\033[0;97m'
# Reset color
NC='\033[0m'

# Function to display help information
show_help() {
    echo "Usage: ${WHITE}prjkt ${YELLOW}-option ${BLUE}[project_name]${NC}"
    echo ""
    echo "Options:"
    echo -e "${YELLOW}-n ${BLUE}[project_name]${NC}      Create a new project directory."
    echo -e "${YELLOW}-c${NC}                     Open 'docker-compose.yml' in nano (use after -n)."
    echo -e "${YELLOW}-r ${BLUE}[project_name]${NC}      Remove the specified project directory."
    echo -e "${YELLOW}-h${NC}                     Display this help message."
}

# Function to prepare change directory command
prepare_change_directory_command() {
    echo "cd \"$1\""
}

# Function to change directory
change_directory() {
    prepare_change_directory_command "$1"
    # You might want to add an additional message here to prompt the user to press Enter
}

# Check for no options
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Parse command line options
while getopts ":n:cr:h" opt; do
    case ${opt} in
        n)
            project_name="$OPTARG"
            read -rp "Enter preferred directory (default: /data/misc/): " custom_dir
            dir=${custom_dir:-"/data/misc/"}
            mkdir -p "$dir/$project_name" && {
                echo -e "\e[32mProject \e[0m>> $project_name <<\e[32m created\e[0m"
                change_directory "$dir/$project_name"
            }
            ;;
        c)
            # Ensure the docker-compose file is opened only if the -n option was used before -c
            if [ -n "$project_name" ]; then
                nano "docker-compose.yml"
            else
                echo "Error: '-c' must be used after '-n [project_name] [directory_path]'"
                exit 1
            fi
            ;;
        r)
            rm -rf "$OPTARG"
            ;;
        h)
            show_help
            ;;
        \?)
            echo "Invalid option: $OPTARG" 1>&2
            show_help
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." 1>&2
            show_help
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))
