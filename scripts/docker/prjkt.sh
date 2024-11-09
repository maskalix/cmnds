#!/bin/bash

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\e[1;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[0;97m'
NC='\033[0m' # Reset color

PROJECT_FOLDER=$(bash cmnds-config read PRJKT_FOLDER)

# Function to display help information
show_help() {
    echo -e "Usage: ${WHITE}prjkt ${YELLOW}[project_name] ${BLUE}[command]${NC}"
    echo ""
    echo "Commands:"
    echo -e "${YELLOW}create, -c, c${NC}           Create a new project directory."
    echo -e "${YELLOW}up, -u, u${NC}               Run docker compose up -d (use after create)."
    echo -e "${YELLOW}view, -v, v${NC}              View project docker-compose.yml."
    echo -e "${YELLOW}down, -d, d${NC}              Run docker compose down."
    echo -e "${YELLOW}remove, -r, r${NC}            Remove the specified project directory."
    echo -e "${YELLOW}recreate, -rc, rc${NC}    Remove and recreate the project directory."
    echo -e "${YELLOW}update, -up, up${NC}            Update the project (runs update.sh or docker compose commands)."
    echo -e "${YELLOW}recreate, -recreate, r${NC}    Remove and recreate the project directory."
    echo -e "${YELLOW}logs, -l, l${NC}              View logs of a running container."
    echo -e "${YELLOW}info, -i, i${NC}              Show information about the project and environment."
    echo -e "${YELLOW}help, -h, h${NC}              Display this help message."
}

# Ensure that both project_name and command are provided
if [[ -z "$1" || -z "$2" ]]; then
    echo -e "${RED}❌ Error: Project name and command are required.${NC}"
    show_help
    exit 1
fi

project_name="$1"
command="$2"

# Handle commands based on the second argument
case "$command" in
    create | -c | c)
        echo -e "${CYAN}Creating new project...${NC}"
        read -rp "Enter project name: " project_name
        read -rp "Enter preferred directory (default: $PROJECT_FOLDER): " custom_dir
        dir=${custom_dir:-$PROJECT_FOLDER}
        mkdir -p "$dir/$project_name" && {
            echo -e "${GREEN}Project '$project_name' created at $dir${NC}"
        }
        ;;
    up | -u | u)
        echo -e "${CYAN}Running docker compose up...${NC}"
        read -rp "Are you sure you want to start the containers for project $project_name? (y/n): " confirm_up
        if [[ "$confirm_up" =~ ^[Yy]$ ]]; then
            cd "$PROJECT_FOLDER/$project_name"
            docker compose up -d
            echo -e "${GREEN}Containers started successfully!${NC}"
        else
            echo -e "${RED}Operation cancelled.${NC}"
        fi
        ;;
    view | -v | v)
        echo -e "${CYAN}Opening docker-compose.yml...${NC}"
        read -rp "Enter project name to view its docker-compose.yml: " project_name
        nano "$PROJECT_FOLDER/$project_name/docker-compose.yml"
        ;;
    down | -d | d)
        echo -e "${CYAN}Running docker compose down...${NC}"
        read -rp "Are you sure you want to stop the containers for project $project_name? (y/n): " confirm_down
        if [[ "$confirm_down" =~ ^[Yy]$ ]]; then
            cd "$PROJECT_FOLDER/$project_name"
            docker compose down
            echo -e "${RED}Containers stopped successfully!${NC}"
        else
            echo -e "${RED}Operation cancelled.${NC}"
        fi
        ;;
    logs | -l | l)
        echo -e "${CYAN}📜 Viewing logs for a container...${NC}"
        
        # Extract the container_name from the docker-compose.yml if present
        container_name=$(grep -oP '^\s*container_name:\s*\K.+' "$PROJECT_FOLDER/$project_name/docker-compose.yml")
        echo -e "docker container logs $container_name | less +G"
        # If container_name is found, use it
        if [[ -n "$container_name" ]]; then
            echo -e "${YELLOW}Showing logs for container: $container_name...${NC}"
            docker container logs $container_name | less +G
        else
            # If container_name is not found, fall back to service names
            echo -e "${YELLOW}No container_name specified, using service names...${NC}"
            
            # Get the list of container (service) names from docker-compose.yml
            container_names=$(docker compose -f "$PROJECT_FOLDER/$project_name/docker-compose.yml" config --services)
            
            # Split the container names into an array
            IFS=$'\n' read -rd '' -a container_array <<< "$container_names"
            
            # If there's only one container (service), show logs for it
            if [ ${#container_array[@]} -eq 1 ]; then
                echo -e "${YELLOW}Showing logs for ${container_array[0]}...${NC}"
                docker container logs ${container_array[0]} | less +G
            else
                echo -e "${YELLOW}Multiple containers found. Please select a container:${NC}"
                select container in "${container_array[@]}"; do
                    if [[ -n "$container" ]]; then
                        echo -e "${YELLOW}Showing logs for $container...${NC}"
                        docker container logs $container | less +G
                        break
                    else
                        echo -e "${YELLOW}Invalid selection. Please try again.${NC}"
                    fi
                done
            fi
        fi
        ;;
    remove | -r | r)
        echo -e "${CYAN}🗑️ Removing project...${NC}"
        read -rp "Are you sure you want to remove the project $project_name? (y/n): " confirm_remove
        if [[ "$confirm_remove" =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_FOLDER/$project_name"
            echo -e "${RED}Project '$project_name' removed.${NC}"
        else
            echo -e "${RED}Remove cancelled.${NC}"
        fi
        ;;
    update | -up | up)
        echo -e "${CYAN}📦 Attempting to update the project...${NC}"
        read -rp "Do you want to update this project? (y/n): " confirm_update
        if [[ "$confirm_update" =~ ^[Yy]$ ]]; then
            if [[ -f "$PROJECT_FOLDER/$project_name/update.sh" ]]; then
                bash "$PROJECT_FOLDER/$project_name/update.sh"
                echo -e "${GREEN}Project updated via update.sh.${NC}"
            else
                echo -e "${CYAN}Running docker compose pull, down, up...${NC}"
                cd "$PROJECT_FOLDER/$project_name"
                docker compose pull
                docker compose down
                docker compose up -d
                echo -e "${GREEN}Project updated successfully!${NC}"
            fi
        else
            echo -e "${RED}Update cancelled.${NC}"
        fi
        ;;
    recreate | -rc | rc)
        echo -e "${CYAN}🌀 Recreating project...${NC}"
        read -rp "Are you sure you want to delete and recreate this project? (y/n): " confirm_recreate
        if [[ "$confirm_recreate" =~ ^[Yy]$ ]]; then
            read -rp "Are you absolutely sure? This will delete all project data! (y/n): " confirm_recreate_final
            if [[ "$confirm_recreate_final" =~ ^[Yy]$ ]]; then
                rm -rf "$PROJECT_FOLDER/$project_name"
                echo -e "${RED}Project deleted.${NC}"
                # Create the project again
                mkdir -p "$PROJECT_FOLDER/$project_name"
                echo -e "${GREEN}Project recreated successfully!${NC}"
            else
                echo -e "${RED}Recreation cancelled.${NC}"
            fi
        else
            echo -e "${RED}Recreation cancelled.${NC}"
        fi
        ;;
    info | -i | i)
        echo -e "${CYAN}📊 Showing project information...${NC}"
        echo -e "${WHITE}Projects found:$(find "$PROJECT_FOLDER" -maxdepth 1 -type d | wc -l)${NC}"
        echo -e "${WHITE}Projects are located at: $PROJECT_FOLDER${NC}"
        ;;    
    help | -h | h)
        show_help
        ;;    
    *)
        echo -e "${RED}❌ Invalid option. Use -h or --help for usage.${NC}"
        show_help
        exit 1
        ;;
esac
