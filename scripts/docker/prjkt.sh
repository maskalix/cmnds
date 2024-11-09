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

# Handle flags and commands
case "$1" in
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
    list | -l | l)
        echo -e "${CYAN}Listing all projects...${NC}"
    
        # Initialize max column widths for each column (Project Name, Service Name, Image, Status, Description)
        max_project_name_len=0
        max_service_name_len=0
        max_image_name_len=0
        max_status_len=0
        max_description_len=0
    
        # Iterate over each project directory to determine the longest string in each column
        find "$PROJECT_FOLDER" -maxdepth 1 -type d | while read project_dir; do
            project_name=$(basename "$project_dir")
            
            # Update the max column width for project name
            max_project_name_len=$(($max_project_name_len > ${#project_name} ? $max_project_name_len : ${#project_name}))
    
            # Check if docker-compose.yml exists in the project directory
            if [[ -f "$project_dir/docker-compose.yml" ]]; then
                services=$(grep -E '^\s*(container_name|image):' "$project_dir/docker-compose.yml" | sed 's/^\s*//g')
    
                service_name=""
                image_name=""
                while read -r line; do
                    if [[ $line =~ container_name: ]]; then
                        service_name="${line#*: }"
                        # Update the max column width for service name
                        max_service_name_len=$(($max_service_name_len > ${#service_name} ? $max_service_name_len : ${#service_name}))
                    elif [[ $line =~ image: ]]; then
                        image_name="${line#*: }"
                        # Update the max column width for image name
                        max_image_name_len=$(($max_image_name_len > ${#image_name} ? $max_image_name_len : ${#image_name}))
                    fi
                done <<< "$services"
    
                # If service and image are both defined, determine status
                status="🟢"
                container_status=$(docker ps --filter "name=$project_name" --format "{{.Status}}" || echo "stopped")
                if [[ $container_status == "stopped" ]]; then
                    status="🔴"
                fi
                # Update the max column width for status
                max_status_len=$(($max_status_len > ${#status} ? $max_status_len : ${#status}))
    
                # Check for description
                description=$(grep -m 1 'description:' "$project_dir/docker-compose.yml" | sed 's/description: //g')
    
                # Escape dollar signs in description (for handling variables like $AUTHENTIK_IMAGE)
                description_escaped="${description//\$/\\\$}"
    
                # Update the max column width for description (only if description exists)
                if [[ -n $description_escaped ]]; then
                    max_description_len=$(($max_description_len > ${#description_escaped} ? $max_description_len : ${#description_escaped}))
                fi
            fi
        done
    
        # Add padding for the headers and columns to make sure they are equally spaced
        padding=2  # Padding between columns
    
        # Calculate total width for the table based on maximum column lengths
        total_width=$((max_project_name_len + max_service_name_len + max_image_name_len + max_status_len + max_description_len + 4 * padding))
    
        # Print header
        printf "| %-${max_project_name_len}s | %-${max_service_name_len}s | %-${max_image_name_len}s | %-${max_status_len}s | %-${max_description_len}s |\n" "Project Name" "Service Name" "Image" "Status" "Description"
        echo "+-$(printf '%-${max_project_name_len}s' "-")-+-$(printf '%-${max_service_name_len}s' "-")-+-$(printf '%-${max_image_name_len}s' "-")-+-$(printf '%-${max_status_len}s' "-")-+-$(printf '%-${max_description_len}s' "-")-+"
    
        # Iterate again over the projects to print the table rows
        find "$PROJECT_FOLDER" -maxdepth 1 -type d | while read project_dir; do
            project_name=$(basename "$project_dir")
            
            if [[ -f "$project_dir/docker-compose.yml" ]]; then
                services=$(grep -E '^\s*(container_name|image):' "$project_dir/docker-compose.yml" | sed 's/^\s*//g')
    
                service_name=""
                image_name=""
                while read -r line; do
                    if [[ $line =~ container_name: ]]; then
                        service_name="${line#*: }"
                    elif [[ $line =~ image: ]]; then
                        image_name="${line#*: }"
                    fi
                done <<< "$services"
    
                # If service and image are both defined, determine status
                status="🟢"
                container_status=$(docker ps --filter "name=$project_name" --format "{{.Status}}" || echo "stopped")
                if [[ $container_status == "stopped" ]]; then
                    status="🔴"
                fi
    
                # Check for description
                description=$(grep -m 1 'description:' "$project_dir/docker-compose.yml" | sed 's/description: //g')
    
                # Escape dollar signs in description (for handling variables like $AUTHENTIK_IMAGE)
                description_escaped="${description//\$/\\\$}"
    
                # Print the row (if description is empty, we leave the description cell blank)
                if [[ -z $description_escaped ]]; then
                    printf "| %-${max_project_name_len}s | %-${max_service_name_len}s | %-${max_image_name_len}s | %-${max_status_len}s | %s |\n" "$project_name" "$service_name / $image_name" "$status" ""
                else
                    printf "| %-${max_project_name_len}s | %-${max_service_name_len}s | %-${max_image_name_len}s | %-${max_status_len}s | %-${max_description_len}s |\n" "$project_name" "$service_name / $image_name" "$status" "$description_escaped"
                fi
            else
                # If docker-compose.yml doesn't exist, print "Missing" for service and image
                printf "| %-${max_project_name_len}s | %-${max_service_name_len}s | %-${max_image_name_len}s | %-${max_status_len}s | %s |\n" "$project_name" "Missing" "Missing" "🔴" ""
            fi
        done
        echo "+-$(printf '%-${max_project_name_len}s' "-")-+-$(printf '%-${max_service_name_len}s' "-")-+-$(printf '%-${max_image_name_len}s' "-")-+-$(printf '%-${max_status_len}s' "-")-+-$(printf '%-${max_description_len}s' "-")-+"
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

    update | -u | u)
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

   
    info | -i | i)
        echo -e "${CYAN}📊 Showing project information...${NC}"
        echo -e "${WHITE}Projects found:$(find "$PROJECT_FOLDER" -maxdepth 1 -type d | wc -l)${NC}"
        echo -e "${WHITE}Root folder: $PROJECT_FOLDER${NC}"
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
