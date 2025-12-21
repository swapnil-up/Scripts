#!/bin/bash
# rofi-todo-toggle.sh
# Toggle todo completion (cross out or uncheck)

TODO_FILE="$HOME/.local/share/todos/todo.txt"

if [ ! -f "$TODO_FILE" ]; then
	notify-send "No todos found" "Create some todos first!"
	exit 1
fi

# Show todos in rofi with line numbers
selected=$(cat -n "$TODO_FILE" | rofi -dmenu -p "Toggle todo" -i)

if [ -n "$selected" ]; then
	# Extract line number
	line_num=$(echo "$selected" | awk '{print $1}')

	# Get the actual line content
	line=$(sed -n "${line_num}p" "$TODO_FILE")

	# Toggle between [ ] and [x]
	if echo "$line" | grep -q "^\[ \]"; then
		# Mark as done
		new_line=$(echo "$line" | sed 's/^\[ \]/[x]/')
		sed -i "${line_num}s|.*|$new_line|" "$TODO_FILE"
		notify-send "✓ Todo completed" "Marked as done"
	elif echo "$line" | grep -q "^\[x\]"; then
		# Mark as undone
		new_line=$(echo "$line" | sed 's/^\[x\]/[ ]/')
		sed -i "${line_num}s|.*|$new_line|" "$TODO_FILE"
		notify-send "↻ Todo reopened" "Marked as not done"
	fi
fi
