# AGENTS

How to work with this repo.

## General

- This is a dotfiles + automation repo, not a software project
- No CI/CD, no tests, no formal linting
- Be careful with destructive operations (rm, git reset --hard)
- Verify changes work before committing

## Directory Roles

- **config/**: Production configs - changes take effect on next login/restart
- **setup/**: Run-once bootstrap - idempotent but slow
- **scripts/**: Used actively - test changes before use

## Before Modifying

1. Check `local/todo.md` and `local/stuff I missed` for known issues
2. Read existing docs in that section
3. Understand integration points (see section READMEs)

## Commands

```bash
# Reload a stowed config
stow -R -t ~ -d config package_name

# Test a script
bash -n script.sh  # syntax check
./script.sh        # dry run if interactive
```

## Commit Style

- Prefix with section: `[config]`, `[setup]`, `[scripts]`
- Keep messages short and descriptive