#!/bin/bash

# Configuration
step=10 # Brightness increase/decrease step size

# Check for arguments
if [ -z "$1" ]; then
  echo "Usage: $0 [up|down]"
  exit 1
fi

# Get current brightness level
# ddcutil getvcp 10 --brief outputs: "VCP 10 C <current> <max>"
# We use awk to grab the 4th field (current value)
current=$(ddcutil getvcp 10 --brief | awk '{print $4}')

# Fallback if ddcutil fails (e.g., monitor busy or permissions issue)
if [ -z "$current" ]; then
  notify-send -u critical "Brightness Error" "Could not read monitor brightness.\nCheck ddcutil permissions."
  exit 1
fi

# Calculate new brightness based on argument
case "$1" in
  up)
    new_brightness=$((current + step))
    # Clamp to max 100
    if [ "$new_brightness" -gt 100 ]; then new_brightness=100; fi
    ;;
  down)
    new_brightness=$((current - step))
    # Clamp to min 0
    if [ "$new_brightness" -lt 0 ]; then new_brightness=0; fi
    ;;
  *)
    echo "Usage: $0 [up|down]"
    exit 1
    ;;
esac

# Apply the new brightness
# Only set if the value actually changed to save I2C bus traffic
if [ "$current" -ne "$new_brightness" ]; then
    ddcutil setvcp 10 "$new_brightness"
fi

# Determine icon based on brightness level
# Common icon names: display-brightness-low/medium/high/off
if [ "$new_brightness" -le 30 ]; then
  icon="display-brightness-low"
elif [ "$new_brightness" -le 70 ]; then
  icon="display-brightness-medium"
else
  icon="display-brightness-high"
fi

# Send notification
# -h string:x-canonical-private-synchronous:brightness_notification -> Unique tag so it doesn't overwrite volume
# -h int:value:$new_brightness -> Progress bar
notify-send \
  -h string:x-canonical-private-synchronous:brightness_notification \
  -h int:value:"$new_brightness" \
  -t 1000 \
  -i "$icon" \
  "Brightness" "${new_brightness}%"
