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

# Action for 'remove' (or '-r' or 'r' flag)
if [ "$run_r" = true ]; then
    read -rp "⚠️ Are you sure you want to REMOVE the directory $project_name? This action cannot be undone! (y/n): " confirm_remove
    if [[ $confirm_remove == "y" || $confirm_remove == "Y" ]]; then
        read -rp "❗ This is your final confirmation. Do you REALLY want to DELETE the directory $project_name? (y/n): " final_confirm_remove
        if [[ $final_confirm_remove == "y" || $final_confirm_remove == "Y" ]]; then
            rm -rf "$dir/$project_name"
            echo -e "${RED}❌ Project $project_name removed.${NC}"
        else
            echo -e "${CYAN}🛑 Remove operation canceled.${NC}"
        fi
    else
        echo -e "${CYAN}🛑 Remove operation canceled.${NC}"
    fi
fi

# Action for 'view docker-compose.yml' (or '-v' or 'v' flag)
if [ "$run_v" = true ]; then
    read -rp "👀 Do you want to VIEW the docker-compose.yml file for $project_name? (y/n): " confirm_view
    if [[ $confirm_view == "y" || $confirm_view == "Y" ]]; then
        cd "$dir/$project_name" || exit
        nano -R "docker-compose.yml"
    else
        echo -e "${CYAN}🛑 View operation canceled.${NC}"
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

# Action for 'update' (or '-u' or 'u' flag)
if [ "$run_update" = true ]; then
    cd "$dir/$project_name" || exit
    
    echo -e "${BLUE}🔄 Checking for updates for project: $project_name${NC}"
    echo -e "1. Pulling the latest images using 'docker compose pull'."
    echo -e "2. Bringing down the containers with 'docker compose down'."
    echo -e "3. Restarting the containers with 'docker compose up -d'."
    
    read -rp "💡 Do you want to proceed with the update? (y/n): " update_confirm
    if [[ $update_confirm == "y" || $update_confirm == "Y" ]]; then
        if [ -f "update.sh" ]; then
            echo -e "${YELLOW}📜 Running the custom update script (update.sh)...${NC}"
            bash ./update.sh
        else
            echo -e "${CYAN}⚡ No custom update script found. Running default docker compose update...${NC}"
            docker compose pull
            docker compose down
            docker compose up -d
            echo -e "${CYAN}🔄 Docker Compose updated successfully!${NC}"
        fi
    else
        echo -e "${CYAN}🛑 Update operation canceled.${NC}"
    fi
fi

# Action for 'recreate' (or '-recreate' or 'r' flag)
if [ "$run_recreate" = true ]; then
    read -rp "⚠️ Are you sure you want to REMOVE and RECREATE the project $project_name? This action will delete all data! (y/n): " confirm_recreate
    if [[ $confirm_recreate == "y" || $confirm_recreate == "Y" ]]; then
        read -rp "❗ This is your final confirmation. Do you REALLY want to DELETE and RECREATE the project $project_name? (y/n): " final_confirm_recreate
        if [[ $final_confirm_recreate == "y" || $final_confirm_recreate == "Y" ]]; then
            rm -rf "$dir/$project_name"
            mkdir -p "$dir/$project_name"
            echo -e "${GREEN}🔄 Project $project_name recreated successfully!${NC}"
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
    containers=$(docker compose ps -q)
    
    if [ -z "$containers" ]; then
        echo -e "${RED}❌ No running containers found!${NC}"
    else
        echo -e "${CYAN}📜 Available containers to view logs for:${NC}"
        select container in $containers; do
            if [ -n "$container" ]; then
                echo -e "${CYAN}📜 Showing logs for container: $container...${NC}"
                docker logs "$container"
                break
            else
                echo -e "${RED}❌ Invalid choice.${NC}"
            fi
        done
    fi
fi
