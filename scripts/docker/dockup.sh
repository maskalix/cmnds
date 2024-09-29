#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

# Function to show a progress bar
show_progress() {
    local current=$1
    local total=$2
    if (( total > 0 )); then
        local progress=$((current * 100 / total))
        local bar_length=50  # Length of the progress bar
        local filled_length=$((progress * bar_length / 100))
        local bar=""

        # Create the progress bar
        for ((i=0; i<filled_length; i++)); do
            bar+="#"
        done
        for ((i=filled_length; i<bar_length; i++)); do
            bar+=" "
        done

        # Print the current image and progress bar
        printf "\rChecking for updates on image: %s\n" "$current_image"
        printf "[%-${bar_length}s] %d%%" "$bar" "$progress"
    fi
}

# Function to check for updates
check_updates() {
    updates=()
    echo -e "${CYAN}Checking for updates...${RESET}"
    
    # Get the list of Docker images
    local total_images=$(docker images --format "{{.Repository}}:{{.Tag}}" | wc -l)
    if (( total_images == 0 )); then
        echo -e "${RED}No Docker images found.${RESET}"
        return
    fi

    local current_image=0

    docker images --format "{{.Repository}}:{{.Tag}}" | while read -r image; do
        current_image=$((current_image + 1))

        # Clear previous output
        printf "\033c" # Clear the screen
        
        # Display current image and initialize the progress bar
        echo -e "${YELLOW}Checking for updates on image: ${MAGENTA}$image...${RESET}"
        
        # Check for newer versions available
        if docker pull "$image" 2>&1 | grep "Downloaded newer image" > /dev/null; then
            updates+=("$image")
        fi
        
        # Show progress
        show_progress "$current_image" "$total_images"
        sleep 1  # Simulate some delay for visibility
    done

    printf "\n"  # Move to the next line after the progress bar
    echo -e "${GREEN}Update check completed.${RESET}"
    
    if [ ${#updates[@]} -eq 0 ]; then
        echo -e "${RED}No updates available.${RESET}"
    else
        echo -e "${CYAN}Available updates:${RESET}"
        for update in "${updates[@]}"; do
            echo -e "${MAGENTA}$update${RESET}"
        done
    fi
}

# Function to update a specific container
update_container() {
    local container=$1
    echo -e "${YELLOW}Updating container: ${MAGENTA}$container...${RESET}"
    if docker pull "$container" | grep "Downloaded newer image" > /dev/null; then
        echo -e "${GREEN}$container updated.${RESET}"
    else
        echo -e "${GREEN}$container is already up to date.${RESET}"
    fi
}

# Function to update selected containers
update_selection() {
    echo -e "${CYAN}Available Docker Containers:${RESET}"
    docker images --format "{{.Repository}}:{{.Tag}}"
    
    read -p "Enter the containers to update (separated by space): " -a containers
    local total_containers=${#containers[@]}
    
    if (( total_containers == 0 )); then
        echo -e "${RED}No containers selected for update.${RESET}"
        return
    fi

    local current_container=0

    for container in "${containers[@]}"; do
        current_container=$((current_container + 1))
        
        # Clear previous output and print current container being updated
        printf "\033c" # Clear the screen
        echo -e "${YELLOW}Updating container: ${MAGENTA}$container...${RESET}"
        update_container "$container"
        show_progress "$current_container" "$total_containers"
        sleep 1  # Simulate some delay for visibility
    done

    printf "\n"  # Move to the next line after the progress bar
    echo -e "${GREEN}Selected containers update completed.${RESET}"
}

# Function to update all containers
update_all_containers() {
    all_images=$(docker images --format "{{.Repository}}:{{.Tag}}")
    local total_images=$(echo "$all_images" | wc -l)
    
    if (( total_images == 0 )); then
        echo -e "${RED}No Docker images found.${RESET}"
        return
    fi

    local current_image=0
    echo -e "${CYAN}Updating all containers...${RESET}"

    for image in $all_images; do
        current_image=$((current_image + 1))
        
        # Clear previous output and print current image being updated
        printf "\033c" # Clear the screen
        echo -e "${YELLOW}Updating image: ${MAGENTA}$image...${RESET}"
        update_container "$image"
        show_progress "$current_image" "$total_images"
        sleep 1  # Simulate some delay for visibility
    done

    printf "\n"  # Move to the next line after the progress bar
    echo -e "${GREEN}All containers updated successfully.${RESET}"
}

# Function for console menu
main_menu() {
    while true; do
        printf "\033c"  # Clear the screen
        echo -e "${BLUE}========================${RESET}"
        echo -e "  ${CYAN}Docker Update Manager${RESET}  "
        echo -e "${BLUE}========================${RESET}"
        echo -e "${YELLOW}1. Check for Updates${RESET}"
        echo -e "${YELLOW}2. Update Selected Containers${RESET}"
        echo -e "${YELLOW}3. Update All Containers${RESET}"
        echo -e "${YELLOW}4. Exit${RESET}"
        read -p "Select an option [1-4]: " choice

        case $choice in
            1)
                check_updates
                read -p "Press any key to continue... " -n1 -s
                echo
                ;;
            2)
                update_selection
                read -p "Press any key to continue... " -n1 -s
                echo
                ;;
            3)
                update_all_containers
                read -p "Press any key to continue... " -n1 -s
                echo
                ;;
            4)
                echo -e "${GREEN}Exiting...${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option selected. Please try again.${RESET}"
                ;;
        esac
    done
}

# Start the main menu
main_menu
