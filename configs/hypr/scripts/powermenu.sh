#!/usr/bin/env bash

# ==============================================================================
#  CONFIGURATION
# ==============================================================================
TEMP_THEME_FILE="/tmp/rofi-powermenu.rasi"

# Options (Nerd Fonts included directly in the strings)
# Ensure you have a Nerd Font installed (like JetBrainsMono Nerd Font)
logout="󰗽    Logout"
poweroff="    Poweroff"
reboot="    Reboot"
suspend="    Suspend"
cancel="󰜉    Cancel"

# ==============================================================================
#  ROFI THEME GENERATION (Vertical Monolith)
# ==============================================================================
cat > "$TEMP_THEME_FILE" << EOF
/*****----- Configuration -----*****/
configuration {
    show-icons:                 false;
    /* SMOOTH SELECTION */
    hover-select:               true;
    me-select-entry:            "MousePrimary";
    me-accept-entry:            "!MousePrimary";
}

/*****----- Global Properties -----*****/
* {
    font:                       "JetBrains Mono Bold 12";
    
    /* COLORS */
    bg-col:                     #101010FA;  /* Dark Background */
    sel-bg:                     #202020FF;  /* Lighter Selection */
    border-col:                 #cccccc;    /* gray-white Border */
    text-col:                   #FFFFFF;    /* White Text */
    
    background-color:           transparent;
    text-color:                 @text-col;
    margin:                     0px;
    padding:                    0px;
}

/*****----- Main Window -----*****/
window {
    location:                    center;
    anchor:                      center;
    fullscreen:                  false;
    
    /* Fixed Width for the menu */
    width:                       300px;
    
    /* SHARP CORNERS */
    border-radius:               0px;
    
    background-color:            @bg-col;
    
    /* 1px BORDER */
    border:                      1px;
    border-color:                @border-col;
    
    children:                    [ "listview" ];
}

/*****----- Listview -----*****/
listview {
    enabled:                     true;
    columns:                     1;
    lines:                       5; /* 5 items */
    cycle:                       true;
    dynamic:                     true;
    scrollbar:                   false;
    layout:                      vertical;
    
    spacing:                     10px;
    padding:                     20px;
    
    background-color:            transparent;
    cursor:                      "default";
}

/*****----- Elements -----*****/
element {
    enabled:                     true;
    padding:                     12px;
    border-radius:               0px;
    cursor:                      pointer;
    background-color:            transparent;
    text-color:                  @text-col;
    
    /* Invisible border to keep alignment */
    border:                      1px;
    border-color:                transparent;
}

element selected.normal {
    background-color:            @sel-bg;
    text-color:                  @border-col;
    
    /* Sharp 1px Highlight Border */
    border:                      1px;
    border-color:                @border-col;
}

element-text {
    background-color:            transparent;
    text-color:                  inherit;
    cursor:                      inherit;
    vertical-align:              0.5;
    horizontal-align:            0.0; /* Left Align */
}
EOF

# ==============================================================================
#  LOGIC
# ==============================================================================

# Feed the options into Rofi
CHOICE=$(echo -e "$poweroff\n$reboot\n$suspend\n$logout\n$cancel" | rofi -dmenu \
    -theme "$TEMP_THEME_FILE" \
    -p "Power")

# Actions
case "$CHOICE" in
  "$logout")
    hyprctl dispatch exit
    ;;
  "$poweroff")
    systemctl poweroff
    ;;
  "$reboot")
    systemctl reboot
    ;;
  "$suspend")
    # Lock screen logic (checking for hyprlock or swaylock)
    if command -v hyprlock &> /dev/null; then
        pidof hyprlock || hyprlock &
        sleep 1
    elif command -v swaylock &> /dev/null; then
        pidof swaylock || swaylock &
        sleep 1
    fi
    systemctl suspend
    ;;
  "$cancel")
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
