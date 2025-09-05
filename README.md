# Time Tracker — CLI Project Time Logger

A tiny Bash script to track time you spend on projects from the command line. Start a timer, stop it, and your sessions are appended to a CSV you can open in any spreadsheet app.

> **At a glance**
> - Commands: `start`, `end`, `status`, `help`
> - Data file: `$HOME/time.csv`
> - Temp state: `$HOME/.time_track_temp`
> - Cross‑platform: works on macOS (BSD `date`) and Linux (GNU `date`)

---

## Features
- ✅ Start/stop timers per project (track multiple projects concurrently)
- 📝 Logs CSV rows with headers: `project,start,end,total`
- 🧮 Duration is calculated precisely using epoch timestamps
- 💻 Works on macOS and Linux without extra dependencies
- 🔍 Quick `status` view of currently running timers

---

## Installation

1. **Save the script** (for example as `time`):  
   ```bash
   mkdir -p "$HOME/bin"
   # paste your script into $HOME/bin/time
   chmod +x "$HOME/bin/time"
   ```

2. **Add to your PATH** (if not already):  
   ```bash
   # Bash
   echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
   # Zsh
   echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
   ```

3. **Verify**:  
   ```bash
   time --help
   ```

> You can name the script whatever you like. The usage examples below assume the command is `time`.

---

## Usage

```text
Time Tracker - CLI Project Time Logger

Usage:
  time start --project <project-name>     Start tracking time for a project
  time end --project <project-name>       End tracking and log time to CSV
  time status                             Show all currently tracked projects
  time --help | help                      Show this help message

Examples:
  time start --project bcd-1234
  time end --project bcd-1234
  time status
```

### Examples

Start tracking a task:
```bash
time start --project bcd-1234
# [✓] Started tracking for 'bcd-1234' at 2025-09-05 10:42 AM
```

Stop and log it:
```bash
time end --project bcd-1234
# [✓] Ended tracking for 'bcd-1234' at 2025-09-05 11:17 AM
# [⏱] Duration: 0h 35m
```

See what’s currently running:
```bash
time status
# [⏳] Active projects:
# Project         | Start Time
# ----------------|-----------------------
# bcd-1234        | 2025-09-05 10:42 AM
```

---

## Output files

- **CSV log**: `~/time.csv` (auto-created with header on first write)  
  Example rows:
  ```csv
  project,start,end,total
  bcd-1234,2025-09-05 10:42 AM,2025-09-05 11:17 AM,0h 35m
  ```

- **Temp state**: `~/.time_track_temp`  
  Stores active sessions in `project|start_time` lines, one per running project.

> Tip: Pretty‑print the CSV in your terminal:
> ```bash
> column -s, -t < "$HOME/time.csv" | less -S
> ```

---

## Customization

Open the script and tweak these constants at the top:

```bash
CSV_FILE="$HOME/time.csv"           # where sessions are logged
TEMP_FILE="$HOME/.time_track_temp"  # temp store for active timers
DATE_FORMAT="+%Y-%m-%d %I:%M %p"    # e.g., 2025-09-05 03:14 PM
```

- Use 24‑hour format by changing to:  
  `DATE_FORMAT="+%Y-%m-%d %H:%M"`
- Log elsewhere (e.g., Dropbox):  
  `CSV_FILE="$HOME/Dropbox/time.csv"`

---

## How it works (under the hood)

- **start**: appends a line `project|<formatted time>` to `TEMP_FILE` (one line per active project).
- **end**: reads the project’s start time, parses it to seconds since epoch, computes duration to “now,” writes a CSV row, and removes the temp line.
- **status**: tabulates current `TEMP_FILE` entries with their start times.

To parse the recorded start time portably, it tries **macOS** `date -j -f` first and falls back to **GNU/Linux** `date -d`:

```bash
# macOS path (BSD date)
date -j -f "%Y-%m-%d %I:%M %p" "$start" "+%s" || # GNU path (Linux)
date -d "$start" "+%s"
```

This makes the script work out‑of‑the‑box on both systems.

---

## Compatibility & requirements

- **Shell**: Bash
- **Utilities**: `date`, `grep`, `cut`, `printf`, `mv`
- **OS**: macOS (uses BSD `date -j -f`) and Linux (uses GNU `date -d`)
- **Time zones**: Durations are computed from epoch timestamps, so DST and timezone shifts are handled correctly by the system `date` parser.

---

## Conventions & best practices

- **Project names**: Use simple names (`letters, numbers, -, _`). Special regex characters (like `|`, `^`, `?`, `*`, `[`) can confuse `grep` matching used internally.
- **Parallel tracking**: You can track multiple projects at once; the script prevents duplicate “start” for the *same* project.
- **Idempotency**: Running `end` without a prior `start` prints a clear warning and does not alter your CSV.

---

## Troubleshooting

- **“Project 'X' is already being tracked.”**  
  You already ran `start` for that project. Use `status` to confirm. If you want a fresh timer, run `end` first.

- **“No start time found for project 'X'.”**  
  There’s no active entry in `~/.time_track_temp`. Start again with `start --project X`.

- **“date: invalid date”** (Linux) or **“illegal option -j”** (BSD)  
  The script tries both parsers automatically. If you edited `DATE_FORMAT`, ensure it matches the recorded format in the temp file.

- **Permissions**  
  Ensure the command is executable: `chmod +x ~/bin/time` and that `~/bin` is on your `PATH`.

---

## Tips & extensions

- **Quick totals per project (last 30 days)** — since `total` is “`Hh Mm`”, you can parse and sum with `awk`:
  ```bash
  awk -F, 'NR>1 && $1=="bcd-1234" { 
    split($4,a," "); 
    h+=a[1]; m+=a[2]; 
  } END { h+=int(m/60); m%=60; printf "bcd-1234: %dh %dm
", h, m }' "$HOME/time.csv"
  ```

- **Change CSV delimiter** — if you prefer semicolons, update the echo that writes CSV rows and the header accordingly.

- **Git alias** — make a short alias:
  ```bash
  echo 'alias tt="$HOME/bin/time"' >> ~/.zshrc
  ```

---

## Uninstall

Remove the script and its data files (optional):
```bash
rm -f "$HOME/bin/time" "$HOME/time.csv" "$HOME/.time_track_temp"
```

---

## License

This README is unlicensed; use, modify, or copy freely. If you plan to share the script publicly, consider adding a license notice to the repository (e.g., MIT).
