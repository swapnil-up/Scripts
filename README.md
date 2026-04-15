# Scripts

Three parts: configs, setup, scripts.

## Motivation

Setting up a new system sucks when you're a power user. Everything from installs to setting up your homerow mods and WM navigation that nobody understands. This helps me get something up atleast partially.

## Structure

| Dir | Purpose |
|-----|---------|
| `config/` | Dotfiles managed via git-stow |
| `setup/` | Bootstrap scripts for fresh systems |
| `scripts/` | Automation utilities |

## Quick Start

```bash
# Bootstrap a new system
cd setup && ./bootstrap.sh

# Stow configs manually
cd config && stow -t ~ */
```

## Formatting

```bash
make format   # shfmt + black
make lint     # syntax check
```

See individual directories for details.