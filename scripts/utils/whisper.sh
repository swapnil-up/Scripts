#!/bin/bash

WHISPER_ROOT="$HOME/github/whisper.cpp"
WHISPER_EXE="$WHISPER_ROOT/build/bin/whisper-cli"
MODEL_PATH="$WHISPER_ROOT/models/ggml-base.en.bin"
TEMP_AUDIO="/tmp/whisper_audio.wav"
 
export DISPLAY=${DISPLAY:-:0}

rm -f "$TEMP_AUDIO"
trap 'rm -f "$TEMP_AUDIO"; exit' USR1

notify-send "Whisper" "Listening... (Press 'ctrl+c' to stop)" -i audio-input-microphone

parecord --format=s16le --rate=16000 --channels=1 "$TEMP_AUDIO" 2>/dev/null

notify-send "Whisper" "Transcribing..." -i software-update-available

if [ -f "$TEMP_AUDIO" ]; then
	# -nt: no timestamps
	TRANSCRIPTION=$($WHISPER_EXE -m "$MODEL_PATH" -f "$TEMP_AUDIO" -nt 2>/dev/null)

	# remove Whisper's [brackets] and extra spaces
	CLEAN_TEXT=$(echo "$TRANSCRIPTION" | sed 's/\[.*\]//g' | tr -s ' ' | sed 's/^ //;s/ $//')

	if [ -n "$CLEAN_TEXT" ]; then
		echo "$CLEAN_TEXT" | xclip -selection clipboard

		notify-send "Whisper Copied" "$CLEAN_TEXT" -i edit-paste
	else
		echo "Error: Transcription was empty."
		notify-send "Whisper Error" "Transcription was empty"
	fi
else
	echo "Error: Audio file was not created. Check your microphone."
	notify-send "Whisper Error" "Audio file not found"
fi
