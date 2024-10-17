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

    # Get the total number of files to be copied
    total_files=$(find "$source_dir" -type f | wc -l)
    current_file=0

    # Copy files from source subfolder to target subfolder
    for file in "$source_dir"/*; do
        if [ -f "$file" ]; then
            ((current_file++))
            rsync --progress "$file" "$target_dir/$subfolder_name/"
            
            # Calculate progress percentage
            percentage=$((100 * current_file / total_files))
            echo -ne "Progress: $percentage% ($current_file/$total_files)\r"
        fi
    done
    echo -ne "\n" # Move to a new line after progress is complete
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
        # Transfer files from each subfolder with progress
        transfer_files "$subfolder" "$transfer_dir"
    fi
done

echo "Transfer completed."
