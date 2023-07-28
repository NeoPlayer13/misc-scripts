#!/bin/bash

servers=("google.com" "yahoo.com" "facebook.com")
failed_count=0
PING_IP_ADDRESS=192.168.1.1

function check_server() {
    if dig +short @1.1.1.1 "$1" >/dev/null; then
        echo "Server $1 is reachable."
        return 0
    else
        echo "Server $1 is unreachable."
        return 1
    fi
}

function restart_sleep() {
    failed_count=0
    sleep 30
}

function reboot_if_needed() {
    if ping -c 1 "$PING_IP_ADDRESS" >/dev/null; then
        echo "The internet connection is down"
    else 
        echo "At least 2 out of 3 servers failed. Rebooting..."
        sudo reboot
    fi
}

sleep 30 # Line for giving time for DHCP to work correctly.

while true; do
    for server in "${servers[@]}"; do
        if ! check_server "$server"; then
            ((failed_count++))
        fi    
    done

    if [ "$failed_count" -eq 1 ]; then
        echo "At least 2 servers are reachable. Waiting 60 seconds before the next check..."
    elif [ "$failed_count" -ge 2 ]; then
        reboot_if_needed
    else
        echo "All servers are reachable. Waiting 60 seconds before the next check..."
    fi

    restart_sleep
    
done