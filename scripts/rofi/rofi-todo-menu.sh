#!/bin/bash
# rofi-todo-menu.sh
# Main menu for todo operations

choice=$(echo -e "Add Todo\nToggle Todo\nRemove Todo\nView All" | rofi -dmenu -p "Todo Manager")

case "$choice" in
"Add Todo")
	~/rofi/rofi-todo-add.sh
	;;
"Toggle Todo")
	~/rofi/rofi-todo-toggle.sh
	;;
"Remove Todo")
	~/rofi/rofi-todo-remove.sh
	;;
"View All")
	# Show all todos in a notification or terminal
	todos=$(cat "$HOME/.local/share/todos/todo.txt")
	notify-send "All Todos" "$todos"
	;;
esac
