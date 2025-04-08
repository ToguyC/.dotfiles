#!/bin/bash

# Function to get CPU times
get_cpu_times() {
    # Read the first line of /proc/stat which contains the CPU times
    awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8}' /proc/stat
}

# Function to calculate CPU usage
calculate_cpu_usage() {
    local -n prev=$1
    local -n curr=$2

    # Calculate the differences
    local prev_idle=$((prev[3] + prev[4]))
    local curr_idle=$((curr[3] + curr[4]))
    local prev_total=0
    local curr_total=0

    for value in "${prev[@]}"; do
        prev_total=$((prev_total + value))
    done

    for value in "${curr[@]}"; do
        curr_total=$((curr_total + value))
    done

    local total_diff=$((curr_total - prev_total))
    local idle_diff=$((curr_idle - prev_idle))
    local usage=$(( (100 * (total_diff - idle_diff)) / total_diff ))

    echo $usage
}

color="#ffffff"
bgcolor="#3f51b5"

if (( $(echo "$CPU_USAGE > 75" | bc -l) )); then
    color="#000000"
    bgcolor="#ff0000"
fi

# Get the initial CPU times
prev_times=($(get_cpu_times))
sleep 1
# Get the CPU times after a short delay
curr_times=($(get_cpu_times))

cpu_usage=$(calculate_cpu_usage prev_times curr_times)

echo "<span color='$color' bgcolor='$bgcolor'> CPU $cpu_usage% </span>"

exit 0
