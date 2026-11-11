#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Instala Zsh, GDB (para o seu debug) e dependências caso não existam na imagem
if ! command -v zsh >/dev/null 2>&1 || ! command -v gdb >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y --no-install-recommends \
        zsh \
        curl \
        git \
        gdb \
        jq \
        python3-argcomplete \
        python3-colcon-common-extensions \
    && sudo rm -rf /var/lib/apt/lists/*
fi

# 2. Instala o Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# 3. Instala os plugins e o tema Powerlevel10k
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# 4. Cria os links simbólicos de terminal
ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/p10k.zsh" "$HOME/.p10k.zsh"

# 5. Injeta a pasta .vscode em ~/ros_ws (se existir) e esconde do Git
if [ -d "$HOME/ros_ws" ] && [ ! -e "$HOME/ros_ws/.vscode" ]; then
    ln -sfn "$DOTFILES_DIR/vscode" "$HOME/ros_ws/.vscode"
    GIT_DIR=$(git -C "$HOME/ros_ws" rev-parse --git-dir 2>/dev/null || true)
    if [ -n "$GIT_DIR" ]; then
        grep -qxF ".vscode/" "$GIT_DIR/info/exclude" 2>/dev/null || echo ".vscode/" >> "$GIT_DIR/info/exclude"
        grep -qxF "ros_ws/.vscode/" "$GIT_DIR/info/exclude" 2>/dev/null || echo "ros_ws/.vscode/" >> "$GIT_DIR/info/exclude"
    fi
fi
