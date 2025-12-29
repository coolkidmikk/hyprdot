#!/bin/bash

# ==============================================================================
#  CONFIGURATION
# ==============================================================================
CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"
TEMP_THEME_FILE="/tmp/rofi-keybinds.rasi"

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    notify-send "Error" "Rofi not installed."
    exit 1
fi

# ==============================================================================
#  1. PARSE HYPRLAND CONFIG
# ==============================================================================
# We use the parsing logic to extract binds that have a comment with #
DATA=$(grep "bind.*#" "$CONFIG_FILE" | grep -v "^\s*#" | \
    awk -F "#" '{
        # Clean up the config line
        gsub(/^\s*bind[a-z]*\s*=\s*/, "", $1);

        # Split: MOD, KEY, DISPATCHER, ARG
        split($1, parts, ",");
        
        mod = parts[1];
        key = parts[2];

        # Clean whitespace
        gsub(/^[ \t]+|[ \t]+$/, "", mod);
        gsub(/^[ \t]+|[ \t]+$/, "", key);
        gsub(/^[ \t]+|[ \t]+$/, "", $2);

        # Replace Variables with readable text
        gsub(/\$mainMod/, "SUPER", mod);
        gsub(/CTRL/, "Ctrl", mod);
        gsub(/SHIFT/, "Shift", mod);
        gsub(/ALT/, "Alt", mod);

        # Construct key combo
        if (mod == "") {
            keys = key;
        } else {
            keys = mod " + " key;
        }

        # Format: Description in Bold White, Keys in Faded Gray
        # We perform the spacing/padding inside Rofi theme, so we just output text here.
        if ($2 != "") {
            # XML/HTML escape (basic) to prevent Pango errors
            gsub(/&/, "&amp;", $2);
            gsub(/</, "&lt;", $2);
            gsub(/>/, "&gt;", $2);
            print "<b>" $2 "</b> <span foreground=\"#606060\">:: " keys "</span>"
        }
    }')

# ==============================================================================
#  2. ROFI THEME GENERATION (Data Sheet Style)
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
    font:                       "JetBrains Mono 10";
    
    /* COLORS */
    bg-col:                     #101010FA;   /* Dark Background */
    sel-bg:                     #202020FF;   /* Selection Background */
    border-col:                 #cccccc;     /* gray-white Border */
    text-col:                   #FFFFFF;     /* White Text */
    dim-col:                    #606060;     /* Dimmed Text */
    
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
    
    /* Width/Height */
    width:                       600px;
    height:                      65%;
    
    /* SHARP CORNERS */
    border-radius:               0px;
    background-color:            @bg-col;
    
    /* 1px BORDER */
    border:                      1px;
    border-color:                @border-col;
    
    children:                    [ "inputbar", "listview" ];
}

/*****----- Input Bar -----*****/
inputbar {
    enabled:                     true;
    spacing:                     10px;
    padding:                     15px;
    border:                      0px 0px 1px 0px; /* Separator line at bottom */
    border-color:                #303030;
    background-color:            transparent;
    children:                    [ "prompt", "entry" ];
}

prompt {
    enabled:                     true;
    padding:                     0px;
    text-color:                  @border-col;
    str:                         "  Keybinds";
}

entry {
    enabled:                     true;
    padding:                     0px;
    text-color:                  @text-col;
    placeholder:                 "Search...";
    placeholder-color:           @dim-col;
}

/*****----- Listview -----*****/
listview {
    enabled:                     true;
    columns:                     1;
    lines:                       10;
    cycle:                       true;
    dynamic:                     true;
    scrollbar:                   false; /* Scrollbar helps for long lists */
    layout:                      vertical;
    
    spacing:                     5px;
    padding:                     10px;
    
    background-color:            transparent;
    cursor:                      "default";
}

/* Custom Scrollbar handle */
scrollbar {
    handle-width:                2px;
    handle-color:                @border-col;
    background-color:            #303030;
    border-radius:               0px;
}

/*****----- Elements -----*****/
element {
    enabled:                     true;
    padding:                     8px 10px;
    border-radius:               0px;
    cursor:                      pointer;
    background-color:            transparent;
    text-color:                  @text-col;
    
    border:                      1px;
    border-color:                transparent;
}

element selected.normal {
    background-color:            @sel-bg;
    text-color:                  @border-col;
    border:                      1px;
    border-color:                @border-col;
}

element-text {
    background-color:            transparent;
    text-color:                  inherit;
    cursor:                      inherit;
    vertical-align:              0.5;
    horizontal-align:            0.0;
    markup:                      true; /* Allow Bold/Span tags */
}
EOF

# ==============================================================================
#  3. EXECUTE
# ==============================================================================

# Output the parsed data into Rofi
echo -e "$DATA" | rofi -dmenu \
    -markup-rows \
    -i \
    -theme "$TEMP_THEME_FILE" \
    -p "Keybinds"
