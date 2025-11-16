#!/bin/bash

DESKTOP_DIR="$HOME/.local/share/applications"

echo "Emergency restore of applications..."

if [ -d "$DESKTOP_DIR" ]; then
    for backup in "$DESKTOP_DIR"/*.locker-backup; do
        if [ -f "$backup" ]; then
            original="${backup%.locker-backup}"
            app_name=$(basename "$original" .desktop)
            
            rm -f "$original"
            mv "$backup" "$original"
            
            echo "Restored: $app_name"
        fi
    done
    
    rm -f "$DESKTOP_DIR"/*.desktop.locker-backup 2>/dev/null
    
    echo "Updating desktop database..."
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$DESKTOP_DIR" 2>/dev/null
    fi
fi

echo "Applications restored. Please log out and log back in, or run:"
echo "killall gnome-shell 2>/dev/null || xfce4-panel -r 2>/dev/null || true"
