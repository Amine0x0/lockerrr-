#!/bin/bash

set -e

INSTALL_DIR="$HOME/.local/bin"
LOCKER_DIR="$HOME/.locker"
DESKTOP_DIR="$HOME/.local/share/applications"

echo "Uninstalling locker..."

rm -f "$INSTALL_DIR/locker"
rm -f "$INSTALL_DIR/locker-shell"
rm -f "$INSTALL_DIR/locker-gui"
rm -f "$INSTALL_DIR/locker-rewrap"

for backup in "$DESKTOP_DIR"/*.locker-backup; do
    if [ -f "$backup" ]; then
        original="${backup%.locker-backup}"
        mv "$backup" "$original"
        echo "Restored: $(basename "$original")"
    fi
done

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

clean_shell_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        return
    fi
    
    local temp_file=$(mktemp)
    local skip=0
    
    while IFS= read -r line; do
        if [[ "$line" == *"locker-shell"* ]] || [[ "$line" == *"locker-rewrap"* ]]; then
            skip=1
            continue
        fi
        
        if [ $skip -eq 1 ]; then
            if [[ "$line" == "fi" ]] || [[ "$line" == "end" ]]; then
                skip=0
                continue
            fi
            continue
        fi
        
        echo "$line" >> "$temp_file"
    done < "$config_file"
    
    mv "$temp_file" "$config_file"
    echo "Cleaned: $config_file"
}

clean_shell_config "$HOME/.zshrc"
clean_shell_config "$HOME/.bashrc"
clean_shell_config "$HOME/.bash_profile"
clean_shell_config "$HOME/.config/fish/config.fish"

echo ""
echo "Uninstallation complete"
echo "Restart your shell: exec zsh"
