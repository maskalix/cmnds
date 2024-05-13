#!/bin/bash

# Function to display help information
show_help() {
    echo "Usage: prjkt.sh [option] [project_name] [directory_path]"
    echo ""
    echo "Options:"
    echo "  -n [project_name] [directory_path]   Create a new project directory."
    echo "  -c                                   Open 'docker-compose.yml' in nano (use after -n)."
    echo "  -r [project_name]                    Remove the specified project directory."
    echo "  -h                                   Display this help message."
}

# Default project directory
default_dir="/data/misc/"

# Check for no options
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Parse command line options
while getopts ":n:cr:h" opt; do
    case ${opt} in
        n)
            project_name="$OPTARG"
            read -rp "Enter preferred directory (default: $default_dir): " custom_dir
            dir=${custom_dir:-$default_dir}
            # Prompt user for confirmation
            read -p "Create project directory '$project_name' in '$dir'? [Y/n] " confirm
            confirm=${confirm:-Y}  # Default to 'Y' if user just presses enter
            if [[ $confirm =~ ^[Yy]$ ]]; then
                mkdir -p "$dir/$project_name"
                cd "$dir/$project_name"
            else
                echo "Operation cancelled."
                exit 1
            fi
            ;;
        c)
            # Ensure the docker-compose file is opened only if the -n option was used before -c
            if [ -n "$project_name" ]; then
                nano "docker-compose.yml"
            else
                echo "Error: '-c' must be used after '-n [project_name] [directory_path]'"
                exit 1
            fi
            ;;
        r)
            rm -rf "$OPTARG"
            ;;
        h)
            show_help
            ;;
        \?)
            echo "Invalid option: $OPTARG" 1>&2
            show_help
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." 1>&2
            show_help
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))
