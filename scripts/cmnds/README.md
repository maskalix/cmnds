# Main CMNDS directory
every script here will be auto-enabled
## CMNDS Variables (cmnds-config)

Command `cmnds-config` has embedded function to R/W variables to `variables.conf`

### Read
inside of other .sh script, two approaches
1. command (RECOMMENDED)
    ```bash
    VAR=$(bash cmnds-config read VAR_NAME)
    ```
2. cmnds root dir (only inside script of cmnds)
    ```bash
    SCRIPT_DIR=$(dirname "$0")
    MANAGE_CONFIG="$SCRIPT_DIR/cmnds-config"
    VAR=$(bash "$MANAGE_CONFIG" read VAR_NAME)
    ```

### Write
inside of other .sh script, two approaches
1. command (RECOMMENDED)
    ```bash
    CONTENT=""
    bash cmnds-config write VAR_NAME "$CONTENT"
    ```
2. cmnds root dir (only inside script of cmnds)
    ```bash
    CONTENT=""
    SCRIPT_DIR=$(dirname "$0")
    MANAGE_CONFIG="$SCRIPT_DIR/cmnds-config"
    bash $MANAGE_CONFIG write VAR_NAME "$CONTENT"
    ```
