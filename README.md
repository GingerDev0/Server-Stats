# Server Stats Monitor

A Bash script that displays system statistics in real-time with color and a smooth auto-update display. The script requires an update interval to be specified using the `-s` flag.

## Features

- **Real-Time Monitoring:** Displays uptime, CPU model, CPU cores, load average, memory usage, swap usage, and disk usage.
- **Color-Coded Output:** Uses ANSI color codes for improved readability.
- **Smooth Display:** Uses the terminal's alternate screen buffer and cursor positioning to reduce flicker.
- **Customizable Update Interval:** Specify the auto-update interval with the `-s` flag.
- **Help & Usage Message:** Easily accessible help message using `-h`.

## Requirements

- Bash shell (version 4.x or later recommended)
- Standard Unix utilities: `awk`, `grep`, `df`, `free`, `tput`

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/SB1988-DEV/Server-Stats.git
   cd Server-Stats

2. **Make the script executable:**

   ```bash
   chmod +x server-stats.sh

## Usage

   ```bash
   ./server-stats.sh -s 5
