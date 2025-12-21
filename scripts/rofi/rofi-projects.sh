#!/bin/bash
# rofi-projects.sh
# Search coding projects and open in VS Code

PROJECT_DIRS=(
  "$HOME/github"
  "$HOME/github/work"
  "$HOME/github/side-hustle"
)

# Find all directories (projects) in the project folders
projects=""
for dir in "${PROJECT_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    # List directories, showing relative path for context
    while IFS= read -r project; do
      # Get just the project name and parent folder for display
      project_name=$(basename "$project")
      parent=$(basename "$(dirname "$project")")

      # Show as "parent/project-name" if not in root github folder
      if [[ "$parent" != "github" ]]; then
        projects+="[$parent] $project_name|$project"$'\n'
      else
        projects+="$project_name|$project"$'\n'
      fi
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  fi
done

# Show in rofi
selection=$(echo "$projects" | rofi -dmenu -i -p "Open Project" -matching fuzzy -format "s")

[ -z "$selection" ] && exit 0

# Extract the full path after the pipe
project_path="${selection#*|}"

if [ -d "$project_path" ]; then
  # Open in VS Code
  code "$project_path"
else
  notify-send "Error" "Project not found: $project_path"
fi
