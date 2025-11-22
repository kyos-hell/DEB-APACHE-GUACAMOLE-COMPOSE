#!/bin/bash
set -e

# --- Retrieve the bind address from the environment or fall back to 0.0.0.0 --- 
GUACD_BIND_ADDRESS="${GUACD_BIND_ADDRESS:-0.0.0.0}"

# --- Final start in foreground --- 
if [ "$1" = "bash" ]; then
    exec /bin/bash
else
    echo "Starting guacd on $GUACD_BIND_ADDRESS:4822..."
    exec /usr/local/sbin/guacd -b "$GUACD_BIND_ADDRESS" -f -L info
fi