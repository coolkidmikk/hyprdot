#!/bin/bash

# ==============================================================================
#   CONFIGURATION
# ==============================================================================
TEMP_THEME_FILE="/tmp/rofi-powermenu.rasi"

# Get Uptime
uptime=$(uptime -p | sed -e 's/up //g')

# Icons (Nerd Font)
shutdown=''
logout='󰍃'
reboot='󰜉'
lock=''
suspend='󰤄'

# ==============================================================================
#   ROFI THEME GENERATION
# ==============================================================================
cat > "$TEMP_THEME_FILE" << EOF
configuration {
    show-icons:                 false;
}

* {
    background:     #101010FA;
    background-alt: #ffffff10;
    foreground:     #FFFFFF;
    selected:       #FFFFFF;
    border-col:     #cccccc;
    font:           "JetBrainsMono Nerd Font 10";
}

window {
    transparency:                "real";
    location:                    center;
    anchor:                      center;
    width:                       500px;
    enabled:                     true;
    border:                      1px solid;
    border-color:                @border-col;
    background-color:            @background;
}

mainbox {
    enabled:                     true;
    spacing:                     15px;
    padding:                     25px;
    background-color:            transparent;
    children:                    [ "message", "listview" ];
}

message {
    enabled:                     true;
    background-color:            transparent;
    text-color:                  @foreground;
}

textbox {
    font:                        "JetBrainsMono Nerd Font 15";
    background-color:            transparent;
    text-color:                  inherit;
    vertical-align:              0.5;
    horizontal-align:            0.5;
}

listview {
    enabled:                     true;
    columns:                     5;
    lines:                       1;
    cycle:                       true;
    dynamic:                     true;
    scrollbar:                   false;
    layout:                      vertical;
    fixed-height:                true;
    fixed-columns:               true;
    spacing:                     15px;
    background-color:            transparent;
}

element {
    enabled:                     true;
    padding:                     15px 0px;
    border-radius:               4px;
    background-color:            transparent;
    text-color:                  @foreground;
    cursor:                      pointer;
}

element selected.normal {
    background-color:            @background-alt;
    border:                      1px solid;
    border-color:                @border-col;
    text-color:                  @selected;
}

element-text {
    font:                        "JetBrainsMono Nerd Font 24";
    background-color:            transparent;
    text-color:                  inherit;
    cursor:                      inherit;
    vertical-align:              0.5;
    horizontal-align:            0.5;
}
EOF

# ==============================================================================
#   LOGIC (Sequence: Shutdown, Logout, Reboot, Lock, Suspend)
# ==============================================================================

# Reordered the icons here:
CHOICE=$(echo -e "$shutdown\n$logout\n$reboot\n$lock\n$suspend" | rofi -dmenu \
    -theme "$TEMP_THEME_FILE" \
    -mesg "Uptime: $uptime" \
    -p "Power")

case "$CHOICE" in
    "$shutdown")
        systemctl poweroff
        ;;
    "$logout")
        hyprctl dispatch exit
        ;;        
    "$reboot")
        systemctl reboot
        ;;        
    "$lock")
        command -v hyprlock &>/dev/null && hyprlock || swaylock
        ;;
    "$suspend")
        systemctl suspend
        ;;
esac
