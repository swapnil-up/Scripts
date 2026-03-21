#!/bin/bash
TMP_FILE="/tmp/espanso_calc_result"
rm -f "$TMP_FILE"

CALC_SCRIPT="$HOME/github/scripts/scripts/espanso/calc.py"

alacritty --title "Calculator" -e bash -c "
    result=\$(echo '' | \
        fzf \
            --prompt 'calc> ' \
            --print-query \
            --no-select-1 \
            --no-mouse \
            --preview 'python3 $CALC_SCRIPT {q}' \
            --preview-window 'up:3:wrap' \
            --bind 'enter:accept')
    query=\$(echo \"\$result\" | head -1)
    computed=\$(python3 $CALC_SCRIPT \"\$query\" 2>/dev/null)
    if [ -n \"\$query\" ] && [ -n \"\$computed\" ] && [[ \"\$computed\" != '?'* ]]; then
        echo \"\$query = \$computed\" > $TMP_FILE
    fi
"

if [ -f "$TMP_FILE" ]; then
    cat "$TMP_FILE"
    rm "$TMP_FILE"
fi