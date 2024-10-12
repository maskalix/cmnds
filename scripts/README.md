**As of now it is highly recommended to NOT change cmnds installation folder (def. /data/scripts/cmnds), can cause errors - scripts are now in rework to load everything from variables, tho, still not completely, will be published in stable release 1.0**

# Commands
- run any command without parameters (or better with <cmnd_name> help) to show help message

| Category      | Command              | Description                                       | Options                                                                                     |
|---------------|----------------------|---------------------------------------------------|--------------------------------------------------------------------------------------------|
| **<a href="./cmnds">CMNDS</a>**     | `cmnds [OPTIONS]`    | CMNDS Info                                        | `-a` : list all commands<br>`-u / cmnds-update`: update<br>`-d / cmnds-update`: deploy<br>`-c / cmnds-config`: config vars<br>`-n / cmnds-nonroot`: register CMNDs for non-root users                            |
| **Docker**    | `bicomposed`         | docker compose up -d --build                      |                                                                                            |
|               | `composed`           | docker compose up -d                              |                                                                                            |
|               | `decompose`          | docker compose down                              |                                                                                            |
|               | `ecompose`           | nano docker-compose.yml                          |                                                                                            |
|               | `recompose`          | docker compose down && docker compose up -d       |                                                                                            |
|               | `prjkt [OPTIONS]`    | Manage project directories                       | `-n [project_name]`: Create new project directorybr>`-c`: Open 'docker-compose.yml' in nano (use after `-n`)<br>`-u`: Run docker compose up -d (use after `-n`)<br>`-v [project_name]`: View project docker-compose.yml<br>`-d [project_name]`: Decompose specified project<br>`-r [project_name]`: Remove specified project directory<br>`-h`: Display this help message |
| **<a href="./revpro">Reverse proxy</a>**     | `revpro`                | NGINX shortcut with easy-to-use reverseproxy management                   |                                                                                            |
|               | `certgen [OPTIONS]`                | Tool to create signed certificate by own CA                |         `-d <domain.tld> -d <*.domain.tld> --years <validity_years> --country <country_code> --state <state> --organization <organization_name> [--alt <alt_domain> ...]`                                                                                   |
| **Files**     | `mcd`                | Make directory and change to it                   |                                                                                            |
|               | `rcmount [OPTIONS]`             | Manage rclone mounts                             | `update/start/stop/restart/state` - Update, start, stop, restart, or show state for rclone mounts |
|               | `rec`                | Remove, edit (nano) and chmod +x if .sh           |                                                                                            |
|               | `cpc`                | Copy files from folder to another with progress |                                                                                            |
|   **System**            | `perf`               | Show PC performance                              |                                                                                            |
|      | `a [OPTIONS] [-y]`                  | Apt package manager                               | Usage: `a [-y] <command> [arguments]`<br>Commands:<br>`i, install`: Install a package<br>`u, update`: Update the list of available packages<br>`ug, upgrade`: Upgrade installed packages<br>`r, remove`: Remove a package<br>`p, purge`: Remove a package along with its configuration files<br>`au, autoremove`: Remove unused packages<br>`c, clean`: Clear out the local repository of retrieved package files<br>`ac, autoclean`: Clear out the local repository of retrieved package files, but only remove package files that can no longer be downloaded<br>`s, source`: Download the source code for a package<br>`h, help`: Display this help message<br>Options:<br>`-y`: Automatically answer 'yes' to prompts |
|               | `update [-y]`             | Update tasks                                     | `apt update + upgrade + restore Docker (if available)`                                         |
|  **Other**    | `ssh-init`             | Prepare everything for SSH connection to server                                    |                                         |



# Currently working on automatizing installation and initialization for all tools
## revpro
- you need to create folder /revpro
## prjkt
- recommended (not needed) is to create /data/misc where inside ./project-name it will create project data (docker compose files etc.)
## update
- it updates & upgrades all packages with optional docker restoration (for cases where you have custom docker deamon.js - so it stops docker, copies back your modified and starts it again) - you need file /data/scripts/docker-recover.sh

## other commands
- to add to the list: dockup, smartchck, cert, revpro-init
