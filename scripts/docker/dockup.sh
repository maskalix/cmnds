#!/bin/bash

# Function to show a progress bar
show_progress() {
    local current=$1
    local total=$2
    local progress=$((current * 100 / total))
    local bar_length=50  # Length of the progress bar
    local filled_length=$((progress * bar_length / 100))
    local bar=$(printf "%-${bar_length}s" "#" | sed "s/ /#/g; s/#/=/g; s/=/ /$filled_length; s/=/=/g")

    printf "\r[%-${bar_length}s] %d%%" "$bar" "$progress"
}

# Function to check for updates
check_updates() {
    updates=()
    echo "Checking for updates..."
    local total_images=$(docker images --format "{{.Repository}}:{{.Tag}}" | wc -l)
    local current_image=0
    
    # Get the list of Docker images
    docker images --format "{{.Repository}}:{{.Tag}}" | while read -r image; do
        current_image=$((current_image + 1))
        echo "Checking $image..."
        # Check for newer versions available
        local latest=$(docker pull "$image" 2>&1 | grep "Downloaded newer image" | wc -l)
        show_progress $current_image $total_images
        if [ "$latest" -eq 1 ]; then
            updates+=("$image")
        fi
    done
    echo -e "\nUpdate check completed."
    echo "${updates[@]}"
}

# Function to update a specific container
update_container() {
    local container=$1
    echo "Updating $container..."
    docker pull "$container" | grep "Downloaded newer image" || echo "$container is already up to date."
}

# Function to update selected containers
update_selection() {
    echo "Available Docker Containers:"
    docker images --format "{{.Repository}}:{{.Tag}}"
    
    read -p "Enter the containers to update (separated by space): " -a containers
    local total_containers=${#containers[@]}
    local current_container=0

    for container in "${containers[@]}"; do
        current_container=$((current_container + 1))
        update_container "$container"
        show_progress $current_container $total_containers
    done
    echo -e "\nSelected containers update completed."
}

# Function to update all containers
update_all_containers() {
    all_images=$(docker images --format "{{.Repository}}:{{.Tag}}")
    local total_images=$(echo "$all_images" | wc -l)
    local current_image=0
    echo "Updating all containers..."

    for image in $all_images; do
        current_image=$((current_image + 1))
        update_container "$image"
        show_progress $current_image $total_images
    done
    echo -e "\nAll containers updated successfully."
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
