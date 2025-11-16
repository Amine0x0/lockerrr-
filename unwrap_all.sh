#!/bin/bash

LOCKER_WRAPPER="$HOME/.local/bin/locker-gui"
DESKTOP_DIR="$HOME/.local/share/applications"
SYSTEM_DESKTOP_DIRS=("/usr/share/applications" "/usr/local/share/applications" "/var/lib/snapd/desktop/applications" "/var/lib/flatpak/exports/share/applications")

echo "Unwrapping all desktop files..."

for wrapped_file in "$DESKTOP_DIR"/*.desktop; do
    if [ ! -f "$wrapped_file" ]; then
        continue
    fi
    
    if grep -q "$LOCKER_WRAPPER" "$wrapped_file" 2>/dev/null; then
        app_name=$(basename "$wrapped_file" .desktop)
        echo "Unwrapping: $app_name"
        
        found_original=false
        for dir in "${SYSTEM_DESKTOP_DIRS[@]}"; do
            if [ -f "$dir/${app_name}.desktop" ]; then
                cp "$dir/${app_name}.desktop" "$wrapped_file"
                found_original=true
                echo "  Restored from: $dir"
                break
            fi
        done
        
        if [ "$found_original" = false ]; then
            rm "$wrapped_file"
            echo "  Removed (no original found)"
        fi
    fi
done

rm -f "$DESKTOP_DIR"/*.locker-backup 2>/dev/null

if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null
fi

echo "All desktop files unwrapped."
echo "Restart your session or run: killall gnome-shell 2>/dev/null"
