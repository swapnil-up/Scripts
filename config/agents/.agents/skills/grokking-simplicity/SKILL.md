---
name: grokking-simplicity
description: Functional programming concepts from Grokking Simplicity - categorize code as Actions/Calculations/Data, use immutability, build layered architecture, compose small functions.
---


# Grokking Simplicity - Reference Skill

This skill captures the core functional programming concepts from *Grokking Simplicity* by Eric Normand. Use this when working on the Entropy Engine or any functional project.

## Overview

The book teaches three core skills:

1. **Categorizing code** - Actions, Calculations, Data → see `actions-calculations-data.md`
2. **Immutability** - Never mutate, always create new → see `immutability.md`
3. **Stratified Design** - Organize into layers → see `stratified-design.md`
4. **Composition** - Build big from small → see `composition.md`

## The Three Categories

All code falls into one of three categories:

### 1. Actions
Code that **does** something - has side effects, depends on when it runs, or can produce different results on different runs.
- Reading/writing to disk, database, network
- Reading current time, random numbers
- Logging, console output
- **Question to ask:** "Does this depend on *when* it runs?"

### 2. Calculations
Code that **computes** a value - pure, deterministic, can be run anytime, produces same output for same input.
- Math operations, string manipulation
- Filtering, mapping, reducing arrays
- Pure functions with no side effects
- **Question to ask:** "Could I replace this with a lookup table?"

### 3. Data
Records of facts - inert, doesn't do anything, can be read or copied freely.
- JSON objects, database records
- Configuration, constants
- Event logs, snapshots
- **Question to ask:** "Would I be comfortable shipping this to a competitor?"

## The Core Skill: Categorization

When writing or reviewing code, ask for each function:

1. **Does it interact with the outside world?** → Action
2. **Does it return a value based only on its inputs?** → Calculation
3. **Is it a record of facts?** → Data

## Why This Matters

### 1. Testability
- **Calculations** are trivial to test - just call with inputs, check outputs
- **Actions** require mocks, spies, or integration tests
- **Data** doesn't need testing - it's just records

### 2. Composability
- Calculations can be freely composed, reordered, and cached
- Actions have ordering constraints (you must connect to DB before querying)
- Data can be read by any calculation

### 3. Parallelism
- Calculations can run in parallel - no race conditions
- Actions must be carefully sequenced
- Data can be shared freely

### 4. Reasoning
- Calculations can be understood in isolation
- Actions require understanding the system state
- Data can be inspected without running anything

## The "Grokking" Workflow

When building with Grokking principles:

1. **Start with data** - Define your immutable snapshots first
2. **Build calculations** - Pure functions that transform data
3. **Wrap in actions** - I/O at the edges (start and end only)
4. **Separate the strata** - Never mix categories in the same function

## Sub-Skills

### actions-calculations-data.md
Detailed guide on categorizing every function. Use when classifying code or debugging mixed responsibilities.

### immutability.md
Patterns for creating new data instead of mutating. Use when writing data transformations or fixing mutation bugs.

### stratified-design.md
Layer organization (Primitives → Domain → Application → I/O). Use when deciding where to place new code.

### composition.md
Building complex pipelines from small functions. Use when refactoring large functions or building transformation chains.

## Key Terms

| Term | Meaning |
|------|---------|
| **Pure function** | A calculation with no side effects |
| **Side effect** | Anything that changes state outside the function |
| **First-class functions** | Functions can be passed as values, stored in variables |
| **Higher-order function** | A function that takes or returns functions |
| **Composition** | Combining small functions to build complex behavior |
| **Deterministic** | Same inputs always produce same outputs |

## Anti-Patterns to Avoid

1. **Mixing categories** - A function that both calculates AND logs is problematic
2. **Action inside calculation** - Calling `console.log()` inside a "pure" function breaks testability
3. **Mutating inputs** - Modifying objects passed as parameters
4. **Hardcoded randomness** - Using `Math.random()` in domain logic - pass seed as argument

## The Entropy Engine Application

This project applies Grokking principles:

- **Data:** `Cell`, `World` interfaces are immutable records
- **Calculations:** `physics.ts` contains pure functions (entropy, movement, feeding)
- **Actions:** `Canvas.svelte` handles rendering, `+page.svelte` handles user input
- **Immutability:** Every tick creates a new World snapshot, never mutates
- **Determinism:** Seeded random ensures reproducible behavior

## For New Agents

When working on this codebase:

1. Keep domain logic in `src/lib/engine/` as pure TypeScript
2. Canvas rendering is an Action - keep it in components
3. Never import Actions into Calculation files
4. Use `readonly` TypeScript modifiers where possible
5. When in doubt, ask: "Is this a calculation that could be tested in isolation?"
