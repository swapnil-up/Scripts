#!/bin/bash

python3 ~/scripts/scripts/rofi/smart_launcher.py \
  | rofi -dmenu -i -p "Launch" -matching normal -allow-custom \
  | python3 ~/scripts/scripts/rofi/smart_launcher.py --dispatch
