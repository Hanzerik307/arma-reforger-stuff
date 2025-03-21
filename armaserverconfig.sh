#!/bin/bash

# armaserverconfig.sh (CLI-Only Version) - Version 1.0 - 2025-03-20
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

# Settings file to store the last selected config
TEMPLATE_DIR="$HOME/.armaserverconfig"
SETTINGS_FILE="$TEMPLATE_DIR/armaserverconfig.ini"
TEMPLATE_FILE="$TEMPLATE_DIR/arma.service.template"

# Load config file from settings, default if not set
if [ -f "$SETTINGS_FILE" ]; then
    CONFIG_FILE=$(grep "^CONFIG_FILE=" "$SETTINGS_FILE" | cut -d'=' -f2)
else
    CONFIG_FILE="$HOME/arma/server.json"
fi

# Array of scenarios (index => scenarioId and description)
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

# Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
RESET='\e[0m'

# Check for jq at startup and warn if not installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq is not installed.${RESET}"
    echo "jq is required for editing or viewing JSON configuration files."
    echo "Without it, options like 'Configure Server' and 'Review Server Config' will not work."
    echo "You can still use other features (e.g., managing the service or listing players)."
    echo
    read -p "Would you like to: [1] Install jq now, [2] See Help/About, or [3] Continue anyway? (1-3): " JQ_CHOICE
    case $JQ_CHOICE in
        1)
            sudo apt install jq --no-install-recommends
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Successfully installed jq.${RESET}"
            else
                echo -e "${YELLOW}Error: Failed to install jq. Proceeding without it.${RESET}"
            fi
            ;;
        2)
            show_help_about
            ;;
        3)
            echo -e "${GREEN}Continuing without jq.${RESET}"
            ;;
        *)
            echo -e "${YELLOW}Invalid choice. Continuing without jq.${RESET}"
            ;;
    esac
    echo
fi

# Function to update JSON file
update_json() {
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Error: jq is not installed. Cannot edit JSON configuration.${RESET}"
        return 1
    fi
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}Error: No server JSON set. Use 'Search for Server JSON' to select one.${RESET}"
        return 1
    fi
    local tmp_file=$(mktemp)
    jq "$1" "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"
    echo -e "${GREEN}Configuration updated successfully. Restart service after all changes are made.${RESET}"
}

# Function to validate IP address
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

# Function to manage service
manage_service() {
    case $1 in
        start)
            systemctl --user start arma.service
            echo -e "${GREEN}Arma service started${RESET}"
            ;;
        stop)
            systemctl --user stop arma.service
            echo -e "${GREEN}Arma service stopped${RESET}"
            ;;
        restart)
            systemctl --user restart arma.service
            echo -e "${GREEN}Arma service restarted${RESET}"
            ;;
        status)
            systemctl --user status arma.service
            ;;
        create_template)
            read -p "Would you like to create a service template file at $TEMPLATE_FILE? (y/N): " CONFIRM
            if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                mkdir -p "$TEMPLATE_DIR"
                cat > "$TEMPLATE_FILE" << 'EOF'
[Unit]
Description=Arma Reforger Server
After=network.target

[Service]
Type=simple
ExecStart=/home/<username>/arma/start.sh
Restart=always
WorkingDirectory=/home/<username>/arma

[Install]
WantedBy=default.target
EOF
                echo -e "${GREEN}Service template successfully created at: $TEMPLATE_FILE${RESET}"
                echo "See 'Help/About' for setup instructions."
            fi
            ;;
    esac
}

# Function to create template files (install.sh.template, steam.txt.template, start.sh.template, server.json.template)
create_template_files() {
    echo "This will create template files for installing and running an Arma Reforger server."
    echo "Files will be placed in: $TEMPLATE_DIR"
    echo "- install.sh.template: Script to download server files via steamcmd"
    echo "- steam.txt.template: SteamCMD configuration"
    echo "- start.sh.template: Server startup script"
    echo "- server.json.template: Default server configuration"
    read -p "Would you like to create these template files? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        mkdir -p "$TEMPLATE_DIR"
        # install.sh.template
        cat > "$TEMPLATE_DIR/install.sh.template" << 'EOF'
#!/bin/bash
/usr/games/steamcmd +force_install_dir $HOME/arma +runscript $HOME/arma/steam.txt
EOF
        # steam.txt.template
        cat > "$TEMPLATE_DIR/steam.txt.template" << 'EOF'
@ShutdownOnFailedCommand 1
login anonymous
app_update 1874900 validate
quit
EOF
        # start.sh.template
        cat > "$TEMPLATE_DIR/start.sh.template" << 'EOF'
#!/bin/bash
$HOME/arma/ArmaReforgerServer -config=$HOME/arma/server.json -profile=$HOME/arma -maxFPS=60
EOF
        # server.json.template
        cat > "$TEMPLATE_DIR/server.json.template" << 'EOF'
{
  "publicAddress": "123.123.123.123",
  "publicPort": 2001,
  "a2s": {
    "address": "123.123.123.123",
    "port": 17777
  },
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
        chmod +x "$TEMPLATE_DIR/install.sh.template" "$TEMPLATE_DIR/start.sh.template"
        echo -e "${GREEN}Template files successfully created in: $TEMPLATE_DIR${RESET}"
        echo "Files: install.sh.template, steam.txt.template, start.sh.template, server.json.template"
        echo "See 'Help/About' for usage instructions."
    fi
}

# Function to clean service logs
clean_logs() {
    echo "Current disk usage for arma.service logs:"
    journalctl --user -u arma.service --disk-usage
    read -p "Enter time to keep logs (e.g., 7days, 2weeks): " TIME
    if [ -n "$TIME" ]; then
        journalctl --user -u arma.service --vacuum-time="$TIME"
        echo -e "${GREEN}Logs cleaned for arma.service (kept last $TIME).${RESET}"
    fi
}

# Function to enable lingering
enable_lingering() {
    if loginctl show-user "$USER" | grep -q "Linger=yes"; then
        echo -e "${GREEN}Lingering is already enabled for $USER.${RESET}"
    else
        read -p "Enable lingering for $USER? This keeps services running after logout (y/N): " CONFIRM
        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            sudo loginctl enable-linger "$USER"
            echo -e "${GREEN}Lingering enabled for $USER.${RESET}"
        fi
    fi
}

# Function to get current value from JSON
get_json_value() {
    if ! command -v jq &> /dev/null; then
        echo "Unknown (jq not installed)"
    elif [ ! -f "$CONFIG_FILE" ]; then
        echo "Unknown (No server JSON set)"
    else
        jq -r "$1" "$CONFIG_FILE" 2>/dev/null || echo "Unknown"
    fi
}

# Function to list players from journalctl (only Name and IdentityId, 6 hours)
list_players() {
    journalctl --user -u arma.service --since "-6 hours" | grep "PlayerId" > /tmp/players_raw.txt
    if [ -s /tmp/players_raw.txt ]; then
        echo "Player Information (Last 6 Hours):" > /tmp/players.txt
        while IFS= read -r line; do
            NAME=$(echo "$line" | grep -o "Name=[^,]*" | cut -d'=' -f2 | tr -d ' ')
            IDENTITY_ID=$(echo "$line" | grep -o "IdentityId=[^ ]*" | cut -d'=' -f2 | tr -d ' ')
            if [ -n "$IDENTITY_ID" ]; then
                echo "Name: $NAME, IdentityId: $IDENTITY_ID" >> /tmp/players.txt
            fi
        done < /tmp/players_raw.txt
        cat /tmp/players.txt
        rm /tmp/players_raw.txt /tmp/players.txt
    else
        echo -e "${YELLOW}No player entries found in the last 6 hours.${RESET}"
        rm /tmp/players_raw.txt
    fi
}

# Function to list scenarios
list_scenarios() {
    echo "Available Scenarios:"
    for i in "${!SCENARIOS[@]}"; do
        IFS='|' read -r scenario_id desc <<< "${SCENARIOS[$i]}"
        echo "  $((i+1)): $desc"
    done
}

# Function to search for server JSON files and save selection
search_configs() {
    CONFIG_LIST=$(find "$HOME" -type f -name "*.json" -exec sh -c 'if [ -f "$(dirname "{}")/ArmaReforgerServer" ] || grep -q "scenarioId" "{}"; then echo "{}"; fi' \; 2>/dev/null)
    if [ -z "$CONFIG_LIST" ]; then
        echo -e "${YELLOW}No Arma Reforger server JSON files found in $HOME.${RESET}"
        return
    fi

    echo "Found server JSON files:"
    i=1
    while IFS= read -r config; do
        echo "  $i) $config"
        ((i++))
    done <<< "$CONFIG_LIST"
    read -p "Enter server JSON number to use (or Enter to skip): " NEW_CONFIG_NUM
    if [ -n "$NEW_CONFIG_NUM" ] && [ "$NEW_CONFIG_NUM" -ge 1 ] && [ "$NEW_CONFIG_NUM" -lt "$i" ]; then
        NEW_CONFIG=$(echo "$CONFIG_LIST" | sed -n "${NEW_CONFIG_NUM}p")
        CONFIG_FILE="$NEW_CONFIG"
        mkdir -p "$TEMPLATE_DIR"
        echo "CONFIG_FILE=$CONFIG_FILE" > "$SETTINGS_FILE"
        echo -e "${GREEN}Server JSON set to: $CONFIG_FILE${RESET}"
        echo "Saved to $SETTINGS_FILE"
    fi
}

# Function to show help and about
show_help_about() {
    echo "About:"
    echo "This script is used for administering Arma Reforger game servers."
    echo "Licensed under the MIT License. See https://opensource.org/licenses/MIT for details."
    echo "Current server JSON: $CONFIG_FILE"
    echo "Settings saved in: $SETTINGS_FILE"
    echo
    echo "Help - Installing Dependencies:"
    echo
    echo "jq: JSON processor (optional, but required for JSON editing/viewing)"
    echo "  Debian/Ubuntu: sudo apt install jq"
    echo "  - Why: jq is used to parse and modify JSON configuration files for your server."
    echo "  - Without jq, you can still manage the service, list players, and create templates."
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
    echo "Manual Server Installation Files:"
    echo "Template files (install.sh.template, steam.txt.template, start.sh.template, server.json.template) can be created via 'Create Template Files' in $TEMPLATE_DIR."
    echo "To use them:"
    echo "1. Install steamcmd (see above)."
    echo "2. Move the files to your desired server directory and remove the .template extension (e.g., ~/arma):"
    echo "   cp $TEMPLATE_DIR/install.sh.template $TEMPLATE_DIR/steam.txt.template $TEMPLATE_DIR/start.sh.template $TEMPLATE_DIR/server.json.template ~/arma"
    echo "   mv ~/arma/install.sh.template ~/arma/install.sh"
    echo "   mv ~/arma/steam.txt.template ~/arma/steam.txt"
    echo "   mv ~/arma/start.sh.template ~/arma/start.sh"
    echo "   mv ~/arma/server.json.template ~/arma/server.json"
    echo "3. Make scripts executable:"
    echo "   chmod +x ~/arma/install.sh ~/arma/start.sh"
    echo "4. Run install.sh to download the server files:"
    echo "   ~/arma/install.sh"
    echo "5. Edit start.sh and server.json as needed (e.g., update paths, IP, ports)."
    echo "6. Run start.sh to launch the server:"
    echo "   ~/arma/start.sh"
    echo
    echo "Service Template Setup:"
    echo "A template file, arma.service.template, can be created via 'Manage Service' -> 'Create Service Template' in $TEMPLATE_DIR."
    echo "To use it:"
    echo "1. Edit $TEMPLATE_FILE:"
    echo "   - Replace '/path/to/your/start_script.sh' with the full path to your server start script (e.g., /home/$USER/arma/start.sh)."
    echo "   - Replace '/path/to/your/server_directory' with the directory containing ArmaReforgerServer (e.g., /home/$USER/arma)."
    echo "2. Move and rename the file:"
    echo "   mkdir -p ~/.config/systemd/user"
    echo "   cp $TEMPLATE_FILE ~/.config/systemd/user/arma.service"
    echo "3. Enable the service:"
    echo "   systemctl --user daemon-reload"
    echo "   systemctl --user enable arma.service"
    echo "4. (Optional) Enable lingering:"
    echo "   sudo loginctl enable-linger $USER"
    echo "   - Keeps services running after logout and starts them at system boot without login."
    echo "5. Start the service:"
    echo "   systemctl --user start arma.service"
    echo "This sets up a user service that auto-restarts and runs at boot if lingering is enabled."
    read -p "Press Enter to continue..."
}

# Main loop
while true; do
    CURRENT_NAME=$(get_json_value ".game.name")
    echo "Arma Server Config (Name: $CURRENT_NAME)"
    echo "Options:"
    echo "  1) Help/About"
    echo "  2) Create Template Files"
    echo "  3) Search for Server JSON"
    echo "  4) Configure Server"
    echo "  5) Manage Service"
    echo "  6) List Players"
    echo "  7) Exit"
    read -p "Enter your choice (1-7): " CHOICE

    case $CHOICE in
        1) # Help/About
            show_help_about
            ;;
        2) # Create Template Files
            create_template_files
            ;;
        3) # Search for Server JSON
            search_configs
            ;;
        4) # Configure Server
            while true; do
                echo "Configure Server Options:"
                echo "  1) Set Server Name"
                echo "  2) Set Game Password"
                echo "  3) Clear Game Password"
                echo "  4) Set Admin Password"
                echo "  5) Set Scenario"
                echo "  6) Set Max Players"
                echo "  7) Set Server Max View Distance (Default 1600)"
                echo "  8) Set Server Min Grass Distance (Default 0)"
                echo "  9) Set Network View Distance (Default 1500)"
                echo "  10) Set Disable 3rd Person"
                echo "  11) Review Server Config"
                echo "  12) Back"
                read -p "Enter configuration option (1-12): " CONFIGURE_ACTION
                case $CONFIGURE_ACTION in
                    1) # Set Server Name
                        CURRENT_NAME=$(get_json_value ".game.name")
                        echo "Current server name: $CURRENT_NAME"
                        read -p "Enter new server name: " NAME
                        if [ -z "$NAME" ]; then
                            echo -e "${YELLOW}Error: Server name cannot be empty.${RESET}"
                        else
                            update_json ".game.name = \"$NAME\""
                        fi
                        ;;
                    2) # Set Game Password
                        CURRENT_PASSWORD=$(get_json_value ".game.password")
                        echo "Current game password: $CURRENT_PASSWORD"
                        read -p "Enter new game password: " PASSWORD
                        if [ -n "$PASSWORD" ]; then
                            update_json ".game.password = \"$PASSWORD\""
                        else
                            echo -e "${YELLOW}Password not changed. Use 'Clear Game Password' to remove it.${RESET}"
                        fi
                        ;;
                    3) # Clear Game Password
                        CURRENT_PASSWORD=$(get_json_value ".game.password")
                        echo "Current game password: $CURRENT_PASSWORD"
                        read -p "Are you sure you want to clear the game password? (y/N): " CONFIRM
                        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                            update_json '.game.password = ""'
                        fi
                        ;;
                    4) # Set Admin Password
                        CURRENT_ADMIN_PASSWORD=$(get_json_value ".game.passwordAdmin")
                        echo "Current admin password: $CURRENT_ADMIN_PASSWORD"
                        read -p "Enter new admin password: " ADMIN_PASSWORD
                        if [ -n "$ADMIN_PASSWORD" ]; then
                            update_json ".game.passwordAdmin = \"$ADMIN_PASSWORD\""
                        else
                            echo -e "${YELLOW}Admin password cannot be empty.${RESET}"
                        fi
                        ;;
                    5) # Set Scenario
                        list_scenarios
                        CURRENT_SCENARIO=$(get_json_value ".game.scenarioId")
                        for i in "${!SCENARIOS[@]}"; do
                            IFS='|' read -r scenario_id desc <<< "${SCENARIOS[$i]}"
                            if [ "$scenario_id" = "$CURRENT_SCENARIO" ]; then
                                echo "Current scenario: $((i+1)): $desc"
                            fi
                        done
                        read -p "Enter scenario number: " SCENARIO_NUM
                        if [ "$SCENARIO_NUM" -ge 1 ] && [ "$SCENARIO_NUM" -le "${#SCENARIOS[@]}" ]; then
                            SCENARIO_ID=$(echo "${SCENARIOS[$((SCENARIO_NUM-1))]}" | cut -d'|' -f1)
                            update_json ".game.scenarioId = \"$SCENARIO_ID\""
                        else
                            echo -e "${YELLOW}Invalid scenario number.${RESET}"
                        fi
                        ;;
                    6) # Set Max Players (Range: 2-128, No Default Displayed)
                        CURRENT_MAX=$(get_json_value ".game.maxPlayers")
                        echo "Current max players: $CURRENT_MAX"
                        read -p "Enter new max players: " MAX_PLAYERS
                        if [[ "$MAX_PLAYERS" =~ ^[0-9]+$ ]] && [ "$MAX_PLAYERS" -ge 2 ] && [ "$MAX_PLAYERS" -le 128 ]; then
                            update_json ".game.maxPlayers = $MAX_PLAYERS"
                        else
                            echo -e "${YELLOW}Warning: Max players must be a number between 2 and 128.${RESET}"
                        fi
                        ;;
                    7) # Set Server Max View Distance (Range: 500-10000, Default 1600)
                        CURRENT_SERVER_VIEW=$(get_json_value ".game.gameProperties.serverMaxViewDistance")
                        echo "Current server max view distance: $CURRENT_SERVER_VIEW"
                        read -p "Enter new server max view distance (default 1600): " SERVER_VIEW
                        if [[ "$SERVER_VIEW" =~ ^[0-9]+$ ]] && [ "$SERVER_VIEW" -ge 500 ] && [ "$SERVER_VIEW" -le 10000 ]; then
                            update_json ".game.gameProperties.serverMaxViewDistance = $SERVER_VIEW"
                        else
                            echo -e "${YELLOW}Warning: Server max view distance must be a number between 500 and 10000.${RESET}"
                        fi
                        ;;
                    8) # Set Server Min Grass Distance (Range: 0-150, Default 0)
                        CURRENT_GRASS_VIEW=$(get_json_value ".game.gameProperties.serverMinGrassDistance")
                        echo "Current server min grass distance: $CURRENT_GRASS_VIEW"
                        read -p "Enter new server min grass distance (default 0): " GRASS_VIEW
                        if [[ "$GRASS_VIEW" =~ ^[0-9]+$ ]] && [ "$GRASS_VIEW" -ge 0 ] && [ "$GRASS_VIEW" -le 150 ]; then
                            update_json ".game.gameProperties.serverMinGrassDistance = $GRASS_VIEW"
                        else
                            echo -e "${YELLOW}Warning: Server min grass distance must be a number between 0 and 150.${RESET}"
                        fi
                        ;;
                    9) # Set Network View Distance (Range: 500-5000, Default 1500)
                        CURRENT_NETWORK_VIEW=$(get_json_value ".game.gameProperties.networkViewDistance")
                        echo "Current network view distance: $CURRENT_NETWORK_VIEW"
                        read -p "Enter new network view distance (default 1500): " NETWORK_VIEW
                        if [[ "$NETWORK_VIEW" =~ ^[0-9]+$ ]] && [ "$NETWORK_VIEW" -ge 500 ] && [ "$NETWORK_VIEW" -le 5000 ]; then
                            update_json ".game.gameProperties.networkViewDistance = $NETWORK_VIEW"
                        else
                            echo -e "${YELLOW}Warning: Network view distance must be a number between 500 and 5000.${RESET}"
                        fi
                        ;;
                    10) # Set Disable 3rd Person
                        CURRENT_DISABLE_3RD=$(get_json_value ".game.gameProperties.disableThirdPerson")
                        echo "Current disable third person: $CURRENT_DISABLE_3RD"
                        read -p "Disable third person view? (y/N): " DISABLE_3RD
                        if [[ "$DISABLE_3RD" =~ ^[Yy]$ ]]; then
                            update_json ".game.gameProperties.disableThirdPerson = true"
                        else
                            update_json ".game.gameProperties.disableThirdPerson = false"
                        fi
                        ;;
                    11) # Review Server Config
                        if ! command -v jq &> /dev/null; then
                            echo -e "${YELLOW}Error: jq is not installed. Cannot view JSON configuration.${RESET}"
                        elif jq . "$CONFIG_FILE" 2>/dev/null; then
                            read -p "Press Enter to continue..."
                        else
                            echo -e "${YELLOW}Error: Unable to read server JSON at $CONFIG_FILE${RESET}"
                        fi
                        ;;
                    12) # Back
                        break
                        ;;
                    *) echo -e "${YELLOW}Invalid configuration option.${RESET}" ;;
                esac
                echo
            done
            ;;
        5) # Manage Service
            while true; do
                echo "Service Options:"
                echo "  1) Start"
                echo "  2) Stop"
                echo "  3) Restart"
                echo "  4) Status"
                echo "  5) Create Service Template"
                echo "  6) Clean Service Logs"
                echo "  7) Enable Lingering"
                echo "  8) Back"
                read -p "Enter service action (1-8): " SERVICE_ACTION
                case $SERVICE_ACTION in
                    1) manage_service "start" ;;
                    2) manage_service "stop" ;;
                    3) manage_service "restart" ;;
                    4) manage_service "status" ;;
                    5) manage_service "create_template" ;;
                    6) clean_logs ;;
                    7) enable_lingering ;;
                    8) break ;;
                    *) echo -e "${YELLOW}Invalid service action.${RESET}" ;;
                esac
                echo
            done
            ;;
        6) # List Players
            list_players
            read -p "Press Enter to continue..."
            ;;
        7) # Exit
            echo -e "${GREEN}Exiting...${RESET}"
            exit 0
            ;;
        *) echo -e "${YELLOW}Invalid choice. Please enter a number between 1 and 7.${RESET}" ;;
    esac
    echo
done

