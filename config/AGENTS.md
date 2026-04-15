# AGENTS

## Integration Points

- **kanata.kbd**: Spacefn layer mirrors i3 keybinds. If adding i3 shortcuts, mirror in symbol/spacefn layers
- **espanso/base.yml**: Many triggers call scripts via shell expansion. Keep paths as `~/github/scripts/...`
- **i3/config**: Binds scripts directly. Some scripts need to be in PATH or use absolute paths

## Adding Configs

1. Create directory: `config/<package>/`
2. For dotfiles: place at root (stow strips the package prefix)
3. For .config files: use `config/<package>/.config/<app>/`
4. Test: `stow -R -t ~ -d config <package>`

## Common Patterns

- Kanata uses tap-hold for home-row mods
- Espanso uses rofi for interactive pickers
- i3 binds $mod+o to anki-piper, $mod+d to rofi-smart-launcher

## Gotchas

- Kanata needs systemd service + user group for uinput
- Espanso requires D-Bus session for service start
- i3 runs startup.sh after 5s delay - scripts may need same delay