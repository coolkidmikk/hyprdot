#!/usr/bin/env bash

# --- CONFIGURATION ---
WIDTH=1000
HEIGHT=600
# ---------------------

# Check if the active window is currently floating
# We use grep to look for "floating: 1" in the active window info
if hyprctl activewindow | grep -q "floating: 1"; then
    # IF IT IS FLOATING:
    # Just toggle it back to tiling. 
    # We do NOT resize here, which fixes the "weird space" issue.
    hyprctl dispatch togglefloating
else
    # IF IT IS TILED:
    # 1. Float it
    # 2. Resize it to specific pixel size
    # 3. Center it
    hyprctl dispatch togglefloating
    hyprctl dispatch resizeactive exact $WIDTH $HEIGHT
    hyprctl dispatch centerwindow 1
fi
