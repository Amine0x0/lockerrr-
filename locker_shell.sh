#!/bin/bash

trap '' SIGINT SIGQUIT

LOCKER_BIN="$HOME/.local/bin/locker"
REWRAP_BIN="$HOME/.local/bin/locker-rewrap"

if [ ! -f "$LOCKER_BIN" ]; then
    return 0 2>/dev/null || exit 0
fi

if ! "$LOCKER_BIN"; then
    exit 1
fi

if [ -f "$REWRAP_BIN" ]; then
    (nohup "$REWRAP_BIN" >/dev/null 2>&1 &)
fi

return 0 2>/dev/null || exit 0
