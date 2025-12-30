#!/bin/bash

# ==============================================================================
#  CONFIGURATION
# ==============================================================================
WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"
CACHE_DIR="${HOME}/.cache/rofi-wallpaper-thumbs-vertical"
TEMP_THEME_FILE="/tmp/rofi-wallpaper-select.rasi"

# Transition config (swww)
TRANSITION_TYPE="grow"
TRANSITION_POS="bottom"
TRANSITION_DURATION=2
TRANSITION_FPS=60

# ==============================================================================
#  ROFI THEME GENERATION (Operator Style - Perfect Fit)
# ==============================================================================
cat > "$TEMP_THEME_FILE" << EOF
/*****----- Configuration -----*****/
configuration {
    modi:                       "drun";
    show-icons:                 true;
    drun-display-format:        "{name}";
    hover-select:               true;
    me-select-entry:            "MousePrimary";
    me-accept-entry:            "!MousePrimary";
}

/*****----- Global Properties -----*****/
* {
    font:                       "JetBrains Mono Bold 10";
    
    /* COLORS */
    bg-col:                     #101010FA;   /* Dark Background */
    sel-bg:                     #FFFFFF05;   /* Subtle highlight */
    border-col:                 #cccccc;     /* Main Border */
    separator-col:              #333333;     /* Vertical Separator Lines */
    
    background-color:           transparent;
    text-color:                 #FFFFFF;
    margin:                     0px;
    padding:                    0px;
}

/*****----- Main Window -----*****/
window {
    location:                    center;
    anchor:                      center;
    fullscreen:                  false;
    
    /* 
       MATH EXPLANATION (FIXED):
       Image Height: 400px
       Window Border: 1px top + 1px bottom = 2px
       TOTAL HEIGHT NEEDED: 402px
    */
    width:                       1006px;
    height:                      402px; 
    
    border-radius:               0px;
    background-color:            @bg-col;
    border:                      1px;
    border-color:                @border-col;
    
    children:                    [ "listview" ];
}

/*****----- Listview -----*****/
listview {
    enabled:                     true;
    layout:                      horizontal;
    
    columns:                     1;
    lines:                       5; 
    
    cycle:                       true;
    dynamic:                     true;
    scrollbar:                   false;
    
    /* Ensure no spacing disrupts the height */
    spacing:                     0px;
    padding:                     0px;
    
    /* This prevents listview from trying to guess row height */
    fixed-height:                false; 
    
    background-color:            transparent;
}

/*****----- Elements -----*****/
element {
    enabled:                     true;
    orientation:                 vertical;
    padding:                     0px;
    margin:                      0px;
    cursor:                      pointer;
    background-color:            transparent;
    
    /* Force exact width */
    width:                       200px;
    
    /* The "Line" between images (Right Border) */
    border:                      0px 1px 0px 0px;
    border-color:                @separator-col;
}

/* Remove the separator line from the very last item so it fits perfectly */
element last {
    border:                      0px;
}

element selected.normal {
    background-color:            @sel-bg;
    z-index:                     1;
    
    /* Highlight Border - Note: Inset border might be safer to prevent sizing jumps, 
       but if it works for you, keep it. */
    border:                      2px;
    border-color:                @border-col;
}

element-icon {
    /* 
       Icon size logic:
       Rofi scales icons to fit within this square size.
       Since your images are 200x400, setting size to 400px ensure height is filled.
    */
    size:                        400px; 
    cursor:                      inherit;
    horizontal-align:            0.5;
    vertical-align:              0.5;
    background-color:            transparent;
}

element-text {
    enabled:                     false;
}
EOF

# ==============================================================================
#  LOGIC
# ==============================================================================

# Create Cache Dir
if [ ! -d "$CACHE_DIR" ]; then
    mkdir -p "$CACHE_DIR"
fi

# Function to generate thumbnails
generate_thumbs() {
    if [ -z "$(ls -A "$WALLPAPER_DIR")" ]; then
        echo "No wallpapers found in $WALLPAPER_DIR" >&2
        return
    fi

    for img in "${WALLPAPER_DIR}"/*.{jpg,jpeg,png,gif,webp}; do
        [ -f "$img" ] || continue
        filename=$(basename "$img")
        thumb="${CACHE_DIR}/${filename}"
        
        # Crop 200x400 strip from center
        if [ ! -f "$thumb" ]; then
            convert "$img" -strip -resize x400^ -gravity center -crop 200x400+0+0 +repage "$thumb"
        fi
        
        echo -en "${filename}\0icon\x1f${thumb}\n"
    done
}

# Run Rofi
SELECTED=$(generate_thumbs | rofi -dmenu \
    -name "rofi_wallpaper" \
    -normal-window \
    -theme "$TEMP_THEME_FILE" \
    -i)

if [ -z "$SELECTED" ]; then
    exit 0
fi

IMAGE_FILE="${SELECTED%%$'\n'*}"

swww img "${WALLPAPER_DIR}/${IMAGE_FILE}" \
    --transition-type "${TRANSITION_TYPE}" \
    --transition-pos "${TRANSITION_POS}" \
    --transition-duration "${TRANSITION_DURATION}" \
    --transition-fps "${TRANSITION_FPS}"
