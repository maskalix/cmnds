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

# Function to create transfer directory if it doesn't exist
create_transfer_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "Transfer directory created: $dir"
    fi
}

# Function to transfer files from subfolders with progress bar
transfer_files() {
    local source_dir="$1"
    local target_dir="$2"
    local subfolder_name=$(basename "$source_dir")
    
    # Create target subfolder in transfer directory if it doesn't exist
    mkdir -p "$target_dir/$subfolder_name"
    echo "Transfer directory created: $target_dir/$subfolder_name"
    
    # Copy files from source subfolder to target subfolder
    for file in "$source_dir"/*; do
        if [ -f "$file" ]; then
            cp "$file" "$target_dir/$subfolder_name/"
        fi
    done
}

# Ask for main folder path
echo "This tool copies only files not folders!"
echo "Enter the source folder path:"
read main_folder
main_folder=$(validate_directory "$main_folder")

# Ask for transfer directory path
echo "Enter the destination directory path:"
read transfer_dir
transfer_dir=$(validate_directory "$transfer_dir")

# Create transfer directory if it doesn't exist
create_transfer_directory "$transfer_dir"

# Loop through subfolders of main folder
for subfolder in "$main_folder"/*; do
    if [ -d "$subfolder" ]; then
        # transfer files from each subfolder with progress
        transfer_files "$subfolder" "$transfer_dir"
    fi
done

echo "Transfer completed."
