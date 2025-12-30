#!/bin/bash

# ==============================================================================
#  MYHYPRRICE AUTO-INSTALLER
#  Styled & Structured
# ==============================================================================

# ------------------------------------------------------------------------------
#  1. VISUAL UTILITIES (The "Symphony" Style Logic)
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Helpers
ok()   { echo -e "${GREEN}  ✓${RESET} $1"; }
err()  { echo -e "${RED}  ✗${RESET} $1"; }
warn() { echo -e "${YELLOW}  !${RESET} $1"; }
info() { echo -e "${CYAN}  ➜${RESET} $1"; }
step() { echo -e "\n${MAGENTA}::${RESET} ${BOLD}$1${RESET}"; }

show_banner() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
   __  __      __  __                 
  |  \/  |    |  \/  |                
  | \  / |_ __| \  / | ___  ___  ___  
  | |\/| | '__| |\/| |/ _ \/ __|/ _ \ 
  | |  | | |  | |  | | (_) \__ \  __/ 
  |_|  |_|_|  |_|  |_|\___/|___/\___| 
                                      
      Hyprland Rice Installer
EOF
    echo -e "${RESET}"
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

# Added rofi-emoji, ddcutil, gum (for better visuals if you want later)
PKGS=(
    "hyprland" "hyprpicker" "hyprshot" "waybar" "rofi" "swww" 
    "kitty" "mako" "fastfetch" "nemo" "yazi" "btop" "cava" 
    "cliphist" "gammastep" "imagemagick" "mpv" "pamixer" 
    "pipewire-alsa" "pipewire-pulse" "networkmanager" "nwg-look"
    "qt6-5compat" "qt6-multimedia-ffmpeg" "qt6-svg" "qt6-virtualkeyboard"
    "sddm" "ttf-jetbrains-mono" "ttf-jetbrains-mono-nerd" "unzip" "unrar"
    "xdg-user-dirs" "zsh" "nano" "tree" "polkit-gnome" "jq" "ddcutil" 
    "rofi-emoji" "gum"
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
# Removed xcursor-comix, added moc-pulse-svn
AUR_PKGS=(
    "discord-ptb" "moc-pulse-svn" 
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

# Logic: Check if asset exists -> Copy to /usr/share/icons -> Update index.theme
if [ -d "assets/cursors/ComixCursors-White" ]; then
    info "Installing ComixCursors-White..."
    
    # Remove old if exists to prevent conflicts
    if [ -d "/usr/share/icons/ComixCursors-White" ]; then
        sudo rm -rf /usr/share/icons/ComixCursors-White
    fi

    # Copy new
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

# Create directories
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

# --- SPECIFIC FIX: MOC CONFIG ---
# Move MOC from .config/moc (where we copied it) to ~/.moc
if [ -d "$CONFIG_DIR/moc" ]; then
    info "Relocating MOC config..."
    if [ -d "$HOME/.moc" ]; then rm -rf "$HOME/.moc"; fi
    mv "$CONFIG_DIR/moc" "$HOME/.moc"
    ok "MOC configured at ~/.moc"
fi

# --- SPECIFIC FIX: FONTS ---
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
        
        # Apply Nvidia Env Vars
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
#  10. SHELL & SDDM
# ------------------------------------------------------------------------------
step "Final Polish"

# SDDM
if [ -d "assets/sddm" ]; then
    sudo mkdir -p /usr/share/sddm/themes/silent
    sudo cp -r assets/sddm/* /usr/share/sddm/themes/silent/
    sudo cp configs/sddm.conf /etc/sddm.conf
    sudo systemctl enable sddm >> $LOG 2>&1
    ok "SDDM theme installed"
fi

# ZSH
if [ -f "assets/zsh/.zshrc" ]; then
    cp "assets/zsh/.zshrc" "$HOME/.zshrc"
    ok "ZSH config installed"
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
