#!/usr/bin/env bash
set -uE -o pipefail  # avoid -e; some commands may return nonzero intentionally

CSV_FILE="${CSV_FILE:-$HOME/time.csv}"
TEMP_FILE="${TEMP_FILE:-$HOME/.time_track_temp}"
DATE_FORMAT="${DATE_FORMAT:-+%Y-%m-%d %I:%M %p}"  # display only

# Ensure temp file exists (do NOT truncate)
mkdir -p -- "$HOME"
touch -- "$TEMP_FILE"

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
  Tracks time in:     $HOME/time.csv        (override with CSV_FILE)
  Temp state stored:  $HOME/.time_track_temp (override with TEMP_FILE)
EOF
}

# ---------- locking ----------
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
cleanup() { unlock || true; }
trap cleanup EXIT INT TERM

# ---------- helpers ----------
die() { echo "[✗] $*" >&2; exit 1; }

validate_project() {
  local name="$1"
  if [ -z "$name" ]; then
    die "Missing --project"
  fi
  # Disallow only the pipe (|) and literal newlines
  case "$name" in
    *$'\n'* ) die "Project name cannot contain newlines" ;;
    *'|'* )   die "Project name cannot contain '|'" ;;
  esac
}

ensure_csv_header() {
  if [ ! -f "$CSV_FILE" ]; then
    printf "project,start,end,duration_seconds,duration\n" > "$CSV_FILE"
  fi
}

# Returns 0 if project is currently tracked, 1 otherwise
is_tracking() {
  local project="$1"
  awk -v FS='|' -v p="$project" 'BEGIN{f=1} $1==p{f=0; exit} END{exit f}' "$TEMP_FILE"
}

# Get the full temp line for a project: "project|start_epoch|start_human"
get_line() {
  local project="$1"
  awk -v FS='|' -v p="$project" '$1==p { print; exit }' "$TEMP_FILE"
}

# Remove project line from temp
remove_project() {
  local project="$1"
  local tmp="${TEMP_FILE}.tmp.$$"
  awk -v FS='|' -v p="$project" '$1!=p' "$TEMP_FILE" > "$tmp"
  mv -f -- "$tmp" "$TEMP_FILE"
}

start_tracking() {
  local project="$1"
  validate_project "$project"

  lock
  if is_tracking "$project"; then
    echo "[!] Project '$project' is already being tracked."
    unlock; return 0
  fi

  local now_human now_epoch
  now_human="$(date "$DATE_FORMAT")"
  now_epoch="$(date +%s)"
  printf "%s|%s|%s\n" "$project" "$now_epoch" "$now_human" >> "$TEMP_FILE"
  echo "[✓] Started tracking for '$project' at $now_human"
  unlock
}

status_tracking() {
  lock
  if [ ! -s "$TEMP_FILE" ]; then
    echo "[ℹ] No active tracking sessions."
    unlock; return 0
  fi

  echo "[⏳] Active projects:"
  printf "%-20s| %s\n" "Project" "Start Time"
  echo "--------------------|------------------------"
  awk -v FS='|' '{ printf "%-20s| %s\n", $1, $3 }' "$TEMP_FILE"
  unlock
}

end_tracking() {
  local project="$1"
  validate_project "$project"

  lock
  local line
  line="$(get_line "$project")"
  if [ -z "$line" ]; then
    echo "[!] No active session found for '$project'."
    unlock; return 0
  fi

  IFS='|' read -r p start_epoch start_human <<<"$line"

  local end_epoch end_human
  end_epoch="$(date +%s)"
  end_human="$(date "$DATE_FORMAT")"

  local duration_seconds=$(( end_epoch - start_epoch ))
  if [ "$duration_seconds" -lt 0 ]; then duration_seconds=0; fi

  # Pretty duration HH:MM
  local hours minutes
  hours=$(( duration_seconds / 3600 ))
  minutes=$(( (duration_seconds % 3600) / 60 ))
  local duration="${hours}h ${minutes}m"

  ensure_csv_header
  printf "%s,%s,%s,%s,%s\n" "$project" "$start_human" "$end_human" "$duration_seconds" "$duration" >> "$CSV_FILE"

  echo "[✓] Ended tracking for '$project' at $end_human"
  echo "[⏱] Duration: $duration"

  remove_project "$project"
  unlock
}

# ---------- CLI parser ----------
command="${1:-}"
shift || true

project=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --project|-p) project="${2:-}"; shift ;;
    --help|help) print_help; exit 0 ;;
    *) ;;  # ignore unknown flags for forward-compat
  esac
  shift || true
done

case "$command" in
  start)  [ -z "$project" ] && { echo "Missing --project"; print_help; exit 1; }; start_tracking "$project" ;;
  end)    [ -z "$project" ] && { echo "Missing --project"; print_help; exit 1; }; end_tracking "$project" ;;
  status) status_tracking ;;
  --help|help) print_help ;;
  *) echo "[✗] Unknown or missing command: '$command'"; print_help; exit 1 ;;
esac
