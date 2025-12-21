#!/bin/bash

# Set thresholds
CPU_THRESHOLD=90
MEMORY_THRESHOLD=90

while true; do
	# Get CPU usage (average over 1 second)
	CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

	# Get Memory usage
	MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
	MEM_AVAILABLE=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
	MEM_USAGE=$(((MEM_TOTAL - MEM_AVAILABLE) * 100 / MEM_TOTAL))

	# Notify if CPU usage exceeds threshold
	if ((${CPU_USAGE%.*} > CPU_THRESHOLD)); then
		notify-send "High CPU Usage" "CPU usage is at ${CPU_USAGE}%!"
	fi

	# Notify if Memory usage exceeds threshold
	if ((MEM_USAGE > MEMORY_THRESHOLD)); then
		notify-send "High Memory Usage" "Memory usage is at ${MEM_USAGE}%!"
	fi

	# Wait before checking again (adjust as needed)
	sleep 30
done
