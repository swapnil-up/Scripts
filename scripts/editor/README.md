# Video Editing Scripts

This repository contains Python scripts for **marker-based video editing** and **text overlays**, designed for quick and repeatable edits.

## Features

* **Marker-based cutting**: Quickly mark cut points and generate trimmed videos.
* **Text overlays**: Add timed text markers and apply them to video.
* **Pipeline-friendly**: Scripts are designed to work together for fast, repeatable workflows.
* **Utilities**: Includes helper functions for FFmpeg commands, validation, and duration checks.

## Requirements

* Python 3
* FFmpeg & FFprobe installed and in PATH
* Standard Python libraries: `os`, `sys`, `subprocess`, `json`

## Scripts and Usage

### 1. Marker-Based Cutting

**Step 1: Mark cut points**

```bash
python3 scripts/editor/marker.py /home/swap/possessions/Videos/skipping40min/VID_20260109_065251.mp4
```

* Open the video in mpv.
* Controls:

  * `m`: mark cut point
  * `[ / ]`: decrease/increase speed
  * `LEFT/RIGHT`: seek backward/forward 5s
  * `UP/DOWN`: seek backward/forward 60s
  * `SPACE`: pause/play
  * `q`: quit and save markers

**Step 2: Process the cuts**

```bash
python3 scripts/editor/process_cuts.py /home/swap/possessions/Videos/skipping40min/VID_20260109_065251.mp4 /home/swap/possessions/Videos/skipping40min/trial.mp4
```

* Generates a trimmed video according to the marked cut points.

### 2. Text Overlay

**Step 1: Mark text positions**

```bash
python3 scripts/editor/text_marker.py /home/swap/possessions/Videos/skipping40min/trial.mp4
```

* Place text markers where overlays should appear.
* Controls similar to marker.py.

**Step 2: Process text overlays**

```bash
python3 scripts/editor/process_text.py /home/swap/possessions/Videos/skipping40min/trial.mp4 /home/swap/possessions/Videos/skipping40min/with_text.mp4
```

* Adds the marked text to the video according to the markers.

## Utilities

Included in `scripts/editor/utils.py`:

* `run_ffmpeg(cmd)`: execute FFmpeg commands safely.
* `get_duration(video_file)`: returns video duration in seconds.
* `validate_file(filepath)`: ensures input file exists.
* Other helpers: GPU detection, preview mode, dry-run, output validation.

## Workflow Example

1. Mark cut points → process cuts → mark text → process text.
2. Use the output for final exports, GIF creation, or social media sharing.

## Notes

* Designed for **repeatable, frictionless edits**.
* Supports preview mode to quickly check edits before full export.
