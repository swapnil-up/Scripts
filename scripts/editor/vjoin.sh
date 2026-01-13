#!/bin/bash

# vjoin - Concatenate video clips
# Usage: vjoin <videos...> -o <output>

VERSION="1.0.0"

show_help() {
    cat << EOF
vjoin - Video Clip Joiner

USAGE:
    vjoin <video_files...> -o <output> [OPTIONS]

OPTIONS:
    -o, --output FILE       Output file (required)
    -i, --interactive       Interactively reorder clips before joining
    -h, --help              Show this help message
    -v, --version           Show version

EXAMPLES:
    # Join in specified order
    vjoin clip_001.mp4 clip_005.mp4 clip_003.mp4 -o final.mp4

    # Auto-sort by number and join
    vjoin clip_*.mp4 -o final.mp4

    # Interactive reordering
    vjoin clip_*.mp4 --interactive -o final.mp4

INTERACTIVE MODE:
    space   Select/deselect clip
    ↑/k     Move cursor/selected clip up
    ↓/j     Move cursor/selected clip down
    d       Delete clip at cursor (or selected clip)
    p       Preview clip at cursor (or selected clip)
    s       Save order and start joining
    q       Quit without joining

NOTES:
    - When using wildcards (clip_*.mp4), clips are auto-sorted numerically
    - Specified files maintain their exact order
    - All clips are re-encoded to ensure compatibility

EOF
}

# Default values
OUTPUT_FILE=""
INPUT_FILES=()
INTERACTIVE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "vjoin version $VERSION"
            exit 0
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -*)
            echo "Error: Unknown option $1"
            show_help
            exit 1
            ;;
        *)
            INPUT_FILES+=("$1")
            shift
            ;;
    esac
done

# Validate input
if [[ ${#INPUT_FILES[@]} -eq 0 ]]; then
    echo "Error: No input files specified"
    show_help
    exit 1
fi

if [[ -z "$OUTPUT_FILE" ]]; then
    echo "Error: No output file specified (-o option required)"
    show_help
    exit 1
fi

# Check dependencies
for cmd in ffmpeg ffprobe; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed"
        exit 1
    fi
done

# Verify all input files exist
for file in "${INPUT_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file"
        exit 1
    fi
done

# Auto-sort if it looks like numbered clips
if [[ ${#INPUT_FILES[@]} -gt 1 ]]; then
    # Check if files follow pattern like clip_001.mp4
    if [[ "${INPUT_FILES[0]}" =~ _[0-9]+\.mp4$ ]]; then
        echo "Auto-sorting clips numerically..."
        IFS=$'\n' INPUT_FILES=($(sort -V <<< "${INPUT_FILES[*]}"))
        unset IFS
    fi
fi

# Get video duration
get_duration() {
    ffprobe -v error -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$1" 2>/dev/null | \
            awk '{printf "%.1fs", $1}'
}

# Interactive reordering
if [[ "$INTERACTIVE" == true ]]; then
    TEMP_LIST=$(mktemp)
    printf '%s\n' "${INPUT_FILES[@]}" > "$TEMP_LIST"
    
    CURSOR=0
    SELECTED_CLIP=-1
    NEED_REDRAW=true
    
    show_list() {
        tput cup 0 0
        echo "=== vjoin - Interactive Clip Ordering ==="
        echo ""
        
        local idx=0
        while IFS= read -r file; do
            local duration=$(get_duration "$file")
            local cursor=" "
            local marker=" "
            [[ $idx -eq $CURSOR ]] && cursor="→"
            [[ $idx -eq $SELECTED_CLIP ]] && marker="✓"
            printf "%s %s %2d. %s (%s)%s\n" "$cursor" "$marker" $((idx + 1)) "$(basename "$file")" "$duration" "$(tput el)"
            ((idx++))
        done < "$TEMP_LIST"
        
        echo ""
        printf "Commands: space=select | ↑/k=up | ↓/j=down | d=delete | p=preview | s=save & join | q=quit%s\n" "$(tput el)"
        tput ed
    }
    
    # Clear screen once at the start
    tput clear
    
    while true; do
        [[ "$NEED_REDRAW" == true ]] && show_list && NEED_REDRAW=false
        
        # Read single character
        read -rsn1 key
        
        # Handle arrow keys (they send multiple bytes)
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            case $key in
                '[A') key='k' ;;  # Up arrow
                '[B') key='j' ;;  # Down arrow
            esac
        fi
        
        case $key in
            ' ') # Space - select/deselect
                if [[ $SELECTED_CLIP -eq $CURSOR ]]; then
                    SELECTED_CLIP=-1  # Deselect
                else
                    SELECTED_CLIP=$CURSOR
                fi
                NEED_REDRAW=true
                ;;
            k) # Move up
                if [[ $SELECTED_CLIP -ge 0 ]]; then
                    # Move selected clip up
                    if [[ $SELECTED_CLIP -gt 0 ]]; then
                        awk -v sel=$SELECTED_CLIP 'NR==sel {tmp=$0; next} 
                             NR==sel+1 {print; print tmp; next} 
                             {print}' "$TEMP_LIST" > "$TEMP_LIST.tmp"
                        mv "$TEMP_LIST.tmp" "$TEMP_LIST"
                        ((SELECTED_CLIP--))
                        CURSOR=$SELECTED_CLIP
                        NEED_REDRAW=true
                    fi
                else
                    # Just move cursor
                    if [[ $CURSOR -gt 0 ]]; then
                        ((CURSOR--))
                        NEED_REDRAW=true
                    fi
                fi
                ;;
            j) # Move down
                total=$(wc -l < "$TEMP_LIST")
                if [[ $SELECTED_CLIP -ge 0 ]]; then
                    # Move selected clip down
                    if [[ $SELECTED_CLIP -lt $((total - 1)) ]]; then
                        awk -v sel=$((SELECTED_CLIP + 1)) 'NR==sel {tmp=$0; next} 
                             NR==sel+1 {print; print tmp; next} 
                             {print}' "$TEMP_LIST" > "$TEMP_LIST.tmp"
                        mv "$TEMP_LIST.tmp" "$TEMP_LIST"
                        ((SELECTED_CLIP++))
                        CURSOR=$SELECTED_CLIP
                        NEED_REDRAW=true
                    fi
                else
                    # Just move cursor
                    if [[ $CURSOR -lt $((total - 1)) ]]; then
                        ((CURSOR++))
                        NEED_REDRAW=true
                    fi
                fi
                ;;
            d) # Delete
                line_to_delete=$CURSOR
                [[ $SELECTED_CLIP -ge 0 ]] && line_to_delete=$SELECTED_CLIP
                
                awk -v sel=$((line_to_delete + 1)) 'NR!=sel' "$TEMP_LIST" > "$TEMP_LIST.tmp"
                mv "$TEMP_LIST.tmp" "$TEMP_LIST"
                
                total=$(wc -l < "$TEMP_LIST")
                [[ $CURSOR -ge $total ]] && ((CURSOR--))
                [[ $CURSOR -lt 0 ]] && CURSOR=0
                SELECTED_CLIP=-1
                NEED_REDRAW=true
                ;;
            p) # Preview
                line_to_preview=$CURSOR
                [[ $SELECTED_CLIP -ge 0 ]] && line_to_preview=$SELECTED_CLIP
                
                preview_file=$(awk -v sel=$((line_to_preview + 1)) 'NR==sel' "$TEMP_LIST")
                if command -v mpv &> /dev/null; then
                    tput clear
                    echo "Previewing: $(basename "$preview_file")"
                    echo "Press q to exit preview..."
                    echo ""
                    mpv --loop --length=10 "$preview_file" 2>&1 | grep -v "^Cannot load"
                    NEED_REDRAW=true
                else
                    tput cup 20 0
                    echo "Error: mpv not found, can't preview                    "
                    sleep 2
                    NEED_REDRAW=true
                fi
                ;;
            s) # Save and join
                # Read files from temp list
                INPUT_FILES=()
                while IFS= read -r file; do
                    INPUT_FILES+=("$file")
                done < "$TEMP_LIST"
                rm -f "$TEMP_LIST"
                break
                ;;
            q) # Quit
                tput clear
                rm -f "$TEMP_LIST"
                echo "Cancelled."
                exit 0
                ;;
        esac
    done
    
    tput clear
fi

# Show final order
echo "Joining clips in this order:"
for i in "${!INPUT_FILES[@]}"; do
    duration=$(get_duration "${INPUT_FILES[$i]}")
    printf "%2d. %s (%s)\n" $((i + 1)) "$(basename "${INPUT_FILES[$i]}")" "$duration"
done
echo ""

# Create concat file for ffmpeg
CONCAT_FILE=$(mktemp --suffix=.txt)

for file in "${INPUT_FILES[@]}"; do
    # Get absolute path and escape single quotes
    abs_path=$(readlink -f "$file")
    abs_path="${abs_path//\'/\'\\\'\'}"
    echo "file '$abs_path'" >> "$CONCAT_FILE"
done

echo "Starting concatenation..."
echo "Output: $OUTPUT_FILE"
echo ""

# Join videos using ffmpeg
# Re-encode to ensure compatibility between clips
ffmpeg -f concat -safe 0 -i "$CONCAT_FILE" \
       -c:v libx264 -preset medium -crf 23 \
       -c:a aac -b:a 192k \
       "$OUTPUT_FILE" \
       -loglevel warning -stats

if [[ $? -eq 0 ]]; then
    final_duration=$(get_duration "$OUTPUT_FILE")
    echo ""
    echo "✓ Successfully created: $OUTPUT_FILE ($final_duration)"
    ls -lh "$OUTPUT_FILE"
else
    echo "✗ Error during concatenation"
    rm -f "$CONCAT_FILE"
    exit 1
fi

# Cleanup
rm -f "$CONCAT_FILE"