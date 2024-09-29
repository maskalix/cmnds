#!/bin/bash

# Function to check for updates
check_updates() {
    updates=()
    # Get the list of Docker images
    docker images --format "{{.Repository}}:{{.Tag}}" | while read -r image; do
        # Check for newer versions available
        local latest=$(docker pull "$image" 2>&1 | grep "Downloaded newer image" | wc -l)
        if [ "$latest" -eq 1 ]; then
            updates+=("$image")
        fi
    done
    echo "${updates[@]}"
}

# Function to update a specific container
update_container() {
    local container=$1
    echo "Updating $container..."
    docker pull "$container"
}

# Function to update selected containers
update_selection() {
    echo "Available Docker Containers:"
    docker images --format "{{.Repository}}:{{.Tag}}"
    
    read -p "Enter the containers to update (separated by space): " -a containers
    for container in "${containers[@]}"; do
        update_container "$container"
    done
}

# Function to update all containers
update_all_containers() {
    all_images=$(docker images --format "{{.Repository}}:{{.Tag}}")
    for image in $all_images; do
        update_container "$image"
    done
    echo "All containers updated."
}

# Function for console menu
main_menu() {
    while true; do
        echo "========================"
        echo "  Docker Update Manager  "
        echo "========================"
        echo "1. Check for Updates"
        echo "2. Update Selected Containers"
        echo "3. Update All Containers"
        echo "4. Exit"
        read -p "Select an option [1-4]: " choice

        case $choice in
            1)
                updates=$(check_updates)
                if [ -z "$updates" ]; then
                    echo "No updates available."
                else
                    echo "Available updates:"
                    echo "$updates"
                fi
                ;;
            2)
                update_selection
                ;;
            3)
                update_all_containers
                ;;
            4)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option selected. Please try again."
                ;;
        esac
        echo ""
    done
}

# Start the main menu
main_menu
