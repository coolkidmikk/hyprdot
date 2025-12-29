#!/bin/bash

# ==============================================================================
#  CONFIGURATION
# ==============================================================================
TEMP_THEME_FILE="/tmp/rofi-launcher.rasi"

# ==============================================================================
#  ROFI THEME GENERATION
# ==============================================================================
cat > "$TEMP_THEME_FILE" << EOF
/*****----- Configuration -----*****/
configuration {
    modi:                       "drun";
    show-icons:                 true;
    display-drun:               "Apps";
    drun-display-format:        "{name}";
    
    /* SMOOTH SELECTION */
    hover-select:               true;
    me-select-entry:            "MousePrimary";
    me-accept-entry:            "!MousePrimary";
}

/*****----- Global Properties -----*****/
* {
    font:                       "JetBrains Mono Bold 11";
    
    /* COLORS */
    bg-col:                     #101010FA;   /* Dark Background */
    sel-bg:                     #202020FF;   /* Selection Background */
    border-col:                 #cccccc;     /* Nord Blue Border */
    text-col:                   #FFFFFF;     /* White Text */
    placeholder-col:            #606060;     /* Dimmed Text */
    
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
    
    /* Fixed Size */
    width:                       500px;
    height:                      400px;
    
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
    padding:                     20px;
    border:                      0px 0px 1px 0px;
    border-color:                #303030;
    background-color:            transparent;
    children:                    [ "textbox-prompt-colon", "entry" ];
}

textbox-prompt-colon {
    enabled:                     true;
    expand:                      false;
    str:                         " ";
    text-color:                  @border-col;
    padding:                     0px 0px 0px 5px;
}

entry {
    enabled:                     true;
    text-color:                  @text-col;
    cursor:                      text;
    placeholder:                 "Search Apps...";
    placeholder-color:           @placeholder-col;
}

/*****----- Listview -----*****/
listview {
    enabled:                     true;
    columns:                     1;
    lines:                       10;
    cycle:                       true;
    dynamic:                     true;
    
    /* NO SCROLLBAR */
    scrollbar:                   false;
    
    layout:                      vertical;
    spacing:                     5px;
    padding:                     15px;
    
    background-color:            transparent;
    cursor:                      "default";
}

/*****----- Elements -----*****/
element {
    enabled:                     true;
    spacing:                     15px;
    padding:                     10px;
    border-radius:               0px; /* Square */
    cursor:                      pointer;
    background-color:            transparent;
    text-color:                  @text-col;
    
    /* Invisible border to keep size stable */
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

element-icon {
    background-color:            transparent;
    size:                        32px;
    cursor:                      inherit;
    vertical-align:              0.5;
}

element-text {
    background-color:            transparent;
    text-color:                  inherit;
    cursor:                      inherit;
    vertical-align:              0.5;
    horizontal-align:            0.0;
}
EOF

# ==============================================================================
#  EXECUTION
# ==============================================================================
rofi -show drun -theme "$TEMP_THEME_FILE"
