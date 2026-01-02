#!/bin/bash

# --- CONFIGURATION ---
# 1. Where to save the video

mkdir -p $HOME/Videos/screenrec

VIDEODIR="$HOME/Videos/screenrec"
FILENAME="$VIDEODIR/rec_$(date +%Y-%m-%d_%H-%M-%S).mp4"

# 2. Audio Settings
# By default, audio is disabled (empty string). 
# To ENABLE audio, simply remove the '#' from the line below:

 AUDIO_ARGS="--audio"
#AUDIO_ARGS="" 

# ---------------------

# Check if recording is already running
if pidof wl-screenrec > /dev/null; then
    # --- STOP RECORDING ---
    # We use SIGINT so the file finalizes correctly
    pkill --signal SIGINT wl-screenrec
    
    # Send notification
    notify-send "Screen Record" "Recording saved to $VIDEODIR" -i video-x-generic
else
    # --- START RECORDING ---
    # Ensure the folder exists
    mkdir -p "$VIDEODIR"
    
    # specific region selection
    GEOMETRY=$(slurp)
    
    # If user hits Esc, exit script
    if [ -z "$GEOMETRY" ]; then
        exit 1
    fi

    # Send notification
    notify-send "Screen Record" "Recording started..." -i video-x-generic
    
    # Start the background process
    # $AUDIO_ARGS will be ignored if it is empty
    wl-screenrec --geometry "$GEOMETRY" --filename "$FILENAME" $AUDIO_ARGS & 
fi
