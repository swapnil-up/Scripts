#!/bin/bash
# rofi-todo-add.sh
# Adds a new todo item

TODO_FILE="$HOME/.local/share/todos/todo.txt"

# Create directory if it doesn't exist
mkdir -p "$(dirname "$TODO_FILE")"

# Get input from rofi
new_todo=$(rofi -dmenu -p "Add todo" -lines 0)

# If user entered something, add it with timestamp
if [ -n "$new_todo" ]; then
	timestamp=$(date "+%Y-%m-%d %H:%M")
	echo "[ ] $timestamp - $new_todo" >>"$TODO_FILE"
	notify-send "✓ Todo Added" "$new_todo"
fi
