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
- between releases/tags is published 100% working, tho old release of cmnds; if you want to use the new one, use command higher to install it
- i don't plan to make cmnds available to be installed from any package manager such as apt
- script can overwrite some of your commands - USE AT OWN RISK
- asking for feature? => create an issue
- cmnds "installs" itself into PATH, after removing it (simply just remove all it's folders - will automate it in the future) clean its record here too
## Installation
```bash
wget --no-cache https://raw.githubusercontent.com/maskalix/cmnds/main/install.sh && chmod +x install.sh && ./install.sh && rm install.sh
```
## Using
### For base-user (non-root)
- run `sudo su && cmnds-nonroot`
- next as root
### For root
- using command `deploy` choose what scripts you want to enable (remember to put asterisk to deploy too, if you want to use it)
- if you didn't activate `deploy`, simply go into the folder of installation and run `./deploy.sh`
- **LIST OF COMMANDS <a href="https://github.com/maskalix/cmnds/blob/main/scripts/README.md">/scripts/README.md</a>**

## Updating 
- using `deploy` enable `cmnds-update`
- run `cmnds-update` and proceed in installation

## Custom commands
- feel free to add own commands into the root folder of CMNDS or into subdirectory
- it must be in .sh format, then it will be registered by `deploy.sh` (`deploy`) command 

## Command not found
- option 1
   -  run `source ~/.bashrc`, sometimes more than once :/
- option 2
   - close and reconnect to SSH
---
© Martin Skalicky 2024
