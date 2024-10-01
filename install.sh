#!/bin/bash

# open the terminal in the same directory and make it executable with the following commands:
# sudo chmod +x install.sh
# Start the script with the following command:
# sudo bash install.sh

# Variable
export created="Manuel Ziel (IgnotusDawn)"
export version="1.0"
export codename="Early Phantom"

BLUE='\033[1;94m'
GREEN='\033[1;92m'
RED='\033[1;91m'
YELLOW='\033[1;93m'
RESETCOLOR='\033[1;00m'
DISABLE_AUTO_WRAP='\033[?7l'
ENABLE_AUTO_WRAP='\033[?7h'

SCRIPT_NAME="AnonyLink.sh"
SCRIPT_PATH="/usr/local/bin/anonylink"
ICON_NAME="anonylink.png"

# Get the home directory of the original user
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
else
    USER_HOME=$HOME
fi

ICON_PATH="$USER_HOME/.local/share/anonylink/$ICON_NAME"
DESKTOP_FILE_PATH="$USER_HOME/Desktop/AnonyLink.desktop"

display_banner() {
echo -e ""
echo -e "$YELLOW"
echo -e "$DISABLE_AUTO_WRAP"
echo -e "     _                            _     _       _    "
echo -e "    / \   _ __   ___  _ __  _   _| |   (_)_ __ | | _ "
echo -e "   / _ \ | '_ \ / _ \| '_ \| | | | |   | | '_ \| |/ |"
echo -e "  / ___ \| | | | (_) | | | | |_| | |___| | | | |   < "
echo -e " /_/   \_\_| |_|\___/|_| |_|\__, |_____|_|_| |_|_|\_|"
echo -e "                            |___/                    " 
echo -e "$RESETCOLOR"
echo -e "$BLUE Created by:\t $RESETCOLOR$RED $created $RESETCOLOR"
echo -e "$BLUE Version:\t $RED $version $RESTECOLOR"
echo -e "$BLUE Codenamed:\t $YELLOW $codename $RESETCOLOR"
echo -e "$ENABLE_AUTO_WRAP"
echo -e "$RESETCOLOR"
}

# Check if script exists
check_script_exists() {
    local script_name=$1
    if [ ! -f "$script_name" ]; then
        echo "The script $script_name does not exist. Please make sure the script is in the same directory as the install script."
        exit 1
    fi
}

# Ask if the script should be installed
ask_install() {
    local script_name=$1
    local script_path=$2
    local desktop_file_path=$3
    local icon_name=$4
    local icon_path=$5
    
    read -p "Do you want to install or update AnonyLink? (y/n) " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "Installation aborted."
        exit 1
    else
        echo -e "\nStarting installation...\n"
        install_script "$script_name" "$script_path" "$desktop_file_path" "$icon_name" "$icon_path"
    fi
}

# Install script
install_script() {
    local script_name=$1
    local script_path=$2
    local desktop_file_path=$3
    local icon_name=$4
    local icon_path=$5

    # Copy script to /usr/local/bin
    echo "Copy $script_name to $script_path..."
    sudo cp "$script_name" "$script_path"

    # Check if script was copied successfully
    if [ ! -f "$script_path" ]; then
        echo "An error occurred while copying the script to $script_path."
        exit 1
    fi

    # Set permissions
    echo "Set $script_path permissions..."
    sudo chmod +x "$script_path"

    # Copy icon to ~/.local/share/anonylink/icons
    # Create the directory if it doesn't exist
    if [ ! -d "$(dirname "$icon_path")" ]; then
        echo "Directory $(dirname "$icon_path") does not exist. Creating it..."
        mkdir -p "$(dirname "$icon_path")"
    else
    echo "Directory $(dirname "$icon_path") already exists. Deleting its contents..."
    rm -rf "$(dirname "$icon_path")/*"
    fi

    echo "Copy $icon_name to $icon_path..."
    sudo cp "$icon_name" "$icon_path"
    # Check if icon was copied successfully
    if [ ! -f "$icon_path" ]; then
        echo "An error occurred while copying the icon to $icon_path."
        exit 1
    fi
    
    # Create .desktop-file
    echo "Create .desktop-file to $desktop_file_path..."
    cat <<EOF > "$desktop_file_path"
[Desktop Entry]
Version=1.0
Name=AnonyLink
Comment=Start AnonyLink Script
Exec=menuexec "anonylink"
Icon=$icon_path
Terminal=true
Type=Application
Categories=Utility;
EOF
    
    # Set.desktop-Datei executable
    echo "Set $desktop_file_path permissions..."
    chmod +x "$desktop_file_path"

    echo "Installation completed."
}

# Main Skript

# Display banner
display_banner

# Check if script exists
check_script_exists "$SCRIPT_NAME"

# Ask if the script should be installed
ask_install "$SCRIPT_NAME" "$SCRIPT_PATH" "$DESKTOP_FILE_PATH" "$ICON_NAME" "$ICON_PATH"