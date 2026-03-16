#!/bin/bash
set -euo pipefail

echo "--- Running Language/Runtime Installer ---"

sudo apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev pkg-config libc6-dev-i386 clang-18 libclang-common-18-dev

sudo apt install -y python3-pip python3-venv python3-full

if [ ! -d "$HOME/.pyenv" ]; then
    echo "Installing Pyenv..."
    curl https://pyenv.run | bash
else
    echo "Pyenv already installed, skipping..."
fi

# Install NVM (Node Version Manager) if missing
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    nvm install --lts
    nvm use --lts
fi

# Install Rust via Rustup if missing
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Install Tree-sitter CLI via Cargo (The GLIBC-safe way)
if ! command -v tree-sitter &> /dev/null; then
    echo "Installing Tree-sitter CLI via Cargo (building from source)..."
    # This ensures it's compiled specifically for your system's GLIBC
    cargo install tree-sitter-cli
fi