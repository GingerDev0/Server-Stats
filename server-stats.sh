#!/bin/bash
# show-stats.sh
# An executable script to display system statistics with color and auto-update interval.
# Requires the -s flag to specify the update interval in seconds.
#
# Usage:
#   ./show-stats.sh -s <seconds>
#   ./show-stats.sh -h    # Display help

# Function to display help/usage
usage() {
    cat << EOF
Usage: $0 -s <seconds>

Options:
  -s <seconds>    Set the update interval in seconds.
  -h              Show this help message.

Example:
  $0 -s 5
EOF
}

# Check if no arguments are given, then show error and help.
if [ "$#" -eq 0 ]; then
    echo "Error: Update interval (-s) is required."
    usage
    exit 1
fi

# Default sleep_interval (unset by default)
sleep_interval=""

# Parse command-line arguments
while getopts ":s:h" opt; do
  case $opt in
    s)
      sleep_interval="$OPTARG"
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      exit 1
      ;;
  esac
done

# Check if sleep_interval is still empty (i.e. -s was not provided)
if [ -z "$sleep_interval" ]; then
    echo "Error: The -s option is required to set the update interval in seconds."
    usage
    exit 1
fi

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function: Convert uptime (in seconds) to a human-readable string.
get_uptime() {
    local total_seconds=$1
    local days=$(( total_seconds / 86400 ))
    local hours=$(( (total_seconds % 86400) / 3600 ))
    local minutes=$(( (total_seconds % 3600) / 60 ))
    local seconds=$(( total_seconds % 60 ))
    local uptime_str=""

    (( days > 0 )) && uptime_str+="${days} Days, "
    (( hours > 0 )) && uptime_str+="${hours} Hours, "
    (( minutes > 0 )) && uptime_str+="${minutes} Minutes"
    (( seconds > 0 )) && {
        if (( minutes > 0 )); then
            uptime_str+=" and ${seconds} Seconds"
        else
            uptime_str+="${seconds} Seconds"
        fi
    }
    echo "$uptime_str"
}

# Function: Convert bytes to a human-readable GB value with two decimals.
bytes_to_gb() {
    awk -v bytes="$1" 'BEGIN { printf "%.2f GB", bytes/(1024*1024*1024) }'
}

# Setup: Switch to alternate screen and hide cursor for smoother updates.
tput smcup   # enter alternate screen
tput civis   # hide cursor

# Ensure that on exit we restore the original screen and cursor
cleanup() {
  tput rmcup   # return to normal screen
  tput cnorm   # show cursor
  exit
}
trap cleanup SIGINT SIGTERM

# Auto-update loop
while true; do
    # Move cursor to top left (without clearing the screen)
    tput cup 0 0

    # -------- Gather Stats --------

    # Uptime (from /proc/uptime)
    uptime_seconds=$(awk '{print int($1)}' /proc/uptime)
    uptime_readable=$(get_uptime "$uptime_seconds")

    # CPU Model (first occurrence)
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2- | sed 's/^ //')

    # CPU Cores (using nproc)
    cpu_cores=$(nproc)

    # Load Average (first three values from /proc/loadavg)
    load_avg=$(awk '{printf "%.8f, %.8f, %.8f", $1, $2, $3}' /proc/loadavg)

    # Memory info (using free -b for bytes)
    read mem_total mem_used mem_free mem_shared mem_buff mem_avail < <(free -b | awk '/^Mem:/ {print $2,$3,$4,$5,$6,$7}')
    mem_total_h=$(bytes_to_gb "$mem_total")
    mem_free_h=$(bytes_to_gb "$mem_free")
    mem_avail_h=$(bytes_to_gb "$mem_avail")

    # Swap info
    read swap_total swap_used swap_free < <(free -b | awk '/^Swap:/ {print $2,$3,$4}')
    swap_total_h=$(bytes_to_gb "$swap_total")
    swap_used_h=$( [ "$swap_used" -eq 0 ] && echo "0 B" || bytes_to_gb "$swap_used" )
    swap_free_h=$(bytes_to_gb "$swap_free")

    # Disk usage for root ("/")
    read disk_total disk_used disk_free < <(df -B1 / | awk 'NR==2 {print $2,$3,$4}')
    disk_total_h=$(bytes_to_gb "$disk_total")
    disk_used_h=$(bytes_to_gb "$disk_used")
    disk_free_h=$(bytes_to_gb "$disk_free")

    # -------- Display Output --------

    # Print ASCII Banner in blue
    echo -e "${BLUE}"
    cat << 'EOF'
 ██████╗ ██╗███╗   ██╗ ██████╗ ███████╗██████╗ ██████╗ ███████╗██╗   ██╗
██╔════╝ ██║████╗  ██║██╔════╝ ██╔════╝██╔══██╗██╔══██╗██╔════╝██║   ██║
██║  ███╗██║██╔██╗ ██║██║  ███╗█████╗  ██████╔╝██║  ██║█████╗  ██║   ██║
██║   ██║██║██║╚██╗██║██║   ██║██╔══╝  ██╔══██╗██║  ██║██╔══╝  ╚██╗ ██╔╝
╚██████╔╝██║██║ ╚████║╚██████╔╝███████╗██║  ██║██████╔╝███████╗ ╚████╔╝ 
 ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝  ╚═══╝  
EOF
    echo -e "${NC}"

    # Print header with current time in green
    current_time=$(date +%T)
    echo -e "${GREEN}[Server Stats - ${current_time}]${NC}"
    echo ""

    # Table border and formatting widths
    border="+--------------------------+----------------------------------------------+"
    printf "%s\n" "$border"

    # Print each stat with the label in yellow
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "Uptime" "$uptime_readable"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "CPU Model" "$cpu_model"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "CPU Cores" "$cpu_cores"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "Load Average" "$load_avg"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "Memory Total" "$mem_total_h"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "Memory Free" "$mem_free_h"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "Memory Avail" "$mem_avail_h"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "Swap Total" "$swap_total_h"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "Swap Free" "$swap_free_h"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "Swap Used" "$swap_used_h"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "Disk Total" "$disk_total_h"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "Disk Free" "$disk_free_h"
    printf "| ${YELLOW}%-24s${NC} | %-44s |\n" "Disk Used" "$disk_used_h"
    printf "%s\n" "$border"

    # Wait before updating again using the provided sleep interval
    sleep "$sleep_interval"
done
