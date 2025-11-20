#!/bin/bash

set -e

LOCKER_WRAPPER="$HOME/.local/bin/locker-gui"
DESKTOP_DIR="$HOME/.local/share/applications"
SYSTEM_DESKTOP_DIRS=("/usr/share/applications" "/usr/local/share/applications" "/var/lib/snapd/desktop/applications" "/var/lib/flatpak/exports/share/applications")

echo "Setting up GUI application interception (ALL apps)..."

mkdir -p "$DESKTOP_DIR"
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/locker_gui.sh" ]; then
    cp "$SCRIPT_DIR/locker_gui.sh" "$LOCKER_WRAPPER"
    chmod +x "$LOCKER_WRAPPER"
else
    echo "Error: locker_gui.sh not found in $SCRIPT_DIR"
    exit 1
fi

wrap_desktop_file() {
    local desktop_file="$1"
    local app_name=$(basename "$desktop_file" .desktop)
    
    local wrapped_file="$DESKTOP_DIR/${app_name}.desktop"
    local backup_file="$wrapped_file.locker-backup"
    
    if [ -f "$wrapped_file" ]; then
        if grep -q "$LOCKER_WRAPPER" "$wrapped_file" 2>/dev/null; then
            return 0
        fi
    fi
    
    if [ ! -f "$backup_file" ]; then
        cp "$desktop_file" "$backup_file"
    fi
    
    cp "$desktop_file" "$wrapped_file"
    sed -i.bak "s|^Exec=\(.*\)|Exec=$LOCKER_WRAPPER \1|g" "$wrapped_file"
    
    if grep -q "^TryExec=" "$wrapped_file"; then
        sed -i.bak "s|^TryExec=|#TryExec=|g" "$wrapped_file"
    fi
    
    rm -f "$wrapped_file.bak"
    
    echo "  Wrapped: $app_name"
    return 0
}

WRAPPED_COUNT=0
SKIPPED_COUNT=0
TOTAL_COUNT=0

for dir in "${SYSTEM_DESKTOP_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        continue
    fi
    
    for desktop_file in "$dir"/*.desktop; do
        if [ ! -f "$desktop_file" ]; then
            continue
        fi
        
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        
        if wrap_desktop_file "$desktop_file"; then
            WRAPPED_COUNT=$((WRAPPED_COUNT + 1))
        else
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        fi
    done
done

echo ""
echo "Setup complete"
echo "Applications found: $TOTAL_COUNT"
echo "Applications wrapped: $WRAPPED_COUNT"
echo "Applications skipped: $SKIPPED_COUNT"
