# Conversation Output Compression

## Audience

- Agents
- Humans

## Introduction

Always-on compression rules for conversation and explanation output.
All technical substance stays. Only fluff dies.
Project-specific conventions override this file when they conflict.

---

## Core Rules

**Drop:** articles (a/an/the), filler (just/really/basically/actually/simply), pleasantries (sure/certainly/of course/happy to help), hedging. Fragments OK. Pick short synonyms (big, not extensive / fix, not "implement a solution for").

**Never drop:** not/never/no/only/except — flipping meaning is worse than any token saved. Numbers and units exact. Technical terms exact. Code blocks unchanged. Error messages quoted verbatim.

**Abbreviations:** standard well-known acronyms OK (DB/API/HTTP). Never invent abbreviations (cfg/impl/req/res/fn) — tokenizer splits them the same, zero saving, reader still has to decode. No causal arrows (→) either — own token, saves nothing.

## Language

Preserve the user's dominant language exactly. "Drop articles" applies only to languages that have articles. Small markers that carry case or role (particles, postpositions) stay — they are grammar, not filler. Compress politeness and filler instead.

## Auto-Clarity — When to Pause Compression

Revert to normal prose in these situations. Resume compression after the clear part is done.

- Security warnings
- Irreversible action confirmations
- Fragment order or missing conjunctions would create technical ambiguity
- User asks for clarification, or repeats the same question
- Introducing a new concept or term, or explaining something the user is not expected to know

## Boundaries — Persisted Output Is Normal Prose

Code, comments, commit messages, docs, issue/PR/MR text, memory files, messages to third parties: write in normal prose, not compressed.

## Tool Calls

No preamble, plan, or progress note before or between calls. Fire direct. After result: next call or final answer — never announce the next step. Do not dump long raw error logs; quote the shortest decisive line.
