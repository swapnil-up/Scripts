#!/bin/bash
set -euo pipefail

echo "--- Running Package Installer ---"

# --- 1. Add External Repos (with existence checks) ---
echo "Checking external repositories..."

# Neovim PPA
if ! grep -q "neovim-ppa/unstable" /etc/apt/sources.list.d/* 2>/dev/null; then
    sudo add-apt-repository ppa:neovim-ppa/unstable -y
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
    "npm" "trash-cli" "gedit" "zoxide" "ncal" "pipx"
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
echo "--- Installing Flatpak Apps ---"

# 1. Ensure we use the native binary, not the snap version
if command -v snap &> /dev/null && snap list | grep -q "^flatpak "; then
    sudo snap remove flatpak
fi

sudo apt install -y flatpak

# 2. Add Flathub
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 3. Install Obsidian
if ! flatpak list | grep -q "md.obsidian.Obsidian"; then
    echo "Installing Obsidian..."
    flatpak install flathub md.obsidian.Obsidian -y
fi

# 4. Fix paths for the current session so Rofi/i3 can see the app immediately
flatpak_exports="$HOME/.local/share/flatpak/exports/share"
if [[ ":$XDG_DATA_DIRS:" != *":$flatpak_exports:"* ]]; then
    export XDG_DATA_DIRS="$flatpak_exports:$XDG_DATA_DIRS"
fi

# --- 5. Clipmenu (Build from Source) ---
if ! command -v clipmenu &> /dev/null; then
    echo "Installing clipmenu from source..."
    
    # Install build/runtime dependencies
    sudo apt install -y xsel xclip libextutils-pkgconfig-perl libx11-dev libxfixes-dev
    # Clone to /tmp so it's wiped on reboot
    TEMP_DIR=$(mktemp -d)
    git clone https://github.com/cdown/clipmenu.git "$TEMP_DIR"
    
    # Build and Install
    # By default, 'make install' puts them in /usr/local/bin
    cd "$TEMP_DIR"
    sudo make install
    
    # Cleanup is handled automatically by using a temp dir, 
    # but let's be explicit:
    rm -rf "$TEMP_DIR"
    echo "clipmenu installed and source removed."
fi

# --- Espanso (AppImage) ---
if ! command -v espanso &> /dev/null; then
    echo "Installing Espanso..."

    sudo apt install -y libfuse2
    
    # 1. Create directory and download
    mkdir -p "$HOME/opt"
    wget -O "$HOME/opt/Espanso.AppImage" 'https://github.com/espanso/espanso/releases/latest/download/Espanso-X11.AppImage'
    chmod u+x "$HOME/opt/Espanso.AppImage"
    
    # 2. Register path (Create alias)
    # Using 'yes' to skip the confirmation prompt if it exists
    yes | sudo "$HOME/opt/Espanso.AppImage" env-path register
    
    # 3. Register and Start Service
    # Note: This requires a D-Bus session, which you have in your i3 environment
    /usr/local/bin/espanso service register
    /usr/local/bin/espanso start
else
    echo "Espanso already exists, skipping."
fi

# --- Calibre ---
if ! command -v calibre &> /dev/null; then
    echo "Installing Calibre..."
    # Install dependencies required by the Calibre installer
    sudo apt install -y libxcb-cursor0 libnss3
    
    # Run the official installer
    # Note: We use --unattended to avoid interactive prompts
    sudo wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin install_dir=/opt isolated=false
else
    echo "Calibre already exists, skipping."
fi


# --- Anki (Official Launcher) ---
if ! command -v anki &> /dev/null; then
    echo "--- Installing Anki via Launcher ---"

    # 1. Install Dependencies
    sudo apt update
    sudo apt install -y libxcb-xinerama0 libxcb-cursor0 libnss3 zstd curl

    # 2. Setup Temporary Workspace
    TEMP_ANKI=$(mktemp -d)
    cd "$TEMP_ANKI"

    # 3. Download the generic Linux launcher
    # This URL is more stable than the specific versioned ones
    LAUNCHER_URL="https://github.com/ankitects/anki/releases/download/25.09/anki-launcher-25.09-linux.tar.zst"
    echo "Downloading Anki Launcher..."
    curl -L "$LAUNCHER_URL" -o anki-launcher.tar.zst

    # 4. Extract and Install
    tar --use-compress-program=unzstd -xf anki-launcher.tar.zst
    
    # Enter the extracted folder (usually named anki-launcher or similar)
    cd anki-launcher*/
    sudo ./install.sh

    # 5. Cleanup
    cd "$HOME"
    rm -rf "$TEMP_ANKI"
    
    echo "Anki Launcher installed. Running 'anki' for the first time will fetch the core files."
else
    echo "Anki already exists, skipping."
fi