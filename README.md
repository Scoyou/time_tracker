# Time Tracker — CLI Project Time Logger

A tiny Bash tool for timing work on projects from your terminal. Start a timer, stop it, and your sessions are saved to a CSV file you can open in any spreadsheet app.

- Commands: `start`, `end`, `status`, `help`
- Default CSV: `$HOME/time.csv`
- Temp state: `$HOME/.time_track_temp`
- Works on macOS and Linux

---

## Install

### Homebrew
Install the published formula from the public tap:

```bash
brew install Scoyou/tools/time-tracker
```

Install the latest development version:

```bash
brew install --HEAD Scoyou/tools/time-tracker
```

Upgrade later:
```bash
brew upgrade Scoyou/tools/time-tracker
```

Uninstall:
```bash
brew uninstall Scoyou/tools/time-tracker
```

> The installed command is `tt`.

### Manual (no Homebrew)
Download the script and place it on your PATH:
```bash
mkdir -p "$HOME/bin"
curl -L -o "$HOME/bin/tt" https://raw.githubusercontent.com/Scoyou/time_tracker/main/time_track.sh
chmod +x "$HOME/bin/tt"

# Add to PATH if needed
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"   # or ~/.bashrc
```

---

## Quick start

```bash
tt start --project bcd-1234
tt status
tt end --project bcd-1234
tt --help
```

Example output:
```
[✓] Started tracking for 'bcd-1234' at 2025-09-05 10:42 AM
[✓] Ended tracking for 'bcd-1234' at 2025-09-05 11:17 AM
[⏱] Duration: 0h 35m
```

---

## Usage

```
Time Tracker - CLI Project Time Logger

Usage:
  tt start --project <project-name>       Start tracking time for a project
  tt end --project <project-name>         End tracking and log time to CSV
  tt status                               Show all currently tracked projects
  tt --help | help                        Show this help message

Examples:
  tt start --project bcd-1234
  tt end --project bcd-1234
  tt status
```

---

## Output files

- **CSV log**: `~/time.csv` (auto-created with header on first write)
  ```csv
  project,start,end,total
  bcd-1234,2025-09-05 10:42 AM,2025-09-05 11:17 AM,0h 35m
  ```

- **Temp state**: `~/.time_track_temp`  
  Each active timer is stored as `project|start_time` on its own line.

Tip: Pretty-print the CSV in the terminal:
```bash
column -s, -t < "$HOME/time.csv" | less -S
```

---

## Configuration

Edit the variables at the top of the script to change file locations or time format:

```bash
CSV_FILE="$HOME/time.csv"           # where sessions are logged
TEMP_FILE="$HOME/.time_track_temp"  # stores active timers
DATE_FORMAT="+%Y-%m-%d %I:%M %p"    # e.g., 2025-09-05 03:14 PM
```

Suggestions:
- 24‑hour time: `DATE_FORMAT="+%Y-%m-%d %H:%M"`
- Save to cloud storage: `CSV_FILE="$HOME/Dropbox/time.csv"`

---

## How it works

- `start` adds a line `project|<formatted time>` to the temp file. Multiple projects can run simultaneously; starting the same project twice is blocked.
- `end` reads the start time, converts to epoch seconds, computes the duration to “now,” writes a CSV row, and removes the temp entry.
- `status` prints a table of active timers.

Time parsing supports both macOS and Linux:
```bash
# macOS (BSD date)
date -j -f "%Y-%m-%d %I:%M %p" "$start" "+%s" || # Linux (GNU date)
date -d "$start" "+%s"
```

---

## Troubleshooting

- **“Project 'X' is already being tracked.”**  
  A timer for that project is already running. See `tt status` or run `tt end --project X`.

- **“No start time found for project 'X'.”**  
  There’s no active entry for that project. Start a new timer with `tt start --project X`.

- **Date parse errors**  
  If you changed `DATE_FORMAT`, make sure it matches the format stored in the temp file.

- **Command not found**  
  If you installed manually, ensure `tt` is executable and on your PATH.

---

## Compatibility

- **OS**: macOS and Linux
- **Shell**: Bash
- **Dependencies**: Standard Unix tools (`date`, `grep`, `cut`, `printf`, `mv`)

---

## Privacy

All data stays on your machine. The tool writes a single CSV file (`~/time.csv`) and a small temp file (`~/.time_track_temp`).

---

## License

MIT — see the `LICENSE` file for details.
