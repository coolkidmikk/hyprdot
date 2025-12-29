#!/usr/bin/env bash

# File to store current state
STATE_FILE="$HOME/.cache/gammastep_state"

# Default values
DEFAULT_TEMP=6500
DEFAULT_BRIGHT=1.0

# Steps for increment/decrement
TEMP_STEP=250
BRIGHT_STEP=0.05

# Min/Max limits
MIN_TEMP=1500
MAX_TEMP=8000
MIN_BRIGHT=0.1
MAX_BRIGHT=1.0

# Ensure state file exists
if [ ! -f "$STATE_FILE" ]; then
    echo "TEMP=$DEFAULT_TEMP" > "$STATE_FILE"
    echo "BRIGHT=$DEFAULT_BRIGHT" >> "$STATE_FILE"
fi

# Read current state
source "$STATE_FILE"

# Function to save state and apply
apply_changes() {
    # Save new values to file
    echo "TEMP=$TEMP" > "$STATE_FILE"
    echo "BRIGHT=$BRIGHT" >> "$STATE_FILE"

    # Kill existing gammastep instances to prevent conflicts
    pkill gammastep

    # Apply new settings
    # -O: Set specific temperature
    # -b: Set brightness (day:night, we set both same for manual control)
    # -P: Reset gamma ramps before applying (prevents weird color artifacts)
    # & disown: Run in background so it doesn't block the script
    gammastep -O "$TEMP" -b "$BRIGHT" -P & disown
    
    # Optional: Send a notification (requires dunst or mako installed)
    notify-send -h string:x-canonical-private-synchronous:gammastep \
        "Gammastep" "Temp: ${TEMP}K | Brightness: ${BRIGHT}" -t 1000
}

case "$1" in
    temp_up)
        if [ "$TEMP" -lt "$MAX_TEMP" ]; then
            TEMP=$((TEMP + TEMP_STEP))
            apply_changes
        fi
        ;;
    temp_down)
        if [ "$TEMP" -gt "$MIN_TEMP" ]; then
            TEMP=$((TEMP - TEMP_STEP))
            apply_changes
        fi
        ;;
    bright_up)
        # Bash doesn't handle floats well, using awk for comparison/addition
        BRIGHT=$(awk "BEGIN {print ($BRIGHT + $BRIGHT_STEP > $MAX_BRIGHT) ? $MAX_BRIGHT : $BRIGHT + $BRIGHT_STEP}")
        apply_changes
        ;;
    bright_down)
        BRIGHT=$(awk "BEGIN {print ($BRIGHT - $BRIGHT_STEP < $MIN_BRIGHT) ? $MIN_BRIGHT : $BRIGHT - $BRIGHT_STEP}")
        apply_changes
        ;;
    reset)
        TEMP=$DEFAULT_TEMP
        BRIGHT=$DEFAULT_BRIGHT
        apply_changes
        ;;
    *)
        echo "Usage: $0 {temp_up|temp_down|bright_up|bright_down|reset}"
        exit 1
        ;;
esac
