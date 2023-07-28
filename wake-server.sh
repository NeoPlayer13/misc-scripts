#!/bin/bash

# Replace 'IP_ADDRESS_TO_PING' with the actual IP address you want to ping
IP_ADDRESS_TO_PING_1="x.x.x.x"
IP_ADDRESS_TO_PING_2="1.1.1.1"

# Replace 'MAC_ADDRESS_TO_WOL' with the actual MAC address you want to send the>
MAC_ADDRESS_TO_WOL="xx:xx:xx:xx:xx:xx"

# Replace 'NIC' with the network interface that you want to send the WOL packages with. 
NIC="xxx"

ping_successful() {
    echo "Both pings were successful"
}

ping_failed() {
    echo "At least one ping failed. Sending WoL packet..."
    sudo etherwake -i $NIC $MAC_ADDRESS_TO_WOL
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
