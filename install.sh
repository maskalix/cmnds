#!/bin/bash

 # Reset text color
NC='\033[0m'           

# Error msg
msg_error() {
    RED='\033[0;31m'
    echo -e "${RED}$1${NC}"
}

# Success msg
msg_success() {
    GREEN='\033[0;32m'
    echo -e "${GREEN}$1${NC}"
}

# Info msg
msg_info() {
    YELLOW='\033[1;33m'
    echo -e "${YELLOW}$1${NC}"
}

# Other msg
msg_other() {
    LIGHT_PURPLE='\033[1;35m'
    echo -e "${LIGHT_PURPLE}$1${NC}"
}

# Function to install dialog if not installed
install_dialog() {
    if ! command -v dialog &>/dev/null; then
        msg_info "Installing dialog..."
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
            msg_error "Error: Unable to determine the package manager. Please install dialog manually and try again."
            exit 1
        fi
    fi
}

# Function to clone the project from GitHub
clone_project() {
    msg_info "Cloning project from GitHub into $SCRIPTS_DIR..."
    git clone --depth 1 --filter=tree:0 https://github.com/maskalix/cmnds.git "$SCRIPTS_DIR" > /dev/null 2>&1
    cd "$SCRIPTS_DIR" || exit 1
    git sparse-checkout set --no-cone scripts > /dev/null 2>&1
    msg_success "Project cloned successfully."
}

# Function to initialize the project
initialize_project() {
    # Move the contents of the scripts folder to the parent directory
    mv "$SCRIPTS_DIR/scripts"/* "$SCRIPTS_DIR"/
    # Remove the now-empty scripts folder
    rmdir "$SCRIPTS_DIR/scripts"
    # Update deploy.sh with customized directories
    sed -i "s|SCRIPTS_DIR=.*|SCRIPTS_DIR=\"$SCRIPTS_DIR\"|g" "$SCRIPTS_DIR/cmnds/deploy.sh"
    sed -i "s|COMMANDS_DIR=.*|COMMANDS_DIR=\"$SCRIPTS_DIR/commands\"|g" "$SCRIPTS_DIR/cmnds/deploy.sh"
    # Make deploy.sh executable
    chmod +x "$SCRIPTS_DIR/cmnds/deploy.sh"
    # Add $SCRIPTS_DIR/commands to ~/.bashrc if not already there
    if ! grep -q "$SCRIPTS_DIR/commands" ~/.bashrc; then
        echo "export PATH=\"$SCRIPTS_DIR/commands:\$PATH\"" >> ~/.bashrc
    fi
    # Source ~/.bashrc
    source ~/.bashrc
    msg_success "Project initialized successfully."
}

# Function to prompt user for SCRIPTS_DIR
prompt_scripts_dir() {
    read -rp "Enter preferred directory for scripts (default: /data/scripts/cmnds): " SCRIPTS_DIR
    SCRIPTS_DIR=${SCRIPTS_DIR:-"/data/scripts/cmnds"}
}

# Function to create SCRIPTS_DIR if it doesn't exist
create_scripts_dir() {
    if [ -d "$SCRIPTS_DIR" ]; then
        msg_other "Directory already exists: $SCRIPTS_DIR"
        read -rp "${YELLOW}Do you want to update the script?${NC} It will delete the existing directory and create a new one. (${GREEN}y${NC}/${RED}N${NC}): " choice
        case "$choice" in
            [yY]|[yY][eE][sS])
                msg_info "Deleting existing directory: $SCRIPTS_DIR"
                rm -rf "$SCRIPTS_DIR"
                mkdir -p "$SCRIPTS_DIR"
                ;;
            *)
                msg_error "Exiting installation process."
                exit 1
                ;;
        esac
    else
        msg_info "Creating directory: $SCRIPTS_DIR"
        mkdir -p "$SCRIPTS_DIR"
    fi
}


# Function to run deploy.sh
run_deploy() {
    msg_info "Running deploy.sh..."
    "$SCRIPTS_DIR/cmnds/deploy.sh"
    msg_success "Commands deployed successfully."
    msg_info "If commands isn't found, then run multiple times >> ${LIGHT_PURPLE}source ~/.bashrc${NC}"
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
    msg_success "Installation completed successfully."
}

# Run installation process
install_project
