# Coding Settings

## Audience

- Agents
- Humans

## Introduction

Behavioral rules for writing code, applied across all repositories.
Project-specific conventions (language, framework, domain vocabulary, etc.) live in each repository's AGENTS.md / CLAUDE.md.
When the two conflict, the project side wins.

## Core Premise

Code is read more often than it is written.
Every decision is judged by: "Can the next person to read this code (human, another agent, future self) understand and modify it in the shortest time?"

---

## 1. Means of Conveying Intent Have a Priority Order

Try from the top. Drop to the next level only when the one above cannot express it.

1. **Type signatures** — express everything the type system can express.
2. **Names** — function and variable names that tell what they do on sight.
3. **Comments** — write the "why" that names cannot convey. Never write the "what" (the code says that).
4. **Tests** — written with awareness that they will be read as usage examples.
5. **Commit messages** — record "why this change was made."
6. **Documentation** — for what the above cannot cover, or for external audiences.

Before reaching for a lower means, revisit the higher one.
Example: if you feel the urge to add a comment, first ask whether renaming would make it unnecessary.

## 2. A Method Is Either a Command or a Query

- **Command**: causes side effects. Returns nothing (`void` / `()` equivalent).
- **Query**: returns a value. No observable side effects.

Do not write functions that do both. Keep the reader able to predict "what happens when I call this."

## 3. Keep the Variable Count Per Function Consciously Low

Count every variable a single function handles (locals, parameters, referenced class fields).

**Guideline: 7 or fewer.**

A function exceeding this is likely beyond human short-term memory. Consider decomposing at that point.

## 4. Keep Cyclomatic Complexity Per Function Low

Count the branches in a single function (if / for / while / case / && / || etc.).

**Guideline: 7 or fewer.**

When exceeded, consider in this order:

1. Guard clauses with early returns to flatten nesting.
2. Extract part of the logic into a separate function.
3. Replace with a data structure (map / table-driven approach).

## 5. When You Deviate From a Rule, Leave the Reason in the Code

The rules in this file work in most cases but are not absolute.
Deviation is fine, provided:

- A one-line comment at the deviation site states the reason.
  - Example: `// deliberate: guideline is 7 vars, allowing M here because ~reason~`
- If you cannot judge on your own, consult a human before writing code.

A visible trace of deviation lets future readers follow or re-evaluate the intent.
