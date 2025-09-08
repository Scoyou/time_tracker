#!/usr/bin/env bash

set -uE -o pipefail  # don't use -e; some commands intentionally return nonzero

CSV_FILE="${CSV_FILE:-$HOME/time.csv}"
TEMP_FILE="${TEMP_FILE:-$HOME/.time_track_temp}"
DATE_FORMAT="${DATE_FORMAT:-+%Y-%m-%d %I:%M %p}"  # e.g., 2025-09-05 03:14 PM

# Ensure temp file exists
mkdir -p -- "$HOME"
: > "$TEMP_FILE" || true

print_help() {
    cat <<'EOF'
Time Tracker - CLI Project Time Logger

Usage:
  tt start --project <project-name>     Start tracking time for a project
  tt end --project <project-name>       End tracking and log time to CSV
  tt status                             Show all currently tracked projects
  tt --help | help                      Show this help message

Examples:
  tt start --project bcd-1234
  tt end --project bcd-1234
  tt status

Files:
  Tracks time in:     $HOME/time.csv  (override with CSV_FILE env var)
  Temp state stored:  $HOME/.time_track_temp  (override with TEMP_FILE env var)
EOF
}

# ---------- locking (optional) ----------
_lock_acquired=0
lock() {
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$TEMP_FILE.lock"
    flock 9
    _lock_acquired=1
  fi
}
unlock() {
  if [ "${_lock_acquired}" -eq 1 ] 2>/dev/null; then
    flock -u 9 || true
    exec 9>&- || true
    _lock_acquired=0
  fi
}
cleanup() {
  unlock || true
}
trap cleanup EXIT INT TERM

# ---------- helpers ----------
die() { echo "[✗] $*" >&2; exit 1; }

validate_project() {
  case "$1" in
    "") die "Missing --project";;
  esac
  # Disallow delimiter and newline to keep the storage format safe
  if printf "%s" "$1" | grep -q '[|]'; then
    die "Project name cannot contain '|'"
  fi
  if printf "%s" "$1" | tr -d '\n' | grep -q . && printf "%s" "$1" | grep -q $'\n'; then
    die "Project name cannot contain newlines"
  fi
}

# Return start time string for project or empty
get_start_time() {
  local project="$1"
  awk -v FS='|' -v p="$project" '
    $1==p {
      # print everything after the first delimiter, preserves any additional fields
      sub(/^[^|]*\|/, "", $0); print $0; exit
    }' "$TEMP_FILE"
}

# Exact match check (exit 0 if found, 1 if not)
is_tracking() {
  local project="$1"
  awk -v FS='|' -v p="$project" 'BEGIN{f=1} $1==p{f=0; exit} END{exit f}' "$TEMP_FILE"
}

# Remove the line for the project (safe even if it was the only line)
remove_start_time() {
  local project="$1"
  local tmp="${TEMP_FILE}.tmp.$$"
  awk -v FS='|' -v p="$project" '$1!=p' "$TEMP_FILE" > "$tmp"
  mv -f -- "$tmp" "$TEMP_FILE"
}

to_epoch() {
  # Convert a formatted datetime string (matching DATE_FORMAT) to epoch seconds
  # Try BSD date (macOS) then GNU date (Linux)
  local dt="$1"
  if date -j -f "%Y-%m-%d %I:%M %p" "$dt" "+%s" >/dev/null 2>&1; then
    date -j -f "%Y-%m-%d %I:%M %p" "$dt" "+%s"
    return
  fi
  if date -d "$dt" "+%s" >/dev/null 2>&1; then
    date -d "$dt" "+%s"
    return
  fi
  die "Failed to parse date: '$dt' (check DATE_FORMAT and locale)"
}

ensure_csv_header() {
  if [ ! -f "$CSV_FILE" ]; then
    printf "project,start,end,total\n" > "$CSV_FILE"
  fi
}

start_tracking() {
  local project="$1"
  validate_project "$project"

  lock
  if is_tracking "$project"; then
    echo "[!] Project '$project' is already being tracked."
    unlock
    return 0
  fi

  local now
  now="$(date "$DATE_FORMAT")"

  printf "%s|%s\n" "$project" "$now" >> "$TEMP_FILE"
  echo "[✓] Started tracking for '$project' at $now"
  unlock
}

end_tracking() {
  local project="$1"
  validate_project "$project"

  lock
  local start
  start="$(get_start_time "$project")"
  if [ -z "$start" ]; then
    echo "[!] No start time found for project '$project'."
    unlock
    return 0
  fi

  local start_epoch end_time end_epoch duration_seconds hours minutes duration
  start_epoch="$(to_epoch "$start")"
  end_time="$(date "$DATE_FORMAT")"
  end_epoch="$(date "+%s")"

  duration_seconds=$(( end_epoch - start_epoch ))
  if [ "$duration_seconds" -lt 0 ]; then
    duration_seconds=0
  fi
  hours=$(( duration_seconds / 3600 ))
  minutes=$(( (duration_seconds % 3600) / 60 ))
  duration="${hours}h ${minutes}m"

  ensure_csv_header
  printf "%s,%s,%s,%s\n" "$project" "$start" "$end_time" "$duration" >> "$CSV_FILE"

  echo "[✓] Ended tracking for '$project' at $end_time"
  echo "[⏱] Duration: $duration"

  remove_start_time "$project"
  unlock
}

status_tracking() {
  lock
  if [ ! -s "$TEMP_FILE" ]; then
    echo "[ℹ] No active tracking sessions."
    unlock
    return 0
  fi

  echo "[⏳] Active projects:"
  printf "%-15s| %s\n" "Project" "Start Time"
  echo "----------------|-----------------------"
  awk -v FS='|' '{ printf "%-15s| %s\n", $1, substr($0, index($0,$2)) }' "$TEMP_FILE"
  unlock
}

# ---------- CLI parser ----------
command="${1:-}"
shift || true

project=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project|-p)
      project="${2:-}"; shift ;;
    --help|help)
      print_help; exit 0 ;;
    *)
      # ignore unknown flags to remain compatible with future extensions
      ;;
  esac
  shift || true
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
  --help|help)
    print_help
    ;;
  *)
    echo "[✗] Unknown or missing command: '$command'"
    print_help
    exit 1
    ;;
esac
