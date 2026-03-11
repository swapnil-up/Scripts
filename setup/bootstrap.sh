#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
set -e

# Ask for sudo upfront and keep it alive
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "Installing base requirements..."

# 1. Update package lists (essential for a fresh install)
sudo apt update -y

# 2. Define your "Seed" packages
# Using 'git', 'stow', 'curl', and 'build-essential' (common for building tools)
PACKAGES=(git stow curl build-essential)

# 3. Install only what is missing
for pkg in "${PACKAGES[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "  [OK] $pkg is already installed."
    else
        echo "  [..] Installing $pkg..."
        sudo apt install -y "$pkg"
    fi
done

# 4. Run Modular Installers
# Get the directory where the script is located to handle relative paths correctly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting modular installations..."

sudo groupadd --system uinput || true
sudo usermod -aG input $USER
sudo usermod -aG uinput $USER
# Add udev rule for non-root access
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/99-input.rules

# Ensure the install scripts are executable
chmod +x "$SCRIPT_DIR/languages.sh"
chmod +x "$SCRIPT_DIR/packages.sh"

# Execute them
"$SCRIPT_DIR/languages.sh"
"$SCRIPT_DIR/packages.sh"


# --- 5. The Stow Phase ---
echo "Linking configurations with Stow..."

mv ~/.bashrc ~/.bashrc.bak
mv ~/.profile ~/.profile.bak

# Find the configs directory relative to the script
CONFIG_DIR="$(cd "$SCRIPT_DIR/../config" && pwd)"

# Change directory to the configs folder
cd "$CONFIG_DIR"

# Loop through every directory inside 'configs/' and stow it
for folder in */; do
    folder=${folder%/} # Remove trailing slash
    echo "  [LINK] Stowing $folder..."
    
    # -R: Restow (handles existing links)
    # -t ~: Target the home directory
    stow -R -t "$HOME" "$folder"
done

echo "Setup complete! Restart your shell."
