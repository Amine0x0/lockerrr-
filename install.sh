#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
LOCKER_DIR="$HOME/.locker"
LOCKER_BIN="$SCRIPT_DIR/locker"
LOCKER_SHELL="$SCRIPT_DIR/locker_shell.sh"
LOCKER_GUI="$SCRIPT_DIR/locker_gui.sh"
LOCKER_REWRAP="$SCRIPT_DIR/locker_rewrap.sh"
ART_FILE="$SCRIPT_DIR/art/art"

echo "Installing locker..."

if [ ! -f "$LOCKER_BIN" ]; then
    echo "Error: locker binary not found"
    echo "Run 'make' first to compile"
    exit 1
fi

mkdir -p "$INSTALL_DIR"
mkdir -p "$LOCKER_DIR"

cp "$LOCKER_BIN" "$INSTALL_DIR/locker"
cp "$LOCKER_SHELL" "$INSTALL_DIR/locker-shell"
cp "$LOCKER_GUI" "$INSTALL_DIR/locker-gui"
cp "$LOCKER_REWRAP" "$INSTALL_DIR/locker-rewrap"
cp "$ART_FILE" "$LOCKER_DIR/art"
chmod +x "$INSTALL_DIR/locker" "$INSTALL_DIR/locker-shell" "$INSTALL_DIR/locker-gui" "$INSTALL_DIR/locker-rewrap"

add_to_shell_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        return
    fi
    
    if grep -q "locker-shell" "$config_file" 2>/dev/null; then
        echo "Locker already configured in $config_file"
        return
    fi
    
    cat >> "$config_file" << 'SHELLCONFIG'

if [ -f "$HOME/.local/bin/locker-shell" ]; then
    source "$HOME/.local/bin/locker-shell"
fi
SHELLCONFIG
    
    echo "Added locker to $config_file"
}

add_to_shell_config "$HOME/.zshrc"
add_to_shell_config "$HOME/.bashrc"
add_to_shell_config "$HOME/.bash_profile"

FISH_CONFIG="$HOME/.config/fish/config.fish"
if command -v fish &> /dev/null; then
    mkdir -p "$HOME/.config/fish"
    
    if [ ! -f "$FISH_CONFIG" ] || ! grep -q "locker-shell" "$FISH_CONFIG" 2>/dev/null; then
        cat >> "$FISH_CONFIG" << 'FISHCONFIG'

if test -f "$HOME/.local/bin/locker-shell"
    source "$HOME/.local/bin/locker-shell"
end
FISHCONFIG
        echo "Added locker to $FISH_CONFIG"
    else
        echo "Locker already configured in $FISH_CONFIG"
    fi
fi

echo ""
read -p "Setup GUI application protection? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$SCRIPT_DIR/setup_gui_interception.sh" ]; then
        bash "$SCRIPT_DIR/setup_gui_interception.sh"
    else
        echo "Error: setup_gui_interception.sh not found"
    fi
fi

echo ""
echo "Installation complete"
echo "Restart your terminal or run: source ~/.zshrc"
