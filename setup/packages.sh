#!/bin/bash
set -euo pipefail

echo "--- Running Package Installer ---"

# --- 1. Add External Repos (with existence checks) ---
echo "Checking external repositories..."

# Neovim PPA
if ! grep -q "neovim-ppa" /etc/apt/sources.list.d/* 2>/dev/null; then
    sudo add-apt-repository ppa:neovim-ppa/stable -y
fi

# Fastfetch PPA
if ! grep -q "fastfetch" /etc/apt/sources.list.d/* 2>/dev/null; then
    sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y
fi

# VS Code Repo (Safe version)
if [ ! -f "/etc/apt/sources.list.d/vscode.list" ]; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
fi

sudo apt update

# --- 2. Install Apps ---
APPS=(
    "tmux" "fzf" "ripgrep" "htop" "bash-completion" "bash"
    "conky-all" "dbus" "dunst" "flameshot" "git-crypt"
    "i3-wm" "i3status" "mpv" "rofi" "stow" "tree" "i3lock"
    "blueman" "pulseaudio-utils" "libpulse0" "maim"
    "npm" "trash-cli" "gedit" "zoxide"
    "firefox" "brightnessctl" "feh" "neovim" "fastfetch" "code"
)

for app in "${APPS[@]}"; do
    if ! dpkg -s "$app" >/dev/null 2>&1; then
        echo "Installing $app..."
        sudo apt install -y "$app"
    else
        echo "$app already exists, skipping."
    fi
done

# --- 3. Binaries & Tools ---

# Starship
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

mkdir -p "$HOME/.local/bin"

# Kanata
if ! command -v kanata &> /dev/null; then
    curl -L https://github.com/jtroo/kanata/releases/latest/download/kanata_linux_x64 -o "$HOME/.local/bin/kanata"
    chmod +x "$HOME/.local/bin/kanata"
fi

# --- 4. Obsidian (Flatpak) ---
if ! command -v flatpak &> /dev/null; then 
    sudo apt install -y flatpak
fi

# ADDED: Introduce system to Flathub store
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Obsidian
flatpak install flathub md.obsidian.Obsidian -y
