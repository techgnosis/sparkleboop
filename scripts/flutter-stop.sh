#!/bin/bash
# Stop a running flutter --machine session and clean up.
# Usage: ./scripts/flutter-stop.sh

PIPE="/tmp/flutter_in"
LOG="/tmp/flutter_out"
PID_FILE="/tmp/flutter_run.pid"
APP_ID_FILE="/tmp/flutter_app_id"

# Try graceful stop first via the machine protocol
if [ -p "$PIPE" ] && [ -f "$APP_ID_FILE" ]; then
    app_id=$(cat "$APP_ID_FILE")
    echo "Sending app.stop..."
    echo "[{\"id\":999,\"method\":\"app.stop\",\"params\":{\"appId\":\"$app_id\"}}]" > "$PIPE" 2>/dev/null || true
    sleep 2
fi

# Kill the process if still running
if [ -f "$PID_FILE" ]; then
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        echo "Killing flutter run (PID $pid)..."
        kill "$pid" 2>/dev/null || true
        sleep 1
        # Force kill if needed
        kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
fi

# Also kill any remaining flutter/dart processes for this project
pkill -f "flutter run --machine" 2>/dev/null || true
pkill -f "tail -f $PIPE" 2>/dev/null || true

# Clean up temp files
rm -f "$PIPE" "$LOG" "$APP_ID_FILE"

echo "Stopped and cleaned up."
