#!/bin/bash

# vcut - Extract video clips interactively using MPV
# Usage: vcut <input_video> [options]

VERSION="1.0.1"

show_help() {
    cat << EOF
vcut - Interactive Video Clip Extractor

USAGE:
    vcut <input_video> [OPTIONS]

OPTIONS:
    -o, --output-dir DIR    Output directory for clips (default: ./clips)
    -p, --prefix NAME       Prefix for output files (default: clip)
    -n, --start-num NUM     Starting clip number (default: auto-detect)
    -h, --help              Show this help message
    -v, --version           Show version

INTERACTIVE MODE:
    i       Mark IN point (start of clip)
    o       Mark OUT point (end of clip)
    s       Save current clip
    q       Quit

EXAMPLES:
    vcut workout.mp4
    vcut raw_footage.mp4 -o today_clips -p deadlift
    vcut another_video.mp4 -n 10  # Start numbering from 10

WORKFLOW:
    1. Video plays in MPV
    2. Press 'i' when you want a clip to start
    3. Press 'o' when you want it to end
    4. Press 's' to save the clip
    5. Repeat for more clips
    6. Press 'q' when done

EOF
}

# Default values
OUTPUT_DIR="./clips"
PREFIX="clip"
INPUT_FILE=""
START_NUM=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "vcut version $VERSION"
            exit 0
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -p|--prefix)
            PREFIX="$2"
            shift 2
            ;;
        -n|--start-num)
            START_NUM="$2"
            shift 2
            ;;
        -*)
            echo "Error: Unknown option $1"
            show_help
            exit 1
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

# Validate input
if [[ -z "$INPUT_FILE" ]]; then
    echo "Error: No input file specified"
    show_help
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: File '$INPUT_FILE' not found"
    exit 1
fi

# Check dependencies
for cmd in ffmpeg mpv; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed"
        exit 1
    fi
done

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Auto-detect starting clip number if not specified
if [[ -z "$START_NUM" ]]; then
    # Find highest existing clip number
    HIGHEST=$(ls "$OUTPUT_DIR"/${PREFIX}_*.mp4 2>/dev/null | \
              sed "s/.*${PREFIX}_\([0-9]*\).mp4/\1/" | \
              sort -n | tail -1)
    
    if [[ -z "$HIGHEST" ]]; then
        START_NUM=1
    else
        START_NUM=$((HIGHEST + 1))
    fi
fi

echo "Starting clip numbers from: $START_NUM"

# Create temporary file for MPV input
TEMP_DIR=$(mktemp -d)
INPUT_CONF="$TEMP_DIR/input.conf"
MARKS_FILE="$TEMP_DIR/marks.txt"
CLIP_COUNTER_FILE="$TEMP_DIR/counter.txt"

# Initialize clip counter
echo "$((START_NUM - 1))" > "$CLIP_COUNTER_FILE"

# Create MPV input configuration
cat > "$INPUT_CONF" << 'MPVCONF'
i script-message mark-in
o script-message mark-out
s script-message save-clip
MPVCONF

# Create Lua script for MPV
LUA_SCRIPT="$TEMP_DIR/clipper.lua"
cat > "$LUA_SCRIPT" << 'LUASCRIPT'
local in_point = nil
local out_point = nil
local marks_file = os.getenv("VCUT_MARKS_FILE")
local counter_file = os.getenv("VCUT_COUNTER_FILE")

function read_counter()
    local f = io.open(counter_file, "r")
    if not f then return 0 end
    local num = tonumber(f:read("*all")) or 0
    f:close()
    return num
end

function write_counter(num)
    local f = io.open(counter_file, "w")
    if not f then return false end
    f:write(tostring(num))
    f:close()
    return true
end

function mark_in()
    local pos = mp.get_property_number("time-pos")
    if pos then
        in_point = pos
        mp.osd_message(string.format("IN: %.2fs", in_point), 2)
    else
        mp.osd_message("Error: Could not get time position", 2)
    end
end

function mark_out()
    local pos = mp.get_property_number("time-pos")
    if pos then
        out_point = pos
        mp.osd_message(string.format("OUT: %.2fs", out_point), 2)
    else
        mp.osd_message("Error: Could not get time position", 2)
    end
end

function save_clip()
    -- Validate inputs
    if not in_point then
        mp.osd_message("Error: No IN point set (press 'i')", 3)
        return
    end
    if not out_point then
        mp.osd_message("Error: No OUT point set (press 'o')", 3)
        return
    end
    if in_point >= out_point then
        mp.osd_message("Error: IN must be before OUT", 3)
        return
    end
    
    -- Read and increment counter
    local counter = read_counter()
    counter = counter + 1
    
    if not write_counter(counter) then
        mp.osd_message("Error: Could not write counter", 3)
        return
    end
    
    -- Write marks to file with validation
    local f = io.open(marks_file, "a")
    if not f then
        mp.osd_message("Error: Could not open marks file", 3)
        return
    end
    
    -- Write as: clip_number start_time end_time
    f:write(string.format("%d %.3f %.3f\n", counter, in_point, out_point))
    f:close()
    
    local duration = out_point - in_point
    mp.osd_message(string.format("✓ Clip %d: %.2fs to %.2fs (%.2fs)", 
                                  counter, in_point, out_point, duration), 3)
    
    -- Reset points for next clip
    in_point = nil
    out_point = nil
end

mp.register_script_message("mark-in", mark_in)
mp.register_script_message("mark-out", mark_out)
mp.register_script_message("save-clip", save_clip)

-- Show controls on start
mp.register_event("file-loaded", function()
    mp.osd_message("vcut | i=IN | o=OUT | s=SAVE | q=QUIT", 5)
end)
LUASCRIPT

# Export environment variables for Lua script
export VCUT_MARKS_FILE="$MARKS_FILE"
export VCUT_COUNTER_FILE="$CLIP_COUNTER_FILE"

echo "Starting vcut interactive mode..."
echo "Controls: i=IN point | o=OUT point | s=SAVE clip | q=QUIT"
echo ""

# Launch MPV
mpv --input-conf="$INPUT_CONF" \
    --script="$LUA_SCRIPT" \
    --osd-level=1 \
    --osd-font-size=30 \
    "$INPUT_FILE"

# Process marked clips
if [[ -f "$MARKS_FILE" ]] && [[ -s "$MARKS_FILE" ]]; then
    echo ""
    echo "Processing clips..."
    
    while IFS=' ' read -r clip_num start_time end_time; do
        # Validate the data
        if ! [[ "$clip_num" =~ ^[0-9]+$ ]]; then
            echo "⚠ Skipping invalid clip number: $clip_num"
            continue
        fi
        
        if ! [[ "$start_time" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            echo "⚠ Skipping invalid start time: $start_time"
            continue
        fi
        
        if ! [[ "$end_time" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            echo "⚠ Skipping invalid end time: $end_time"
            continue
        fi
        
        output_file="$OUTPUT_DIR/${PREFIX}_$(printf "%03d" $clip_num).mp4"
        duration=$(echo "$end_time - $start_time" | bc)
        
        echo "Extracting clip $clip_num: ${start_time}s to ${end_time}s (${duration}s)"
        
        # Use -y to overwrite existing files without prompting
        ffmpeg -y \
               -i "$INPUT_FILE" \
               -ss "$start_time" \
               -t "$duration" \
               -c copy \
               -avoid_negative_ts make_zero \
               "$output_file" \
               -loglevel error -stats
        
        if [[ $? -eq 0 ]]; then
            echo "✓ Saved: $output_file"
        else
            echo "✗ Error saving clip $clip_num"
        fi
        echo ""
    done < "$MARKS_FILE"
    
    total_clips=$(wc -l < "$MARKS_FILE")
    echo "Done! Extracted $total_clips clip(s) to $OUTPUT_DIR/"
    ls -lh "$OUTPUT_DIR"/${PREFIX}_*.mp4 | tail -n "$total_clips"
else
    echo "No clips were marked. Exiting."
fi

# Cleanup
rm -rf "$TEMP_DIR"