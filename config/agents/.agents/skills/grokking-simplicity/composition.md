# Skill: Function Composition

Use this when building complex behavior from simple parts.

## The Idea

Small, focused functions combine to do big things.

```typescript
// Instead of one big function...
function processWorld(world: World): World {
  // 50 lines of mixed logic
}

// Compose small functions
const processWorld = pipe(
  applyEntropy,
  resolveFeeding,
  handleMovement,
  filterDead
);
```

## Common Patterns

### Array Methods Chain

```typescript
const result = cells
  .filter(c => c.energy > 0)      // Calculation
  .map(applyEntropy)               // Calculation
  .sort((a, b) => b.energy - a.energy);  // Calculation
```

### Pipe/Compose

```typescript
function pipe<T>(...fns: ((arg: T) => T)[]): (arg: T) => T {
  return (arg) => fns.reduce((acc, fn) => fn(acc), arg);
}

const nextWorld = pipe(
  applyEntropyToAll,
  resolveAllFeeding,
  moveAllSeekers,
  removeDeadCells
)(currentWorld);
```

### Function Returning Function

```typescript
// Parameterized calculation
function withSettings(settings: WorldSettings) {
  return (cell: Cell) => applyEntropy(cell, settings);
}

const applySeekerEntropy = withSettings({ entropyRate: 1.0 });
```

## Why Composition Beats Control Flow

1. **Testable** - each piece tested independently
2. **Reusable** - small functions combine differently
3. **Readable** - names describe the pipeline
4. **Debuggable** - can trace each step

## In the Entropy Engine

The `nextTick` function is composition:

```typescript
export function nextTick(world: World, seed: number): World {
  // Composition of:
  // 1. Generate random directions (using seed)
  // 2. Apply feeding (seekers eat plants)
  // 3. Move seekers
  // 4. Apply entropy to all
  // 5. Apply move costs
  // 6. Handle reproduction
  // 7. Filter dead cells
}
```

Load this skill when building transformation pipelines or refactoring large functions.