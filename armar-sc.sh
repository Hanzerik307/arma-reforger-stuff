#!/bin/bash

# armar-sc.sh (CLI-Only Version) - Version 1.2 - 2025-03-26
#
# Copyright (c) 2025 Hanzerik307
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Fixed paths for server files and templates
CONFIG_FILE="$HOME/arma/server.json"       # Main server configuration file
ADDONS_DIR="$HOME/arma/profile/addons"     # Directory where mods are stored
TEMPLATE_DIR="$HOME/.arsc"     # Directory for template files

# Array of predefined scenarios (format: scenarioId|description)
SCENARIOS=(
    "{ECC61978EDCC2B5A}Missions/23_Campaign.conf|Conflict - Everon"
    "{59AD59368755F41A}Missions/21_GM_Eden.conf|Game Master - Everon"
    "{2BBBE828037C6F4B}Missions/22_GM_Arland.conf|Game Master - Arland"
    "{C700DB41F0C546E1}Missions/23_Campaign_NorthCentral.conf|Conflict - Northern Everon"
    "{28802845ADA64D52}Missions/23_Campaign_SWCoast.conf|Conflict - Southern Everon"
    "{DAA03C6E6099D50F}Missions/24_CombatOps.conf|Combat Ops - Arland"
    "{C41618FD18E9D714}Missions/23_Campaign_Arland.conf|Conflict - Arland"
    "{DFAC5FABD11F2390}Missions/26_CombatOpsEveron.conf|Combat Ops - Everon"
    "{3F2E005F43DBD2F8}Missions/CAH_Briars_Coast.conf|Capture & Hold: Briars"
    "{F1A1BEA67132113E}Missions/CAH_Castle.conf|Capture & Hold: Montfort Castle"
    "{589945FB9FA7B97D}Missions/CAH_Concrete_Plant.conf|Capture & Hold: Concrete Plant"
    "{9405201CBD22A30C}Missions/CAH_Factory.conf|Capture & Hold: Almara Factory"
    "{1CD06B409C6FAE56}Missions/CAH_Forest.conf|Capture & Hold: Simon's Wood"
    "{7C491B1FCC0FF0E1}Missions/CAH_LeMoule.conf|Capture & Hold: Le Moule"
    "{6EA2E454519E5869}Missions/CAH_Military_Base.conf|Capture & Hold: Camp Blake"
    "{2B4183DF23E88249}Missions/CAH_Morton.conf|Capture & Hold: Morton"
)

# Colors for terminal output (brighter versions)
RED='\e[91m'     # Bright Red for errors
GREEN='\e[92m'   # Bright Green for success messages
YELLOW='\e[93m'  # Bright Yellow for warnings
CYAN='\e[96m'    # Bright Cyan for active mods
MAGENTA='\e[95m' # Bright Magenta for installed mods
RESET='\e[0m'    # Reset to default terminal color

# Check if jq is installed (required for JSON manipulation)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq is not installed.${RESET}"
    echo "jq is required for editing or viewing JSON configuration files."
    echo "You can still use other features (e.g., managing the service)."
    echo
    read -p "Would you like to: [1] Install jq now, [2] See Help/About, or [3] Continue anyway? (1-3): " JQ_CHOICE
    case $JQ_CHOICE in
        1)
            sudo apt install jq --no-install-recommends
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Successfully installed jq.${RESET}"
            else
                echo -e "${RED}Error: Failed to install jq. Proceeding without it.${RESET}"
            fi
            ;;
        2)
            show_help_about
            ;;
        3)
            echo -e "${GREEN}Continuing without jq.${RESET}"
            ;;
        *)
            echo -e "${RED}Invalid choice. Continuing without jq.${RESET}"
            ;;
    esac
    echo
    read -p "Press Enter to continue..." 
    clear
fi

# Update the server.json file with a jq filter
update_json() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed. Cannot edit JSON configuration.${RESET}"
        return 1
    fi
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Error: $CONFIG_FILE not found. Create it with 'Create Template Files'.${RESET}"
        return 1
    fi
    local filter="$1"
    local slurp_file="$2"
    local tmp_file=$(mktemp)
    if [ -n "$slurp_file" ]; then
        jq --slurpfile mods "$slurp_file" "$filter" "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"
    else
        jq "$filter" "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"
    fi
    # Check if the update succeeded
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Configuration updated successfully. Restart service after all changes are made.${RESET}"
    else
        echo -e "${RED}Error: Failed to update configuration file.${RESET}"
    fi
}

# Validate an IP address format
validate_ip() {
    if [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$1"
        for octet in "${octets[@]}"; do
            if [ "$octet" -gt 255 ] || [ "$octet" -lt 0 ]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Manage the systemd service for the Arma server
manage_service() {
    if ! systemctl --user is-enabled arma.service &>/dev/null; then
        echo -e "${YELLOW}Warning: arma.service is not set up. Use 'Create Template Files' and follow 'Service Setup' in Help/About.${RESET}"
        read -p "Press Enter to continue..." 
        clear
        return 1
    fi
    case $1 in
        start)
            systemctl --user start arma.service && echo -e "${GREEN}Arma service started${RESET}" || echo -e "${RED}Error: Failed to start service${RESET}"
            read -p "Press Enter to continue..." 
            clear
            ;;
        stop)
            systemctl --user stop arma.service && echo -e "${GREEN}Arma service stopped${RESET}" || echo -e "${RED}Error: Failed to stop service${RESET}"
            read -p "Press Enter to continue..." 
            clear
            ;;
        restart)
            systemctl --user restart arma.service && echo -e "${GREEN}Arma service restarted${RESET}" || echo -e "${RED}Error: Failed to restart service${RESET}"
            read -p "Press Enter to continue..." 
            clear
            ;;
        status)
            systemctl --user status arma.service --no-pager -n 0
            read -p "Press Enter to continue..." 
            clear
            ;;
    esac
}

# Create template files for server installation and configuration
create_template_files() {
    echo "This will create template files for installing and running an Arma Reforger server."
    echo "Files will be placed in: $TEMPLATE_DIR"
    echo "- install.sh.template: Script to download server files via steamcmd"
    echo "- steam.txt.template: SteamCMD configuration"
    echo "- start.sh.template: Server startup script"
    echo "- server.json.template: Default server configuration"
    echo "- arma.service.tpl: Systemd service template"
    read -p "Would you like to create these template files? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        mkdir -p "$TEMPLATE_DIR"
        cat > "$TEMPLATE_DIR/install.sh.template" << EOF
#!/bin/bash
/usr/games/steamcmd +force_install_dir $HOME/arma +runscript $HOME/arma/steam.txt
EOF
        cat > "$TEMPLATE_DIR/steam.txt.template" << 'EOF'
@ShutdownOnFailedCommand 1
login anonymous
app_update 1874900 validate
quit
EOF
        cat > "$TEMPLATE_DIR/start.sh.template" << EOF
#!/bin/bash
$HOME/arma/ArmaReforgerServer -config=$HOME/arma/server.json -profile=$HOME/arma/profile -maxFPS=60
EOF
        cat > "$TEMPLATE_DIR/server.json.template" << EOF
{
  "publicAddress": "123.123.123.123",
  "publicPort": 2001,
  "game": {
    "name": "Wyoming 307",
    "password": "GamePassword",
    "passwordAdmin": "AdminPassword",
    "admins": [
      "yourplayeridentityid"
    ],
    "scenarioId": "{DAA03C6E6099D50F}Missions/24_CombatOps.conf",
    "maxPlayers": 6,
    "visible": true,
    "crossPlatform": true,
    "supportedPlatforms": [
      "PLATFORM_PC",
      "PLATFORM_XBL",
      "PLATFORM_PSN"
    ],
    "gameProperties": {
      "serverMaxViewDistance": 1500,
      "serverMinGrassDistance": 50,
      "networkViewDistance": 1000,
      "disableThirdPerson": false,
      "fastValidation": true,
      "battlEye": true,
      "VONDisableUI": false,
      "VONDisableDirectSpeechUI": false,
      "VONCanTransmitCrossFaction": false
    },
    "mods": []
  },
  "operating": {
    "lobbyPlayerSynchronise": true,
    "joinQueue": {
      "maxSize": 2
    },
    "disableNavmeshStreaming": []
  }
}
EOF
        cat > "$TEMPLATE_DIR/arma.service.tpl" << EOF
[Unit]
Description=Arma Reforger Server
After=network.target

[Service]
Type=simple
ExecStart=/home/$USER/arma/start.sh
WorkingDirectory=/home/$USER/arma
Restart=always

[Install]
WantedBy=default.target
EOF
        chmod +x "$TEMPLATE_DIR/install.sh.template" "$TEMPLATE_DIR/start.sh.template"
        echo -e "${GREEN}Template files successfully created in: $TEMPLATE_DIR${RESET}"
        echo "Files: install.sh.template, steam.txt.template, start.sh.template, server.json.template, arma.service.tpl"
        echo "See 'Help/About' for usage instructions."
    else
        echo "Template file creation cancelled."
    fi
    read -p "Press Enter to continue..." 
    clear
}

# Enable lingering to keep services running after logout
enable_lingering() {
    if loginctl show-user "$USER" | grep -q "Linger=yes"; then
        echo -e "${GREEN}Lingering is already enabled for $USER.${RESET}"
    else
        read -p "Enable lingering for $USER? This keeps services running after logout (y/N): " CONFIRM
        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            sudo loginctl enable-linger "$USER"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Lingering enabled for $USER.${RESET}"
            else
                echo -e "${RED}Error: Failed to enable lingering.${RESET}"
            fi
        else
            echo "Lingering enablement cancelled."
        fi
    fi
    read -p "Press Enter to continue..." 
    clear
}

# Get a value from the server.json file
get_json_value() {
    if ! command -v jq &> /dev/null; then
        echo "Unknown (jq not installed)"
    elif [ ! -f "$CONFIG_FILE" ]; then
        echo "Unknown (No server JSON set)"
    else
        jq -r "$1" "$CONFIG_FILE" 2>/dev/null || echo "Unknown"
    fi
}

# Display the list of available scenarios
list_scenarios() {
    echo "Available Scenarios:"
    for i in "${!SCENARIOS[@]}"; do
        IFS='|' read -r scenario_id desc <<< "${SCENARIOS[$i]}"
        echo "  $((i+1)): $desc"
    done
}

# Manage mods in the server configuration
manage_mods() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed. Cannot manage mods.${RESET}"
        read -p "Press Enter to continue..." 
        clear
        return 1
    fi
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Error: $CONFIG_FILE not found. Create it with 'Create Template Files'.${RESET}"
        read -p "Press Enter to continue..." 
        clear
        return 1
    fi
    if [ ! -d "$ADDONS_DIR" ]; then
        echo -e "${YELLOW}Warning: $ADDONS_DIR not found. Start the server to create it or check your setup.${RESET}"
    fi

    # Temporary file to store current mods
    TEMP_MODS=$(mktemp)
    jq -c '.game.mods // []' "$CONFIG_FILE" > "$TEMP_MODS"

    while true; do
        # Load metadata from installed mods
        declare -A META_DATA
        declare -A INSTALLED_MODS
        if [ -d "$ADDONS_DIR" ]; then
            meta_files=$(find "$ADDONS_DIR" -type f -name "meta" -not -path "*/core/*" -not -path "*/data/*" 2>/dev/null)
            if [ -n "$meta_files" ]; then
                while IFS= read -r meta_file; do
                    id=$(jq -r '.meta.id' "$meta_file" 2>/dev/null)
                    name=$(jq -r '.meta.name // "Unknown"' "$meta_file" 2>/dev/null)
                    version=$(jq -r '.meta.versions[0].version // "Unknown"' "$meta_file" 2>/dev/null)
                    [ -z "$id" ] || [ "$id" = "null" ] && continue
                    META_DATA["$id"]="$name|$version"
                    INSTALLED_MODS["$id"]=1
                done <<< "$meta_files"
            fi
        fi

        # Display active mods from server.json
        echo -e "${CYAN}Currently active mods in $CONFIG_FILE:${RESET}"
        current_mods=$(jq -r '.[] | .modId' "$TEMP_MODS" 2>/dev/null)
        active_count=0
        if [ -n "$current_mods" ]; then
            i=1
            while IFS= read -r mod_id; do
                if [ -n "${META_DATA[$mod_id]}" ]; then
                    IFS='|' read -r name version <<< "${META_DATA[$mod_id]}"
                else
                    name="Unknown"
                    version="Unknown"
                fi
                printf "${CYAN}%d) ID: %s, Name: %s, Version: %s${RESET}\n" "$i" "$mod_id" "$name" "$version"
                unset "INSTALLED_MODS[$mod_id]"  # Remove from installed list to avoid duplication
                ((i++))
                ((active_count++))
            done <<< "$current_mods"
        fi
        if [ "$active_count" -eq 0 ]; then
            echo -e "${CYAN}None${RESET}"
        fi

        # Display installed but inactive mods
        echo -e "${MAGENTA}Installed mods (not active in $CONFIG_FILE):${RESET}"
        installed_count=0
        if [ ${#INSTALLED_MODS[@]} -gt 0 ]; then
            i=$((active_count + 1))
            for mod_id in "${!INSTALLED_MODS[@]}"; do
                IFS='|' read -r name version <<< "${META_DATA[$mod_id]}"
                printf "${MAGENTA}%d) ID: %s, Name: %s, Version: %s${RESET}\n" "$i" "$mod_id" "$name" "$version"
                ((i++))
                ((installed_count++))
            done
        fi
        if [ "$installed_count" -eq 0 ]; then
            echo -e "${MAGENTA}None${RESET}"
        fi
        echo "----------------------------------------"

        # Prompt user for mod management options
        echo -e "Select mods to add from currently installed/active list separated by spaces (e.g., '1 3 5')"
        echo -e "Type 'clear' to remove all mods from the server json"
        echo -e "Type 'remove number/s (e.g., 'remove 1 3 5' ) to delete specific mods from server json"
        echo -e "Type 'add modid' to manually add a Workshop mod (e.g., 'add 123456')"
        echo -e "Or Enter to skip this step and exit mod management:"
        current_count=$(jq -r 'length' "$TEMP_MODS")
        read -r selections

        if [ "$selections" = "clear" ]; then
            echo -e "${GREEN}Clearing all mods...${RESET}"
            update_json '.game.mods = []'
            jq -c '.game.mods // []' "$CONFIG_FILE" > "$TEMP_MODS"  # Refresh temp file
            read -p "Press Enter to continue..." 
            clear
        elif [[ "$selections" =~ ^remove[[:space:]]+(.+)$ ]]; then
            remove_nums="${BASH_REMATCH[1]}"
            if [ "$current_count" -eq 0 ]; then
                echo -e "${YELLOW}No mods to remove.${RESET}"
            else
                # Build jq filter to remove specific mods
                remove_filter=". | del(.["
                first=true
                for num in $remove_nums; do
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$current_count" ]; then
                        if [ "$first" = true ]; then
                            remove_filter="$remove_filter$((num-1))"
                            first=false
                        else
                            remove_filter="$remove_filter,$((num-1))"
                        fi
                    fi
                done
                remove_filter="$remove_filter])"
                if [ "$first" = false ]; then  # Only run if valid indices were provided
                    jq -c "$remove_filter" "$TEMP_MODS" > "$TEMP_MODS.tmp" && mv "$TEMP_MODS.tmp" "$TEMP_MODS"
                    echo -e "${GREEN}Selected mods removed.${RESET}"
                    update_json '.game.mods = $mods[0]' "$TEMP_MODS"
                    jq -c '.game.mods // []' "$CONFIG_FILE" > "$TEMP_MODS"
                else
                    echo -e "${RED}Error: No valid mod numbers specified for removal.${RESET}"
                fi
            fi
            read -p "Press Enter to continue..." 
            clear
        elif [[ "$selections" =~ ^add[[:space:]]+(.+)$ ]]; then
            new_modid="${BASH_REMATCH[1]}"
            if [ -n "$new_modid" ]; then
                jq -c --arg id "$new_modid" '. += [{"modId": $id}] | unique_by(.modId)' "$TEMP_MODS" > "$TEMP_MODS.tmp" && mv "$TEMP_MODS.tmp" "$TEMP_MODS"
                echo -e "${GREEN}Mod $new_modid added.${RESET}"
                update_json '.game.mods = $mods[0]' "$TEMP_MODS"
                jq -c '.game.mods // []' "$CONFIG_FILE" > "$TEMP_MODS"
            else
                echo -e "${RED}Error: No mod ID specified. Use 'add <modid>' (e.g., 'add 123456').${RESET}"
            fi
            read -p "Press Enter to continue..." 
            clear
        elif [ -n "$selections" ]; then
            # Add selected mods from the list
            if [ $((active_count + installed_count)) -gt 0 ]; then
                declare -A ALL_MODS
                i=1
                if [ -n "$current_mods" ]; then
                    while IFS= read -r mod_id; do
                        ALL_MODS["$i"]="$mod_id"
                        ((i++))
                    done <<< "$current_mods"
                fi
                for mod_id in "${!INSTALLED_MODS[@]}"; do
                    ALL_MODS["$i"]="$mod_id"
                    ((i++))
                done

                for num in $selections; do
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le $((active_count + installed_count)) ]; then
                        mod_id="${ALL_MODS[$num]}"
                        jq -c --arg id "$mod_id" '. += [{"modId": $id}] | unique_by(.modId)' "$TEMP_MODS" > "$TEMP_MODS.tmp" && mv "$TEMP_MODS.tmp" "$TEMP_MODS"
                    fi
                done
                update_json '.game.mods = $mods[0]' "$TEMP_MODS"
                jq -c '.game.mods // []' "$CONFIG_FILE" > "$TEMP_MODS"
            else
                echo -e "${RED}Error: No mods available to select from.${RESET}"
            fi
            read -p "Press Enter to continue..." 
            clear
        else
            break  # Empty input exits the loop
        fi

        # Ask if user wants to continue managing mods
        echo
        read -p "Continue managing mods? (y/N): " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            break
        fi
        clear
    done

    rm -f "$TEMP_MODS"  # Clean up temporary file
}

# Display help and about information
show_help_about() {
    echo "About:"
    echo "This script is used for administering an Arma Reforger server installed at $HOME/arma."
    echo "Licensed under the MIT License. See https://opensource.org/licenses/MIT for details."
    echo "Server JSON: $CONFIG_FILE"
    echo "Addons directory: $ADDONS_DIR"
    echo
    echo "Help - Installing Dependencies:"
    echo
    echo "jq: JSON processor (required for configuration)"
    echo "  Debian/Ubuntu: sudo apt install jq"
    echo "  - Why: jq is used to parse and modify JSON configuration files for your server."
    echo
    echo "steamcmd: Steam command-line tool (required for server install)"
    echo "  See: https://developer.valvesoftware.com/wiki/SteamCMD for more details."
    echo "  Installation instructions:"
    echo
    echo "  Debian 12 (Bookworm):"
    echo "    SteamCMD is in the 'non-free' repository, and 32-bit (i386) packages must be enabled."
    echo "    Note: The 'apt-add-repository' command is not available in Debian 12 by default."
    echo "    Steps:"
    echo "    1. Edit /etc/apt/sources.list to include 'contrib', 'non-free', and 'non-free-firmware':"
    echo "       sudo nano /etc/apt/sources.list"
    echo "       Example /etc/apt/sources.list:"
    echo "         deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware"
    echo "         deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware"
    echo "         deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware"
    echo "    2. Update and install required tools:"
    echo "       sudo apt update"
    echo "       sudo apt upgrade"
    echo "       sudo apt install software-properties-common"
    echo "    3. Enable 32-bit architecture:"
    echo "       sudo dpkg --add-architecture i386"
    echo "    4. Update again and install SteamCMD:"
    echo "       sudo apt update"
    echo "       sudo apt install steamcmd"
    echo
    echo "  Ubuntu:"
    echo "    SteamCMD is in the 'multiverse' repository, and 32-bit (i386) packages must be enabled."
    echo "    Steps:"
    echo "    1. Update and upgrade your system:"
    echo "       sudo apt update"
    echo "       sudo apt upgrade"
    echo "    2. Enable the 'multiverse' repository:"
    echo "       sudo add-apt-repository multiverse"
    echo "    3. Enable 32-bit architecture:"
    echo "       sudo dpkg --add-architecture i386"
    echo "    4. Update again and install SteamCMD:"
    echo "       sudo apt update"
    echo "       sudo apt install steamcmd"
    echo
    echo "Server Installation:"
    echo "1. Install steamcmd (see above)."
    echo "2. Create template files using 'Create Template Files'."
    echo "3. Create the Arma server directory:"
    echo "   mkdir -p $HOME/arma"
    echo "4. Move templates to $HOME/arma and remove .template extension (excludes arma.service.tpl):"
    echo "   cp $TEMPLATE_DIR/*.template $HOME/arma"
    echo "   mv $HOME/arma/*.template $HOME/arma/*"
    echo "5. Make scripts executable:"
    echo "   chmod +x $HOME/arma/install.sh $HOME/arma/start.sh"
    echo "6. Run install.sh to download server files:"
    echo "   $HOME/arma/install.sh"
    echo "7. Edit $HOME/arma/server.json (IP, ports, etc.) as needed."
    echo "8. Start the server:"
    echo "   $HOME/arma/start.sh"
    echo
    echo "Service Setup:"
    echo "1. Create template files via 'Create Template Files' (includes arma.service.tpl)."
    echo "2. Move the service file to your user systemd directory:"
    echo "   mkdir -p ~/.config/systemd/user"
    echo "   cp $TEMPLATE_DIR/arma.service.tpl ~/.config/systemd/user/arma.service"
    echo "3. Enable and start:"
    echo "   systemctl --user daemon-reload"
    echo "   systemctl --user enable arma.service"
    echo "   systemctl --user start arma.service"
    echo "4. (Optional) Enable lingering:"
    echo "   sudo loginctl enable-linger $USER"
    read -p "Press Enter to continue..." 
    clear
}

# Main loop for the script
while true; do
    CURRENT_NAME=$(get_json_value ".game.name")
    echo "Arma Server Config (Name: $CURRENT_NAME)"
    echo "Options:"
    echo "  1) Help/About"
    echo "  2) Create Template Files"
    echo "  3) Configure Server"
    echo "  4) Manage Service"
    echo "  5) Exit"
    read -p "Enter your choice (1-5): " CHOICE

    case $CHOICE in
        1) # Display help and about info
            show_help_about
            ;;
        2) # Create template files for server setup
            create_template_files
            ;;
        3) # Configure server settings
            clear
            while true; do
                echo "Configure Server Options:"
                # Network settings (matches server.json top-level)
                echo "  Network Settings:"
                echo "    1) Set Public IP Address"
                echo "    2) Set Public Port (Default 2001)"
                echo "-----------"
                # Game settings (matches server.json "game" section)
                echo "  Game Settings:"
                echo "    3) Set Server Name"
                echo "    4) Set Game Password"
                echo "    5) Set Admin Password"
                echo "    6) Set Scenario"
                echo "    7) Set Max Players"
                echo "    8) Set Crossplay Platforms"
                echo "-----------"
                # Game properties (matches server.json "game.gameProperties")
                echo "  Game Properties:"
                echo "    9) Set Server Max View Distance (Default 1600)"
                echo "    10) Set Server Min Grass Distance (Default 0)"
                echo "    11) Set Network View Distance (Default 1500)"
                echo "    12) Set Disable 3rd Person"
                echo "-----------"
                # Mods (matches server.json "game.mods")
                echo "  Mods:"
                echo "    13) Manage Mods"
                echo "-----------"
                # Review and exit
                echo "  Review:"
                echo "    14) Review Server Config"
                echo "    15) Back"
                read -p "Enter configuration option (1-15): " CONFIGURE_ACTION
                case $CONFIGURE_ACTION in
                    1) # Set Public IP Address (publicAddress)
                        CURRENT_IP=$(get_json_value ".publicAddress")
                        echo "Current public IP address: $CURRENT_IP"
                        if [[ -n "$BASH_VERSION" && "${BASH_VERSINFO[0]}" -ge 4 ]]; then
                            read -e -p "Enter new public IP address: " -i "$CURRENT_IP" PUBLIC_IP
                        else
                            echo "Enter new public IP address (backspace to edit):"
                            read -p "[$CURRENT_IP]: " PUBLIC_IP
                            [ -z "$PUBLIC_IP" ] && PUBLIC_IP="$CURRENT_IP"
                        fi
                        if validate_ip "$PUBLIC_IP"; then
                            update_json ".publicAddress = \"$PUBLIC_IP\""
                        else
                            echo -e "${RED}Error: Invalid IP address format. Use xxx.xxx.xxx.xxx.${RESET}"
                        fi
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    2) # Set Public Port (publicPort)
                        CURRENT_PUBLIC_PORT=$(get_json_value ".publicPort")
                        echo "Current public port: $CURRENT_PUBLIC_PORT"
                        if [[ -n "$BASH_VERSION" && "${BASH_VERSINFO[0]}" -ge 4 ]]; then
                            read -e -p "Enter new public port (default 2001): " -i "$CURRENT_PUBLIC_PORT" PUBLIC_PORT
                        else
                            echo "Enter new public port (default 2001, backspace to edit):"
                            read -p "[$CURRENT_PUBLIC_PORT]: " PUBLIC_PORT
                            [ -z "$PUBLIC_PORT" ] && PUBLIC_PORT="$CURRENT_PUBLIC_PORT"
                        fi
                        if [[ "$PUBLIC_PORT" =~ ^[0-9]+$ ]] && [ "$PUBLIC_PORT" -ge 1024 ] && [ "$PUBLIC_PORT" -le 65535 ]; then
                            update_json ".publicPort = $PUBLIC_PORT"
                        else
                            echo -e "${RED}Error: Public port must be a number between 1024 and 65535.${RESET}"
                        fi
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    3) # Set Server Name (game.name)
                        CURRENT_NAME=$(get_json_value ".game.name")
                        echo "Current server name: $CURRENT_NAME"
                        if [[ -n "$BASH_VERSION" && "${BASH_VERSINFO[0]}" -ge 4 ]]; then
                            read -e -p "Enter new server name: " -i "$CURRENT_NAME" NAME
                        else
                            echo "Enter new server name (backspace to edit):"
                            read -p "[$CURRENT_NAME]: " NAME
                            [ -z "$NAME" ] && NAME="$CURRENT_NAME"
                        fi
                        if [ -z "$NAME" ]; then
                            echo -e "${RED}Error: Server name cannot be empty.${RESET}"
                        else
                            update_json ".game.name = \"$NAME\""
                        fi
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    4) # Set Game Password (game.password)
                        CURRENT_PASSWORD=$(get_json_value ".game.password")
                        echo "Current game password: $CURRENT_PASSWORD"
                        if [[ -n "$BASH_VERSION" && "${BASH_VERSINFO[0]}" -ge 4 ]]; then
                            read -e -p "Enter new game password (empty to clear): " -i "$CURRENT_PASSWORD" PASSWORD
                        else
                            echo "Enter new game password (empty to clear, backspace to edit):"
                            read -p "[$CURRENT_PASSWORD]: " PASSWORD
                            [ -z "$PASSWORD" ] && PASSWORD="$CURRENT_PASSWORD"
                        fi
                        update_json ".game.password = \"$PASSWORD\""
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    5) # Set Admin Password (game.passwordAdmin)
                        CURRENT_ADMIN_PASSWORD=$(get_json_value ".game.passwordAdmin")
                        echo "Current admin password: $CURRENT_ADMIN_PASSWORD"
                        if [[ -n "$BASH_VERSION" && "${BASH_VERSINFO[0]}" -ge 4 ]]; then
                            read -e -p "Enter new admin password: " -i "$CURRENT_ADMIN_PASSWORD" ADMIN_PASSWORD
                        else
                            echo "Enter new admin password (backspace to edit):"
                            read -p "[$CURRENT_ADMIN_PASSWORD]: " ADMIN_PASSWORD
                            [ -z "$ADMIN_PASSWORD" ] && ADMIN_PASSWORD="$CURRENT_ADMIN_PASSWORD"
                        fi
                        if [ -n "$ADMIN_PASSWORD" ]; then
                            update_json ".game.passwordAdmin = \"$ADMIN_PASSWORD\""
                        else
                            echo -e "${RED}Error: Admin password cannot be empty.${RESET}"
                        fi
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    6) # Set Scenario (game.scenarioId)
                        list_scenarios
                        CURRENT_SCENARIO=$(get_json_value ".game.scenarioId")
                        for i in "${!SCENARIOS[@]}"; do
                            IFS='|' read -r scenario_id desc <<< "${SCENARIOS[$i]}"
                            if [ "$scenario_id" = "$CURRENT_SCENARIO" ]; then
                                echo "Current scenario: $((i+1)): $desc"
                            fi
                        done
                        read -p "Enter scenario number: " SCENARIO_NUM
                        if [ "$SCENARIO_NUM" -ge 1 ] && [ "$SCENARIO_NUM" -le "${#SCENARIOS[@]}" ] 2>/dev/null; then
                            SCENARIO_ID=$(echo "${SCENARIOS[$((SCENARIO_NUM-1))]}" | cut -d'|' -f1)
                            update_json ".game.scenarioId = \"$SCENARIO_ID\""
                        else
                            echo -e "${RED}Error: Invalid scenario number. Must be between 1 and ${#SCENARIOS[@]}.${RESET}"
                        fi
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    7) # Set Max Players (game.maxPlayers)
                        CURRENT_MAX=$(get_json_value ".game.maxPlayers")
                        echo "Current max players: $CURRENT_MAX"
                        if [[ -n "$BASH_VERSION" && "${BASH_VERSINFO[0]}" -ge 4 ]]; then
                            read -e -p "Enter new max players: " -i "$CURRENT_MAX" MAX_PLAYERS
                        else
                            echo "Enter new max players (backspace to edit):"
                            read -p "[$CURRENT_MAX]: " MAX_PLAYERS
                            [ -z "$MAX_PLAYERS" ] && MAX_PLAYERS="$CURRENT_MAX"
                        fi
                        if [[ "$MAX_PLAYERS" =~ ^[0-9]+$ ]] && [ "$MAX_PLAYERS" -ge 2 ] && [ "$MAX_PLAYERS" -le 128 ]; then
                            update_json ".game.maxPlayers = $MAX_PLAYERS"
                        else
                            echo -e "${RED}Error: Max players must be a number between 2 and 128.${RESET}"
                        fi
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    8) # Set Crossplay Platforms (game.supportedPlatforms, game.crossPlatform)
                        CURRENT_PLATFORMS=$(get_json_value ".game.supportedPlatforms")
                        echo "Current crossplay platforms: $CURRENT_PLATFORMS"
                        echo "Select crossplay option:"
                        echo "  1) All platforms (PC, Xbox, PS5) - No mods allowed"
                        echo "  2) PC and Xbox - Mods allowed"
                        echo "  3) PC only - Mods allowed"
                        read -p "Enter choice (1-3): " CROSSPLAY_CHOICE
                        case $CROSSPLAY_CHOICE in
                            1)
                                update_json '.game.supportedPlatforms = ["PLATFORM_PC", "PLATFORM_XBL", "PLATFORM_PSN"] | .game.crossPlatform = true'
                                echo -e "${YELLOW}Note: PS5 does not support mods. Ensure no mods are active for PS5 crossplay.${RESET}"
                                ;;
                            2)
                                update_json '.game.supportedPlatforms = ["PLATFORM_PC", "PLATFORM_XBL"] | .game.crossPlatform = true'
                                echo -e "${GREEN}Set to PC and Xbox crossplay. Mods are allowed.${RESET}"
                                echo -e "${YELLOW}Note: PSN players won't be able to join.${RESET}"
                                ;;
                            3)
                                update_json '.game.supportedPlatforms = ["PLATFORM_PC"] | .game.crossPlatform = false'
                                echo -e "${GREEN}Set to PC only. Mods are allowed.${RESET}"
                                echo -e "${YELLOW}Note: XBL and PSN players won't be able to join.${RESET}"
                                ;;
                            *)
                                echo -e "${RED}Error: Invalid choice. Must be 1, 2, or 3.${RESET}"
                                ;;
                        esac
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    9) # Set Server Max View Distance (game.gameProperties.serverMaxViewDistance)
                        CURRENT_SERVER_VIEW=$(get_json_value ".game.gameProperties.serverMaxViewDistance")
                        echo "Current server max view distance: $CURRENT_SERVER_VIEW"
                        if [[ -n "$BASH_VERSION" && "${BASH_VERSINFO[0]}" -ge 4 ]]; then
                            read -e -p "Enter new server max view distance (default 1600): " -i "$CURRENT_SERVER_VIEW" SERVER_VIEW
                        else
                            echo "Enter new server max view distance (default 1600, backspace to edit):"
                            read -p "[$CURRENT_SERVER_VIEW]: " SERVER_VIEW
                            [ -z "$SERVER_VIEW" ] && SERVER_VIEW="$CURRENT_SERVER_VIEW"
                        fi
                        if [[ "$SERVER_VIEW" =~ ^[0-9]+$ ]] && [ "$SERVER_VIEW" -ge 500 ] && [ "$SERVER_VIEW" -le 10000 ]; then
                            update_json ".game.gameProperties.serverMaxViewDistance = $SERVER_VIEW"
                        else
                            echo -e "${RED}Error: Server max view distance must be a number between 500 and 10000.${RESET}"
                        fi
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    10) # Set Server Min Grass Distance (game.gameProperties.serverMinGrassDistance)
                        CURRENT_GRASS_VIEW=$(get_json_value ".game.gameProperties.serverMinGrassDistance")
                        echo "Current server min grass distance: $CURRENT_GRASS_VIEW"
                        if [[ -n "$BASH_VERSION" && "${BASH_VERSINFO[0]}" -ge 4 ]]; then
                            read -e -p "Enter new server min grass distance (default 0): " -i "$CURRENT_GRASS_VIEW" GRASS_VIEW
                        else
                            echo "Enter new server min grass distance (default 0, backspace to edit):"
                            read -p "[$CURRENT_GRASS_VIEW]: " GRASS_VIEW
                            [ -z "$GRASS_VIEW" ] && GRASS_VIEW="$CURRENT_GRASS_VIEW"
                        fi
                        if [[ "$GRASS_VIEW" =~ ^[0-9]+$ ]] && [ "$GRASS_VIEW" -ge 0 ] && [ "$GRASS_VIEW" -le 150 ]; then
                            update_json ".game.gameProperties.serverMinGrassDistance = $GRASS_VIEW"
                        else
                            echo -e "${RED}Error: Server min grass distance must be a number between 0 and 150.${RESET}"
                        fi
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    11) # Set Network View Distance (game.gameProperties.networkViewDistance)
                        CURRENT_NETWORK_VIEW=$(get_json_value ".game.gameProperties.networkViewDistance")
                        echo "Current network view distance: $CURRENT_NETWORK_VIEW"
                        if [[ -n "$BASH_VERSION" && "${BASH_VERSINFO[0]}" -ge 4 ]]; then
                            read -e -p "Enter new network view distance (default 1500): " -i "$CURRENT_NETWORK_VIEW" NETWORK_VIEW
                        else
                            echo "Enter new network view distance (default 1500, backspace to edit):"
                            read -p "[$CURRENT_NETWORK_VIEW]: " NETWORK_VIEW
                            [ -z "$NETWORK_VIEW" ] && NETWORK_VIEW="$CURRENT_NETWORK_VIEW"
                        fi
                        if [[ "$NETWORK_VIEW" =~ ^[0-9]+$ ]] && [ "$NETWORK_VIEW" -ge 500 ] && [ "$NETWORK_VIEW" -le 5000 ]; then
                            update_json ".game.gameProperties.networkViewDistance = $NETWORK_VIEW"
                        else
                            echo -e "${RED}Error: Network view distance must be a number between 500 and 5000.${RESET}"
                        fi
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    12) # Set Disable 3rd Person (game.gameProperties.disableThirdPerson)
                        CURRENT_DISABLE_3RD=$(get_json_value ".game.gameProperties.disableThirdPerson")
                        echo "Current disable third person: $CURRENT_DISABLE_3RD"
                        read -p "Disable third person view? (y/N): " DISABLE_3RD
                        if [[ "$DISABLE_3RD" =~ ^[Yy]$ ]]; then
                            update_json ".game.gameProperties.disableThirdPerson = true"
                        else
                            update_json ".game.gameProperties.disableThirdPerson = false"
                        fi
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    13) # Manage Mods (game.mods)
                        manage_mods
                        clear
                        ;;
                    14) # Review Server Config
                        if ! command -v jq &> /dev/null; then
                            echo -e "${RED}Error: jq is not installed. Cannot view JSON configuration.${RESET}"
                        elif jq . "$CONFIG_FILE" 2>/dev/null; then
                            echo "Server configuration displayed above."
                        else
                            echo -e "${RED}Error: Unable to read server JSON at $CONFIG_FILE${RESET}"
                        fi
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                    15) # Back to main menu
                        break
                        ;;
                    *) 
                        echo -e "${RED}Error: Invalid configuration option. Must be 1-15.${RESET}"
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                esac
            done
            clear
            ;;
        4) # Manage the server service
            clear
            while true; do
                echo "Service Options:"
                echo "  1) Start"
                echo "  2) Stop"
                echo "  3) Restart"
                echo "  4) Status"
                echo "  5) Enable Lingering"
                echo "  6) Back"
                read -p "Enter service action (1-6): " SERVICE_ACTION
                case $SERVICE_ACTION in
                    1) manage_service "start" ;;
                    2) manage_service "stop" ;;
                    3) manage_service "restart" ;;
                    4) manage_service "status" ;;
                    5) enable_lingering ;;
                    6) break ;;
                    *) 
                        echo -e "${RED}Error: Invalid service action. Must be 1-6.${RESET}"
                        read -p "Press Enter to continue..." 
                        clear
                        ;;
                esac
            done
            clear
            ;;
        5) # Exit the script
            echo -e "${GREEN}Exiting...${RESET}"
            read -p "Press Enter to continue..." 
            clear
            exit 0
            ;;
        *) 
            echo -e "${RED}Error: Invalid choice. Please enter a number between 1 and 5.${RESET}"
            read -p "Press Enter to continue..." 
            clear
            ;;
    esac
done
