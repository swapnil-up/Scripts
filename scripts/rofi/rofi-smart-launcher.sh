#!/bin/bash
# rofi-smart-launcher.sh

TODO_FILE="$HOME/.local/share/todos/todo.txt"

# Get all desktop apps from multiple sources
apps=$(find /usr/share/applications \
	~/.local/share/applications \
	/var/lib/snapd/desktop/applications \
	/var/lib/flatpak/exports/share/applications \
	~/.local/share/flatpak/exports/share/applications \
	-name "*.desktop" 2>/dev/null |
	xargs awk -F= '
        /^\[Desktop Entry\]/ { 
            in_entry=1
            name=""
            type=""
        }
        in_entry && /^Name=/ && name=="" { name=$2 }
        in_entry && /^Type=/ { type=$2 }
        in_entry && name && type=="Application" {
            print name
            in_entry=0
        }
        /^\[/ && !/^\[Desktop Entry\]/ { in_entry=0 }
    ' | sort -u)

# Build menu with custom commands first
menu=$(
	cat <<EOF
📝 tt - Toggle Todo
➕ t,text - Add Todo
🗑️ tr - Remove Todo
🌐 w,query - Web Search (w,gh,query for GitHub, w,yt,query for YouTube, etc)
💻 p,name - Open Project
📓 n,name - Obsidian Notes (n,daily for today)
---
$apps
EOF
)

# Get raw input
input=$(echo "$apps" | rofi -dmenu -i -p "Launch" -matching fuzzy -allow-custom)
[ -z "$input" ] && exit 0

# Command mode detection
if [[ "$input" == ,* ]]; then
	MODE="command"
	query="${input#,}" # strip leading comma
else
	MODE="app"
	query="$input"
fi

if [[ "$MODE" == "app" ]]; then
	echo "$apps" | grep -Fxq "$input" || exit 0
	selection="$input"

	clean_name=$(echo "$selection" | sed 's/^[^a-zA-Z0-9]*[[:space:]]*//' | sed 's/[[:space:]]*-.*//')

	desktop_file=$(find /usr/share/applications \
		~/.local/share/applications \
		/var/lib/snapd/desktop/applications \
		/var/lib/flatpak/exports/share/applications \
		~/.local/share/flatpak/exports/share/applications \
		-name "*.desktop" 2>/dev/null |
		xargs grep -l "^Name=$clean_name$" 2>/dev/null | head -1)

	if [ -n "$desktop_file" ]; then
		gtk-launch "$(basename "$desktop_file" .desktop)" 2>/dev/null
	elif command -v "$clean_name" &>/dev/null; then
		nohup "$clean_name" >/dev/null 2>&1 &
	else
		notify-send "Error" "Cannot launch: $clean_name"
	fi

	exit 0
fi

command_help=$(
	cat <<EOF
tt            toggle todo
t <text>      add todo
tr            remove todo
p <name>      open project
n <name>      obsidian note (n daily)
w,<site> <q>  web search (gh, yt, lb, wiki)
EOF
)

case "$query" in
tt | tr | p | n | n\ daily | t\ * | w,*\ *)
	# Command is complete enough → skip help UI
	;;
*)
	# Show help only when command is incomplete
	rofi -dmenu -p ",command" -matching normal -filter "$query" <<<"$command_help" >/dev/null
	;;
esac

# Split on first space
cmd=$(echo "$query" | awk '{print $1}')
rest=$(echo "$query" | cut -d' ' -f2-)

# Split comma subcommands (for w,lb etc)
IFS=',' read -r base sub <<<"$cmd"

# Handle commands
case "$base" in
tt)
	~/scripts/scripts/rofi/rofi-todo-toggle.sh
	;;

t)
	[ -n "$rest" ] && echo "[ ] $(date '+%Y-%m-%d %H:%M') - $rest" >>"$HOME/.local/share/todos/todo.txt"
	notify-send "✓ Todo added" "$rest"
	;;

tr)
	~/scripts/scripts/rofi/rofi-todo-remove.sh
	;;

p)
	if [ -z "$rest" ]; then
		~/scripts/scripts/rofi/rofi-projects.sh
	else
		for dir in "$HOME/github" "$HOME/github/work" "$HOME/github/side-hustle"; do
			[ -d "$dir/$rest" ] && code "$dir/$rest" && exit 0
		done
		~/scripts/scripts/rofi/rofi-projects.sh
	fi
	;;

n)
	if [ "$rest" = "daily" ]; then
		note="$HOME/obsidian-vault/$(date '+%Y-%m-%d').md"
		[ ! -f "$note" ] && printf "# %s\n\n" "$(date)" >"$note"
		i3-msg "exec alacritty -e nvim '$note'"
	else
		~/scripts/scripts/rofi/rofi-obsidian.sh
	fi
	;;

w)
	q="${rest// /+}"
	case "$sub" in
	gh) firefox-dev "https://github.com/search?q=$q" ;;
	yt) firefox-dev "https://youtube.com/results?search_query=$q" ;;
	lb) firefox-dev "https://libgen.is/search.php?req=$q" ;;
	wiki) firefox-dev "https://en.wikipedia.org/w/index.php?search=$q" ;;
	*) firefox-dev "https://google.com/search?q=$q" ;;
	esac
	;;

*)
	notify-send "Unknown command" ",$query"
	;;
esac
