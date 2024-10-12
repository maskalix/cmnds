# CMNDS - Simple commands to ease using Linux server
```
   ______ __  ___ _   __ ____  _____
  / ____//  |/  // | / // __ \/ ___/
 / /    / /|_/ //  |/ // / / /\__ \ 
/ /___ / /  / // /|  // /_/ /___/ / 
\____//_/  /_//_/ |_//_____//____/

Simple commands to ease using Linux server                            
```                                
# IMPORTANT
- always read <a href="https://github.com/maskalix/cmnds/blob/main/scripts/README.md">/scripts/README.md</a>, where are important informations about usage of each command etc.
- i don't plan to make cmnds available to be installed from any package manager such as apt
- script can overwrite some of your commands - USE AT OWN RISK
- asking for feature? => create an issue
- cmnds "installs" itself into PATH, after removing it (simply just remove all it's folders - will automate it in the future) clean its record here too
## Installation
- Option 1: download install.sh and run it
- **Option 2 (recommended)**:
   ```bash
   mkdir $HOME/cmnds-temp && wget --no-cache -q https://raw.githubusercontent.com/maskalix/cmnds/main/install.sh -P $HOME/cmnds-temp && chmod +x $HOME/cmnds-temp/install.sh && $HOME/cmnds-temp/install.sh && rm $HOME/cmnds-temp/install.sh
   ```
- Option 3 (old):
   ```bash
   wget --no-cache https://raw.githubusercontent.com/maskalix/cmnds/main/install.sh && chmod +x install.sh && ./install.sh && rm install.sh
   ```
## Using
### For base-user (non-root)
1. run `sudo su && cmnds-nonroot`
2. same as root
### For root
1. using command `cmnds -d` choose what scripts you want to enable *[(**c**)hoose/(**d**)isable all/(**e**)nable all]*
   - remember to put asterisk to deploy too, if you want to use it
  
## List of commands
   <a href="https://github.com/maskalix/cmnds/blob/main/scripts/README.md">/scripts/README.md</a>

## Updating 
- run `cmnds -u` and proceed in installation

## Custom commands
- feel free to add own commands into the root folder of CMNDS or into subdirectory
- it must be in .sh format, then it will be registered by `cmnds -d` command
- THEY WILL BE OVERWRITTEN BY UPDATING CMNDS!
- i also recommend checking out my other repository with random scripts (mainly for Debian-based distros)
   - https://github.com/maskalix/commands-pile

## Command not found
- option 1
   -  run `source ~/.bashrc`, sometimes more than once :/
- option 2
   - close and reconnect to SSH
---
© Martin Skalicky 2024
