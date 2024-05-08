#!/bin/bash

# Function to create aliases for apt commands
a() {
    # Convert hyphens to spaces
    local command="${1//-/ }"
    shift

    case "$command" in
        i|install)
            apt install "$@"
            ;;
        u|update)
            apt update
            ;;
        ug|upgrade)
            apt upgrade
            ;;
        r|remove)
            apt remove "$@"
            ;;
        p|purge)
            apt purge "$@"
            ;;
        au|autoremove)
            apt autoremove
            ;;
        c|clean)
            apt clean
            ;;
        ac|autoclean)
            apt autoclean
            ;;
        s|source)
            apt source "$@"
            ;;
        -h|--help)
            display_help
            ;;
        *)
            echo "Invalid command. Use '-h' or '--help' to display available commands."
            ;;
    esac
}

# Function to display help message
display_help() {
    cat << EOF
Usage: a <command> [arguments]

Commands:
  i, install      Install a package
  u, update       Update the list of available packages
  ug, upgrade     Upgrade installed packages
  r, remove       Remove a package
  p, purge        Remove a package along with its configuration files
  au, autoremove  Remove unused packages
  c, clean        Clear out the local repository of retrieved package files
  ac, autoclean   Clear out the local repository of retrieved package files, but only remove package files that can no longer be downloaded
  s, source       Download the source code for a package
  -h, --help      Display this help message
EOF
}

# Call the function with the provided command and arguments
a "$@"
