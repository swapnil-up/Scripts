#!/bin/bash

# A temporary file to store our selection
TMP_FILE="/tmp/espanso_snip_selection"
rm -f "$TMP_FILE"

# Launch your terminal in a floating window
# -e runs the command inside it
alacritty --title "Snippet Picker" -e bash -c "
    selection=\$(rg --line-number --column --no-heading --color=always --smart-case -g '!snip-picker.sh' . ~/github/scripts/scripts/snippets | \
        fzf --ansi \
            --delimiter : \
            --preview 'batcat --color=always --style=numbers --highlight-line {2} {1}')

    if [ -n \"\$selection\" ]; then
        # Extract the filename from the 'file:line:col:text' format
        echo \"\$selection\" | cut -d: -f1 > $TMP_FILE
    fi
"

# Wait a split second for the file to be written, then return its content
if [ -f "$TMP_FILE" ]; then
	cat "$(cat $TMP_FILE)"
	rm "$TMP_FILE"
fi
