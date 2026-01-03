#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# indicators
ok()   { echo -e "${GREEN}  ✓${RESET} $1"; }
err()  { echo -e "${RED}  ✗${RESET} $1"; }
warn() { echo -e "${YELLOW}  !${RESET} $1"; }
info() { echo -e "${CYAN}  ➜${RESET} $1"; }
step() { echo -e "\n${MAGENTA}::${RESET} ${BOLD}$1${RESET}"; }

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

# ------------------------------------------------------------------------------
#  3. PRE-FLIGHT & DEPENDENCIES
# ------------------------------------------------------------------------------
if [ "$EUID" -eq 0 ]; then
    err "Please do not run this script as root! Run it as a normal user."
    exit 1
fi

show_banner
step "Initializing Installation"


if ! command -v gum &> /dev/null; then
    info "Installing 'gum' for the installer UI..."
    sudo pacman -S --needed --noconfirm gum &> /dev/null
fi

# ------------------------------------------------------------------------------
#  4. USER CHOICES
# ------------------------------------------------------------------------------
step "Configuration Choices"

# --- Choice 1: AUR Helper ---
if command -v yay &> /dev/null; then
    HELPER="yay"
    ok "Detected existing AUR helper: yay"
elif command -v paru &> /dev/null; then
    HELPER="paru"
    ok "Detected existing AUR helper: paru"
else
    echo -e "${YELLOW}  Which AUR helper do you prefer?${RESET}"
    if command -v gum &> /dev/null; then
        HELPER=$(gum choose "yay" "paru")
    else
        select h in yay paru; do HELPER=$h; break; done
    fi
    ok "Selected AUR Helper: $HELPER"
fi

# --- Choice 2: Notification Daemon ---
echo -e "${YELLOW}  Which Notification Daemon do you prefer?${RESET}"
if command -v gum &> /dev/null; then
    NOTIF_DAEMON=$(gum choose "mako" "swaync")
else
    select n in mako swaync; do NOTIF_DAEMON=$n; break; done
fi
ok "Selected Notifications: $NOTIF_DAEMON"

# ------------------------------------------------------------------------------
#  5. SYSTEM UPDATE & AUR SETUP
# ------------------------------------------------------------------------------
step "Updating System & Base"
sudo pacman -Syu --noconfirm >> $LOG 2>&1 || err "System update failed (Check $LOG)"

# Install AUR Helper if missing
if ! command -v $HELPER &> /dev/null; then
    info "Installing $HELPER..."
    sudo pacman -S --needed base-devel git --noconfirm >> $LOG 2>&1
    git clone "https://aur.archlinux.org/$HELPER.git" >> $LOG 2>&1
    cd $HELPER
    makepkg -si --noconfirm >> $LOG 2>&1
    cd ..
    rm -rf $HELPER
    ok "$HELPER installed"
fi

# ------------------------------------------------------------------------------
#  6. PACKAGE INSTALLATION
# ------------------------------------------------------------------------------
step "Installing Official Packages"

# Standard Packages (Removed 'mako'/'swaync' from here to add dynamically)
PKGS=(
    "hyprland" "xorg-server" "xorg-xinit" "wayland-protocols" "hyprpicker" "hyprshot" "waybar" "rofi" "swww" 
    "kitty" "fastfetch" "nemo" "yazi" "btop" "cava" 
    "cliphist" "gammastep" "imagemagick" "mpv" "pamixer" 
    "pipewire-alsa" "pipewire-pulse" "networkmanager" "nwg-look"
    "qt6-5compat" "qt6-multimedia-ffmpeg" "qt6-svg" "qt6-virtualkeyboard"
    "sddm" "ttf-jetbrains-mono" "ttf-jetbrains-mono-nerd" 
    "adobe-source-han-sans-cn-fonts" "adobe-source-han-sans-jp-fonts" 
    "adobe-source-han-sans-kr-fonts" "unzip" "unrar"
    "xdg-user-dirs" "zsh" "nano" "tree" "jq" "ddcutil" 
    "rofi-emoji" "firefox" "libva" "intel-media-driver" "libva-utils"
)

# Add the chosen notification daemon
PKGS+=("$NOTIF_DAEMON")

# Install loop (Symphony Style Checkmarks)
for PKG in "${PKGS[@]}"; do
    if sudo pacman -S --needed --noconfirm "$PKG" >> $LOG 2>&1; then
        ok "$PKG"
    else
        err "$PKG failed"
    fi
done

step "Installing AUR Packages"
AUR_PKGS=("moc-pulse" "wl-screenrec")

for PKG in "${AUR_PKGS[@]}"; do
    if $HELPER -S --needed --noconfirm "$PKG" >> $LOG 2>&1; then
        ok "$PKG"
    else
        err "$PKG failed"
    fi
done

# ------------------------------------------------------------------------------
#  7. CURSOR SETUP
# ------------------------------------------------------------------------------
step "Setting up Cursor Theme"

if [ -d "assets/cursors/ComixCursors-White" ]; then
    [ -d "/usr/share/icons/ComixCursors-White" ] && sudo rm -rf /usr/share/icons/ComixCursors-White
    sudo cp -r assets/cursors/ComixCursors-White /usr/share/icons/
    
    # Update default theme file
    echo "[Icon Theme]" | sudo tee /usr/share/icons/default/index.theme > /dev/null
    echo "Inherits=ComixCursors-White" | sudo tee -a /usr/share/icons/default/index.theme > /dev/null
    ok "Cursor theme applied globally"
else
    warn "Cursor assets not found! Skipping."
fi

# ------------------------------------------------------------------------------
#  8. DOTFILES & CONFIGS
# ------------------------------------------------------------------------------
step "Deploying Configs"

xdg-user-dirs-update
mkdir -p ~/Downloads ~/Documents ~/Music ~/Pictures ~/Videos ~/Templates ~/Public
mkdir -p "$FONT_DIR"

# Backup logic
BACKUP_DIR="$HOME/.backup"
mkdir -p "$BACKUP_DIR"

DIRS=("hypr" "waybar" "kitty" "fastfetch" "nemo" "nwg-look" "gtk-3.0" "gtk-4.0")

# Add the chosen notification config folder to backup list
if [ "$NOTIF_DAEMON" == "mako" ]; then DIRS+=("mako"); fi
if [ "$NOTIF_DAEMON" == "swaync" ]; then DIRS+=("swaync"); fi

for dir in "${DIRS[@]}"; do
    if [ -d "$CONFIG_DIR/$dir" ]; then
        # Move the config folder to the backup directory
        mv "$CONFIG_DIR/$dir" "$BACKUP_DIR/$dir"
        
        # Updated message to show exact location
        info "Backed up $dir to $BACKUP_DIR/$dir"
    fi
done

# Copy Configs
cp -r configs/* "$CONFIG_DIR/"
ok "Dotfiles copied"

# --- MOC ---
if [ -d "$CONFIG_DIR/moc" ]; then
    [ -d "$HOME/.moc" ] && rm -rf "$HOME/.moc"
    mv "$CONFIG_DIR/moc" "$HOME/.moc"
    ok "MOC configured at ~/.moc"
fi

# --- FONTS ---
if [ -d "assets/fonts" ]; then
    cp -r assets/fonts/* "$FONT_DIR/"
    fc-cache -fv >> $LOG 2>&1
    ok "Custom fonts installed"
fi

# ------------------------------------------------------------------------------
#  9. HARDWARE & DRIVERS
# ------------------------------------------------------------------------------
step "Hardware Setup"

# Nvidia Check
if lspci | grep -i "nvidia" > /dev/null; then
    info "Nvidia GPU detected"
    if gum confirm "Install Nvidia Drivers?"; then
        sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils libva-nvidia-driver >> $LOG 2>&1
        cat <<EOF >> "$CONFIG_DIR/hypr/hyprland.conf"

# NVIDIA AUTO-VARS
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
EOF
        ok "Nvidia drivers & vars applied"
    fi
fi

# DDCUTIL
if ! groups | grep -q "i2c"; then
    sudo usermod -aG i2c $USER
    echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf > /dev/null
    ok "Brightness control (i2c) enabled"
fi

# ------------------------------------------------------------------------------
#  10. SHELL (ZSH + OMZ)
# ------------------------------------------------------------------------------
step "Setting up ZSH Environment"

# Install OMZ
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> $LOG 2>&1
    ok "Oh My Zsh installed"
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
mkdir -p "$HOME/.oh-my-zsh/themes"

# Install Plugins
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" >> $LOG 2>&1
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" >> $LOG 2>&1
ok "Plugins installed"

# Copy Custom Theme
if [ -f "assets/zsh/a.zsh-theme" ]; then
    cp "assets/zsh/a.zsh-theme" "$HOME/.oh-my-zsh/themes/a.zsh-theme"
    ok "Custom theme 'a' installed"
fi

# Copy .zshrc
if [ -f "assets/zsh/.zshrc" ]; then
    cp "assets/zsh/.zshrc" "$HOME/.zshrc"
    ok "Custom .zshrc applied"
fi

# Change Shell
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    sudo chsh -s /usr/bin/zsh "$USER"
    ok "Shell changed to Zsh"
fi

# ------------------------------------------------------------------------------
#  11. FINALIZATION
# ------------------------------------------------------------------------------
step "Finalizing"

# SDDM
if [ -d "assets/sddm/silent" ]; then
    sudo mkdir -p /usr/share/sddm/themes
    [ -d "/usr/share/sddm/themes/silent" ] && sudo rm -rf /usr/share/sddm/themes/silent
    sudo cp -r assets/sddm/silent /usr/share/sddm/themes/
    sudo cp configs/sddm.conf /etc/sddm.conf
    sudo systemctl enable sddm >> $LOG 2>&1
    ok "SDDM theme applied"
fi

# Assets
mkdir -p "$ASSET_DIR"
cp -r assets/wallpapers/* "$ASSET_DIR/"
chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh 2>/dev/null
ok "Wallpapers & Scripts set"

echo
echo -e "${GREEN}#########################################################"
echo "   INSTALLATION COMPLETE"
echo "   Please reboot to apply group changes and start SDDM."
echo "#########################################################${RESET}"
echo
