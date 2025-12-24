#!/bin/bash
# rofi-projects.sh — daily cached project launcher

PROJECT_DIRS=(
	"$HOME/github"
	"$HOME/github/work"
	"$HOME/github/side-hustle"
)

CACHE_DIR="$HOME/.cache"
TODAY=$(date '+%Y-%m-%d')
CACHE_FILE="$CACHE_DIR/rofi-projects-$TODAY.txt"

mkdir -p "$CACHE_DIR"

get_latest_mtime() {
    timeout 5s find "$1" \
      -type d \( \
        -name .git \
        -o -name node_modules \
        -o -name vendor \
        -o -name dist \
        -o -name build \
        -o -name .cache \
        -o -name .idea \
        -o -name .vscode \
      \) -prune \
      -o -type f -printf "%T@\n" 2>/dev/null \
    | sort -nr \
    | head -n 1
}

build_cache() {
    >"$CACHE_FILE"

    for dir in "${PROJECT_DIRS[@]}"; do
        [ ! -d "$dir" ] && continue

        while IFS= read -r project; do
            project_name=$(basename "$project")
            parent=$(basename "$(dirname "$project")")

            mtime=$(get_latest_mtime "$project")
            [ -z "$mtime" ] && mtime=0

            if [[ "$parent" != "github" ]]; then
                label="[$parent] $project_name"
            else
                label="$project_name"
            fi

            echo "$mtime|$label|$project" >>"$CACHE_FILE"

        done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
    done

    sort -nr "$CACHE_FILE" -o "$CACHE_FILE"
}

# Build cache once per day
[ ! -f "$CACHE_FILE" ] && build_cache

selection=$(cut -d'|' -f2- "$CACHE_FILE" \
	| rofi -dmenu -i -p "Open Project" -matching fuzzy -format "s")

[ -z "$selection" ] && exit 0

project_path="${selection#*|}"
code "$project_path"
