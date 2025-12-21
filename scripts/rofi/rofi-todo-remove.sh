#!/bin/bash
# rofi-todo-remove.sh
# Remove a todo item completely

TODO_FILE="$HOME/.local/share/todos/todo.txt"

if [ ! -f "$TODO_FILE" ]; then
  notify-send "No todos found" "Create some todos first!"
  exit 1
fi

# Show todos in rofi with line numbers
selected=$(cat -n "$TODO_FILE" | rofi -dmenu -p "Remove todo" -i)

if [ -n "$selected" ]; then
  # Extract line number
  line_num=$(echo "$selected" | awk '{print $1}')

  # Remove the line
  sed -i "${line_num}d" "$TODO_FILE"
  notify-send "🗑 Todo removed" "Deleted from list"
fi
