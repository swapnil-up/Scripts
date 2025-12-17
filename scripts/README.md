## Scripts
Just a collection of scripts I use while trying to rice my system

### Using scripts and saving them for when I eventually inevitably fuck up my config files.

the only important one right now is the i3config. The fun things I've put in right now is the keyboard mapping being switched for l-alt and ~l-win~ l-super so that I'm able to press the mod key easily while also being able to access the in-app shortcuts that use alt by using the right alt.
command is: exec setxkbmap -option 'altwin:swap_lalt_lwin'

There's also the commands at the end that's been used to add shortcuts for taking a screenshot and putting it in the clipboard.

### 2024-03-05 Update
added a few things.
first was qutebrowser which was fun to use. Currently removed because of lack of plugins (especially leechblock) using vimium extension on firefox instead

the greyscale works. Steps:
	turn on picom in background with: picom -b
	run ./toggle-monitor-grayscale.sh
	
Forgot but got the starship interface for terminal. Easy install, but remember to get nerdfonts first.

i3 also had me getting custom keybindings at least for the most common things. mod+b for opening firefox and mod+g to open nautilus atm.

### Autostart acquired
Problem: I started using the grayscale often and messing around in my terminal, so scrolling up the terminal history to scroll the list of past commands became annoying. 

Solution: Figured out how to autorun scripts through i3. Just putting the commands in i3 didn't work, so made a custom shell and delayed by 5sec because it wasn't working well. Assumption is that other executions related to the script not running when done on start. 

Current: Automatic grayscale and changing the left alt and left win keys. Probably some changes in i3 over the period like anki shortcut into i3


### For kanata:
i've gone down the rabbit hole because my hands hurt after coding too long, especially pinkies (and left hand). I'm a programmer. I use qwerty
Currently I have 
left alt as enter
right alt as backspace
capslock as ctrl/esc (not used much, pinky hurts)
home row mods
space when held is nav layer (hjkl arrow keys, yuio is home pgup/down, end, and mouse on the left keys: wersdf)
double tap j is esc
x has macro that selects  all and deletes while in nav layer
