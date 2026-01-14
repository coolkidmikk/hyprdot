#!/bin/bash

PING_TARGET="1.1.1.1"
ROUTE_OUTPUT=$(ip route get "$PING_TARGET" 2>/dev/null)

if [ $? -ne 0 ]; then
    # Use "alt" to trigger the "disconnected" icon
    echo '{"text": "No Internet", "alt": "disconnected", "class": "disconnected"}'
    exit 0
fi

INTERFACE=$(echo "$ROUTE_OUTPUT" | grep -oP 'dev \K\S+')

if ! ping -c 1 -W 1 "$PING_TARGET" &> /dev/null; then
    echo '{"text": "No Internet", "alt": "disconnected", "class": "disconnected"}'
    exit 0
fi

if [[ "$INTERFACE" == e* ]]; then
    IP_ADDR=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    # Use "alt" to trigger the "ethernet" icon
    echo "{\"text\": \"Wired\", \"alt\": \"ethernet\", \"class\": \"ethernet\", \"tooltip\": \"Interface: $INTERFACE\nIP: $IP_ADDR\"}"

elif [[ "$INTERFACE" == w* ]]; then
    SSID=$(iwgetid -r)
    SIGNAL=$(grep "$INTERFACE" /proc/net/wireless | awk '{print int($3 * 100 / 70)}')
    IP_ADDR=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    
    # We put the signal percentage directly into the "text" field
    echo "{\"text\": \"$SIGNAL%\", \"alt\": \"wifi\", \"class\": \"wifi\", \"tooltip\": \"SSID: $SSID\nSignal: $SIGNAL%\nIP: $IP_ADDR\"}"

else
    echo "{\"text\": \"Connected\", \"alt\": \"ethernet\", \"class\": \"ethernet\"}"
fi
