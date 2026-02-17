#!/bin/bash
# Start flutter run --machine with a named pipe for programmatic hot reload.
# Usage: ./scripts/flutter-start.sh [project_dir]

set -e

PROJECT_DIR="${1:-.}"
PIPE="/tmp/flutter_in"
LOG="/tmp/flutter_out"
PID_FILE="/tmp/flutter_run.pid"

cd "$PROJECT_DIR"

# Clean up any previous session
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
        echo "Stopping previous flutter run (PID $old_pid)..."
        kill "$old_pid" 2>/dev/null || true
        sleep 2
    fi
    rm -f "$PID_FILE"
fi

rm -f "$PIPE" "$LOG"
mkfifo "$PIPE"

echo "Starting flutter run --machine..."
echo "  Pipe:   $PIPE"
echo "  Log:    $LOG"

# tail -f keeps the pipe open so multiple writes don't cause EOF
nohup bash -c 'tail -f '"$PIPE"' | flutter run --machine > '"$LOG"' 2>&1' &>/dev/null &
echo $! > "$PID_FILE"

echo "  PID:    $(cat "$PID_FILE")"
echo ""
echo "Waiting for app to launch..."

# Wait for the app to be ready (look for app.started or appId)
timeout=300
elapsed=0
app_id=""
while [ $elapsed -lt $timeout ]; do
    if [ -f "$LOG" ]; then
        app_id=$(grep -o '"appId":"[^"]*"' "$LOG" 2>/dev/null | head -1 | cut -d'"' -f4)
        if [ -n "$app_id" ]; then
            # Wait a bit more for the app to fully render
            started=$(grep -c "app.started\|Syncing files" "$LOG" 2>/dev/null || true)
            if [ "$started" -gt 0 ] 2>/dev/null; then
                break
            fi
        fi
    fi
    sleep 3
    elapsed=$((elapsed + 3))
    echo "  ... ($elapsed s)"
done

if [ -z "$app_id" ]; then
    echo "ERROR: App did not start within ${timeout}s. Check $LOG for details."
    exit 1
fi

echo "$app_id" > /tmp/flutter_app_id

echo ""
echo "App is running!"
echo "  App ID: $app_id"
echo ""
echo "Usage:"
echo "  ./scripts/flutter-reload.sh          # hot reload"
echo "  ./scripts/flutter-reload.sh --full   # full restart"
echo "  ./scripts/flutter-stop.sh            # stop flutter"
echo "  tail -f $LOG                         # watch logs"
