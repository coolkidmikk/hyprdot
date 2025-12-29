#!/bin/bash

# ==============================================================================
#  CONFIGURATION
# ==============================================================================
WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"
CACHE_DIR="${HOME}/.cache/rofi-wallpaper-thumbs"
TEMP_THEME_FILE="/tmp/rofi-wallpaper-select.rasi"

# Transition config (swww)
TRANSITION_TYPE="grow"
TRANSITION_POS="bottom"
TRANSITION_DURATION=2
TRANSITION_FPS=60

# ==============================================================================
#  ROFI THEME GENERATION (Bottom Film Strip)
# ==============================================================================
cat > "$TEMP_THEME_FILE" << EOF
/*****----- Configuration -----*****/
configuration {
    modi:                       "drun";
    show-icons:                 true;
    drun-display-format:        "{name}";
    /* SMOOTH SELECTION: Hover to select, Click to activate */
    hover-select:               true;
    me-select-entry:            "MousePrimary";
    me-accept-entry:            "!MousePrimary";
}

/*****----- Global Properties -----*****/
* {
    font:                       "JetBrains Mono 10";
    
    /* COLORS */
    /* Background: Dark Grey (98% opacity for visibility) */
    bg-col:                     #101010FA; 
    /* Selection Background: Slightly lighter */
    sel-bg:                     #202020FF;
    /* Accent: White/Cyan mix */
    border-col:                 #cccccc;
    
    background-color:           transparent;
    text-color:                 #FFFFFF;
    margin:                     0px;
    padding:                    0px;
}

/*****----- Main Window -----*****/
window {
    /* Anchored to the bottom */
    location:                    south;
    anchor:                      south;
    fullscreen:                  false;
    
    /* Width: 98% (Almost full width) */
    width:                       98%;
    
    /* Height: Enough for 1 row of images */
    height:                      240px; 
    
    x-offset:                    0px;
    y-offset:                    -20px; /* Slight float from bottom edge */

    /* Aesthetics: Square & Dark */
    border-radius:               0px;
    background-color:            @bg-col;
    
    /* BORDER: Small 1px border around the dock */
    border:                      1px;
    border-color:                @border-col;
    
    children:                    [ "listview" ];
}

/*****----- Listview -----*****/
listview {
    enabled:                     true;
    
    /* HORIZONTAL LAYOUT (Film Strip) */
    layout:                      horizontal;
    columns:                     1; 
    lines:                       100; /* Allow many items in the horizontal line */
    
    cycle:                       true;
    dynamic:                     true;
    scrollbar:                   false;
    
    /* Spacing between wallpapers */
    spacing:                     20px;
    padding:                     20px;
    
    background-color:            transparent;
}

/*****----- Elements -----*****/
element {
    enabled:                     true;
    orientation:                 vertical;
    padding:                     10px;
    border-radius:               0px;
    cursor:                      pointer;
    background-color:            transparent;
    
    /* Invisible 1px border default to keep size stable */
    border:                      1px;
    border-color:                transparent;
}

element selected.normal {
    background-color:            @sel-bg;
    /* BORDER: Only 1px */
    border:                      1px;
    border-color:                @border-col;
}

element-icon {
    /* Large thumbnails */
    size:                        150px;
    cursor:                      inherit;
    horizontal-align:            0.5;
    vertical-align:              0.5;
    background-color:            transparent;
}

element-text {
    enabled:                     false; /* Text Hidden */
}
EOF

# ==============================================================================
#  LOGIC
# ==============================================================================

# Create Cache Dir if not exists
if [ ! -d "$CACHE_DIR" ]; then
    mkdir -p "$CACHE_DIR"
fi

# Ensure swww is running
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon &
    sleep 0.5
fi

# Function to generate thumbnails
generate_thumbs() {
    # Check if directory is empty
    if [ -z "$(ls -A "$WALLPAPER_DIR")" ]; then
        echo "No wallpapers found in $WALLPAPER_DIR" >&2
        return
    fi

    for img in "${WALLPAPER_DIR}"/*.{jpg,jpeg,png,gif,webp}; do
        [ -f "$img" ] || continue
        filename=$(basename "$img")
        thumb="${CACHE_DIR}/${filename}"
        
        # Create thumbnail if it doesn't exist
        # Resize to 500x500
        if [ ! -f "$thumb" ]; then
            convert "$img" -strip -resize 500x500^ -gravity center -extent 500x500 "$thumb"
        fi
        
        # Output for Rofi
        echo -en "${filename}\0icon\x1f${thumb}\n"
    done
}

# Run Rofi
SELECTED=$(generate_thumbs | rofi -dmenu \
    -theme "$TEMP_THEME_FILE" \
    -i)

# Exit if cancelled
if [ -z "$SELECTED" ]; then
    exit 0
fi

# Extract filename
IMAGE_FILE="${SELECTED%%$'\n'*}"

# Apply Wallpaper
swww img "${WALLPAPER_DIR}/${IMAGE_FILE}" \
    --transition-type "${TRANSITION_TYPE}" \
    --transition-pos "${TRANSITION_POS}" \
    --transition-duration "${TRANSITION_DURATION}" \
    --transition-fps "${TRANSITION_FPS}"
