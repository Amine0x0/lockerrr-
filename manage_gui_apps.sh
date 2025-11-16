#!/bin/bash


set -e

LOCKER_WRAPPER="$HOME/.local/bin/locker-gui"
DESKTOP_DIR="$HOME/.local/share/applications"
SYSTEM_DESKTOP_DIRS=("/usr/share/applications" "/usr/local/share/applications" "/var/lib/snapd/desktop/applications" "/var/lib/flatpak/exports/share/applications")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ ! -f "$LOCKER_WRAPPER" ]; then
    echo -e "${RED}Error: locker-gui wrapper not found${NC}"
    echo "Please run ./install.sh first"
    exit 1
fi

is_wrapped() {
    local app_name="$1"
    [ -f "$DESKTOP_DIR/${app_name}.desktop.locker-backup" ]
}

get_all_apps() {
    local apps=()
    local seen=()
    
    for dir in "${SYSTEM_DESKTOP_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            continue
        fi
        
        for desktop_file in "$dir"/*.desktop; do
            if [ ! -f "$desktop_file" ]; then
                continue
            fi
            
            if grep -q "^Type=Application" "$desktop_file" 2>/dev/null && \
               ! grep -q "^NoDisplay=true" "$desktop_file" 2>/dev/null && \
               ! grep -q "^Terminal=true" "$desktop_file" 2>/dev/null; then
                
                local app_name=$(basename "$desktop_file" .desktop)
                
                if [[ ! " ${seen[@]} " =~ " ${app_name} " ]]; then
                    local display_name=$(grep "^Name=" "$desktop_file" | head -1 | cut -d'=' -f2)
                    [ -z "$display_name" ] && display_name="$app_name"
                    
                    apps+=("$app_name|$display_name")
                    seen+=("$app_name")
                fi
            fi
        done
    done
    
    printf '%s\n' "${apps[@]}" | sort -t'|' -k2
}

wrap_app() {
    local app_name="$1"
    
    local desktop_file=""
    for dir in "${SYSTEM_DESKTOP_DIRS[@]}"; do
        if [ -f "$dir/${app_name}.desktop" ]; then
            desktop_file="$dir/${app_name}.desktop"
            break
        fi
    done
    
    if [ -z "$desktop_file" ]; then
        echo -e "${RED}Error: Desktop file not found for $app_name${NC}"
        return 1
    fi
    
    local wrapped_file="$DESKTOP_DIR/${app_name}.desktop"
    
    if is_wrapped "$app_name"; then
        echo -e "${YELLOW}Already wrapped: $app_name${NC}"
        return 0
    fi
    
    if [ -f "$wrapped_file" ]; then
        cp "$wrapped_file" "$wrapped_file.locker-backup"
    fi
    
    mkdir -p "$DESKTOP_DIR"
    cp "$desktop_file" "$wrapped_file"
    sed -i "s|^Exec=\(.*\)|Exec=$LOCKER_WRAPPER \1|g" "$wrapped_file"
    
    if grep -q "^TryExec=" "$wrapped_file"; then
        sed -i "s|^TryExec=|#TryExec=|g" "$wrapped_file"
    fi
    
    echo -e "${GREEN}✓ Wrapped: $app_name${NC}"
    return 0
}

unwrap_app() {
    local app_name="$1"
    local wrapped_file="$DESKTOP_DIR/${app_name}.desktop"
    local backup_file="$wrapped_file.locker-backup"
    
    if ! is_wrapped "$app_name"; then
        echo -e "${YELLOW}Not wrapped: $app_name${NC}"
        return 0
    fi
    
    rm -f "$wrapped_file"
    mv "$backup_file" "$wrapped_file"
    
    echo -e "${GREEN}✓ Unwrapped: $app_name${NC}"
    return 0
}

show_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    Locker GUI Application Manager         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo "1) List all wrapped applications"
    echo "2) List all available applications"
    echo "3) Wrap specific application"
    echo "4) Unwrap specific application"
    echo "5) Wrap all applications"
    echo "6) Unwrap all applications"
    echo "7) Interactive selection mode"
    echo "8) Exit"
    echo ""
    echo -n "Choose an option: "
}

list_wrapped() {
    echo ""
    echo -e "${GREEN}=== Currently Wrapped Applications ===${NC}"
    local count=0
    
    for backup in "$DESKTOP_DIR"/*.locker-backup; do
        if [ -f "$backup" ]; then
            local app_name=$(basename "$backup" .desktop.locker-backup)
            local wrapped_file="$DESKTOP_DIR/${app_name}.desktop"
            local display_name=$(grep "^Name=" "$wrapped_file" 2>/dev/null | head -1 | cut -d'=' -f2)
            [ -z "$display_name" ] && display_name="$app_name"
            
            echo "  ✓ $display_name ($app_name)"
            count=$((count + 1))
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo "  No applications are currently wrapped"
    else
        echo ""
        echo "Total: $count applications"
    fi
}

list_available() {
    echo ""
    echo -e "${BLUE}=== Available Applications ===${NC}"
    
    local apps=($(get_all_apps))
    local count=0
    
    for app in "${apps[@]}"; do
        local app_name=$(echo "$app" | cut -d'|' -f1)
        local display_name=$(echo "$app" | cut -d'|' -f2)
        
        if is_wrapped "$app_name"; then
            echo -e "  ${GREEN}[WRAPPED]${NC} $display_name ($app_name)"
        else
            echo "  [      ] $display_name ($app_name)"
        fi
        count=$((count + 1))
    done
    
    echo ""
    echo "Total: $count applications found"
}

interactive_mode() {
    echo ""
    echo -e "${YELLOW}=== Interactive Selection Mode ===${NC}"
    echo "Loading applications..."
    
    local apps=($(get_all_apps))
    local selected=()
    
    for app in "${apps[@]}"; do
        local app_name=$(echo "$app" | cut -d'|' -f1)
        if is_wrapped "$app_name"; then
            selected+=("$app_name")
        fi
    done
    
    echo ""
    echo "Use this feature with command line tools like 'fzf' or 'dialog'"
    echo "For now, you can use options 3 and 4 to wrap/unwrap individual apps"
}

while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            list_wrapped
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            list_available
            echo ""
            read -p "Press Enter to continue..."
            ;;
        3)
            echo ""
            echo -n "Enter application name to wrap: "
            read -r app_name
            wrap_app "$app_name"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        4)
            echo ""
            echo -n "Enter application name to unwrap: "
            read -r app_name
            unwrap_app "$app_name"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        5)
            echo ""
            echo "Wrapping all applications..."
            local apps=($(get_all_apps))
            for app in "${apps[@]}"; do
                local app_name=$(echo "$app" | cut -d'|' -f1)
                wrap_app "$app_name"
            done
            echo ""
            read -p "Press Enter to continue..."
            ;;
        6)
            echo ""
            echo "Unwrapping all applications..."
            for backup in "$DESKTOP_DIR"/*.locker-backup; do
                if [ -f "$backup" ]; then
                    local app_name=$(basename "$backup" .desktop.locker-backup)
                    unwrap_app "$app_name"
                fi
            done
            echo ""
            read -p "Press Enter to continue..."
            ;;
        7)
            interactive_mode
            echo ""
            read -p "Press Enter to continue..."
            ;;
        8)
            echo ""
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo ""
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
done
