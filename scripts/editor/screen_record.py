#!/usr/bin/env python3
import sys
import subprocess
import signal

def record_screen(output_file, region=None, fps=30, show_mouse=True):
    """
    Record screen using ffmpeg
    region: tuple of (x, y, width, height) or None for full screen
    """
    
    cmd = ['ffmpeg', '-y']
    
    # Video input from X11
    if region:
        x, y, width, height = region
        cmd.extend(['-video_size', f'{width}x{height}'])
        cmd.extend(['-f', 'x11grab', '-i', f':0.0+{x},{y}'])
    else:
        cmd.extend(['-f', 'x11grab', '-i', ':0.0'])
    
    # Show/hide mouse cursor
    if show_mouse:
        cmd.extend(['-draw_mouse', '1'])
    else:
        cmd.extend(['-draw_mouse', '0'])
    
    # Frame rate
    cmd.extend(['-framerate', str(fps)])
    
    # Codec settings
    cmd.extend(['-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '23'])
    
    cmd.append(output_file)
    
    print("Recording screen...")
    print("Press Ctrl+C to stop")
    print()
    
    # Start recording
    process = subprocess.Popen(cmd)
    
    def signal_handler(sig, frame):
        print("\nStopping recording...")
        process.terminate()
        process.wait()
        print(f"✓ Saved: {output_file}")
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    
    process.wait()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: screen_record.py OUTPUT [OPTIONS]")
        print("\nOptions:")
        print("  --region X Y W H    Record specific region")
        print("  --fps FPS           Frame rate (default: 30)")
        print("  --no-mouse          Hide mouse cursor")
        print("\nExamples:")
        print("  screen_record.py demo.mp4")
        print("  screen_record.py demo.mp4 --region 0 0 1920 1080 --fps 60")
        print("  screen_record.py demo.mp4 --no-mouse")
        print("\nPress Ctrl+C to stop recording")
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    region = None
    fps = 30
    show_mouse = True
    
    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == '--region' and i + 4 < len(sys.argv):
            region = (int(sys.argv[i+1]), int(sys.argv[i+2]), 
                     int(sys.argv[i+3]), int(sys.argv[i+4]))
            i += 5
        elif sys.argv[i] == '--fps' and i + 1 < len(sys.argv):
            fps = int(sys.argv[i + 1])
            i += 2
        elif sys.argv[i] == '--no-mouse':
            show_mouse = False
            i += 1
        else:
            i += 1
    
    record_screen(output_file, region, fps, show_mouse)