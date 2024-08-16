#!/bin/bash

# Define the directory you want to add to the PATH
DIR="/data/scripts/cmnds/commands"

# Define the line to be added to the PATH
EXPORT_LINE="export PATH=\"$DIR:\$PATH\""

# Files to update
FILES_TO_UPDATE=("/etc/profile" "/etc/bash.bashrc" "/etc/profile.d/custom_path.sh")

# Add the export line to each file if not already present
for file in "${FILES_TO_UPDATE[@]}"; do
    if [ -f "$file" ]; then
        if ! grep -qF "$EXPORT_LINE" "$file"; then
            echo "$EXPORT_LINE" >> "$file"
            echo "Added to $file"
        else
            echo "Already present in $file"
        fi
    else
        echo "File $file does not exist, creating it."
        echo "#!/bin/bash" > "$file"
        echo "$EXPORT_LINE" >> "$file"
        chmod +x "$file"
    fi
done

echo "PATH updated for all users. Please log out and log in again to apply changes."
