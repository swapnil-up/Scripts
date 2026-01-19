#!/usr/bin/env python3
import sys
import json
import os
import tempfile
from utils import run_ffmpeg, validate_file, get_duration

def format_time(seconds):
    """Convert seconds to HH:MM:SS.ms"""
    mins, secs = divmod(seconds, 60)
    hours, mins = divmod(mins, 60)
    return f"{int(hours):02d}:{int(mins):02d}:{secs:06.3f}"

def process_marked_cuts(input_file, output_file, fast=True):
    """
    Process video based on markers file
    Removes all sections between marker pairs
    """
    validate_file(input_file)
    
    markers_file = f"{input_file}.markers.json"
    if not os.path.exists(markers_file):
        print(f"Error: No markers file found ({markers_file})")
        print("Run marker.py first to create markers")
        sys.exit(1)
    
    with open(markers_file, 'r') as f:
        markers = json.load(f)
    
    if len(markers) == 0:
        print("No markers found. Nothing to cut.")
        sys.exit(1)
    
    if len(markers) % 2 != 0:
        print("ERROR: Odd number of markers. Each cut needs a start AND end marker.")
        print(f"You have {len(markers)} markers. Add one more or remove one.")
        sys.exit(1)
    
    duration = get_duration(input_file)
    
    # Build list of segments to KEEP
    segments = []
    last_end = 0
    
    print("Cutting out:")
    for i in range(0, len(markers), 2):
        cut_start = markers[i]
        cut_end = markers[i+1]
        
        print(f"  Section {i//2+1}: {format_time(cut_start)} -> {format_time(cut_end)}")
        
        # Keep segment before this cut
        if cut_start > last_end:
            segments.append((last_end, cut_start))
        
        last_end = cut_end
    
    # Keep final segment after last cut
    if last_end < duration:
        segments.append((last_end, duration))
    
    print(f"\nKeeping {len(segments)} segments")
    
    if len(segments) == 0:
        print("ERROR: All video would be cut out!")
        sys.exit(1)
    
    # Create temporary clips for each segment
    temp_clips = []
    codec = ['-c', 'copy'] if fast else ['-c:v', 'libx264', '-preset', 'fast']
    
    try:
        for i, (start, end) in enumerate(segments):
            temp_file = tempfile.mktemp(suffix='.mp4')
            temp_clips.append(temp_file)
            
            print(f"Processing segment {i+1}/{len(segments)}...")
            
            cmd = ['ffmpeg', '-y', '-ss', str(start), '-to', str(end),
                   '-i', input_file] + codec + [temp_file]
            run_ffmpeg(cmd)
        
        # Join all segments
        print("Joining segments...")
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            for clip in temp_clips:
                f.write(f"file '{os.path.abspath(clip)}'\n")
            concat_file = f.name
        
        cmd = ['ffmpeg', '-y', '-f', 'concat', '-safe', '0',
               '-i', concat_file] + codec + [output_file]
        run_ffmpeg(cmd)
        
        os.unlink(concat_file)
        print(f"\nDone! Output: {output_file}")
        
        # Show summary
        original_duration = duration
        kept_duration = sum(end - start for start, end in segments)
        cut_duration = original_duration - kept_duration
        
        print(f"\nSummary:")
        print(f"  Original: {original_duration:.1f}s")
        print(f"  Cut out: {cut_duration:.1f}s ({cut_duration/original_duration*100:.1f}%)")
        print(f"  Final: {kept_duration:.1f}s")
    
    finally:
        # Cleanup temp files
        for clip in temp_clips:
            if os.path.exists(clip):
                os.unlink(clip)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: process_cuts.py INPUT OUTPUT [--precise]")
        print("Example: process_cuts.py raw_workout.mp4 edited.mp4")
        print("\nProcesses cuts based on markers from marker.py")
        sys.exit(1)
    
    fast = '--precise' not in sys.argv
    process_marked_cuts(sys.argv[1], sys.argv[2], fast)