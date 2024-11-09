#!/bin/bash

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
GRAY='\033[1;33m'
BLUE='\e[1;34m'
WHITE='\033[0;97m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # Reset color

PROJECT_FOLDER=$(bash cmnds-config read PRJKT_FOLDER)

# Function to display help information
show_help() {
    echo -e "Usage: ${WHITE}prjkt ${YELLOW}[project_name] ${BLUE}[flags...]${NC}"
    echo ""
    echo "Commands:"
    echo -e "${YELLOW}create${NC}, ${YELLOW}-c${NC}, ${YELLOW}c${NC}           Create a new project directory."
    echo -e "${YELLOW}up${NC}, ${YELLOW}-u${NC}, ${YELLOW}u${NC}               Run docker compose up -d (use after create)."
    echo -e "${YELLOW}view${NC}, ${YELLOW}-v${NC}, ${YELLOW}v${NC}              View project docker-compose.yml."
    echo -e "${YELLOW}down${NC}, ${YELLOW}-d${NC}, ${YELLOW}d${NC}              Run docker compose down."
    echo -e "${YELLOW}remove${NC}, ${YELLOW}-r${NC}, ${YELLOW}r${NC}            Remove the specified project directory."
    echo -e "${YELLOW}update${NC}, ${YELLOW}-u${NC}, ${YELLOW}u${NC}            Update the project (runs update.sh or docker compose commands)."
    echo -e "${YELLOW}recreate${NC}, ${YELLOW}-recreate${NC}, ${YELLOW}r${NC}   Remove and recreate the project directory."
    echo -e "${YELLOW}logs${NC}, ${YELLOW}-l${NC}, ${YELLOW}l${NC}              View logs of a running container."
    echo -e "${YELLOW}list${NC}, ${YELLOW}-l${NC}, ${YELLOW}l${NC}              List all projects with services and Docker images."
    echo -e "${YELLOW}info${NC}, ${YELLOW}-i${NC}, ${YELLOW}i${NC}              Show information about the project and environment."
    echo -e "${YELLOW}help${NC}, ${YELLOW}-h${NC}, ${YELLOW}h${NC}              Display this help message."
}

# Check for no options
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Default directory
dir="/data/misc/"

# Parse flags and execute the appropriate command
for flag in "$@"; do
    case "$flag" in
        # Handle 'create' flag
        create|-c|c)
            echo -e "${CYAN}🔨 Creating project directory...${NC}"
            read -rp "Enter the project name: " project_name
            read -rp "Enter directory path (default: $dir): " custom_dir
            dir=${custom_dir:-$dir}
            mkdir -p "$dir/$project_name"
            echo -e "${GREEN}🎉 Project '$project_name' created successfully!${NC}"
            ;;
        
        # Handle 'up' flag
        up|-u|u)
            echo -e "${CYAN}🚀 Running docker compose up -d...${NC}"
            read -rp "Enter the project name: " project_name
            read -rp "Enter directory path (default: $dir): " custom_dir
            dir=${custom_dir:-$dir}
            cd "$dir/$project_name" || exit
            docker compose up -d
            echo -e "${CYAN}🚀 Docker Compose started successfully!${NC}"
            ;;
        
        # Handle 'down' flag
        down|-d|d)
            echo -e "${CYAN}🛑 Running docker compose down...${NC}"
            read -rp "Enter the project name: " project_name
            read -rp "Enter directory path (default: $dir): " custom_dir
            dir=${custom_dir:-$dir}
            cd "$dir/$project_name" || exit
            docker compose down
            echo -e "${CYAN}🛑 Docker Compose stopped and removed containers.${NC}"
            ;;
        
        # Handle 'view' flag
        view|-v|v)
            echo -e "${CYAN}📄 Viewing docker-compose.yml...${NC}"
            read -rp "Enter the project name: " project_name
            read -rp "Enter directory path (default: $dir): " custom_dir
            dir=${custom_dir:-$dir}
            cd "$dir/$project_name" || exit
            nano "docker-compose.yml"
            ;;
        
        # Handle 'remove' flag
        remove|-r|r)
            echo -e "${CYAN}⚠️ Removing project directory...${NC}"
            read -rp "Enter the project name: " project_name
            read -rp "Enter directory path (default: $dir): " custom_dir
            dir=${custom_dir:-$dir}
            read -rp "Are you sure you want to remove $project_name? This action cannot be undone. (y/n): " confirm_remove
            if [[ $confirm_remove == "y" || $confirm_remove == "Y" ]]; then
                rm -rf "$dir/$project_name"
                echo -e "${RED}❌ Project '$project_name' removed successfully!${NC}"
            else
                echo -e "${CYAN}🛑 Remove operation canceled.${NC}"
            fi
            ;;
        
        # Handle 'update' flag
        update|-u|u)
            echo -e "${CYAN}🔄 Updating project...${NC}"
            read -rp "Enter the project name: " project_name
            read -rp "Enter directory path (default: $dir): " custom_dir
            dir=${custom_dir:-$dir}
            cd "$dir/$project_name" || exit
            update_script="$dir/$project_name/update.sh"
            if [ -f "$update_script" ]; then
                read -rp "An update script was found. Do you want to run it? (y/n): " confirm_update
                if [[ $confirm_update == "y" || $confirm_update == "Y" ]]; then
                    bash "$update_script"
                    echo -e "${GREEN}✔️ Update completed successfully!${NC}"
                else
                    echo -e "${CYAN}🛑 Update operation canceled.${NC}"
                fi
            else
                read -rp "No update script found. Do you want to run 'docker compose pull', 'docker compose down', and 'docker compose up -d'? (y/n): " confirm_docker_update
                if [[ $confirm_docker_update == "y" || $confirm_docker_update == "Y" ]]; then
                    docker compose pull
                    docker compose down
                    docker compose up -d
                    echo -e "${GREEN}✔️ Docker containers updated successfully!${NC}"
                else
                    echo -e "${CYAN}🛑 Docker update operation canceled.${NC}"
                fi
            fi
            ;;
        
        # Handle 'list' flag
        list|-l|l)
            echo -e "${CYAN}📋 Listing all projects...${NC}"
            for project in "$dir"/*; do
                if [ -d "$project" ]; then
                    project_name=$(basename "$project")
                    echo -e "${YELLOW}Project: $project_name${NC}"
                    
                    # Get container names from docker-compose.yml using grep and sed
                    container_names=$(grep -oP '^\s*container_name:.*' "$project/docker-compose.yml" | sed 's/.*container_name: "\(.*\)"/\1/')
                    if [ -z "$container_names" ]; then
                        # If no container_name, use service names instead
                        container_names=$(grep -oP '^\s*services:\s*\K.*' "$project/docker-compose.yml" | sed 's/^\s*//')
                    fi
                    
                    # Loop over container names and extract their images
                    for container in $container_names; do
                        image=$(grep -oP "^\s*image:.*" "$project/docker-compose.yml" | sed 's/.*image: "\(.*\)"/\1/')
                        echo -e "  - ${BLUE}Service: $container${NC}, ${GREEN}Image: $image${NC}"
                    done
                fi
            done
            ;;
        
        # Handle 'info' flag
        info|-i|i)
            echo -e "${CYAN}ℹ️ Showing project info...${NC}"
            project_count=$(find "$dir" -maxdepth 1 -type d | wc -l)
            echo -e "${GREEN}Projects found: $project_count${NC}"
            echo -e "${YELLOW}Root folder: $dir${NC}"
            echo -e "${GREEN}Projects are located at: $PROJECT_FOLDER${NC}"
            ;;
        
        # Handle 'help' flag
        help|-h|h)
            show_help
            ;;
        
        *)
            echo -e "${RED}❌ Invalid option: $flag${NC}"
            show_help
            exit 1
            ;;
    esac
done
