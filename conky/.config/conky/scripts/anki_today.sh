#!/bin/bash

DB="$HOME/.local/share/Anki2/User 1/collection.anki2"

if [ ! -f "$DB" ]; then
  echo "0"
  exit 1
fi

SECONDS_IN_DAY=86400
TIME_THRESHOLD=$(($(date +%s) - $SECONDS_IN_DAY - 600))

# Execute the SQL query
sqlite3 "$DB" "
SELECT COUNT()
FROM revlog
WHERE id/1000 >= $TIME_THRESHOLD;
"
