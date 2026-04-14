#!/bin/bash

# --- CONFIGURATION ---
MODEL_PATH="$HOME/github/piper_tts-1.4.2/en_US-lessac-medium.onnx"
DEFAULT_SPEED="0.7"

if pgrep -x "piper" > /dev/null; then
    pkill piper && pkill aplay
    notify-send "Piper TTS" "Stopped reading."
    exit 0
fi

SPEED=${1:-$DEFAULT_SPEED}

Get text from clipboard
TEXT=$(xclip -selection clipboard -o)

if [ -z "$TEXT" ]; then
    notify-send "Piper TTS" "Clipboard is empty!" -u low
    exit 1
fi

notify-send "Piper TTS" "Reading clipboard..." -i audio-speakers

echo "$TEXT" | piper --model $MODEL_PATH --length_scale $SPEED --output_raw | aplay -r 22050 -f S16_LE -t raw