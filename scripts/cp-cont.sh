#!/bin/bash

# Function to validate directory existence
validate_directory() {
    local dir="$1"
    while [ ! -d "$dir" ]; do
        echo "Directory not found. Please enter a valid directory path:"
        read dir
    done
    echo "$dir"
}

# Function to create export directory if it doesn't exist
create_export_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "Export directory created: $dir"
    fi
}

# Function to export files from subfolders with progress bar
export_files() {
    local source_dir="$1"
    local target_dir="$2"
    local subfolder_name=$(basename "$source_dir")
    
    # Create target subfolder in export directory if it doesn't exist
    mkdir -p "$target_dir/$subfolder_name"
    echo "Export directory created: $target_dir/$subfolder_name"
    
    # Copy files from source subfolder to target subfolder with progress
    rsync -a --progress "$source_dir"/* "$target_dir/$subfolder_name/"
}

# Ask for main folder path
echo "This tool copies only files not folders!"
echo "Enter the main folder path:"
read main_folder
main_folder=$(validate_directory "$main_folder")

# Ask for export directory path
echo "Enter the export directory path:"
read export_dir
export_dir=$(validate_directory "$export_dir")

# Create export directory if it doesn't exist
create_export_directory "$export_dir"

# Loop through subfolders of main folder
for subfolder in "$main_folder"/*; do
    if [ -d "$subfolder" ]; then
        # Export files from each subfolder with progress
        export_files "$subfolder" "$export_dir"
    fi
done

echo "Export completed."
