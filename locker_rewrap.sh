#!/bin/bash

LOCKER_WRAPPER="$HOME/.local/bin/locker-gui"
DESKTOP_DIR="$HOME/.local/share/applications"

if [ ! -f "$LOCKER_WRAPPER" ]; then
    exit 0
fi

for backup in "$DESKTOP_DIR"/*.locker-backup; do
    if [ ! -f "$backup" ]; then
        continue
    fi
    
    app_name=$(basename "$backup" .locker-backup)
    wrapped_file="$DESKTOP_DIR/${app_name}"
    
    if [ ! -f "$wrapped_file" ] || ! grep -q "$LOCKER_WRAPPER" "$wrapped_file" 2>/dev/null; then
        if [ -f "$backup" ]; then
            cp "$backup" "$wrapped_file"
            sed -i "s|^Exec=\(.*\)|Exec=$LOCKER_WRAPPER \1|g" "$wrapped_file" 2>/dev/null
        fi
    fi
done

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
