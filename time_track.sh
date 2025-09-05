#!/bin/bash

CSV_FILE="$HOME/time.csv"
TEMP_FILE="$HOME/.time_track_temp"
DATE_FORMAT="+%Y-%m-%d %I:%M %p"

touch "$TEMP_FILE"

print_help() {
    cat <<EOF
Time Tracker - CLI Project Time Logger

Usage:
  $0 start --project <project-name>     Start tracking time for a project
  $0 end --project <project-name>       End tracking and log time to CSV
  $0 status                              Show all currently tracked projects
  $0 --help | help                       Show this help message

Examples:
  $0 start --project bcd-1234
  $0 end --project bcd-1234
  $0 status

Files:
  Tracks time in:     $CSV_FILE
  Temp state stored:  $TEMP_FILE
EOF
}

get_start_time() {
    grep "^$1|" "$TEMP_FILE" | cut -d'|' -f2-
}

remove_start_time() {
    grep -v "^$1|" "$TEMP_FILE" > "${TEMP_FILE}.tmp" && mv "${TEMP_FILE}.tmp" "$TEMP_FILE"
}

is_tracking() {
    grep -q "^$1|" "$TEMP_FILE"
}

start_tracking() {
    local project="$1"
    if is_tracking "$project"; then
        echo "[!] Project '$project' is already being tracked."
        return
    fi
    local now
    now=$(date "$DATE_FORMAT")
    echo "$project|$now" >> "$TEMP_FILE"
    echo "[✓] Started tracking for '$project' at $now"
}

end_tracking() {
    local project="$1"
    local start
    start=$(get_start_time "$project")

    if [ -z "$start" ]; then
        echo "[!] No start time found for project '$project'."
        return
    fi

    if date -j -f "%Y-%m-%d %I:%M %p" "$start" "+%s" >/dev/null 2>&1; then
        start_epoch=$(date -j -f "%Y-%m-%d %I:%M %p" "$start" "+%s")
    else
        start_epoch=$(date -d "$start" "+%s")
    fi

    end_time=$(date "$DATE_FORMAT")
    end_epoch=$(date "+%s")

    duration_seconds=$(( end_epoch - start_epoch ))
    hours=$(( duration_seconds / 3600 ))
    minutes=$(( (duration_seconds % 3600) / 60 ))
    duration="${hours}h ${minutes}m"

    if [ ! -f "$CSV_FILE" ]; then
        echo "project,start,end,total" > "$CSV_FILE"
    fi
    echo "$project,$start,$end_time,$duration" >> "$CSV_FILE"

    echo "[✓] Ended tracking for '$project' at $end_time"
    echo "[⏱] Duration: $duration"

    remove_start_time "$project"
}

status_tracking() {
    if [ ! -s "$TEMP_FILE" ]; then
        echo "[ℹ] No active tracking sessions."
        return
    fi

    echo "[⏳] Active projects:"
    echo "Project         | Start Time"
    echo "----------------|-----------------------"
    while IFS="|" read -r project start_time; do
        printf "%-15s| %s\n" "$project" "$start_time"
    done < "$TEMP_FILE"
}

# CLI parser
command="$1"
shift || true

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --project) project="$2"; shift ;;
        *) ;;
    esac
    shift
done

case "$command" in
    start)
        [ -z "$project" ] && { echo "Missing --project"; print_help; exit 1; }
        start_tracking "$project"
        ;;
    end)
        [ -z "$project" ] && { echo "Missing --project"; print_help; exit 1; }
        end_tracking "$project"
        ;;
    status)
        status_tracking
        ;;
    --help | help)
        print_help
        ;;
    *)
        echo "[✗] Unknown or missing command: '$command'"
        print_help
        exit 1
        ;;
esac
