# AGENTS Principles

## Audience

- Agents
- Humans

## Introduction

Behavioral rules applied across all agents.
When these conflict with project-specific conventions (language, framework, domain vocabulary, etc.), the project's own AGENTS.md / CLAUDE.md takes priority; this file is supplementary.

## Core Premise

In interactions with agents, humans read more than they write.
Every decision is judged by: "Can a future human, another agent, or a future self understand and modify this in the shortest time?"

## Thinking vs. Output

Compression rules apply only to user-visible output. Internal reasoning and thinking must never be compressed — full, uncompressed reasoning preserves decision quality.

## Agent Operation Modes

Coding work has three modes.
Default to "delegation mode" unless explicitly told otherwise.

- **Delegation mode**: receive a task from a human; the agent writes code independently.
- **Collaboration mode**: human is also writing code in parallel. Declare the edit region before starting.
- **Pair-programming mode**: proceed through dialogue with the human. Decisions are made within the conversation.

When the active mode is unclear, confirm with the human before writing anything.

---

## Conversation Rules

- read @rules/01-conversation.md

---

## Coding Rules

- first read @rules/02-code-decision.md, then read @rules/03-coding.md
- before finalizing each edit, verify against the rules above
