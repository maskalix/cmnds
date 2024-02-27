# Define a function named 'up'
up() {
    # ANSI color code for yellow text
    YELLOW='\033[1;33m'
    # ANSI color code to reset text color
    NC='\033[0m'

    # Go up one directory
    cd ..
    # Print message indicating directory change in yellow text
    echo -e "${YELLOW}One up!${NC}"
}
