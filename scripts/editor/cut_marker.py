#!/usr/bin/env python3
import sys
import subprocess
import json
import os

def mark_cuts(input_file):
    """
    Open video in mpv, let user mark cut points
    Controls:
    - 'm' to mark a cut point
    - '1'/'2' to adjust playback speed
    - space to pause/play
    - arrow keys to seek
    
    Marks are saved in pairs - each pair of marks defines a section to CUT OUT
    """
    
    markers_file = f"{input_file}.markers.json"
    
    # Check if markers already exist
    markers = []
    if os.path.exists(markers_file):
        response = input(f"Found existing markers for this file. (l)oad them, (d)elete and start fresh, or (c)ancel? ")
        if response.lower() == 'l':
            with open(markers_file, 'r') as f:
                markers = json.load(f)
            print(f"Loaded {len(markers)} existing markers")
        elif response.lower() == 'd':
            os.remove(markers_file)
            print("Deleted old markers, starting fresh")
        else:
            print("Cancelled")
            return
    
    print(f"\nMarking cuts for: {input_file}")
    print("Controls:")
    print("  m - Mark cut point")
    print("  [ / ] - Decrease/increase speed")
    print("  LEFT/RIGHT - Seek backward/forward 5s")
    print("  UP/DOWN - Seek backward/forward 60s")
    print("  SPACE - Pause/play")
    print("  q - Quit and save markers\n")
    
    if markers:
        print("Existing markers:")
        for i, m in enumerate(markers, 1):
            print(f"  {i}. {m}")
        print()
    
    # MPV lua script to capture timestamps
    lua_script = f"""
    markers = {{}}
    
    function mark_timestamp()
        local time = mp.get_property_number("time-pos")
        table.insert(markers, time)
        mp.osd_message(string.format("Marked: %.2fs (Total: %d marks)", time, #markers), 2)
    end
    
    function save_and_quit()
        local file = io.open("{input_file}.timestamps.tmp", "w")
        for i, time in ipairs(markers) do
            file:write(string.format("%.3f\\n", time))
        end
        file:close()
        mp.osd_message("Saved " .. #markers .. " markers", 2)
        mp.command("quit")
    end
    
    mp.add_key_binding("m", "mark", mark_timestamp)
    mp.add_key_binding("q", "save_quit", save_and_quit)
    """
    
    # Write lua script to temp file
    lua_file = f"/tmp/mpv_marker_{os.getpid()}.lua"
    with open(lua_file, 'w') as f:
        f.write(lua_script)
    
    # Run mpv with the script
    cmd = [
        'mpv',
        '--speed=2', 
        '--osd-level=3',
        f'--script={lua_file}',
        input_file
    ]
    
    try:
        subprocess.run(cmd)
        
        # Read timestamps from temp file
        timestamp_file = f"{input_file}.timestamps.tmp"
        if os.path.exists(timestamp_file):
            with open(timestamp_file, 'r') as f:
                new_markers = [float(line.strip()) for line in f if line.strip()]
            
            markers.extend(new_markers)
            markers.sort()
            
            # Save all markers
            with open(markers_file, 'w') as f:
                json.dump(markers, f, indent=2)
            
            os.remove(timestamp_file)
            
            print(f"\nSaved {len(markers)} total markers to {markers_file}")
            print("\nMarkers:")
            for i, m in enumerate(markers, 1):
                mins, secs = divmod(m, 60)
                hours, mins = divmod(mins, 60)
                print(f"  {i}. {int(hours):02d}:{int(mins):02d}:{secs:05.2f}")
            
            # Show what will be cut
            if len(markers) % 2 == 0:
                print("\nSections to CUT OUT:")
                for i in range(0, len(markers), 2):
                    start_m = markers[i]
                    end_m = markers[i+1]
                    duration = end_m - start_m
                    print(f"  Cut {i//2+1}: {format_time(start_m)} -> {format_time(end_m)} ({duration:.1f}s)")
            else:
                print("\nWARNING: Odd number of markers! Markers should come in pairs (start/end of cut).")
                print("Run marker.py again to add the missing marker.")
    
    finally:
        if os.path.exists(lua_file):
            os.remove(lua_file)

def format_time(seconds):
    """Convert seconds to HH:MM:SS.ms format"""
    mins, secs = divmod(seconds, 60)
    hours, mins = divmod(mins, 60)
    return f"{int(hours):02d}:{int(mins):02d}:{secs:05.2f}"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: marker.py INPUT_VIDEO")
        print("Example: marker.py raw_workout.mp4")
        print("\nThis opens the video in mpv. Press 'm' to mark cut points.")
        print("Markers come in PAIRS - each pair defines a section to remove.")
        sys.exit(1)
    
    mark_cuts(sys.argv[1])