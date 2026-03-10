#!/bin/bash
set -euo pipefail

echo "--- Running Package Installer ---"

# --- 1. Add External Repos ---
echo "Adding external repositories..."
sudo add-apt-repository ppa:neovim-ppa/stable -y
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y # For Fastfetch

# VS Code Repo
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt update

APPS=(
    "tmux"
    "fzf"
    "ripgrep"
    "htop"
    "bash-completion"
    "bash"
    "conky"
    "dbus"
    "dunst"
    "flameshot"
    "git-crypt"
    "i3-wm"
    "i3status"
    "mpv"
    "rofi"
    "stow"
    "tree"
    "i3lock"
    "blueman"
    "pulseaudio-utils"
    "libpulse0"
    "maim"
    "firefox"
    "brightnessctl"
    "feh"
    "neovim"
    "fastfetch"
    "code"
)

for app in "${APPS[@]}"; do
    if ! command -v "$app" &> /dev/null; then
        echo "Installing $app..."
        sudo apt install -y "$app"
    else
        echo "$app already exists, skipping."
    fi
done

# Starship
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

mkdir -p "$HOME/.local/bin"

# Kanata (Assuming you have cargo from languages.sh, or download binary)
if ! command -v kanata &> /dev/null; then
    # Simple binary download to ~/.local/bin/
    curl -L https://github.com/jtroo/kanata/releases/latest/download/kanata_linux_x64 -o ~/.local/bin/kanata
    chmod +x ~/.local/bin/kanata
fi

# Obsidian (Flatpak is easiest for Ubuntu)
if ! command -v flatpak &> /dev/null; then sudo apt install -y flatpak; fi
flatpak install flathub md.obsidian.Obsidian -y