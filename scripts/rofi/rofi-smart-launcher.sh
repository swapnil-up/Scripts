#!/bin/bash
# rofi-smart-launcher.sh

TODO_FILE="$HOME/.local/share/todos/todo.txt"

# Get all desktop apps
apps=$(find /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null |
  xargs grep -h "^Name=" |
  sed 's/^Name=//' |
    sort -u)

# Build menu with custom commands first
menu=$(
  cat <<EOF
📝 tt - Toggle Todo
➕ t: - Add Todo (e.g. t:buy milk)
🗑️ tr - Remove Todo
🌐 w: - Web Search (e.g. w:rust tutorials)
💻 p: - Open Project (e.g. p:scripts)
---
$apps
EOF
)

# Show apps + custom commands
selection=$(echo "$menu" | rofi -dmenu -i -p "Launch" -matching fuzzy)

[ -z "$selection" ] && exit 0

# Handle special commands
if [[ "$selection" == *"tt"* ]] || [[ "$selection" == "📝 tt - Toggle Todo" ]]; then
  ~/scripts/scripts/rofi/rofi-todo-toggle.sh
    
elif [[ "$selection" == *"tr"* ]] || [[ "$selection" == "🗑️ tr - Remove Todo" ]]; then
  ~/scripts/scripts/rofi/rofi-todo-remove.sh
    
elif [[ "$selection" == t:* ]] || [[ "$selection" == *"t: - Add Todo"* ]]; then
    # Extract the actual todo text
    todo="${selection#*t:}"
    todo="${todo#*Add Todo*}"
    todo=$(echo "$todo" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -n "$todo" ]; then
    echo "[ ] $(date '+%Y-%m-%d %H:%M') - $todo" >>"$TODO_FILE"
        notify-send "✓ Todo added" "$todo"
    fi
    
elif [[ "$selection" == w:* ]] || [[ "$selection" == *"w: - Web Search"* ]]; then
    # Extract the actual search query
    query="${selection#*w:}"
    query="${query#*Web Search*}"
    query=$(echo "$query" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -n "$query" ]; then
        firefox-developer-edition "https://www.google.com/search?q=${query// /+}" &
    fi

elif [[ "$selection" == p:* ]] || [[ "$selection" == *"p: - Open Project"* ]]; then
    # Open project picker or search directly
    project_query="${selection#*p:}"
    project_query="${project_query#*Open Project*}"
    project_query=$(echo "$project_query" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -n "$project_query" ]; then
        # Search for project matching the query
        PROJECT_DIRS=("$HOME/github" "$HOME/github/work" "$HOME/github/side-hustle")
        for dir in "${PROJECT_DIRS[@]}"; do
            if [ -d "$dir/$project_query" ]; then
                code "$dir/$project_query"
                exit 0
            fi
        done
        # Not found directly, open the full picker
        ~/scripts/scripts/rofi/rofi-projects.sh
    else
        # No query, open picker
        ~/scripts/scripts/rofi/rofi-projects.sh
    fi
    
elif [[ "$selection" == "---" ]] || [[ "$selection" == "" ]]; then
    # Separator or empty, do nothing
    exit 0
    
else
    # Launch app by name - strip any emoji/description first
    clean_selection=$(echo "$selection" | sed 's/^[[:space:]]*[^a-zA-Z0-9]*[[:space:]]*//')
    
  desktop_file=$(find /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null |
        xargs grep -l "^Name=$clean_selection$" | head -1)
    
    if [ -n "$desktop_file" ]; then
        gtk-launch "$(basename "$desktop_file" .desktop)"
    else
        # Try running as command - but validate it exists first
    if command -v "$clean_selection" &>/dev/null; then
            nohup "$clean_selection" >/dev/null 2>&1 &
        else
            notify-send "Error" "Cannot launch: $clean_selection"
        fi
    fi
fi
