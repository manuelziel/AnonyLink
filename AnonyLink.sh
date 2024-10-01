#!/bin/bash

# AnonyLink
# Description: 
# The script is used to maintain anonymity and protect the user's identity.
# This requires root privileges to disable network interfaces
# and change the MAC-address, hostname and connect to a Wi-Fi network with the specified MAC-address.

# Devs:
# Manuel Ziel (IgnotusDawn) <ManuelZiel@gmail.com>

# AnonyLink is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# You can get a copy of the license at www.gnu.org/licenses
#
# AnonyLink is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# with this Repro. If not, see <http://www.gnu.org/licenses/>.

# Save the script in a file (e.g. AnonyLink.sh),
# open the terminal in the same directory and make it executable with the following commands:
# sudo chmod +x AnonyLink.sh
# Start the script with the following command:
# sudo ./AnonyLink.sh

# See anonsurf https://github.com/ParrotSec/anonsurf
# use https://check.torproject.org/api/ip to check if the IP-address is over TOR
# use https://check.torproject.org/exit-addresses to check if the IP-Address is a TOR exit node
# use https://ipleak.net/ to check for DNS-Leaks

# Variables used in the script:
# $NEW_HOSTNAME: The new hostname for the system.
# $INTERFACE: The network interface that will be used (e.g. wlan0).
# $NEW_MAC: The new MAC-Address that will be assigned to the interface.

export created="Manuel Ziel (IgnotusDawn)"
export version="1.0"
export codename="Early Phantom"
export BLUE='\033[1;94m'
export GREEN='\033[1;92m'
export RED='\033[1;91m'
export YELLOW='\033[1;93m'
export RESETCOLOR='\033[1;00m'
export DISABLE_AUTO_WRAP='\033[?7l'
export ENABLE_AUTO_WRAP='\033[?7h'

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

PARAMETER_HOSTNAME=false
PARAMETER_MAC=false
PARAMETER_ANON=false
NEW_HOSTNAME=""
INTERFACE=""
NEW_MAC=""
SELECTED_NETWORK=""
SECURED_NETWORK=""

# Function to check the failed anonyme network state
check_failed_anonyme_network_state() {
    if [ -f /tmp/failed_anonyme_network_state ]; then
        echo -e "\nLast state failed with: "
        cat /tmp/failed_anonyme_network_state
        read -p "${RED}WARNING! THERE IS AN ERROR MESSAGE IN THE MEMORY. THIS CAN BE CRITICAL. CHECK IT! DO YOU WANT TO CONTINUE ANYWAY? (y/n)${RESETCOLOR}:" confirm
        if [ "$confirm" == "y" ]; then
            # Delete the failed state
            read -p "Delete the failed state? (y/n)" confirm_delete
            if [ "$confirm_delete" == "y" ]; then            
                sudo rm -f /tmp/failed_anonyme_network_state
                if [ $? -eq 0 ]; then
                    echo -e "\nSuccessfully deleted the failed state."
                else
                    echo -e "\n${RED}Failed to delete the failed state.${RESETCOLOR}"
                    exit 1
                fi
            else
                echo "Aborting Skript."
                exit 1
            fi
        else
            echo "Aborting Skript."
            exit 1
        fi
    fi
}

# Function to write the failed anonyme network state
write_failed_anonyme_network_state() {
    local message=$1
    echo "$message" > /tmp/failed_anonyme_network_state
}

# Set Parameter
set_parameter() {
    read -p "Change Hostname and MAC-Address? (y/n): " confirm_parm_one
    if [ "$confirm_parm_one" == "y" ]; then
        # Set parameter hostname and mac
        PARAMETER_HOSTNAME=true
        PARAMETER_MAC=true

        # Set AnonSurf
        if command -v anonsurf &> /dev/null; then
            read -p "Start AnonSurf? (y/n): " confirm_parm_two
            if [ "$confirm_parm_two" == "y" ]; then
                PARAMETER_ANON=true
            else
                PARAMETER_ANON=false
            fi
        else
            echo -e "${RED} Your System can not run under TOR ${RESETCOLOR}"
            read -p "${RED} AnonSurf is not installed. Continue without AnonSurf? (y/n): ${RESETCOLOR}" confirm_parm_three
            if [ "$confirm_parm_three" == "y" ]; then
                PARAMETER_ANON=false
            else
                echo -e "You aborted the script."
                exit 1
            fi
        fi
    else
        echo -e "Script aborted. MAC and Hostname is the minimum requirement."
        exit 1
    fi

    # Show the parameter
    echo -e "\nParameters:"
    echo -e "Change Hostname\t\t ... ${BLUE} $PARAMETER_HOSTNAME ${RESETCOLOR}"
    echo -e "Change MAC-Address\t ... ${BLUE} $PARAMETER_MAC ${RESETCOLOR}"
    echo -e "Start AnonSurf\t\t ... ${BLUE} $PARAMETER_ANON ${RESETCOLOR}"

    read -p "Do you want to continue with these parameters? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo -e "Script aborted."
        exit 1
    fi
}

# Delete all saved networks
delete_saved_networks() {
    echo -e "\nDelete all saved networks..."
    sudo rm -f /etc/NetworkManager/system-connections/*
    if [ $? -eq 0 ]; then
        echo -e "Successfully deleted all saved networks."
    else
        echo -e "${RED}Failed to delete all saved networks.${RESETCOLOR}"
        exit 1
    fi
}

# Disable all network interfaces
function_disable_interfaces() {
    echo "Disabling all network interfaces..."
    for iface in $(ls /sys/class/net/); do
        sudo ip link set $iface down
        if [ $? -eq 0 ]; then
            echo -e "Successfully disabled $iface."
        else
            echo -e "${RED}Failed to disable $iface.${RESETCOLOR}"
            exit 1
        fi
    done
}

# Function to stop all network services and reset the network configurations
function_stop_network_services() {
    local green_stopped="${GREEN}STOPPED${RESETCOLOR}"

    echo -e "\nStop all network services:"

    # Stop all main network services
    sudo systemctl stop NetworkManager
    if [ $? -eq 0 ]; then
        echo -e "NetworkManager\t ... $green_stopped"
    else
        echo -e "${RED}WARNING! Failed to stop NetworkManager service. Poweroff system...${RESETCOLOR}"
        write_failed_anonyme_network_state "Failed to stop NetworkManager service."

        # Power off the system if the NetworkManager service cannot be stopped
        sudo poweroff
        exit 1
    fi

    sudo systemctl stop networking
    if [ $? -eq 0 ]; then
        echo -e "networking\t ... $green_stopped"
    else
        echo -e "${RED}WARNING! Failed to stop networking service. Poweroff system...${RESETCOLOR}"
        write_failed_anonyme_network_state "Failed to stop networking service."

        # Power off the system if the networking service cannot be stopped
        sudo poweroff
        exit 1
    fi

    sudo systemctl stop wpa_supplicant
    if [ $? -eq 0 ]; then
        echo -e "wpa_supplicant\t ... $green_stopped"
    else
        echo -e "${RED}WARNING! Failed to stop wpa_supplicant service. Poweroff system...${RESETCOLOR}"
        write_failed_anonyme_network_state "Failed to stop wpa_supplicant service."

        # Power off the system if the wpa_supplicant service cannot be stopped
        sudo poweroff
        exit 1
    fi

    sudo systemctl stop bluetooth
    if [ $? -eq 0 ]; then
        echo -e "bluetooth\t ... $green_stopped"
    else
        echo -e "${RED}WARNING! Failed to stop bluetooth service. Poweroff system...${RESETCOLOR}"
        write_failed_anonyme_network_state "Failed to stop bluetooth service."

        # Power off the system if the bluetooth service cannot be stopped
        sudo poweroff
        exit 1
    fi
}
    
# Function to check all network services
function_check_network_services() {
    local parameter_anon=$1

    local green_run="${GREEN}RUN${RESETCOLOR}"
    local green_started="${GREEN}STARTED${RESETCOLOR}"
    local green_stopped="${GREEN}STOPPED${RESETCOLOR}"

    echo "Checking network services..."

    # Check if the NetworkManager service is running
    if systemctl is-active --quiet NetworkManager; then
        echo -e "NetworkManager\t ... $green_run"
    else
        sudo systemctl start NetworkManager
        if [ $? -eq 0 ]; then
            echo -e "NetworkManager\t ... $green_started"
        else
            echo -e "\n${RED}Failed to start NetworkManager service.${RESETCOLOR}"
            exit 1
        fi
    fi

    # Check if the networking service is running
    if systemctl is-active --quiet networking; then
        echo -e "networking\t ... $green_run"
    else
        sudo systemctl start networking
        if [ $? -eq 0 ]; then
            echo -e "networking\t ... $green_started"
        else
            echo -e "\n${RED}Failed to start networking service.${RESETCOLOR}"
            exit 1
        fi
    fi

    # Check if the wpa_supplicant service is running
    if systemctl is-active --quiet wpa_supplicant; then
        echo -e "wpa_supplicant\t ... $green_run"
    else
        sudo systemctl start wpa_supplicant
        if [ $? -eq 0 ]; then
            echo -e "wpa_supplicant\t ... $green_started"
        else
            echo -e "\n${RED}Failed to start wpa_supplicant service.${RESETCOLOR}"
            exit 1
        fi
    fi

    # Disable Bluetooth service
    sudo systemctl stop bluetooth
    if [ $? -eq 0 ]; then
        echo -e "bluetooth\t ... $green_stopped"
    else
        echo "${RED}WARNING! Failed to stop bluetooth service. Poweroff system...${RESETCOLOR}"
        write_failed_anonyme_network_state "Failed to stop bluetooth service."
        function_stop_network_services
        exit 1
    fi

    # Check AnonSurf
    if [ "$parameter_anon" = true ]; then 
    echo "Checking AnonSurf..."   
    anonsurf start
    anonsurf_output=$(anonsurf start)
        if echo "$anonsurf_output" | grep -q "AnonSurf is running"; then
            echo -e "AnonSurf\t ... $green_run"
        else
            echo -e "\n${RED}Failed to start AnonSurf service.${RESETCOLOR}"
            exit 1
        fi
    fi
}

# Function to change the hostname
change_hostname() {
    local new_hostname=$1

    # First update /etc/hosts with the new hostname
    sudo sed -i "s/^127.0.0.1.*/127.0.0.1\tlocalhost\t$new_hostname/" /etc/hosts
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}Failed to update /etc/hosts with new hostname.${RESETCOLOR}"
        exit 1
    fi

    sleep 2  # Wait for the changes to take effect

    # Then change the hostname using hostnamectl
    sudo hostnamectl set-hostname "$new_hostname"
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}hostnamectl failed to change the hostname.${RESETCOLOR}"
        exit 1
    fi

    sleep 2  # Wait for the changes to take effect

    # Force the system to reload the hostname configuration
    echo -e "\nRestarting networking service..."
    sudo systemctl restart networking
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}Failed to restart networking service.${RESETCOLOR}"
        exit 1
    fi

    sleep 2  # Wait for the changes to take effect

    # Verify the new hostname
    local current_hostname=$(hostname)
    if [ "$current_hostname" == "$new_hostname" ]; then
        echo "Hostname successfully changed to $new_hostname."
    else
        echo -e "\n${RED}Failed to change the hostname. Aborting connection.${RESETCOLOR}"
        exit 1
    fi
}

# Prompt for a new Hostname
prompt_hostname() {
    local new_hostname

    # Show the current Hostname
    local current_hostname=$(hostname)
    echo -e "\nNote: To maintain your anonymity, you should choose a hostname \nthat does not contain any personal information and changes regularly. \nAn anonymized hostname helps protect your identity and prevents \npossible conclusions about your true identity."
    echo -e "\nCurrent Hostname: $current_hostname"
    while true; do
        read -p "Type the new Hostname: " new_hostname
        if [ -z "$new_hostname" ]; then
            echo "Hostname cannot be empty. Please try again."
            continue
        fi

        read -p "Do you want to use this Hostname: $new_hostname? (y/n): " confirm_hostname
        if [ "$confirm_hostname" == "y" ]; then
            # Set Hostname
            change_hostname $new_hostname
            break
        else
            echo "Type a new Hostname!"
        fi
    done
    NEW_HOSTNAME=$new_hostname
}

# Function to select the network interface
function_select_interface() {
    local interfaces=($(ip link show | grep "^[0-9]:" | awk -F: '{print $2}' | tr -d ' '))
    local interface

    echo -e "\nSelect network interface:"
    select interface in "${interfaces[@]}"; do
        if [[ -n "$interface" ]]; then
            echo "Selected interface: $interface"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    INTERFACE=$interface
}

# Show the permanent MAC address
show_perm_mac() {
    local interface=$1

    echo -e "\n"
    local perm_mac=$(ip link show $interface | grep -oP '(?<=permaddr )([0-9a-f]{2}:){5}[0-9a-f]{2}')
    if [ -n "$perm_mac" ]; then
        local oui=$(echo $perm_mac | cut -d':' -f1-3)
        local rest=$(echo $perm_mac | cut -d':' -f4-6)
        echo -e "Permanent MAC-Address: ${RED}$oui${RESETCOLOR}:$rest"
    else
        echo "${YELLOW}Permanent MAC-Address not found.${RESETCOLOR}"
    fi
}

# Prompt for MAC address
prompt_mac_address() {
    local interface=$1
    local new_mac

    # Show the permanent MAC address
    show_perm_mac $interface

    while true; do
        read -p "Type the new MAC address (or press Enter to set a random MAC): " new_mac
        if [ -z "$new_mac" ]; then
            new_mac=$(sudo macchanger -r $interface | grep 'New MAC' | awk '{print $3}')
            echo "Generated random MAC-Address: $new_mac"
        else
            # Validate MAC address format
            if ! [[ "$new_mac" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
                echo "Invalid MAC-Address format. Please try again."
                continue
            fi
        fi

        local oui=$(echo $new_mac | cut -d':' -f1-3)
        local rest=$(echo $new_mac | cut -d':' -f4-6)
        echo -e "New MAC-Address: ${RED}$oui${RESETCOLOR}:$rest"    

        read -p "Do you want to use this MAC-Address: $new_mac? (y/n): " confirm_mac
        if [ "$confirm_mac" == "y" ]; then
            break
        fi
    done

    NEW_MAC=$new_mac
}

# Function to change the MAC address
change_mac_address() {
    local interface=$1
    local new_mac=$2

    # Set the interface with the new MAC address
    echo "Changing MAC address of $interface to $new_mac..."

    sudo ip link set $interface down
    sudo ip link set $interface address $new_mac
    sudo ip link set $interface up

    echo "Waiting for the interface to come up..."

    # Verify MAC address change
    local current_mac=$(cat /sys/class/net/$interface/address)
    if [ "$current_mac" == "$new_mac" ]; then
        echo "MAC address successfully changed to $new_mac."
    else
        echo -e "\n${RED}Failed to change MAC-Address.${RESETCOLOR}"
        exit 1
    fi
}

# Scan for available Wi-Fi networks
function_scan_wifi_networks() {
    local interface=$1

    echo -e "\nScanning for available Wi-Fi networks..."
    sudo iwlist $interface scan | grep 'ESSID\|Encryption key\|Quality'

    # List available Wi-Fi networks
    networks=$(nmcli -t -f SSID,SECURITY,SIGNAL device wifi list ifname $interface)

    # Combine open and secured networks into an array with labels
    IFS=$'\n' read -d '' -r -a network_list <<< "$(echo "$networks" | awk -F: '{if ($2 == "") print "[Open] \"" $1 "\" (Signal: " $3 "%)"; else print "[Encrypted] \"" $1 "\" (Signal: " $3 "%)"}')"

    # Prompt user to select a network
    echo -e "\nSelect a Wi-Fi network:"
    select network in "${network_list[@]}"; do
        if [[ -n "$network" ]]; then
            echo "Selected network: $network"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    SELECTED_NETWORK=$(echo "$network" | awk -F\" '{print $2}')
    if echo "$network" | grep -q "\[Encrypted\]"; then
        SECURED_NETWORK=true
    else
        SECURED_NETWORK=false
    fi
}

# Check if the Hostname was changed during the connection
function_check_hostname_change() {
    local new_hostname=$1

    # Check if the Hostname was changed during the connection
    local current_hostname=$(hostname)
    if [ "$current_hostname" != "$new_hostname" ]; then
        local massage="The hostname was unauthorizedly changed from $new_hostname to $current_hostname during the connection. The connection will be killed."
        echo -e "${RED}WARNING!${RESETCOLOR} $massage"
        write_failed_anonyme_network_state "The hostname was unauthorizedly changed."
        function_disable_interfaces
        function_stop_network_services
        cleanup
    fi
}

# Check if someone changed the MAC address
function_check_mac_address_change() {
    local interface=$1
    local new_mac=$2

    # Check if the MAC address was changed during the connection
    local phys_mac=$(cat /sys/class/net/$interface/address)
    if [ "$phys_mac" != "$new_mac" ]; then
        local massage="The MAC-Address was unauthorizedly changed from $new_mac to $phys_mac. \nAborting connection."
        echo -e "${RED}WARNING!${RESETCOLOR} $massage"
        write_failed_anonyme_network_state "The MAC-Address was unauthorizedly changed."
        function_disable_interfaces
        function_stop_network_services
        cleanup
    fi
}

# Connect to the selected Wi-Fi network
function_connect_to_network() {
    local parameter_anon=$1
    local interface=$2
    local selected_network=$3
    local secured_network=$4
    local new_mac=$5
    local new_hostname=$6

    echo -e "\n"
    if [ "$secured_network" == "true" ] ; then
        read -sp "Type the password for $selected_network: " password
        echo -e "\n"
        read -p "Do you want to connect to $selected_network with the MAC-Address $new_mac over $interface? (y/n): " confirm_connection
        if [ "$confirm_connection" == "y" ]; then

            # Add a new connection
            nmcli connection add type wifi ifname "$interface" con-name "$selected_network" ssid "$selected_network" \
            802-11-wireless.cloned-mac-address "$new_mac" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$password"

            # Connection up
            nmcli connection up "$selected_network"

            if [ $? -eq 0 ]; then
                echo -e "\nSuccessfully connected to $selected_network."
                # Start monitoring changes in the background
                start_savety_monitor_task $parameter_anon $interface $new_mac $new_hostname
            else
                echo -e "\n${RED}Failed to connect to $selected_network.${RESETCOLOR}"
                function_disable_interfaces
                function_stop_network_services
                exit 1
            fi
        else
            echo -e "\nConnection aborted."
            exit 1
        fi
    else
        read -p "The network $selected_network is open. Do you want to connect with the MAC-Address $new_mac over $interface? (y/n): " confirm_connection
        if [ "$confirm_connection" == "y" ]; then

            # Add a new connection
            nmcli connection add type wifi ifname "$interface" con-name "$selected_network" ssid "$selected_network" \
            802-11-wireless.cloned-mac-address "$new_mac"

            # Connection up
            nmcli connection up "$selected_network"

            if [ $? -eq 0 ]; then
                echo -e "\nSuccessfully connected to $selected_network."
                # Start monitoring changes in the background
                start_savety_monitor_task $parameter_anon $interface $new_mac $new_hostname
            else
                echo -e "\n${RED}Failed to connect to $selected_network.${RESETCOLOR}"
                function_disable_interfaces
                function_stop_network_services
                exit 1
            fi
        else
            echo -e "\nConnection aborted."
            exit 1
        fi
    fi
}

# Function to check Hostname and MAC-Address in a loop
savety_monitor_task() {
    local parameter_anon=$1
    local interface=$2
    local new_mac=$3
    local new_hostname=$4
    local response=""

    local green_running="${GREEN}RUNNING${RESETCOLOR}"
    local green_started="${GREEN}STARTED${RESETCOLOR}"
    local green_stopped="${GREEN}STOPPED${RESETCOLOR}"

    while true; do
        function_check_hostname_change $new_hostname
        function_check_mac_address_change $interface $new_mac

        # Disable Bluetooth service
        if systemctl is-active --quiet bluetooth; then
            sudo systemctl stop bluetooth
            if [ $? -eq 0 ]; then
                echo -e "bluetooth\t ... $green_stopped"
            else
                echo "${RED}WARNING! Failed to stop bluetooth service. Poweroff system...${RESETCOLOR}"
                write_failed_anonyme_network_state "Failed to stop bluetooth service."
                function_stop_network_services
                cleanup
                exit 1
            fi
        fi

        # Check AnonSurf services are still running 
        if [ "$parameter_anon" = true ]; then
            local anonsurf_status=$(anonsurf myip)
            if echo "$anonsurf_status" | grep -q "Resource temporarily unavailable"; then
                response="AnonSurf service has no network connection."
                exit 1
            elif echo "$anonsurf_status" | grep -q "You are under Tor network"; then
                response="AnonSurf\t ... $green_running"
            elif echo "$anonsurf_status" | grep -q "You are not under Tor network"; then
                response="${RED}Failed you are not under Tor.${RESETCOLOR}"
                echo -e "\n${RED}Failed you are not under Tor.${RESETCOLOR}"
                write_failed_anonyme_network_state "Failed you are not under Tor"
                function_stop_network_services
                cleanup
                exit 1
            else
                response="${RED}Unknown AnonSurf status.${RESETCOLOR}"
                echo -e "\n$response"
                write_failed_anonyme_network_state "Unknown AnonSurf status"
                function_stop_network_services
                cleanup
                exit 1
            fi
        fi

        # Check for changes in the network connection
        echo -ne "${BLUE}Last savety monitor check: $(date +'%H:%M:%S') "$response" \r ${RESETCOLOR}"

        sleep 20  # Check every 20 seconds
    done
}

# run the function to monitor changes in the background
start_savety_monitor_task() {
    local parameter_anon=$1
    local interface=$2
    local new_mac=$3
    local new_hostname=$4
    local monitor_pid=$!

    # Clear the terminal
    clear
    display_banner
    echo -e "\nStarting background task savety monitor to check changes at the network connection..."
    echo -e "Stop the script with ctrl + c to kill the background task \nor run the following command:"
    echo -e "sudo kill -9 $monitor_pid"

    sleep 10  # Wait for the connection to establish
    echo -e "\nMonitoring changes at the network connection:\nAnonSurf: "$parameter_anon"; interface: "$interface"; mac: "$new_mac"; hostname: "$new_hostname""
    echo -e "\n"

    savety_monitor_task $parameter_anon $interface $new_mac $new_hostname &
    
    # Set trap to catch SIGINT (Ctrl + C) and call cleanup
    trap "cleanup $monitor_pid" SIGINT

    # Wait for the background task to finish (which it won't, unless killed)
    wait $monitor_pid
}

# Function to handle script termination
cleanup() {
    local parameter_anon=$PARAMETER_ANON
    local monitor_pid=$1
    echo "Terminating background task..."
    kill -TERM $monitor_pid
    wait $monitor_pid 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Background task terminated."
    else
        echo "Failed to terminate background task."
    fi

    function_disable_interfaces
    function_stop_network_services
    delete_saved_networks
    function_check_network_services $parameter_anon
    exit 0
}

# Main script

# Display the banner
display_banner

# Check if the script is running with root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW} \nThis script requires root privileges to disable network interfaces and change the MAC address. ${RESETCOLOR}"
    echo -e "${YELLOW} Please run this script with sudo ${RESETCOLOR}"
    echo -e "${YELLOW} Example: sudo anonylink ${RESETCOLOR}\n"
    exit 1
fi

# Set parameter
set_parameter

# Disable all network interfaces
function_stop_network_services

# Check if the last connection failed
check_failed_anonyme_network_state

# Delete all saved networks (if required)
delete_saved_networks

# Check the network services with ufw and tor
function_check_network_services $PARAMETER_ANON

# Prompt for a new hostname
prompt_hostname

# Select the network interface
function_select_interface

# Prompt for MAC-Address
prompt_mac_address $INTERFACE

# Scan for available Wi-Fi networks
function_scan_wifi_networks $INTERFACE

# Connect to the selected Wi-Fi network with the specified MAC address
function_connect_to_network $PARAMETER_ANON $INTERFACE $SELECTED_NETWORK $SECURED_NETWORK $NEW_MAC $NEW_HOSTNAME