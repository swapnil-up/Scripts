#!/usr/bin/env python3
import sys
from utils import validate_file, print_video_info

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: info.py VIDEO_FILE")
        print("Example: info.py workout.mp4")
        sys.exit(1)
    
    validate_file(sys.argv[1])
    print_video_info(sys.argv[1])