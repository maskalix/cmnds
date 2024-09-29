#!/bin/bash

# Function to check for updates
check_updates() {
    docker images --format "{{.Repository}}:{{.Tag}}" | while read -r image; do
        # Check for newer versions available
        local latest=$(docker pull "$image" | grep "Downloaded newer image" | wc -l)
        if [ "$latest" -eq 1 ]; then
            echo "$image"
        fi
    done
}

# Function to update a specific container
update_container() {
    local container=$1
    echo "Updating $container..."
    docker pull "$container"
}

# Function to get user selection and perform updates
update_selection() {
    local selected_containers=$(zenity --list --checklist \
        --title="Select Docker Containers to Update" \
        --column="Update" --column="Container" \
        $(docker images --format "false|{{.Repository}}:{{.Tag}}" | sed 's/|/ FALSE /g'))

    if [ "$selected_containers" ]; then
        IFS='|' read -ra containers <<< "$selected_containers"
        for container in "${containers[@]}"; do
            update_container "$container"
        done
        zenity --info --text="Selected containers updated."
    else
        zenity --error --text="No containers selected."
    fi
}

# Function for GUI options
main_menu() {
    choice=$(zenity --list --title="Docker Update Manager" \
        --column="Action" \
        "Check for Updates" \
        "Update Selected Containers" \
        "Update All Containers" \
        "Exit")

    case $choice in
        "Check for Updates")
            updates=$(check_updates)
            if [ -z "$updates" ]; then
                zenity --info --text="No updates available."
            else
                zenity --info --text="Available updates:\n$updates"
            fi
            main_menu
            ;;
        "Update Selected Containers")
            update_selection
            main_menu
            ;;
        "Update All Containers")
            all_images=$(docker images --format "{{.Repository}}:{{.Tag}}")
            for image in $all_images; do
                update_container "$image"
            done
            zenity --info --text="All containers updated."
            main_menu
            ;;
        "Exit")
            exit 0
            ;;
        *)
            zenity --error --text="Invalid option selected."
            main_menu
            ;;
    esac
}

# Start the main menu
main_menu
