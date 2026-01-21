#!/usr/bin/env python3
import sys
import os
import tempfile
from utils import run_ffmpeg, validate_file, get_video_info, parse_time

def create_gif(input_file, output_file, start=None, duration=None, 
               fps=15, width=None, quality='medium'):
    """
    Convert video to optimized GIF
    
    quality presets:
    - 'low': smaller file, lower quality (good for long gifs)
    - 'medium': balanced (default)
    - 'high': better quality, larger file (good for short demos)
    - 'max': highest quality (use sparingly)
    """
    validate_file(input_file)
    
    info = get_video_info(input_file)
    
    # Quality settings
    quality_settings = {
        'low': {'fps': 10, 'scale': 480, 'colors': 128},
        'medium': {'fps': 15, 'scale': 640, 'colors': 256},
        'high': {'fps': 20, 'scale': 800, 'colors': 256},
        'max': {'fps': 30, 'scale': -1, 'colors': 256},  # -1 means no scaling
    }
    
    settings = quality_settings.get(quality, quality_settings['medium'])
    
    # Override with user settings
    if fps:
        settings['fps'] = fps
    if width:
        settings['scale'] = width
    
    # Build filter complex for optimal gif quality
    # Using palettegen/paletteuse gives way better quality than direct conversion
    filters = []
    
    # Scale if needed
    if settings['scale'] != -1:
        if info.get('width', 0) > settings['scale']:
            filters.append(f"scale={settings['scale']}:-1:flags=lanczos")
    
    # Set fps
    filters.append(f"fps={settings['fps']}")
    
    filter_str = ','.join(filters) if filters else None
    
    # Generate palette for better colors
    palette_file = tempfile.mktemp(suffix='.png')
    
    try:
        print(f"Creating GIF with {quality} quality...")
        print(f"  FPS: {settings['fps']}")
        print(f"  Width: {settings['scale'] if settings['scale'] != -1 else info.get('width', '?')}")
        print(f"  Colors: {settings['colors']}")
        
        # Step 1: Generate palette
        palette_cmd = ['ffmpeg', '-y']
        
        if start:
            palette_cmd.extend(['-ss', str(parse_time(start))])
        if duration:
            palette_cmd.extend(['-t', str(parse_time(duration))])
        
        palette_cmd.extend(['-i', input_file])
        
        if filter_str:
            palette_cmd.extend(['-vf', f"{filter_str},palettegen=max_colors={settings['colors']}:stats_mode=diff"])
        else:
            palette_cmd.extend(['-vf', f"palettegen=max_colors={settings['colors']}:stats_mode=diff"])
        
        palette_cmd.append(palette_file)
        
        print("Generating color palette...")
        run_ffmpeg(palette_cmd, show_progress=False)
        
        # Step 2: Create gif using palette
        gif_cmd = ['ffmpeg', '-y']
        
        if start:
            gif_cmd.extend(['-ss', str(parse_time(start))])
        if duration:
            gif_cmd.extend(['-t', str(parse_time(duration))])
        
        gif_cmd.extend(['-i', input_file, '-i', palette_file])
        
        if filter_str:
            gif_cmd.extend(['-lavfi', f"{filter_str} [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5"])
        else:
            gif_cmd.extend(['-lavfi', "paletteuse=dither=bayer:bayer_scale=5"])
        
        gif_cmd.append(output_file)
        
        print("Creating GIF...")
        run_ffmpeg(gif_cmd, show_progress=False)
        
        # Show file size
        size_mb = os.path.getsize(output_file) / (1024 * 1024)
        print(f"\n✓ Created: {output_file}")
        print(f"  Size: {size_mb:.2f} MB")
        
        if size_mb > 10:
            print("\n⚠ Warning: GIF is large (>10MB). Consider:")
            print("  - Using lower quality: --quality low")
            print("  - Reducing duration")
            print("  - Reducing width: --width 480")
            print("  - Lowering fps: --fps 10")
    
    finally:
        if os.path.exists(palette_file):
            os.unlink(palette_file)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: gif.py INPUT OUTPUT [OPTIONS]")
        print("\nOptions:")
        print("  --start TIME        Start time (e.g., '10' or '00:00:10')")
        print("  --duration TIME     Duration (e.g., '5' or '00:00:05')")
        print("  --fps FPS           Frame rate (default: depends on quality)")
        print("  --width WIDTH       Output width in pixels (height auto)")
        print("  --quality PRESET    low/medium/high/max (default: medium)")
        print("\nExamples:")
        print("  gif.py demo.mp4 demo.gif")
        print("  gif.py video.mp4 clip.gif --start 10 --duration 5 --quality high")
        print("  gif.py screen.mp4 small.gif --width 480 --fps 10 --quality low")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    # Parse options
    start = None
    duration = None
    fps = 16
    width = None
    quality = 'medium'
    
    i = 3
    while i < len(sys.argv):
        if sys.argv[i] == '--start' and i + 1 < len(sys.argv):
            start = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == '--duration' and i + 1 < len(sys.argv):
            duration = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == '--fps' and i + 1 < len(sys.argv):
            fps = int(sys.argv[i + 1])
            i += 2
        elif sys.argv[i] == '--width' and i + 1 < len(sys.argv):
            width = int(sys.argv[i + 1])
            i += 2
        elif sys.argv[i] == '--quality' and i + 1 < len(sys.argv):
            quality = sys.argv[i + 1]
            i += 2
        else:
            i += 1
    
    create_gif(input_file, output_file, start, duration, fps, width, quality)