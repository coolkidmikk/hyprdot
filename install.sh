#!/bin/bash

show_banner() {
    local banner=(
        "  _    _                      _        _   "
        " | |  | |                    | |      | |  "
        " | |__| |_   _ _ __  _ __  __| | ___ | |_ "
        " |  __  | | | | '_ \| '__|/ _\` |/ _ \| __|"
        " | |  | | |_| | |_) | |  | (_| | (_) | |_ "
        " |_|  |_|\__, | .__/|_|   \__,_|\___/ \__|"
        "          __/ | |                         "
        "         |___/|_|                         "
    )

    local cols=$(tput cols)
    local rows=$(tput lines)
    local b_width=${#banner[0]}
    local b_height=${#banner[@]}
    local start_col=$(( (cols - b_width) / 2 ))
    local start_row=$(( rows / 4 ))
    local chars="!@#$%^&*()_+-=[]{}|;:,.<>?0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    clear
    tput civis

    for (( i=0; i<40; i++ )); do
        for (( r=0; r<b_height; r++ )); do
            tput cup $((start_row + r)) $start_col
            local line="${banner[$r]}"
            for (( c=0; c<${#line}; c++ )); do
                local char="${line:$c:1}"
                if [[ "$char" == " " ]]; then
                    printf " "
                else
                    if (( RANDOM % 40 < i )); then
                        local r_val=$(( 120 + i * 3 ))
                        local g_val=$(( 50 + i * 2 ))
                        local b_val=255
                        printf "\e[38;2;${r_val};${g_val};${b_val}m%s\e[0m" "$char"
                    else
                        printf "\e[38;5;236m%s\e[0m" "${chars:$(( RANDOM % ${#chars} )):1}"
                    fi
                fi
            done
        done
        sleep 0.04
    done

    local sub="[ Initializing system protocols... ]"
    local sub_col=$(( (cols - ${#sub}) / 2 ))
    tput cup $((start_row + b_height + 2)) $sub_col
    
    for (( i=0; i<${#sub}; i++ )); do
        printf "\e[1;36m%s\e[0m" "${sub:$i:1}"
        sleep 0.02
    done

    echo -e "\n"
    tput cnorm
}

# ------------------------------------------------------------------------------
#  2. VARIABLES & PATHS
# ------------------------------------------------------------------------------
LOG="install.log"
CONFIG_DIR="$HOME/.config"
ASSET_DIR="$HOME/Pictures/Wallpapers"
FONT_DIR="$HOME/.local/share/fonts"
CURSOR_DIR="/usr/share/icons"

# ------------------------------------------------------------------------------
#  3. PRE-FLIGHT CHECKS
# ------------------------------------------------------------------------------
if [ "$EUID" -eq 0 ]; then
    err "Please do not run this script as root! Run it as a normal user."
    exit 1
fi

show_banner
step "Initializing Installation"
info "Log file: $LOG"

# ------------------------------------------------------------------------------
#  4. SYSTEM UPDATE
# ------------------------------------------------------------------------------
step "Updating System"
if sudo pacman -Syu --noconfirm >> $LOG 2>&1; then
    ok "System updated"
else
    err "System update failed. Check $LOG"
    exit 1
fi

# ------------------------------------------------------------------------------
#  5. AUR HELPER SETUP
# ------------------------------------------------------------------------------
step "Configuring AUR Helper"
if command -v yay &> /dev/null; then
    HELPER="yay"
    ok "yay is already installed"
elif command -v paru &> /dev/null; then
    HELPER="paru"
    ok "paru is already installed"
else
    info "Installing yay..."
    sudo pacman -S --needed base-devel git --noconfirm >> $LOG 2>&1
    git clone https://aur.archlinux.org/yay.git >> $LOG 2>&1
    cd yay
    makepkg -si --noconfirm >> $LOG 2>&1
    cd ..
    rm -rf yay
    HELPER="yay"
    ok "yay installed"
fi

# ------------------------------------------------------------------------------
#  6. PACKAGE INSTALLATION
# ------------------------------------------------------------------------------
step "Installing Official Packages"

PKGS=(
    "hyprland" "hyprpicker" "hyprshot" "waybar" "rofi" "swww" 
    "kitty" "mako" "fastfetch" "nemo" "yazi" "btop" "cava" 
    "cliphist" "gammastep" "imagemagick" "mpv" "pamixer" 
    "pipewire-alsa" "pipewire-pulse" "networkmanager" "nwg-look"
    "qt6-5compat" "qt6-multimedia-ffmpeg" "qt6-svg" "qt6-virtualkeyboard"
    "sddm" "ttf-jetbrains-mono" "ttf-jetbrains-mono-nerd" "adobe-source-han-sans-cn-fonts"
    "adobe-source-han-sans-jp-fonts" "adobe-source-han-sans-kr-fonts" "unzip" "unrar"
    "xdg-user-dirs" "zsh" "nano" "tree" "polkit-gnome" "jq" "ddcutil" 
    "rofi-emoji" "gum" "firefox" "libva" "intel-media-driver" "libva-utils"
)

# Install loop for better visual feedback
for PKG in "${PKGS[@]}"; do
    if sudo pacman -S --needed --noconfirm "$PKG" >> $LOG 2>&1; then
        ok "$PKG"
    else
        err "$PKG failed to install"
    fi
done

step "Installing AUR Packages"
AUR_PKGS=(
     "moc-pulse-svn" "wl-screenrec"
)

for PKG in "${AUR_PKGS[@]}"; do
    if $HELPER -S --needed --noconfirm "$PKG" >> $LOG 2>&1; then
        ok "$PKG"
    else
        err "$PKG failed to install"
    fi
done

# ------------------------------------------------------------------------------
#  7. CURSOR SETUP (MANUAL)
# ------------------------------------------------------------------------------
step "Setting up Cursor Theme"

if [ -d "assets/cursors/ComixCursors-White" ]; then
    info "Installing ComixCursors-White..."
    
    if [ -d "/usr/share/icons/ComixCursors-White" ]; then
        sudo rm -rf /usr/share/icons/ComixCursors-White
    fi

    sudo cp -r assets/cursors/ComixCursors-White /usr/share/icons/
    
    # Update default theme file
    echo "[Icon Theme]" | sudo tee /usr/share/icons/default/index.theme > /dev/null
    echo "Inherits=ComixCursors-White" | sudo tee -a /usr/share/icons/default/index.theme > /dev/null
    
    ok "Cursor theme copied and applied globally"
else
    warn "assets/cursors/ComixCursors-White not found! Skipping cursor setup."
fi

# ------------------------------------------------------------------------------
#  8. DOTFILES & CONFIGS
# ------------------------------------------------------------------------------
step "Deploying Configs"

xdg-user-dirs-update
mkdir -p ~/Downloads ~/Documents ~/Music ~/Pictures ~/Videos ~/Templates ~/Public
mkdir -p "$FONT_DIR"

# Backup function
backup_config() {
    local DIR=$1
    if [ -d "$CONFIG_DIR/$DIR" ]; then
        BACKUP="$HOME/.rice-backup/config/$DIR"
        mkdir -p "$(dirname "$BACKUP")"
        mv "$CONFIG_DIR/$DIR" "$BACKUP"
        info "Backed up $DIR"
    fi
}

mkdir -p "$HOME/.rice-backup"

# Copy standard configs
DIRS=("hypr" "waybar" "kitty" "mako" "fastfetch" "nemo" "nwg-look" "gtk-3.0" "gtk-4.0")
for dir in "${DIRS[@]}"; do
    backup_config "$dir"
done

cp -r configs/* "$CONFIG_DIR/"
ok "Standard dotfiles copied"

# --- MOC FIX ---
if [ -d "$CONFIG_DIR/moc" ]; then
    info "Relocating MOC config..."
    if [ -d "$HOME/.moc" ]; then rm -rf "$HOME/.moc"; fi
    mv "$CONFIG_DIR/moc" "$HOME/.moc"
    ok "MOC configured at ~/.moc"
fi

# --- Emoji FONTS ---
if [ -d "assets/fonts" ]; then
    cp -r assets/fonts/* "$FONT_DIR/"
    fc-cache -fv >> $LOG 2>&1
    ok "Custom fonts installed (Twemoji)"
else
    warn "No fonts found in assets/fonts"
fi

# ------------------------------------------------------------------------------
#  9. GPU & DRIVERS
# ------------------------------------------------------------------------------
step "GPU Setup"
if lspci | grep -i "nvidia" > /dev/null; then
    info "Nvidia GPU detected"
    read -p "  Install Nvidia Drivers? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils libva-nvidia-driver >> $LOG 2>&1
        cat <<EOF >> "$CONFIG_DIR/hypr/hyprland.conf"

# NVIDIA AUTO-VARS
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
EOF
        ok "Nvidia drivers & env vars applied"
    fi
else
    ok "No Nvidia GPU requiring special steps"
fi

# DDCUTIL Permissions
if ! groups | grep -q "i2c"; then
    sudo usermod -aG i2c $USER
    echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf > /dev/null
    ok "Added user to i2c group for brightness control"
fi

# ------------------------------------------------------------------------------
#  10. SHELL (OH-MY-ZSH + PLUGINS)
# ------------------------------------------------------------------------------
step "Setting up ZSH Environment"

# 1. Install Oh My Zsh (Unattended)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> $LOG 2>&1
    ok "Oh My Zsh installed"
else
    ok "Oh My Zsh already installed"
fi

# 2. Install Plugins (Autosuggestions + Syntax Highlighting)
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
PLUGIN_DIR="$ZSH_CUSTOM/plugins"

if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
    info "Cloning zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions" >> $LOG 2>&1
    ok "Autosuggestions installed"
fi

if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    info "Cloning zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR/zsh-syntax-highlighting" >> $LOG 2>&1
    ok "Syntax Highlighting installed"
fi

# --- Copy custom theme to OMZ themes directory ---
if [ -f "assets/zsh/a.zsh-theme" ]; then
    cp "assets/zsh/a.zsh-theme" "$HOME/.oh-my-zsh/themes/a.zsh-theme"
    ok "Custom theme 'a' installed to Oh My Zsh"
fi

# 3. Apply Custom .zshrc
# We do this LAST to ensure we overwrite the default OMZ template
if [ -f "assets/zsh/.zshrc" ]; then
    cp "assets/zsh/.zshrc" "$HOME/.zshrc"
    ok "Custom .zshrc applied"
else
    warn "assets/zsh/.zshrc not found!"
fi

# 4. Change Default Shell
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    info "Changing default shell to Zsh..."
    sudo chsh -s /usr/bin/zsh "$USER"
    ok "Shell changed to Zsh"
fi

# ------------------------------------------------------------------------------
#  11. SDDM & FINALIZATION
# ------------------------------------------------------------------------------
step "Final Polish"

# SDDM
    
if [ -d "assets/sddm/silent" ]; then
    sudo mkdir -p /usr/share/sddm/themes
    if [ -d "/usr/share/sddm/themes/silent" ]; then
        sudo rm -rf /usr/share/sddm/themes/silent
    fi
    sudo cp -r assets/sddm/silent /usr/share/sddm/themes/
    sudo cp configs/sddm.conf /etc/sddm.conf
    sudo systemctl enable sddm >> $LOG 2>&1
    ok "SDDM theme installed"
fi

# Wallpapers
mkdir -p "$ASSET_DIR"
cp -r assets/wallpapers/* "$ASSET_DIR/"
ok "Wallpapers copied"

# Executable scripts
chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh
ok "Scripts made executable"

# ------------------------------------------------------------------------------
#  COMPLETION
# ------------------------------------------------------------------------------
echo
echo -e "${GREEN}#########################################################"
echo "   INSTALLATION COMPLETE"
echo "   Please reboot to apply group changes and start SDDM."
echo "#########################################################${RESET}"
echo
