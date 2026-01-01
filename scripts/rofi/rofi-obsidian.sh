#!/bin/bash
# Flexible Obsidian notes handler
# ~/scripts/scripts/rofi-obsidian-flex.sh

declare -A profiles

# trigger => "folder|template_file|single_file_flag"
profiles[n]="$HOME/obsidian-vault|$HOME/scripts/scripts/template/obsidian.md|"            # new notes in vault root
profiles[til]="$HOME/github/coding-problems/learning-notes/TIL|$HOME/scripts/scripts/template/til.md|"  # quick snippets
profiles[why]="$HOME/notes/why|$HOME/.config/obsidian/templates/why.md|$HOME/scripts/scripts/template/why.md"  # why notes
profiles[hmm]="$HOME/scratchpad/hmm.md||1"    # append-only scratchpad

trigger="$1"
inline="$2"
[ -z "$trigger" ] && exit 0
config="${profiles[$trigger]}"
[ -z "$config" ] && exit 0

folder="${config%%|*}"
rest="${config#*|}"
template="${rest%%|*}"
single_file="${rest##*|}"

# Helper: launch in nvim
launch() {
    i3-msg "exec alacritty -e nvim '$1'"
}

render_template() {
    local title="$1"
    local template_file="$2"

    sed \
      -e "s/{{title}}/$title/g" \
      -e "s/{{date}}/$(date '+%Y-%m-%d %H:%M')/g" \
      "$template_file"
}

append_hmm() {
    local file="$1"

    mkdir -p "$(dirname "$file")"
    [ ! -f "$file" ] && touch "$file"

    input=$(rofi -dmenu -p "hmm…" -lines 0)
    [ -z "$input" ] && exit 0

    {
        echo ""
        echo "## $(date '+%Y-%m-%d %H:%M')"
        echo "$input"
    } >>"$file"

    launch "$file"
}


# Append-only single file
if [ "$single_file" == "1" ]; then
    append_hmm "$folder"
    exit 0
fi

# Build rofi menu: list all .md files (without extension)
mkdir -p "$folder"
files=$(find "$folder" -maxdepth 1 -type f -name "*.md" \
    -printf "%T@|%f\n" \
  | sort -nr \
  | cut -d'|' -f2 \
  | sed 's/\.md$//')

menu="$files"

# If inline argument provided, skip rofi and use it
inline=$(echo "$inline" | xargs)
if [ -n "$inline" ]; then
    selection="$inline"
else
    selection=$(echo -e "$files" | rofi -dmenu -i -p "Obsidian" -matching fuzzy -format "s")
    [ -z "$selection" ] && exit 0
fi

# Determine file path
file_path="$folder/$selection.md"

# Create file if it doesn't exist
if [ ! -f "$file_path" ]; then
    if [ -n "$template" ] && [ -f "$template" ]; then
        render_template "$selection" "$template" >"$file_path"
    else
        echo -e "# $selection\n\nCreated: $(date '+%Y-%m-%d %H:%M')\n" >"$file_path"
    fi
fi

launch "$file_path"
