#!/bin/bash

LOCKER_BIN="$HOME/.local/bin/locker"
REWRAP_BIN="$HOME/.local/bin/locker-rewrap"
SESSION_FILE="$HOME/.locker/.session"
SESSION_TIMEOUT=1800

if [ ! -f "$LOCKER_BIN" ]; then
    return 0 2>/dev/null || exit 0
fi

if [ -f "$SESSION_FILE" ]; then
    LAST_AUTH=$(cat "$SESSION_FILE" 2>/dev/null || echo "0")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_AUTH))
    
    if [ $TIME_DIFF -lt $SESSION_TIMEOUT ]; then
        if [ -f "$REWRAP_BIN" ]; then
            (nohup "$REWRAP_BIN" >/dev/null 2>&1 &)
        fi
        return 0 2>/dev/null || exit 0
    fi
fi

trap '' SIGINT SIGQUIT

if ! "$LOCKER_BIN"; then
    exit 1
fi

trap - SIGINT SIGQUIT

if [ -f "$REWRAP_BIN" ]; then
    (nohup "$REWRAP_BIN" >/dev/null 2>&1 &)
fi

return 0 2>/dev/null || exit 0
