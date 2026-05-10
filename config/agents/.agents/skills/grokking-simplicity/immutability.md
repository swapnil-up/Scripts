# Skill: Immutability Patterns

Use this when writing data transformations or refactoring mutable code.

## The Rule

**Never mutate existing records — create new ones.**

## In Practice

### Objects

```javascript
// ❌ Bad - mutating
cell.energy -= decay;

// ✅ Good - creating new
const newCell = { ...cell, energy: cell.energy - decay };
```

### Arrays

```javascript
// ❌ Bad - mutating
cells.push(newCell);
cells.splice(i, 1);

// ✅ Good - creating new
const newCells = [...cells, newCell];
const filtered = cells.filter((c, idx) => idx !== i);
```

### Nested Objects

```javascript
// ❌ Bad - mutating nested
world.settings.entropyRate = 0.5;

// ✅ Good - create path
const newWorld = {
  ...world,
  settings: { ...world.settings, entropyRate: 0.5 }
};
```

## TypeScript Readonly

Use `readonly` to enforce immutability at the type level:

```typescript
interface Cell {
  readonly id: number;
  readonly type: CellType;
  readonly energy: number;
  // ...
}
```

## Why It Matters

1. **Time-travel debugging** - can replay history
2. **Concurrency** - no race conditions
3. **Undo/redo** - trivial to implement
4. **Reasoning** - state changes are explicit

## In the Entropy Engine

Every `nextTick()` returns a **completely new World**:
- The old world is preserved for rewind
- History is a stack of snapshots
- Debugging: compare worlds before/after

Load this skill when creating data transformations or fixing mutation bugs.