#!/bin/bash

# Check if NAME is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 NAME"
    exit 1
fi

NAME=$1

# Unmount the filesystem
if ! umount "$NAME"; then
    echo "Failed to unmount $NAME"
    exit 1
fi

# Remount all filesystems listed in /etc/fstab
if ! mount -a; then
    echo "Failed to mount filesystems listed in /etc/fstab"
    exit 1
fi

echo "Successfully remounted $NAME and all other filesystems."
