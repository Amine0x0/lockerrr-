#!/bin/bash

LOCKER_BIN="$HOME/.local/bin/locker"
SESSION_FILE="$HOME/.locker/.session"
SESSION_TIMEOUT=1800

if [ ! -f "$LOCKER_BIN" ]; then
    exec "$@"
fi

if [ -f "$SESSION_FILE" ]; then
    LAST_AUTH=$(cat "$SESSION_FILE" 2>/dev/null || echo "0")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_AUTH))
    
    if [ $TIME_DIFF -lt $SESSION_TIMEOUT ]; then
        exec "$@"
    fi
fi

AUTH_SCRIPT="/tmp/locker_auth_$$"
cat > "$AUTH_SCRIPT" << 'AUTHSCRIPT'
#!/bin/bash
trap '' SIGINT SIGQUIT
if "$HOME/.local/bin/locker"; then
    echo ""
    sleep 1
    exit 0
else
    echo ""
    echo "Authentication failed"
    sleep 2
    exit 1
fi
AUTHSCRIPT
chmod +x "$AUTH_SCRIPT"

if command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal --title="Locker Authentication" --wait -- "$AUTH_SCRIPT" || exit 1
elif command -v konsole >/dev/null 2>&1; then
    konsole --title "Locker Authentication" -e "$AUTH_SCRIPT" || exit 1
elif command -v xfce4-terminal >/dev/null 2>&1; then
    xfce4-terminal --title="Locker Authentication" -e "$AUTH_SCRIPT" || exit 1
elif command -v xterm >/dev/null 2>&1; then
    xterm -T "Locker Authentication" -e "$AUTH_SCRIPT" || exit 1
elif command -v alacritty >/dev/null 2>&1; then
    alacritty --title "Locker Authentication" -e "$AUTH_SCRIPT" || exit 1
elif command -v kitty >/dev/null 2>&1; then
    kitty --title "Locker Authentication" -e "$AUTH_SCRIPT" || exit 1
else
    "$LOCKER_BIN" || exit 1
fi

rm -f "$AUTH_SCRIPT"

exec "$@"
