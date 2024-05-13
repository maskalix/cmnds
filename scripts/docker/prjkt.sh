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
    echo -e "Usage: ${WHITE}prjkt ${YELLOW}-option ${BLUE}[project_name]${NC}"
    echo ""
    echo "Options:"
    echo -e "${YELLOW}-n ${BLUE}[project_name]${NC}      Create a new project directory."
    echo -e "${YELLOW}-c${NC}                     Open 'docker-compose.yml' in nano (use after -n [project_name])."
    echo -e "${YELLOW}-u${NC}                     Run the docker compose up -d (use after -n [project_name])."
    echo -e "${YELLOW}-v ${BLUE}[project_name]${NC}      View project docker-compose.yml."
    echo -e "${YELLOW}-r ${BLUE}[project_name]${NC}      Remove the specified project directory."
    echo -e "${YELLOW}-h${NC}                     Display this help message."
}

# Check for no options
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

run_c=false
run_u=false

# Parse command line options
while getopts ":n:v:crhuv:" opt; do
    case ${opt} in
        n)
            project_name="$OPTARG"
            read -rp "Enter preferred directory (default: /data/misc/): " custom_dir
            dir=${custom_dir:-"/data/misc/"}
            mkdir -p "$dir/$project_name" && {
                echo -e "\e[32mProject \e[0m>> $project_name <<\e[32m created\e[0m"
            }
            ;;
        c)
            run_c=true
            ;;
        u)
            run_u=true
            ;;
        r)
            rm -rf "$OPTARG"
            ;;
        h)
            show_help
            ;;
        v)
            project_name="$OPTARG"
            read -rp "Enter preferred directory (default: /data/misc/): " custom_dir
            dir=${custom_dir:-"/data/misc/"}
            echo -R "${dir}docker-compose.yml"
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

# If both -c and -u options were provided, execute both actions
if [ "$run_c" = true ] && [ "$run_u" = true ]; then
    # Ensure the docker-compose file is opened only if the -n option was used before -c
    if [ -n "$project_name" ]; then
        cd "$dir/$project_name"
        nano "docker-compose.yml"
        docker compose up -d
        echo -e "${YELLOW}Docker Composed successfully!${NC}"
    else
        echo "Error: '-c' and '-u' must be used after '-n [project_name] [directory_path]'"
        exit 1
    fi
# If only -u is provided, execute docker compose up -d
elif [ "$run_u" = true ]; then
    if [ -n "$project_name" ]; then
        cd "$dir/$project_name"
        docker compose up -d
        echo -e "${YELLOW}Docker Composed successfully!${NC}"
    else
        echo "Error: '-u' must be used after '-n [project_name] [directory_path]'"
        exit 1
    fi
# If only -c is provided, execute cd and nano
elif [ "$run_c" = true ]; then
    if [ -n "$project_name" ]; then
        cd "$dir/$project_name"
        nano "docker-compose.yml"
    else
        echo "Error: '-c' must be used after '-n [project_name] [directory_path]'"
        exit 1
    fi
fi
