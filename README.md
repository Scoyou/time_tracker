# Time Tracker — CLI Project Time Logger

A tiny Bash script to track time you spend on projects from the command line. Start a timer, stop it, and sessions are appended to a CSV you can open in any spreadsheet app.

- Commands: `start`, `end`, `status`, `help`
- Data file: `$HOME/time.csv`
- Temp state: `$HOME/.time_track_temp`
- Cross-platform: macOS (BSD `date`) + Linux (GNU `date`)

Repository: **https://github.com/Scoyou/time_tracker**

---

## Installation

### Option A — Homebrew (recommended)

This project ships a Homebrew formula in your personal tap. The script in the repo is `time_track.sh` and is installed as the command `tt` to avoid clashing with the system `time` utility.

Install from your tap:
```bash
brew install Scoyou/tap/time-tracker
```

Install the latest commit from `main` (no tag required):
```bash
brew install --HEAD Scoyou/tap/time-tracker
```

Upgrade to a newer version (after you publish a new tag and bump the formula):
```bash
brew upgrade Scoyou/tap/time-tracker
```

Uninstall:
```bash
brew uninstall Scoyou/tap/time-tracker
```

> On Apple Silicon, Homebrew is under `/opt/homebrew`. The commands above work the same on Intel or Apple Silicon.

### Option B — Manual install (no Homebrew)

Copy the script somewhere on your `PATH` and name it `tt`:
```bash
mkdir -p "$HOME/bin"
cp time_track.sh "$HOME/bin/tt"
chmod +x "$HOME/bin/tt"

# Add to PATH if needed (choose your shell)
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"   # bash
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"    # zsh
```

---

## Quick start

```bash
tt start --project bcd-1234
tt status
tt end --project bcd-1234
tt --help
```

Sample output:
```
[✓] Started tracking for 'bcd-1234' at 2025-09-05 10:42 AM
[✓] Ended tracking for 'bcd-1234' at 2025-09-05 11:17 AM
[⏱] Duration: 0h 35m
```

---

## Usage reference

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
  Stores active sessions in `project|start_time` format (one per active project).

> Tip: Pretty-print the CSV:
> ```bash
> column -s, -t < "$HOME/time.csv" | less -S
> ```

---

## Configuration

Edit the constants at the top of the script:
```bash
CSV_FILE="$HOME/time.csv"           # where sessions are logged
TEMP_FILE="$HOME/.time_track_temp"  # stores active timers
DATE_FORMAT="+%Y-%m-%d %I:%M %p"    # e.g., 2025-09-05 03:14 PM
```
- Prefer 24-hour time: `DATE_FORMAT="+%Y-%m-%d %H:%M"`
- Log to cloud storage: `CSV_FILE="$HOME/Dropbox/time.csv"`

---

## How it works

- **start** → appends `project|<formatted time>` to the temp file (multiple projects may run concurrently; duplicates for the *same* project are blocked).
- **end** → reads start time, converts to epoch, computes duration to “now,” writes a CSV row, removes the temp entry.
- **status** → prints a table of active timers.

Time parsing tries **macOS** (BSD) first, then **GNU** (Linux):
```bash
# macOS path (BSD date)
date -j -f "%Y-%m-%d %I:%M %p" "$start" "+%s" || # GNU path (Linux)
date -d "$start" "+%s"
```

---

## Troubleshooting

- **Project already tracked**: Use `status` to confirm; stop with `end` before starting again.
- **No start time found**: There is no active entry in `~/.time_track_temp`.
- **Date parse errors**: Ensure `DATE_FORMAT` matches the stored start time format if you have modified it.
- **Permissions**: `chmod +x` and confirm the binary is on your PATH.
- **Name clash**: The command `time` conflicts with the system tool. This project uses `tt`.

## License

MIT License

Copyright (c) 2025 Scoyou

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

