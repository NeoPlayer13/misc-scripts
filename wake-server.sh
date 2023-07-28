#!/bin/bash

# Replace 'IP_ADDRESS_TO_PING' with the actual IP address you want to ping
IP_ADDRESS_TO_PING_1="192.168.1.133"
IP_ADDRESS_TO_PING_2="1.1.1.1" #Modify later

# Replace 'MAC_ADDRESS_TO_WOL' with the actual MAC address you want to send the>
MAC_ADDRESS_TO_WOL="4C:CC:6A:0F:D2:38"

ping_successful() {
    echo "Both pings were successful"
}

ping_failed() {
    echo "At least one ping failed. Sending WoL packet..."
    sudo etherwake -i eth0 $MAC_ADDRESS_TO_WOL
}

while true; do
    if ping -c 1 $IP_ADDRESS_TO_PING_1 >/dev/null && ping -c 1 $IP_ADDRESS_TO_PING_2 >/dev/null; then
        ping_successful
    elif ping -c 1 $IP_ADDRESS_TO_PING_1 >/dev/null; then
        echo "First ping was successful but the second one failed"
        #echo "Control device have issues"
        echo "Internet connection is down" 
    elif ping -c 1 $IP_ADDRESS_TO_PING_2 >/dev/null; then
        echo "First ping failed but the second one was successful"
        ping_failed
    else
        echo "Both pings failed"
        echo "Possible network or power failure"
    fi
    sleep 300 # Wait for 5 minutes for the next check
done