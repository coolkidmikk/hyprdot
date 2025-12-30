#!/bin/bash

# ==============================================================================
#  HYPRLAND AUTO-INSTALLER (ARCH LINUX)
#  Updated for MOC & Emoji Support
# ==============================================================================

# Colors for pretty output
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

# Script variables
LOG="install.log"
CONFIG_DIR="$HOME/.config"
ASSET_DIR="$HOME/Pictures/Wallpapers"
FONT_DIR="$HOME/.local/share/fonts"

# Header
clear
echo -e "${BLUE}"
echo "#########################################################"
echo "        INITIALIZING HYPRLAND RICE INSTALLER"
echo "#########################################################"
echo -e "${RESET}"

# 1. Check for sudo (but don't run the whole script as sudo)
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Please do not run this script as root!${RESET}"
    exit 1
fi

# 2. Update System first
echo -e "${CYAN}[1/14] Updating system...${RESET}"
echo "---------------------------------------------------------"
sudo pacman -Syu --noconfirm | tee -a $LOG

# 3. AUR Helper Selection
echo -e "\n${CYAN}[2/14] Setup AUR Helper${RESET}"
echo "---------------------------------------------------------"
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
    sudo pacman -S --needed base-devel git --noconfirm | tee -a $LOG
    git clone https://aur.archlinux.org/$HELPER.git
    cd $HELPER
    makepkg -si --noconfirm | tee -a $LOG
    cd ..
    rm -rf $HELPER
else
    echo -e "${GREEN}[OK] $HELPER is already installed.${RESET}"
fi

# 4. Install Official Packages
# Added rofi-emoji and ddcutil based on your request
PKGS=(
    "hyprland" "hyprpicker" "hyprshot" "waybar" "rofi" "swww" 
    "kitty" "mako" "fastfetch" "nemo" "yazi" "btop" "cava" 
    "cliphist" "gammastep" "imagemagick" "mpv" "pamixer" 
    "pipewire-alsa" "pipewire-pulse" "networkmanager" "nwg-look"
    "qt6-5compat" "qt6-multimedia-ffmpeg" "qt6-svg" "qt6-virtualkeyboard"
    "sddm" "ttf-jetbrains-mono" "ttf-jetbrains-mono-nerd" "unzip" "unrar"
    "xdg-user-dirs" "zsh" "nano" "tree" "polkit-gnome" "jq" "ddcutil" 
    "rofi-emoji"
)

echo -e "\n${CYAN}[3/14] Installing Official Packages${RESET}"
echo "---------------------------------------------------------"
sudo pacman -S --needed --noconfirm "${PKGS[@]}" | tee -a $LOG

# --- Setup Standard Directories IMMEDIATELY ---
echo -e "\n${CYAN}[4/14] Setting up User Directories${RESET}"
echo "---------------------------------------------------------"
xdg-user-dirs-update
mkdir -p ~/Downloads ~/Documents ~/Music ~/Pictures ~/Videos ~/Templates ~/Public
echo -e "${GREEN}[OK] Directories created.${RESET}"

# 5. Custom Fonts (Twemoji for Emoji Picker)
echo -e "\n${CYAN}[5/14] Installing Custom Fonts${RESET}"
echo "---------------------------------------------------------"
mkdir -p "$FONT_DIR"
if [ -d "assets/fonts" ]; then
    echo -e "${YELLOW}[*] Copying fonts...${RESET}"
    cp -r assets/fonts/* "$FONT_DIR/"
    echo -e "${GREEN}[OK] Fonts copied to $FONT_DIR.${RESET}"
else
    echo -e "${YELLOW}[!] No assets/fonts folder found. Skipping custom font install.${RESET}"
fi

# 6. Install AUR Packages
# Added moc-pulse-svn
AUR_PKGS=(
    "discord-ptb" "xcursor-comix" "moc-pulse-svn" 
)

echo -e "\n${CYAN}[6/14] Installing AUR Packages${RESET}"
echo "---------------------------------------------------------"
$HELPER -S --needed --noconfirm "${AUR_PKGS[@]}" | tee -a $LOG

# 7. Graphics & Monitor Setup
echo -e "\n${CYAN}[7/14] Graphics & Monitor Setup${RESET}"
echo "---------------------------------------------------------"
if lspci | grep -i "nvidia" > /dev/null; then
    echo -e "${GREEN}Nvidia GPU detected.${RESET}"
    read -p "Do you want to install Nvidia drivers & Hyprland patches? (y/n): " nvidia_confirm
    if [[ $nvidia_confirm == "y" || $nvidia_confirm == "Y" ]]; then
        sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils libva-nvidia-driver | tee -a $LOG
        echo -e "\n# NVIDIA TWEAKS\nenv = LIBVA_DRIVER_NAME,nvidia\nenv = XDG_SESSION_TYPE,wayland\nenv = GBM_BACKEND,nvidia-drm\nenv = __GLX_VENDOR_LIBRARY_NAME,nvidia" >> nvidia_env.tmp
    fi
elif lspci | grep -i "intel" > /dev/null; then
    echo -e "${GREEN}Intel GPU detected.${RESET}"
fi

# DDCUTIL Setup
echo -e "${YELLOW}[*] Setting up Monitor Brightness Control (ddcutil)...${RESET}"
if ! lsmod | grep -q "i2c_dev"; then
    sudo modprobe i2c-dev
fi
if [ ! -f /etc/modules-load.d/i2c-dev.conf ]; then
    echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf > /dev/null
fi
sudo usermod -aG i2c $USER

# 8. Backup Existing Configs
echo -e "\n${CYAN}[8/14] Backing up existing configs${RESET}"
echo "---------------------------------------------------------"
BACKUP_DIR="$HOME/.rice-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
DIRS_TO_BACKUP=("hypr" "waybar" "kitty" "mako" "fastfetch" "nemo" "nwg-look" "gtk-3.0" "gtk-4.0" "moc")

for dir in "${DIRS_TO_BACKUP[@]}"; do
    # Check .config first
    if [ -d "$CONFIG_DIR/$dir" ]; then
        mv "$CONFIG_DIR/$dir" "$BACKUP_DIR/$dir"
        echo -e "Moved ~/.config/$dir to backup"
    fi
    # Check Home for .moc
    if [ "$dir" == "moc" ] && [ -d "$HOME/.moc" ]; then
        mv "$HOME/.moc" "$BACKUP_DIR/.moc"
        echo -e "Moved ~/.moc to backup"
    fi
done

# 9. Copy Configs
echo -e "\n${CYAN}[9/14] Copying Dotfiles${RESET}"
echo "---------------------------------------------------------"
# Copy everything to .config first
cp -r configs/* "$CONFIG_DIR/"

# Handle MOC specifically (Move from .config/moc to ~/.moc)
if [ -d "$CONFIG_DIR/moc" ]; then
    echo -e "${YELLOW}[*] Setting up MOC configuration...${RESET}"
    if [ -d "$HOME/.moc" ]; then rm -rf "$HOME/.moc"; fi
    mv "$CONFIG_DIR/moc" "$HOME/.moc"
    echo -e "${GREEN}[OK] MOC config moved to ~/.moc${RESET}"
fi

echo -e "${GREEN}[OK] Configs copied.${RESET}"

# Apply Nvidia env if exists
if [ -f nvidia_env.tmp ]; then
    cat nvidia_env.tmp >> "$CONFIG_DIR/hypr/hyprland.conf"
    rm nvidia_env.tmp
fi

# Make scripts executable
chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh
echo -e "${GREEN}[OK] Scripts made executable.${RESET}"

# 10. Copy Assets (Wallpapers)
echo -e "\n${CYAN}[10/14] Copying Wallpapers${RESET}"
echo "---------------------------------------------------------"
mkdir -p "$ASSET_DIR"
cp -r assets/wallpapers/* "$ASSET_DIR/"
echo -e "${GREEN}[OK] Wallpapers installed.${RESET}"

# 11. Notification Daemon Choice
echo -e "\n${CYAN}[11/14] Notification Setup${RESET}"
echo "---------------------------------------------------------"
read -p "Use Mako (default) or install SwayNC? (m/s): " notif_choice
if [[ $notif_choice == "s" || $notif_choice == "S" ]]; then
    sudo pacman -S --needed --noconfirm swaync | tee -a $LOG
    sed -i 's/exec-once = mako/exec-once = swaync/' "$CONFIG_DIR/hypr/hyprland.conf"
    echo -e "${GREEN}[OK] Switched to SwayNC.${RESET}"
fi

# 12. SDDM Setup
echo -e "\n${CYAN}[12/14] SDDM Theme Setup${RESET}"
echo "---------------------------------------------------------"
if [ -d "assets/sddm" ]; then
    sudo mkdir -p /usr/share/sddm/themes/silent
    sudo cp -r assets/sddm/* /usr/share/sddm/themes/silent/
    sudo cp configs/sddm.conf /etc/sddm.conf
    sudo mkdir -p /etc/sddm.conf.d
    echo -e "${GREEN}[OK] SDDM Theme installed.${RESET}"
else
    echo -e "${RED}[ERROR] SDDM assets not found!${RESET}"
fi

# 13. Shell Setup
echo -e "\n${CYAN}[13/14] Shell Setup (Zsh)${RESET}"
echo "---------------------------------------------------------"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions 2>/dev/null
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting 2>/dev/null

if [ -f "assets/zsh/a.zsh-theme" ]; then
    cp "assets/zsh/a.zsh-theme" "$HOME/.oh-my-zsh/themes/"
fi
if [ -f "assets/zsh/.zshrc" ]; then
    cp "assets/zsh/.zshrc" "$HOME/.zshrc"
fi
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    chsh -s /usr/bin/zsh
fi

# 14. Finalize
echo -e "\n${CYAN}[14/14] Finalizing${RESET}"
echo "---------------------------------------------------------"
echo -e "${YELLOW}[*] Refreshing fonts...${RESET}"
fc-cache -fv > /dev/null

echo -e "${YELLOW}[*] Enabling SDDM...${RESET}"
sudo systemctl enable sddm 2>/dev/null

echo -e "${GREEN}"
echo "#########################################################"
echo "    INSTALLATION COMPLETE!"
echo "    Please reboot your system."
echo "#########################################################"
echo -e "${RESET}"
