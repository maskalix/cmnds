#!/bin/bash

# Colors
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
LIGHT_PURPLE='\033[1;35m'
BLUE='\e[1;34m'

# Error msg
msg_error() {
    echo -e "${RED}$1${NC}"
}

# Success msg
msg_success() {
    echo -e "${GREEN}$1${NC}"
}

# Info msg
msg_info() {
    echo -e "${YELLOW}$1${NC}"
}

# Other msg
msg_other() {
    echo -e "${LIGHT_PURPLE}$1${NC}"
}

cmnds() {
    echo -e "${GREEN}   ________  ____   ______  _____\n  / ____/  |/  / | / / __ \/ ___/\n / /   / /|_/ /  |/ / / / /\__ \ \n/ /___/ /  / / /|  / /_/ /___/ /\n\____/_/  /_/_/ |_/_____//____/${NC}"
    echo -e "${GREEN}CMNDs installer tool${NC}"
    echo -e "${GREEN}>> created by Martin Skalicky"
    echo -e ">> GitHub → @maskalix${NC}"
    echo -e ">> alpha release\n"
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
    msg_info "◌ Cloning project from GitHub into $SCRIPTS_DIR..."
    if [ -d "$SCRIPTS_DIR" ]; then      
        git clone --depth 1 --filter=tree:0 https://github.com/maskalix/cmnds.git "$SCRIPTS_DIR" > /dev/null 2>&1
        cd "$SCRIPTS_DIR" || exit 1
        git log --format=%cd --date=format-local:"%Y-%m-%d %H:%M:%S" -1 > version
        cd "$SCRIPTS_DIR" || exit 1
        git sparse-checkout set --no-cone scripts > /dev/null 2>&1
        msg_success "✔ Project cloned successfully."
    else
        msg_error "✖ Project cloning error"
    fi
}

# Function to initialize the project
initialize_project() {
    # Move the contents of the scripts folder to the parent directory
    mv "$SCRIPTS_DIR/scripts"/* "$SCRIPTS_DIR"/
    # Remove the now-empty scripts folder
    rmdir "$SCRIPTS_DIR/scripts"
    # Update cmnds-deploy.sh with customized directories
    sed -i "s|SCRIPTS_DIR=.*|SCRIPTS_DIR=\"$SCRIPTS_DIR\"|g" "$SCRIPTS_DIR/cmnds/cmnds-deploy.sh"
    sed -i "s|COMMANDS_DIR=.*|COMMANDS_DIR=\"$SCRIPTS_DIR/commands\"|g" "$SCRIPTS_DIR/cmnds/cmnds-deploy.sh"
    # Make cmnds-deploy.sh executable
    chmod +x "$SCRIPTS_DIR/cmnds/cmnds-deploy.sh"
    # Add $SCRIPTS_DIR/commands to ~/.bashrc if not already there
    if ! grep -q "$SCRIPTS_DIR/commands" ~/.bashrc; then
        echo "export PATH=\"$SCRIPTS_DIR/commands:\$PATH\"" >> ~/.bashrc
    fi
    # Source ~/.bashrc
    source ~/.bashrc
    msg_success "✔ Project initialized successfully."
}

create_scripts_dir() {
    if [ -d "$SCRIPTS_DIR" ]; then
        echo -e "${RED}Directory $SCRIPTS_DIR already exists! ${NC}${BLUE}Do you want to update the script?${NC} Deletes existing directory and creates a new one. (${GREEN}y${NC}/${RED}N${NC}): \c"
        read -r choice
        case "$choice" in
            [yY]|[yY][eE][sS])              
                # Check if variables.conf exists and move it out temporarily
                if [ -f "$SCRIPTS_DIR/cmnds/variables.conf" ]; then
                    cp $SCRIPTS_DIR/cmnds/variables.conf $HOME/variables.conf
                    msg_other "✔ variables.conf saved"
                fi
                
                msg_info "◌ Deleting existing directory: $SCRIPTS_DIR"
                rm -rf "$SCRIPTS_DIR"
                mkdir -p "$SCRIPTS_DIR"
                ;;
            *)
                msg_error "Exiting installation process. Goodbye! :x"
                exit 1
                ;;
        esac
    else
        msg_info "◌ Creating directory: $SCRIPTS_DIR"
        mkdir -p "$SCRIPTS_DIR"
    fi
}

prompt_scripts_dir() {
    # If command cmnds exists > find the directory of the "cmnds" command
    if command -v cmnds >/dev/null 2>&1; then    
        CMNDS_LOCATION=$(command -v cmnds)
        echo "CMDNS LOC: $CMNDS_LOCATION"
        CMNDS_DIR=$(dirname "$(command -v cmnds)")
        MANAGE_CONFIG="$CMNDS_DIR/cmnds-config"
        CMNDS_INSTALL_FOLDER=$(bash $CMNDS_DIR/cmnds-config read CMNDS_INSTALL_FOLDER)
        if [[ -n "$CMNDS_INSTALL_FOLDER" ]]; then
            SCRIPTS_DIR="$CMNDS_INSTALL_FOLDER"
            echo -e "⚠ ${BLUE}Using scripts directory (from CMNDS_INSTALL_FOLDER variable):${NC} $SCRIPTS_DIR"
        else
            echo -e "⚠ ${RED}Variable CMNDS_INSTALL_FOLDER not present!${NC} ${BLUE}Enter preferred directory for scripts${NC} (default: /data/scripts/cmnds): \c"
            read -r SCRIPTS_DIR
            SCRIPTS_DIR=${SCRIPTS_DIR:-"/data/scripts/cmnds"}
            echo -e "${BLUE}Using scripts directory: $SCRIPTS_DIR${NC}"
        fi
    else
        echo -e "⚠ ${BLUE}Enter preferred directory for scripts${NC} (default: /data/scripts/cmnds): \c"
        read -r SCRIPTS_DIR
        SCRIPTS_DIR=${SCRIPTS_DIR:-"/data/scripts/cmnds"}
        echo -e "${BLUE}Using scripts directory: $SCRIPTS_DIR${NC}"
    fi
}

# Function to run cmnds-deploy.sh
run_deploy() {
    msg_info "◌ Running cmnds-deploy.sh..."
    "$SCRIPTS_DIR/cmnds/cmnds-deploy.sh"
    msg_success "✔ Commands deployed successfully."
    msg_info "⚠ If commands isn't found, then run multiple times >> ${LIGHT_PURPLE}source ~/.bashrc${NC}"
}

# Main function to execute installation process
install_project() {
    cmnds
    install_dialog
    prompt_scripts_dir
    create_scripts_dir
    clone_project
    initialize_project
    run_deploy
    source ~/.bashrc
    msg_success "✔ Installation completed successfully."
    # Restore variables.conf if it was backed up
    if [ -f $HOME/variables.conf ]; then
        mv $HOME/variables.conf $SCRIPTS_DIR/cmnds/variables.conf
        msg_other "✔ variables.conf restored"
    fi
}

# Run installation process
install_project
