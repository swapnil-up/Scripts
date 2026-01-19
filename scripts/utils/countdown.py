#!/usr/bin/env python3
import sys, time, subprocess

seconds = int(sys.argv[1]) if len(sys.argv) > 1 else 300

time.sleep(seconds)

subprocess.run([
    "notify-send",
    "⏰ Timer done",
    f"{seconds // 60} minutes passed"
])
