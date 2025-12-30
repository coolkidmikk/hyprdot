#!/bin/bash

# ==============================================================================
#  CONFIGURATION
# ==============================================================================
CACHE_DIR="${HOME}/.cache"
EMOJI_FILE="${CACHE_DIR}/emojis.txt"
TEMP_THEME_FILE="/tmp/rofi-emoji.rasi"

# Source: Official Unicode Consortium List
EMOJI_SOURCE_URL="https://unicode.org/Public/emoji/15.0/emoji-test.txt"

# Check dependencies
if ! command -v curl &> /dev/null; then notify-send "Error" "curl is missing"; exit 1; fi
if ! command -v wl-copy &> /dev/null; then notify-send "Error" "wl-copy is missing"; exit 1; fi

# ==============================================================================
#  1. FETCH EMOJI LIST
# ==============================================================================
if [ -f "$EMOJI_FILE" ]; then
    if grep -q "404" "$EMOJI_FILE"; then rm "$EMOJI_FILE"; fi
fi

if [ ! -f "$EMOJI_FILE" ]; then
    notify-send "Emoji Picker" "Downloading emoji list..."
    curl -sL "$EMOJI_SOURCE_URL" | \
    grep "; fully-qualified" | \
    awk -F'# ' '{print $2}' | \
    sed 's/E[0-9]\+\.[0-9]\+ //g' > "$EMOJI_FILE"
fi

# ==============================================================================
#  2. ROFI THEME GENERATION
# ==============================================================================
cat > "$TEMP_THEME_FILE" << EOF
/*****----- Configuration -----*****/
configuration {
    show-icons:                 false;
    hover-select:               true;
    me-select-entry:            "MousePrimary";
    me-accept-entry:            "!MousePrimary";
}

/*****----- Global Properties -----*****/
* {
    /* 
       Global Font: Strict JetBrains Mono Nerd Font.
       We do NOT add the emoji font here, to prevent it from overriding text.
    */
    font:                       "JetBrainsMono Nerd Font 10";
    
    /* COLORS */
    bg-col:                     #101010FA;
    sel-bg:                     #202020FF;
    border-col:                 #cccccc;
    text-col:                   #FFFFFF;
    dim-col:                    #606060;
    
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
    width:                       380px;
    height:                      420px;
    border-radius:               0px;
    background-color:            @bg-col;
    border:                      1px;
    border-color:                @border-col;
    children:                    [ "inputbar", "listview" ];
}

/*****----- Input Bar -----*****/
inputbar {
    enabled:                     true;
    spacing:                     10px;
    padding:                     12px;
    border:                      0px 0px 1px 0px;
    border-color:                #303030;
    children:                    [ "textbox-prompt-colon", "entry" ];
}

textbox-prompt-colon {
    enabled:                     true;
    expand:                      false;
    str:                         " "; 
    text-color:                  @border-col;
    padding:                     0px 5px 0px 0px;
}

entry {
    enabled:                     true;
    text-color:                  @text-col;
    cursor:                      text;
    placeholder:                 "Search...";
    placeholder-color:           @dim-col;
}

/*****----- Listview -----*****/
listview {
    enabled:                     true;
    columns:                     1;
    lines:                       8;
    cycle:                       true;
    dynamic:                     true;
    scrollbar:                   false;
    layout:                      vertical;
    spacing:                     5px;
    padding:                     10px;
    background-color:            transparent;
}

/*****----- Elements -----*****/
element {
    enabled:                     true;
    padding:                     8px 10px;
    border-radius:               0px;
    cursor:                      pointer;
    background-color:            transparent;
    text-color:                  @text-col;
    orientation:                 horizontal;
    spacing:                     15px; 
    border:                      1px;
    border-color:                transparent;
}

element selected.normal {
    background-color:            @sel-bg;
    text-color:                  @border-col;
    border:                      1px;
    border-color:                @border-col;
}

/* Enable Pango Markup to allow font switching inline */
element-text {
    background-color:            transparent;
    text-color:                  inherit;
    cursor:                      inherit;
    vertical-align:              0.5;
    horizontal-align:            0.0;
    markup:                      true;
}
EOF

# ==============================================================================
#  3. EXECUTION
# ==============================================================================

# FORCE TWEMOJI FOR ICONS
# We wrap the emoji in a span tag specifying the font family "Twemoji"
# If "Twemoji" doesn't work, try "Twitter Color Emoji" (depends on how the system named it)
SELECTED=$(awk '{ 
    emoji=$1; 
    $1=""; 
    print "<span font=\"Twemoji Mozilla\" size=\"large\">" emoji "</span>" $0 
}' "$EMOJI_FILE" | rofi -dmenu \
    -markup-rows \
    -name "rofi_emoji" \
    -theme "$TEMP_THEME_FILE" \
    -i \
    -p "Emoji")

if [ -z "$SELECTED" ]; then
    exit 0
fi

# Clean up tags before pasting
EMOJI=$(echo "$SELECTED" | sed 's/<[^>]*>//g' | awk '{print $1}')

echo -n "$EMOJI" | wl-copy
hyprctl dispatch sendshortcut CTRL, V, activewindow
