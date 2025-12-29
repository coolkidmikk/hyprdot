#!/bin/bash

# ==============================================================================
#  HYPRLAND AUTO-INSTALLER (ARCH LINUX)
#  Created for your Minimal Rice
# ==============================================================================

# Colors for pretty output
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# Script variables
LOG="install.log"
CONFIG_DIR="$HOME/.config"
ASSET_DIR="$HOME/Pictures/Wallpapers"

# Header
echo -e "${BLUE}"
echo "---------------------------------------------------------"
echo "    INITIALIZING HYPRLAND RICE INSTALLER"
echo "---------------------------------------------------------"
echo -e "${RESET}"

# 1. Check for sudo (but don't run the whole script as sudo)
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Please do not run this script as root!${RESET}"
    exit 1
fi

# 2. Update System first
echo -e "${YELLOW}[*] Updating system...${RESET}"
sudo pacman -Syu --noconfirm >> $LOG 2>&1

# 3. AUR Helper Selection
echo -e "${YELLOW}[?] Which AUR helper do you want to use?${RESET}"
select aur_helper in "paru" "yay"; do
    case $aur_helper in
        paru) 
            HELPER="paru"
            break
            ;;
        yay) 
            HELPER="yay"
            break
            ;;
        *) echo "Invalid option";;
    esac
done

# Install AUR helper if missing
if ! command -v $HELPER &> /dev/null; then
    echo -e "${YELLOW}[*] Installing $HELPER...${RESET}"
    sudo pacman -S --needed base-devel git --noconfirm
    git clone https://aur.archlinux.org/$HELPER.git
    cd $HELPER
    makepkg -si --noconfirm
    cd ..
    rm -rf $HELPER
else
    echo -e "${GREEN}[OK] $HELPER is already installed.${RESET}"
fi

# 4. Install Official Packages
PKGS=(
    "hyprland" "hyprpicker" "hyprshot" "waybar" "rofi" "swww" 
    "kitty" "mako" "fastfetch" "nemo" "yazi" "btop" "cava" 
    "cliphist" "gammastep" "imagemagick" "mpv" "pamixer" 
    "pipewire-alsa" "pipewire-pulse" "networkmanager" "nwg-look"
    "qt6-5compat" "qt6-multimedia-ffmpeg" "qt6-svg" "qt6-virtualkeyboard"
    "sddm" "ttf-jetbrains-mono" "ttf-jetbrains-mono-nerd" "unzip" "unrar"
    "xdg-user-dirs" "zsh" "nano" "tree" "polkit-gnome" "jq"
)

echo -e "${YELLOW}[*] Installing official packages...${RESET}"
sudo pacman -S --needed --noconfirm "${PKGS[@]}" >> $LOG 2>&1

# --- NEW STEP: Setup Standard Directories IMMEDIATELY ---
echo -e "${YELLOW}[*] Setting up user directories (Downloads, Music, etc)...${RESET}"
xdg-user-dirs-update

# Force creation just in case xdg-update was lazy
mkdir -p ~/Downloads ~/Documents ~/Music ~/Pictures ~/Videos ~/Templates ~/Public

# 5. Install AUR Packages
AUR_PKGS=(
    "discord-ptb" "xcursor-comix" 
)

echo -e "${YELLOW}[*] Installing AUR packages with $HELPER...${RESET}"
$HELPER -S --needed --noconfirm "${AUR_PKGS[@]}" >> $LOG 2>&1

# 6. GPU Detection & Driver Setup
echo -e "${YELLOW}[?] Detecting GPU...${RESET}"
if lspci | grep -i "nvidia" > /dev/null; then
    echo -e "${GREEN}Nvidia GPU detected.${RESET}"
    read -p "Do you want to install Nvidia drivers & Hyprland patches? (y/n): " nvidia_confirm
    if [[ $nvidia_confirm == "y" || $nvidia_confirm == "Y" ]]; then
        sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils libva-nvidia-driver
        echo -e "\n# NVIDIA TWEAKS\nenv = LIBVA_DRIVER_NAME,nvidia\nenv = XDG_SESSION_TYPE,wayland\nenv = GBM_BACKEND,nvidia-drm\nenv = __GLX_VENDOR_LIBRARY_NAME,nvidia" >> nvidia_env.tmp
    fi
elif lspci | grep -i "intel" > /dev/null; then
    echo -e "${GREEN}Intel GPU detected.${RESET}"
else
    echo -e "${YELLOW}Other GPU (AMD/VM) detected. Skipping specific drivers.${RESET}"
fi

# 7. Backup Existing Configs
echo -e "${YELLOW}[*] Backing up existing configurations...${RESET}"
BACKUP_DIR="$HOME/.rice-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

DIRS_TO_BACKUP=("hypr" "waybar" "kitty" "mako" "fastfetch" "nemo" "nwg-look" "gtk-3.0" "gtk-4.0")

for dir in "${DIRS_TO_BACKUP[@]}"; do
    if [ -d "$CONFIG_DIR/$dir" ]; then
        mv "$CONFIG_DIR/$dir" "$BACKUP_DIR/$dir"
        echo -e "Moved $dir to backup."
    fi
done

# 8. Copy Configs
echo -e "${YELLOW}[*] Copying configuration files...${RESET}"
cp -r configs/* "$CONFIG_DIR/"

if [ -f nvidia_env.tmp ]; then
    cat nvidia_env.tmp >> "$CONFIG_DIR/hypr/hyprland.conf"
    rm nvidia_env.tmp
fi

chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh

# 9. Copy Assets (Wallpapers)
echo -e "${YELLOW}[*] Copying wallpapers...${RESET}"
mkdir -p "$ASSET_DIR"
cp -r assets/wallpapers/* "$ASSET_DIR/"

# 10. Notification Daemon Choice
read -p "Use Mako (default) or install SwayNC? (m/s): " notif_choice
if [[ $notif_choice == "s" || $notif_choice == "S" ]]; then
    sudo pacman -S --needed --noconfirm swaync
    sed -i 's/exec-once = mako/exec-once = swaync/' "$CONFIG_DIR/hypr/hyprland.conf"
fi

# 11. SDDM Setup
echo -e "${YELLOW}[*] Setting up SDDM Theme...${RESET}"
if [ -d "assets/sddm" ]; then
    sudo cp -r assets/sddm /usr/share/sddm/themes/silent
    sudo cp configs/sddm.conf /etc/sddm.conf
    sudo mkdir -p /etc/sddm.conf.d
fi

# 12. Shell Setup
echo -e "${YELLOW}[*] Setting up Zsh...${RESET}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting

if [ -f "assets/zsh/a.zsh-theme" ]; then
    cp "assets/zsh/a.zsh-theme" "$HOME/.oh-my-zsh/themes/"
fi

if [ -f "assets/zsh/.zshrc" ]; then
    cp "assets/zsh/.zshrc" "$HOME/.zshrc"
fi

if [ "$SHELL" != "/usr/bin/zsh" ]; then
    chsh -s /usr/bin/zsh
fi

# 13. Finalize
echo -e "${YELLOW}[*] Refreshing fonts and settings...${RESET}"
fc-cache -fv

# We run this again just in case the new config file changed paths
xdg-user-dirs-update 

# Enable SDDM
sudo systemctl enable sddm

echo -e "${GREEN}"
echo "---------------------------------------------------------"
echo "    INSTALLATION COMPLETE!"
echo "    Please reboot your system."
echo "---------------------------------------------------------"
echo -e "${RESET}"
