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
    echo -e "Usage: ${WHITE}prjkt ${YELLOW}[command] ${BLUE}[project_name]${NC}"
    echo ""
    echo "Commands:"
    echo -e "${YELLOW}create, -c, c${NC}           Create a new project directory."
    echo -e "${YELLOW}up, -u, u${NC}               Run docker compose up -d (use after create)."
    echo -e "${YELLOW}view, -v, v${NC}              View project docker-compose.yml."
    echo -e "${YELLOW}down, -d, d${NC}              Run docker compose down."
    echo -e "${YELLOW}remove, -r, r${NC}            Remove the specified project directory."
    echo -e "${YELLOW}update, -u, u${NC}            Update the project (runs update.sh or docker compose commands)."
    echo -e "${YELLOW}recreate, -recreate, r${NC}    Remove and recreate the project directory."
    echo -e "${YELLOW}logs, -l, l${NC}              View logs of a running container."
    echo -e "${YELLOW}list, -l, l${NC}              List all projects with services and Docker images."
    echo -e "${YELLOW}info, -i, i${NC}              Show information about the project and environment."
    echo -e "${YELLOW}help, -h, h${NC}              Display this help message."
}

# Handle 'create' flag (short -c, long create)
create|-c|c)
    echo -e "${CYAN}Creating new project...${NC}"
    read -rp "Enter project name: " project_name
    read -rp "Enter preferred directory (default: $PROJECT_FOLDER): " custom_dir
    dir=${custom_dir:-$PROJECT_FOLDER}
    mkdir -p "$dir/$project_name" && {
        echo -e "${GREEN}Project '$project_name' created at $dir${NC}"
    }
    ;;

# Handle 'up' flag (short -u, long up)
up|-u|u)
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

# Handle 'view' flag (short -v, long view)
view|-v|v)
    echo -e "${CYAN}Opening docker-compose.yml...${NC}"
    read -rp "Enter project name to view its docker-compose.yml: " project_name
    nano "$PROJECT_FOLDER/$project_name/docker-compose.yml"
    ;;

# Handle 'down' flag (short -d, long down)
down|-d|d)
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

# Handle 'remove' flag (short -r, long remove)
remove|-r|r)
    echo -e "${CYAN}🗑️ Removing project...${NC}"
    read -rp "Are you sure you want to remove the project $project_name? (y/n): " confirm_remove
    if [[ "$confirm_remove" =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECT_FOLDER/$project_name"
        echo -e "${RED}Project '$project_name' removed.${NC}"
    else
        echo -e "${RED}Remove cancelled.${NC}"
    fi
    ;;

# Handle 'update' flag (short -u, long update)
update|-u|u)
    echo -e "${CYAN}📦 Attempting to update the project...${NC}"
    read -rp "Do you want to update this project? This will pull updates and recreate containers. (y/n): " confirm_update
    if [[ "$confirm_update" =~ ^[Yy]$ ]]; then
        cd "$PROJECT_FOLDER/$project_name"
        # Try to execute update.sh if available
        if [ -f "./update.sh" ]; then
            bash update.sh
        else
            docker compose pull
            docker compose down
            docker compose up -d
        fi
        echo -e "${GREEN}Project updated successfully!${NC}"
    else
        echo -e "${RED}Update cancelled.${NC}"
    fi
    ;;

# Handle 'recreate' flag (short -r, long recreate)
recreate|-recreate|r)
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

# Handle 'logs' flag (short -l, long logs)
logs|-l|l)
    echo -e "${CYAN}📜 Viewing logs for a container...${NC}"
    read -rp "Enter project name to view logs: " project_name
    read -rp "Enter container name or number: " container_name
    docker container logs "$container_name"
    ;;

# Handle 'list' flag (short -l, long list)
list|-l|l)
    echo -e "${CYAN}📋 Listing all projects...${NC}"

    # Loop over all project directories
    for project in "$PROJECT_FOLDER"/*; do
        if [ -d "$project" ]; then
            project_name=$(basename "$project")
            echo -e "\n${YELLOW}Project: $project_name${NC}"
            
            # Extract container names from docker-compose.yml
            container_names=$(grep -oP '^\s*container_name:.*' "$project/docker-compose.yml" | sed 's/.*container_name: "\(.*\)"/\1/')
            if [ -z "$container_names" ]; then
                # If no container_name, use service names instead
                container_names=$(grep -oP '^\s*services:\s*\K.*' "$project/docker-compose.yml" | sed 's/^\s*//')
            fi

            # Print the table header
            echo -e "${BLUE}Container Name${NC}    ${GREEN}Image${NC}"

            # Loop over container names and extract their images
            for container in $container_names; do
                image=$(grep -A 1 "^\s*container_name: $container" "$project/docker-compose.yml" | grep -oP '^\s*image:.*' | sed 's/.*image: "\(.*\)"/\1/')
                
                # If no image found, display a placeholder
                if [ -z "$image" ]; then
                    image="No image specified"
                fi
                
                # Print container name and image in a table format
                printf "%-20s %-40s\n" "$container" "$image"
            done
        fi
    done
    echo -e "${CYAN}✅ Listing complete!${NC}"
    ;;

# Handle 'info' flag (short -i, long info)
info|-i|i)
    echo -e "${CYAN}ℹ️ Showing project info...${NC}"
    project_count=$(find "$PROJECT_FOLDER" -maxdepth 1 -type d | wc -l)
    echo -e "${GREEN}Projects found: $project_count${NC}"
    echo -e "${YELLOW}Root folder: $PROJECT_FOLDER${NC}"
    echo -e "${GREEN}Projects are located at: $PROJECT_FOLDER${NC}"
    ;;

# Handle 'help' flag (short -h, long help)
help|-h|h)
    show_help
    ;;

# Invalid option
*)
    echo -e "${RED}❌ Invalid option. Use -h or --help for usage.${NC}"
    show_help
    exit 1
    ;;
esac
