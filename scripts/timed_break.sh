#!/bin/bash

# Define the wait time (in seconds) before opening Calibre
WAIT_TIME=10 # Adjusted to 10 seconds

# Define the reading time (in seconds)
READ_TIME=10 # Adjusted to 10 seconds

while true; do
	# Block Calibre from opening until the wait period is over
	echo "Please wait for $WAIT_TIME seconds before you can open Calibre."

	# Wait for the defined amount of time before allowing Calibre to open
	for ((i = WAIT_TIME; i > 0; i--)); do
		# If Calibre is running during the wait time, kill it
		if pgrep -x "calibre" >/dev/null; then
			echo "Calibre is running during the wait time. Killing the process."
			pkill -x "calibre" # Kill Calibre if it's running
		fi
		sleep 1 # Check every second
	done

	# After the wait period, notify the user
	echo "You can now open Calibre. Press ENTER to continue."
	read -r # Wait for the user to press Enter

	# Open Calibre
	calibre &
	CALIBRE_PID=$! # Get the process ID of the launched Calibre instance

	# Let the user read for the specified reading time
	echo "You now have $READ_TIME seconds to read."
	sleep $READ_TIME # Allow reading for the specified amount of time

	# Close Calibre using the stored PID after the reading time is over
	echo "Closing Calibre after $READ_TIME seconds of reading."
	kill $CALIBRE_PID # Kill Calibre using its process ID

	# Notify user that the process is complete
	echo "Calibre has been closed after $READ_TIME seconds."
done
