# Skill: Stratified Design

Use this when organizing code into layers or deciding where a new function belongs.

## The Layers (Bottom to Top)

### 1. Primitives
- Pure math operations
- Basic data transformations
- **Never depends on layers above**

```typescript
// src/lib/engine/primitives.ts
export function add(a: number, b: number): number { return a + b; }
export function wrap(value: number, max: number): number {
  return ((value % max) + max) % max;
}
```

### 2. Domain Rules
- Business logic for your specific problem
- Uses primitives
- **Still pure calculations**

```typescript
// src/lib/engine/physics.ts
export function applyEntropy(cell: Cell, rate: number): Cell {
  // Uses wrap() from primitives
  return { ...cell, energy: cell.energy - Math.floor(cell.energy * rate / 100) };
}
```

### 3. Application Logic
- Orchestrates domain rules
- Main pipelines (like `nextTick`)
- Still calculations!

```typescript
// src/lib/engine/universe.ts
export function nextTick(world: World): World {
  const withEntropy = world.cells.map(c => applyEntropy(c, world.settings));
  // ...
}
```

### 4. I/O (Actions)
- Rendering, network, storage
- **Only at the very edges**

```typescript
// src/lib/components/Canvas.svelte
// Rendering is an Action
```

### 5. Orchestration
- Main loops, event handlers
- Calls calculations, triggers actions

```typescript
// src/routes/+page.svelte
// Ties together engine (calculation) + canvas (action)
```

## The Dependency Rule

**Calculations can only depend on calculations at the same or lower layer.**

```
Actions ← can depend on anything
Calculations (L3) ← L3, L2, L1
Calculations (L2) ← L2, L1
Calculations (L1) ← L1 only
```

## In the Entropy Engine

| File | Layer | Type |
|------|-------|------|
| `data.ts` | Data | Types/interfaces |
| `physics.ts` | Domain Rules | Calculations |
| `universe.ts` | Application | Calculation pipeline |
| `Canvas.svelte` | I/O | Action |
| `+page.svelte` | Orchestration | Action |

Load this skill when deciding where to place new code or resolving import dependencies.