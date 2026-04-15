#!/bin/bash

INPUT=$(xclip -o -selection clipboard 2>/dev/null)
if [ -z "$INPUT" ]; then
	exit 0
fi

CASE_SCRIPT="$HOME/github/scripts/scripts/espanso/case.py"
TMP_FILE="/tmp/espanso_case_result"
rm -f "$TMP_FILE"

alacritty --title "Case Picker" -e bash -c "
    selection=\$(python3 $CASE_SCRIPT --list '$INPUT' | \
        fzf \
            --prompt 'case> ' \
            --preview 'python3 $CASE_SCRIPT --format {1} \"$INPUT\"' \
            --preview-window 'up:3:wrap' \
            --delimiter ':')
    if [ -n \"\$selection\" ]; then
        format=\$(echo \"\$selection\" | cut -d: -f1 | xargs)
        python3 $CASE_SCRIPT --format \"\$format\" '$INPUT' > $TMP_FILE
    fi
"

if [ -f "$TMP_FILE" ]; then
	cat "$TMP_FILE"
	rm "$TMP_FILE"
fi
