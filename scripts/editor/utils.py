#!/usr/bin/env python3
import subprocess
import sys
import os

def run_ffmpeg(cmd):
    """Execute ffmpeg command and handle errors"""
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return result

def get_duration(video_file):
    """Get video duration in seconds"""
    cmd = ['ffprobe', '-v', 'error', '-show_entries', 
           'format=duration', '-of', 
           'default=noprint_wrappers=1:nokey=1', video_file]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return float(result.stdout.strip())

def validate_file(filepath):
    """Check if file exists"""
    if not os.path.isfile(filepath):
        print(f"Error: {filepath} not found")
        sys.exit(1)