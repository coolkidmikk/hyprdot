#!/bin/bash

# Configuration
step=5  # Volume increase/decrease step size

# Check for arguments
if [ -z "$1" ]; then
  echo "Usage: $0 [up|down|mute]"
  exit 1
fi

# Execute pamixer command based on argument
case "$1" in
  up)
    pamixer -i "$step"
    ;;
  down)
    pamixer -d "$step"
    ;;
  mute)
    pamixer -t
    ;;
esac

# Get current volume and mute status
volume=$(pamixer --get-volume)
is_muted=$(pamixer --get-mute)

# Determine icon and text
if [ "$is_muted" = "true" ]; then
  icon="audio-volume-muted"
  text="Muted"
else
  if [ "$volume" -lt 30 ]; then
    icon="audio-volume-low"
  elif [ "$volume" -lt 70 ]; then
    icon="audio-volume-medium"
  else
    icon="audio-volume-high"
  fi
  text="$volume%"
fi

# Send notification
# -h string:x-canonical-private-synchronous:sys-notify -> Prevents notification stacking
# -h int:value:$volume -> Adds a progress bar (if supported by notification theme)
# -t 1000 -> Disappears after 1 second
notify-send \
  -h string:x-canonical-private-synchronous:sys-notify \
  -h int:value:"$volume" \
  -t 1000 \
  -i "$icon" \
  "Volume" "$text"
