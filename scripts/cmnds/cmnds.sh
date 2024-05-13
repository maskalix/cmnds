#!/bin/bash

# Function to display help message
show_help() {
    echo "Usage: $0 [option]"
    echo "Options:"
    echo "  -h  : Display help message"
    echo "  -u  : Update CMNDS"
}

# Function to list all scripts in the same directory as cmnds.sh
list_commands() {
    echo "Available commands:"
    for file in $(dirname "$0")/*.sh; do
        if [ "$file" != "$0" ]; then
            echo "$(basename "$file" .sh)"
        fi
    done
}

# Function to run cmnds-update
run_update() {
    echo "Running update..."
    if [ "$1" == "-s" ]; then
        echo -e "\n\ny\n\n"
    fi
    cmnds-update
}

# Function to get version number from ../version file
get_version() {
    if [ -f "../version" ]; then
        echo "($(cat ../version))"
    else
        echo "(unknown)"
    fi
}

# If no arguments are provided, print version number and show help message
if [ $# -eq 0 ]; then
    echo "CMNDS version alpha $(get_version)"
    show_help
    exit 0
fi

# Parse command-line options
while getopts ":hu:" opt; do
    case $opt in
        h)  show_help
            exit 0
            ;;
        u)  run_update "$OPTARG"
            exit 0
            ;;
        :)  echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# If an unknown argument is provided
if [ $OPTIND -eq 1 ]; then
    echo "Invalid option. Use '-h' for help."
    exit 1
fi
