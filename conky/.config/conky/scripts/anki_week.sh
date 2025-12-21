#!/bin/bash

DB="$HOME/.local/share/Anki2/User 1/collection.anki2"

if [ ! -f "$DB" ]; then
	echo "0"
	exit 1
fi

# 7 days ago in seconds
WEEK_AGO=$(($(date +%s) - 604800))

sqlite3 "$DB" "
SELECT COUNT()
FROM revlog
WHERE id/1000 >= $WEEK_AGO;
"
