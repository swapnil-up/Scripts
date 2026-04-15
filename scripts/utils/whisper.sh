#!/bin/bash

WHISPER_ROOT="$HOME/github/whisper.cpp"
WHISPER_EXE="$WHISPER_ROOT/build/bin/whisper-cli"
MODEL_PATH="$WHISPER_ROOT/models/ggml-base.en.bin"
TEMP_AUDIO="/tmp/whisper_audio.wav"

rm -f "$TEMP_AUDIO"

stop_recording() {
	echo -e "\n[Recording Stopped]"
}
trap stop_recording SIGINT

echo "Listening... (Press Ctrl+C to stop)"
notify-send "Whisper" "Listening... Press 'c' to stop." -i audio-input-microphone

# 3. Record (16kHz, Mono, 16-bit)
arecord -f S16_LE -r 16000 -c 1 "$TEMP_AUDIO" 2>/dev/null

# 4. Transcription Phase
trap - SIGINT
echo "Transcribing..."
notify-send "Whisper" "Transcribing audio..." -i software-update-available

if [ -f "$TEMP_AUDIO" ]; then
	# -nt: no timestamps
	TRANSCRIPTION=$($WHISPER_EXE -m "$MODEL_PATH" -f "$TEMP_AUDIO" -nt 2>/dev/null)

	# remove Whisper's [brackets] and extra spaces)
	CLEAN_TEXT=$(echo "$TRANSCRIPTION" | sed 's/\[.*\]//g' | xargs)

	if [ -n "$CLEAN_TEXT" ]; then
		echo "$CLEAN_TEXT" | xclip -selection clipboard
		xclip -selection clipboard -o >/dev/null 2>&1

		echo "------------------------------"
		echo "Transcribed: $CLEAN_TEXT"
		echo "------------------------------"
		echo "Copied to clipboard!"
		notify-send "Whisper Copied" "$CLEAN_TEXT" -i edit-paste
	else
		echo "Error: Transcription was empty."
		notify-send "Whisper Error" "Transcription was empty" -u critical
	fi
else
	echo "Error: Audio file was not created. Check your microphone."
	notify-send "Whisper Error" "Audio file not found" -u critical
fi
