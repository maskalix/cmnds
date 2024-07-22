#!/bin/bash

# Configuration file
RCMOUNT_FILE="/data/scripts/cmnds/files/rcmount"

# Associative array to store remote mounts
declare -A REMOTE_MOUNTS

# Function to update rcmount file with data from rclone listremotes
update_rcmount_file() {
    echo "Updating $RCMOUNT_FILE with data from rclone..."

    # Clear existing content
    > "$RCMOUNT_FILE"

    # Get list of remotes from rclone
    remotes=$(rclone listremotes)

    # Iterate through each remote
    while IFS= read -r remote; do
        # Remove leading and trailing whitespace (if any)
        remote=$(echo "$remote" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # Generate a safe mount path using the remote name
        # Replace special characters with underscores
        modified=$(echo "$remote" | tr -cd '[:alnum:]-' | tr '[:upper:]' '[:lower:]')

        # Append to rcmount file
        echo "$remote /remote/$modified" >> "$RCMOUNT_FILE"
    done <<< "$remotes"

    echo "Updated $RCMOUNT_FILE successfully."
}

# Function to read remote mounts from configuration file
read_rcmount_file() {
    while IFS= read -r line || [[ -n "$line" ]]; do
        remote=$(echo "$line" | awk '{print $1}')
        mount_path=$(echo "$line" | awk '{print $2}')
        REMOTE_MOUNTS["$remote"]=$mount_path
    done < "$RCMOUNT_FILE"
}

# Function to mount remotes
mount_remotes() {
    REMOTE_MOUNTS=$(read_rcmount_file)
    for remote in "${!REMOTE_MOUNTS[@]}"; do
        mount_path="${REMOTE_MOUNTS[$remote]}"
        
        if [ -n "$mount_path" ]; then
            echo -e "Mounting $remote at $mount_path ..."

            # Check if mount path directory exists, otherwise create it
            if [ ! -d "$mount_path" ]; then
                echo "Creating directory $mount_path ..."
                mkdir -p "$mount_path"
            fi

            # Replace 'rclone' with the correct path to your rclone executable if needed
            rclone mount "$remote" "$mount_path" --daemon &
        else
            echo -e "Skipping $remote as it is not configured to be mounted."
        fi
    done
}

# Function to unmount remotes
unmount_remotes() {
    for mount_path in "${REMOTE_MOUNTS[@]}"; do
        if [ -n "$mount_path" ]; then
            echo -e "Unmounting $mount_path ..."
            fusermount -u "$mount_path"
        fi
    done
}

# Function to show current mount state
show_mount_state() {
    echo "Current mount state:"
    for remote in "${!REMOTE_MOUNTS[@]}"; do
        mount_path="${REMOTE_MOUNTS[$remote]}"
        
        if mount | grep -q "$mount_path"; then
            echo -e "  $remote \t- \e[32mMounted\e[0m"
        else
            echo -e "  $remote \t- \e[31mNot mounted\e[0m"
        fi
    done
}

edit() {
    echo "Editing mounts file: ! AT OWN RISK !"
    nano $RCMOUNT_FILE
}

# Main script execution
case "$1" in
    update)
        update_rcmount_file
        ;;
    start)
        read_rcmount_file
        mount_remotes
        ;;
    stop)
        read_rcmount_file
        unmount_remotes
        ;;
    restart)
        read_rcmount_file
        unmount_remotes
        mount_remotes
        ;;
    state)
        read_rcmount_file
        show_mount_state
        ;;
    edit)
        edit
        ;;
    *)
        echo "Usage: $0 {update|start|stop|restart|state|edit}"
        exit 1
        ;;
esac

exit 0
