#!/bin/bash
set -euo pipefail
set -e

echo "--- Running Language/Runtime Installer ---"

sudo apt install -y build-essential libssl-dev pkg-config

sudo apt install -y python3-pip python3-venv python3-full

# Install NVM (Node Version Manager) if missing
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# Install Rust via Rustup if missing
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
