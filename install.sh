#!/bin/bash

# Function to install dialog if not installed
install_dialog() {
    if ! command -v dialog &>/dev/null; then
        echo "Installing dialog..."
        # Check if the package manager is apt (Debian/Ubuntu)
        if command -v apt &>/dev/null; then
            sudo apt update
            sudo apt install -y dialog
        # Check if the package manager is yum (Red Hat/CentOS)
        elif command -v yum &>/dev/null; then
            sudo yum install -y dialog
        # Check if the package manager is pacman (Arch Linux)
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy --noconfirm dialog
        # If the package manager is not found, prompt the user to install dialog manually
        else
            echo "Error: Unable to determine the package manager. Please install dialog manually and try again."
            exit 1
        fi
    fi
}

# Function to clone the project from GitHub
clone_project() {
    echo "Cloning project from GitHub into $SCRIPTS_DIR..."
    git clone --depth 1 --filter=tree:0 https://github.com/maskalix/cmnds.git "$SCRIPTS_DIR"
    cd "$SCRIPTS_DIR" || exit 1
    git sparse-checkout set --no-cone scripts
    echo "Project cloned successfully."
}

# Function to initialize the project
initialize_project() {
    # Move the contents of the scripts folder to the parent directory
    mv "$SCRIPTS_DIR/scripts"/* "$SCRIPTS_DIR"/
    # Remove the now-empty scripts folder
    rmdir "$SCRIPTS_DIR/scripts"
    # Update deploy.sh with customized directories
    sed -i "s|SCRIPTS_DIR=.*|SCRIPTS_DIR=\"$SCRIPTS_DIR\"|g" "$SCRIPTS_DIR/deploy.sh"
    sed -i "s|COMMANDS_DIR=.*|COMMANDS_DIR=\"$SCRIPTS_DIR/commands\"|g" "$SCRIPTS_DIR/deploy.sh"
    # Make deploy.sh executable
    chmod +x "$SCRIPTS_DIR/deploy.sh"
    # Add $SCRIPTS_DIR/commands to ~/.bashrc if not already there
    if ! grep -q "$SCRIPTS_DIR/commands" ~/.bashrc; then
        echo "export PATH=\"$SCRIPTS_DIR/commands:\$PATH\"" >> ~/.bashrc
    fi
    # Source ~/.bashrc
    source ~/.bashrc
    echo "Project initialized successfully."
}

# Function to prompt user for SCRIPTS_DIR
prompt_scripts_dir() {
    read -rp "Enter preferred directory for scripts (default: /data/scripts): " SCRIPTS_DIR
    SCRIPTS_DIR=${SCRIPTS_DIR:-"/data/scripts"}
}

# Function to create SCRIPTS_DIR if it doesn't exist
create_scripts_dir() {
    if [ -d "$SCRIPTS_DIR" ]; then
        echo "Directory already exists: $SCRIPTS_DIR"
        read -rp "Do you want update the script? It will delete the existing directory and create a new one? (y/n): " choice
        case "$choice" in
            [yY]|[yY][eE][sS])
                echo "Deleting existing directory: $SCRIPTS_DIR"
                rm -rf "$SCRIPTS_DIR"
                mkdir -p "$SCRIPTS_DIR"
                ;;
            *)
                echo "Exiting installation process."
                exit 1
                ;;
        esac
    else
        echo "Creating directory: $SCRIPTS_DIR"
        mkdir -p "$SCRIPTS_DIR"
    fi
}


# Function to run deploy.sh
run_deploy() {
    echo "Running deploy.sh..."
    "$SCRIPTS_DIR/deploy.sh"
    echo "deploy.sh executed successfully."
}

# Main function to execute installation process
install_project() {
    install_dialog
    prompt_scripts_dir
    create_scripts_dir
    clone_project
    initialize_project
    run_deploy
    source ~/.bashrc
    echo "Installation completed successfully."
}

# Run installation process
install_project

# Add the script to PATH and source .bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
