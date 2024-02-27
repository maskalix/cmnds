#!/bin/bash

# Function to clone the project from GitHub
clone_project() {
    echo "Cloning project from GitHub..."
    git clone https://github.com/maskalix/cmnds/tree/main/scripts%20 "$SCRIPTS_DIR"
    echo "Project cloned successfully."
}

# Function to initialize the project
initialize_project() {
    # Update deploy.sh with customized directories
    sed -i "s|SCRIPTS_DIR=.*|SCRIPTS_DIR=\"$SCRIPTS_DIR\"|g" "$SCRIPTS_DIR/deploy.sh"
    sed -i "s|COMMANDS_DIR=.*|COMMANDS_DIR=\"$SCRIPTS_DIR/commands\"|g" "$SCRIPTS_DIR/deploy.sh"

    echo "Project initialized successfully."
}

# Main function to execute installation process
install_project() {
    initialize_project
    clone_project

    echo "Installation completed successfully."
}

# Set the default SCRIPTS_DIR
SCRIPTS_DIR="/data/scripts"

# Run installation process
install_project
