#!/bin/bash

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export DISPLAY=:0

# Get song info
# We use a specific format. If tags are empty, we handle it below.
INFO=$(mocp -Q "%artist\n%song\n%album\n%file")

# Read variables line by line
IFS=$'\n' read -d '' -r ARTIST TITLE ALBUM FILE <<< "$INFO"

# Logic: If Title is empty, use the Filename
if [ -z "$TITLE" ]; then 
    TITLE=$(basename "$FILE")
fi

# Logic: If Artist is empty, say Unknown
if [ -z "$ARTIST" ]; then
    ARTIST="Unknown Artist"
fi

# Send to Mako
# -a "mocp" sets the app-name (matches your mako group-by)
notify-send -a "mocp" \
            -h string:x-canonical-private-synchronous:mocp \
            -i multimedia-volume-control \
            "$TITLE" "$ARTIST"
