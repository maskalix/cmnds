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
    echo "Flags:"
    echo -e "${YELLOW}create${NC}, ${YELLOW}-c${NC}, ${YELLOW}c${NC}           Create a new project directory."
    echo -e "${YELLOW}up${NC}, ${YELLOW}-u${NC}, ${YELLOW}u${NC}               Run docker compose up -d (use after create)."
    echo -e "${YELLOW}view${NC}, ${YELLOW}-v${NC}, ${YELLOW}v${NC}              View project docker-compose.yml."
    echo -e "${YELLOW}down${NC}, ${YELLOW}-d${NC}, ${YELLOW}d${NC}              Run docker compose down."
    echo -e "${YELLOW}remove${NC}, ${YELLOW}-r${NC}, ${YELLOW}r${NC}            Remove the specified project directory."
    echo -e "${YELLOW}update${NC}, ${YELLOW}-u${NC}, ${YELLOW}u${NC}            Update the project (runs update.sh or docker compose commands)."
    echo -e "${YELLOW}recreate${NC}, ${YELLOW}-recreate${NC}, ${YELLOW}r${NC}   Remove and recreate the project directory."
    echo -e "${YELLOW}logs${NC}, ${YELLOW}-l${NC}, ${YELLOW}l${NC}              View logs of a running container."
    echo -e "${YELLOW}list${NC}, ${YELLOW}-l${NC}, ${YELLOW}l${NC}              List all projects with services and Docker images."
    echo -e "${YELLOW}help${NC}, ${YELLOW}-h${NC}, ${YELLOW}h${NC}              Display this help message."
}

# Check for no options
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Project name is the first argument
project_name="$1"
shift # Remove the project name from the arguments

# Directory setup
dir="/data/misc/"

# Actions flags (initialize to false)
run_create=false
run_c=false
run_u=false
run_r=false
run_v=false
run_d=false
run_logs=false
run_update=false
run_recreate=false
run_list=false

# Parse flags in all formats (short, long, or mixed)
for flag in "$@"; do
    case "$flag" in
        create|-c|c)
            run_create=true
            ;;
        up|-u|u)
            run_u=true
            ;;
        view|-v|v)
            run_v=true
            ;;
        down|-d|d)
            run_d=true
            ;;
        remove|-r|r)
            run_r=true
            ;;
        update|-u|u)
            run_update=true
            ;;
        logs|-l|l)
            run_logs=true
            ;;
        recreate|-recreate|r)
            run_recreate=true
            ;;
        list|-l|l)
            run_list=true
            ;;
        help|-h|h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid flag: $flag${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Action for 'list' (or '-l' or 'l' flag)
if [ "$run_list" = true ]; then
    echo -e "${CYAN}📋 Listing all projects with their services and Docker images:${NC}"

    # Loop through all project directories and find docker-compose.yml files
    for project_dir in "$dir"/*; do
        if [ -d "$project_dir" ]; then
            compose_file="$project_dir/docker-compose.yml"
            if [ -f "$compose_file" ]; then
                project_name=$(basename "$project_dir")
                echo -e "\n${YELLOW}Project: $project_name${NC}"
                
                # Parse docker-compose.yml for services and Docker images
                echo -e "${BLUE}  Services and Docker Images:${NC}"
                services=$(yq eval '.services' "$compose_file" 2>/dev/null)
                
                if [ -z "$services" ]; then
                    echo -e "${RED}❌ No services found in $compose_file!${NC}"
                else
                    # Loop through each service and get the Docker image
                    echo "$services" | jq -r 'keys[]' | while read -r service; do
                        image=$(yq eval ".services.$service.image" "$compose_file")
                        if [ -n "$image" ]; then
                            echo -e "    - ${WHITE}$service${NC}: ${CYAN}$image${NC}"
                        else
                            echo -e "    - ${WHITE}$service${NC}: ${RED}No image defined${NC}"
                        fi
                    done
                fi
            fi
        fi
    done
fi

# Action for 'create' (or 'create' or '-c' or 'c' flag)
if [ "$run_create" = true ]; then
    read -rp "🔨 Are you sure you want to CREATE the project $project_name? (y/n): " confirm_create
    if [[ $confirm_create == "y" || $confirm_create == "Y" ]]; then
        mkdir -p "$dir/$project_name" && echo -e "${GREEN}🎉 Project $project_name created successfully!${NC}"
    else
        echo -e "${CYAN}🛑 Create operation canceled.${NC}"
    fi
fi

# Action for 'open docker-compose.yml' (or '-c' or 'c' flag)
if [ "$run_c" = true ]; then
    read -rp "📄 Are you sure you want to OPEN docker-compose.yml for $project_name? (y/n): " confirm_open
    if [[ $confirm_open == "y" || $confirm_open == "Y" ]]; then
        cd "$dir/$project_name" || exit
        nano "docker-compose.yml"
    else
        echo -e "${CYAN}🛑 Open operation canceled.${NC}"
    fi
fi

# Action for 'up' (or '-u' or 'u' flag)
if [ "$run_u" = true ]; then
    read -rp "🚀 Are you sure you want to START the containers for $project_name with 'docker compose up -d'? (y/n): " confirm_up
    if [[ $confirm_up == "y" || $confirm_up == "Y" ]]; then
        cd "$dir/$project_name" || exit
        docker compose up -d
        echo -e "${CYAN}🚀 Docker Compose started successfully!${NC}"
    else
        echo -e "${CYAN}🛑 Start operation canceled.${NC}"
    fi
fi

# Action for 'down' (or '-d' or 'd' flag)
if [ "$run_d" = true ]; then
    read -rp "🛑 Are you sure you want to STOP the containers for $project_name with 'docker compose down'? (y/n): " confirm_down
    if [[ $confirm_down == "y" || $confirm_down == "Y" ]]; then
        cd "$dir/$project_name" || exit
        docker compose down
        echo -e "${CYAN}🛑 Docker Compose stopped and removed containers.${NC}"
    else
        echo -e "${CYAN}🛑 Stop operation canceled.${NC}"
    fi
fi

# Action for 'remove' (or '-r' or 'r' flag)
if [ "$run_r" = true ]; then
    read -rp "⚠️ Are you sure you want to REMOVE the directory $project_name? This action cannot be undone! (y/n): " confirm_remove
    if [[ $confirm_remove == "y" || $confirm_remove == "Y" ]]; then
        read -rp "❗ This is your final confirmation. Do you REALLY want to DELETE the directory $project_name? (y/n): " final_confirm_remove
        if [[ $final_confirm_remove == "y" || $final_confirm_remove == "Y" ]]; then
            rm -rf "$dir/$project_name"
            echo -e "${RED}❌ Project $project_name removed successfully!${NC}"
        else
            echo -e "${CYAN}🛑 Remove operation canceled.${NC}"
        fi
    else
        echo -e "${CYAN}🛑 Remove operation canceled.${NC}"
    fi
fi

# Action for 'update' (or '-u' or 'u' flag)
if [ "$run_update" = true ]; then
    cd "$dir/$project_name" || exit
    update_script="$dir/$project_name/update.sh"
    
    if [ -f "$update_script" ]; then
        read -rp "🔄 An update script was found. Do you want to run it? (y/n): " confirm_update
        if [[ $confirm_update == "y" || $confirm_update == "Y" ]]; then
            bash "$update_script"
            echo -e "${GREEN}✔️ Update completed successfully!${NC}"
        else
            echo -e "${CYAN}🛑 Update operation canceled.${NC}"
        fi
    else
        read -rp "🛠️ No update script found. Do you want to run 'docker compose pull', 'docker compose down', and 'docker compose up -d'? (y/n): " confirm_docker_update
        if [[ $confirm_docker_update == "y" || $confirm_docker_update == "Y" ]]; then
            docker compose pull
            docker compose down
            docker compose up -d
            echo -e "${GREEN}✔️ Docker containers updated successfully!${NC}"
        else
            echo -e "${CYAN}🛑 Update operation canceled.${NC}"
        fi
    fi
fi

# Action for 'recreate' (or '-recreate' or 'r' flag)
if [ "$run_recreate" = true ]; then
    read -rp "⚠️ Are you sure you want to REMOVE and RECREATE the project $project_name? (y/n): " confirm_recreate
    if [[ $confirm_recreate == "y" || $confirm_recreate == "Y" ]]; then
        read -rp "❗ This will delete the entire project. Do you REALLY want to DELETE and RECREATE $project_name? (y/n): " final_confirm_recreate
        if [[ $final_confirm_recreate == "y" || $final_confirm_recreate == "Y" ]]; then
            rm -rf "$dir/$project_name"
            mkdir -p "$dir/$project_name"
            echo -e "${GREEN}✔️ Project $project_name recreated successfully!${NC}"
        else
            echo -e "${CYAN}🛑 Recreate operation canceled.${NC}"
        fi
    else
        echo -e "${CYAN}🛑 Recreate operation canceled.${NC}"
    fi
fi

# Action for 'logs' (or '-l' or 'l' flag)
if [ "$run_logs" = true ]; then
    cd "$dir/$project_name" || exit
    container_name=$(yq eval '.services | keys | .[0]' "$dir/$project_name/docker-compose.yml")
    read -rp "📜 Viewing logs for container: $container_name. Are you sure? (y/n): " confirm_logs
    if [[ $confirm_logs == "y" || $confirm_logs == "Y" ]]; then
        docker container logs "$container_name"
    else
        echo -e "${CYAN}🛑 Logs operation canceled.${NC}"
    fi
fi
