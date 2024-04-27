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
mkdir -p "$export_dir"

# Function to export files from subfolders
export_files() {
    local folder="$1"
    for file in "$folder"/*; do
        if [ -f "$file" ]; then
            cp "$file" "$export_dir"
        fi
    done
}

# Loop through subfolders of main folder
for subfolder in "$main_folder"/*; do
    if [ -d "$subfolder" ]; then
        # Export files from each subfolder
        export_files "$subfolder"
    fi
done

echo "Export completed."
