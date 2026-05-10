# Skill: Categorizing Code

Use this when classifying functions or reviewing code structure.

## The Three Categories

Ask for each function:

### Is it an Action?
- Does it interact with the outside world (file, network, DB)?
- Does it depend on when it runs?
- Could it produce different results on different runs?
- → **Actions** are everything with side effects

### Is it a Calculation?
- Does it return a value based only on its inputs?
- Could you replace it with a lookup table?
- Would it be safe to call during a airplane mode flight?
- → **Calculations** are pure, deterministic functions

### Is it Data?
- Is it a record of facts?
- Does it just sit there, waiting to be read?
- Would you be comfortable sending it to a competitor?
- → **Data** is inert records

## Quick Reference

| Question | Answer → Category |
|----------|------------------|
| Does it write to disk/network? | Action |
| Does it read the current time? | Action |
| Does it use Math.random()? | Action |
| Does it filter/map/reduce? | Calculation |
| Does it return a computed value? | Calculation |
| Is it a JSON object? | Data |
| Is it a config/constant? | Data |

## Common Mistakes

- A function that's both a calculation AND logs to console = **mixed category**
- A "pure" function that reads a global variable = **not pure**
- Calling an action inside a calculation = **breaks testability**

## In the Entropy Engine

- `physics.ts` → **Calculations only**
- `Canvas.svelte` → **Actions** (rendering is a side effect)
- `data.ts` → **Data** (interfaces and types)

Load this skill when you need to classify code or debug mixed responsibilities.