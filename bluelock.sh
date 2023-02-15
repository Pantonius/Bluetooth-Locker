#!/bin/bash

bt_addr=$1 # <your bluetooth device address>
bt_threshold=$2 # <your threshold value>
locked=false

coproc bluetoothctl
echo -e 'agent on' >&${COPROC[1]}

if [ -z $bt_addr ]; then
    answer=""
    while [ -z "$answer" ]; do
        echo "Scanning for devices..."
        
        echo -e 'scan on' >&${COPROC[1]}
        sleep 1.5
        devices=$(echo "devices" | bluetoothctl | tail -n+3 | grep -E '([A-F0-9]{2}:){5}[A-F0-9]{2}' | cut -d" " -f2- | nl)
        echo -e 'scan off' >&${COPROC[1]}
        
        echo "$devices"
        echo "Which device do you want to use for bluelock? (press ENTER to retry)"
        read answer

        if [ -z "$answer" ]; then
            continue
        fi

        bt_addr=$(echo "$devices" | grep -E "^[ ]*$answer" | sed -r 's/.*(([A-F0-9]{2}:){5}[A-F0-9]{2}).*/\1/g')
    done

    # TODO add pairing capability
    bluetoothctl discoverable on
    bluetoothctl connect $bt_addr
    bluetoothctl discoverable off
fi

if [ -z $bt_threshold ]; then
    bt_threshold=10
fi

while true; do
    res=$(hcitool rssi $bt_addr)
    rssi=$(echo $res | sed -r 's/(.*([0-9]+))/\2/g')

    if [ -z $rssi ] && [ $locked != true ]; then
        echo Device not connected!
    else
        printf "\r%b" "RSSI is $rssi"
        if [ $rssi -gt $bt_threshold ] && [ $locked != true ]; then
            locked=true
            $(xdg-screensaver lock)
        elif [ $rssi -lt $bt_threshold ] && [ $locked == true ]; then
            locked=false
            $(loginctl unlock-session)
        fi
    fi

    sleep 1
done