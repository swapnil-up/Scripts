#!/bin/bash
# rofi-obsidian.sh
# Search and open Obsidian notes

VAULT_PATH="$HOME/obsidian-vault"

# Special commands at the top
special_commands="🆕 new - Create new note in vault root
📅 daily - Open today's daily note
---"

# Find all markdown files, sorted by modification time (newest first)
notes=$(find "$VAULT_PATH" -type f -name "*.md" -printf "%T@ %p\n" 2>/dev/null | \
    sort -rn | \
    cut -d' ' -f2- | \
    sed "s|$VAULT_PATH/||" | \
    sed 's|\.md$||')

# Combine special commands with notes
menu=$(cat <<EOF
$special_commands
$notes
EOF
)

# Show in rofi
selection=$(echo "$menu" | rofi -dmenu -i -p "Obsidian" -matching fuzzy -format "s")

[ -z "$selection" ] && exit 0

# Handle special commands
if [[ "$selection" == *"new"* ]] || [[ "$selection" == "🆕 new"* ]]; then
    # Get note name
    note_name=$(rofi -dmenu -p "Note name" -lines 0)
    
    if [ -n "$note_name" ]; then
        # Create the note with some content
        note_path="$VAULT_PATH/${note_name}.md"
        
        cat > "$note_path" <<EOF
# $note_name

Created: $(date '+%Y-%m-%d %H:%M')

EOF
        
        # Open in nvim inside a terminal
        i3-msg "exec alacritty -e nvim '$note_path'"
        
        notify-send "📝 Note created" "$note_name"
    fi
    
elif [[ "$selection" == *"daily"* ]] || [[ "$selection" == "📅 daily"* ]]; then
    # Open or create daily note
    daily_note="$(date '+%Y-%m-%d').md"
    daily_path="$VAULT_PATH/$daily_note"
    
    if [ ! -f "$daily_path" ]; then
        # Create daily note with template
        cat > "$daily_path" <<EOF
# $(date '+%A, %B %d, %Y')

## Today's Focus


## Notes


## Tasks
- [ ] 

EOF
    fi
    
    # Open in nvim inside a terminal
    i3-msg "exec alacritty -e nvim '$daily_path'"
    
elif [[ "$selection" == "---" ]] || [[ "$selection" == "" ]]; then
    exit 0
    
else
    # Open selected note in nvim inside a terminal
    note_path="$VAULT_PATH/${selection}.md"
    
    if [ -f "$note_path" ]; then
        i3-msg "exec alacritty -e nvim '$note_path'"
    else
        notify-send "Error" "Note not found: $selection"
    fi
fi