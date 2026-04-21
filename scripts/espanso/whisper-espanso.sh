#!/bin/bash

WHISPER_ROOT="$HOME/github/whisper.cpp"
WHISPER_EXE="$WHISPER_ROOT/build/bin/whisper-cli"
MODEL_PATH="$WHISPER_ROOT/models/ggml-base.en.bin"
TEMP_AUDIO="/tmp/whisper_audio_$$.wav"
STOP_FILE="/tmp/whisper_stop_$$"

rm -f "$TEMP_AUDIO" "$STOP_FILE"

notify-send "Whisper" "Recording... (Enter or click to stop)" -i audio-input-microphone

parecord --format=s16le --rate=16000 --channels=1 "$TEMP_AUDIO" 2>/dev/null &
PID=$!

while [ ! -f "$STOP_FILE" ] && kill -0 $PID 2>/dev/null; do
	sleep 0.5
done

kill $PID 2>/dev/null
rm -f "$STOP_FILE"

if [ -f "$TEMP_AUDIO" ] && [ -s "$TEMP_AUDIO" ]; then
	notify-send "Whisper" "Transcribing..." -i software-update-available
	TRANSCRIPTION=$($WHISPER_EXE -m "$MODEL_PATH" -f "$TEMP_AUDIO" -nt 2>/dev/null)
	CLEAN_TEXT=$(echo "$TRANSCRIPTION" | sed 's/\[.*\]//g' | xargs)

	if [ -n "$CLEAN_TEXT" ]; then
		printf '%s' "$CLEAN_TEXT"
	else
		echo "[empty]"
	fi
fi

rm -f "$TEMP_AUDIO"