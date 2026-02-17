#!/bin/bash
# Send a hot reload (or full restart) to a running flutter --machine session.
# Usage: ./scripts/flutter-reload.sh [--full]

set -e

PIPE="/tmp/flutter_in"
LOG="/tmp/flutter_out"
APP_ID_FILE="/tmp/flutter_app_id"

if [ ! -p "$PIPE" ]; then
    echo "ERROR: Named pipe $PIPE not found. Run flutter-start.sh first."
    exit 1
fi

if [ ! -f "$APP_ID_FILE" ]; then
    echo "ERROR: App ID file not found. Run flutter-start.sh first."
    exit 1
fi

app_id=$(cat "$APP_ID_FILE")

full_restart=false
if [ "$1" = "--full" ] || [ "$1" = "-f" ]; then
    full_restart=true
fi

# Use a unique request ID based on timestamp
req_id=$(date +%s%N | cut -c1-10)

if [ "$full_restart" = true ]; then
    echo "Sending full restart..."
    echo "[{\"id\":$req_id,\"method\":\"app.restart\",\"params\":{\"appId\":\"$app_id\",\"fullRestart\":true,\"pause\":false}}]" > "$PIPE"
else
    echo "Sending hot reload..."
    echo "[{\"id\":$req_id,\"method\":\"app.restart\",\"params\":{\"appId\":\"$app_id\",\"fullRestart\":false,\"pause\":false}}]" > "$PIPE"
fi

# Wait for the reload result
sleep 1
timeout=15
elapsed=0
while [ $elapsed -lt $timeout ]; do
    result=$(grep "\"id\":$req_id" "$LOG" 2>/dev/null | tail -1 || true)
    if [ -n "$result" ]; then
        code=$(echo "$result" | grep -o '"code":[0-9]*' | cut -d: -f2)
        message=$(echo "$result" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        if [ "$code" = "0" ]; then
            echo "OK: $message"
        else
            echo "FAILED (code $code): $message"
        fi
        exit 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

echo "WARNING: No response within ${timeout}s. Check $LOG"
