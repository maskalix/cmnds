#!/bin/bash

# Function to create, edit, and execute a script
rec() {
    # Check if filename argument is provided
    if [ -z "$1" ]; then
        echo "Usage: rec <filename>"
        exit 1
    fi

    # Check if the file already exists
    if [ -f "$1" ]; then
        # If file exists, ask the user whether to delete it or abort
        read -p "File \"$1\" already exists. Do you want to delete it and create a new one? (yes/no): " choice
        case "$choice" in
            yes|YES|Yes)
                # If the user chooses to delete, remove the existing file
                rm "$1"
                ;;
            *)
                # If the user chooses not to delete or enters an invalid choice, exit
                echo "Aborted."
                exit 0
                ;;
        esac
    fi

    # Open file in Nano
    nano "$1"

    # Get the file extension
    file_extension="${1##*.}"

    # Make the file executable if it's a shell script
    if [ "$file_extension" == "sh" ]; then
        chmod +x "$1"
    fi

    # Execute the file if it's executable
    if [ -x "$1" ]; then
        if [[ "$1" == */* ]]; then
            "$1"
        else
            "./$1"
        fi
    else
        echo "File \"$1\" is not executable. You may need to make it executable manually."
    fi
}

# Call the function with the provided filename argument
rec "$1"
