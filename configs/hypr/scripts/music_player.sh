#!/bin/bash

# Define the Kitty class name for the music player window
MUSIC_CLASS="music"

# Define the path to your music directory
MUSIC_DIR="$HOME/Music"

# Launch Kitty with the custom class and run mocp
# The '-e' option executes the command inside the new terminal window.
# If mocp is already running, this will bring it to the foreground.
# If not, it will start a new instance.
kitty --class $MUSIC_CLASS -e mocp $MUSIC_DIR
