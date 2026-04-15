# AGENTS

## Testing Scripts

```bash
# Shell syntax check
bash -n script.sh

# Dry run (if interactive)
./script.sh 

# For Python: verify deps
python3 -c "import module" 2>/dev/null || echo "missing"
```

## Common Patterns

- **i3 binds**: Use absolute path `~/github/scripts/scripts/...`
- **espanso shell**: Uses rofi for interactive, returns result
- **anki**: Uses AnkiConnect API on localhost:8765

## Dependencies

- Most need: xclip, xdotool, rofi
- Video editing: ffmpeg, ffprobe
- TTS/STT: ~/github/piper_tts, whisper.cpp

## Integration Examples

- `anki-piper.sh`: Captures clipboard, sends to Anki via API
- `rofi-smart-launcher.sh`: Python script pipes to rofi, dispatches choice
- `piper.sh`: Reads clipboard aloud via TTS