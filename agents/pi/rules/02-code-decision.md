# Pre-Code Decision Ladder

## Audience

- Agents
- Humans

## Introduction

Always-on decision rules applied before writing any code.
Lazy means efficient, not careless. The best code is the code never written.
Project-specific conventions override this file when they conflict.

---

## The Ladder

Before writing any code, stop at the first rung that holds:

1. Does this need to be built at all? (YAGNI)
2. Does it already exist in this codebase? Reuse the helper, util, or pattern that's already here.
3. Does the standard library already do this? Use it.
4. Does a native platform feature cover it? Use it.
5. Does an already-installed dependency solve it? Use it.
6. Can this be one line? Make it one line.
7. Only then: write the minimum code that works.

The ladder runs after you understand the problem, not instead of it: read the task and the code it touches, trace the real flow end to end, then climb.

## Bug Fixes

A report names a symptom. Fix the root cause. Grep every caller of the function you touch and fix the shared function once — one guard there is a smaller diff than one per caller, and patching only the reported path leaves sibling callers still broken.

## Rules

- No abstractions that weren't explicitly requested.
- No new dependency if it can be avoided.
- No boilerplate nobody asked for.
- Deletion over addition. Boring over clever. Fewest files possible.
- Shortest working diff wins, but only once you understand the problem.
- Question complex requests: "Do you actually need X, or does Y cover it?"
- Pick the edge-case-correct option when two stdlib approaches are the same size.

## Deliberate Simplifications

Mark deliberate simplifications that cut a real corner with a `deliberate:` comment naming the ceiling and the upgrade path.

```
// deliberate: O(n²) scan, fine under ~1k items. Switch to a hash set if list grows.
```

## Not Lazy About

- Understanding the problem — read it fully and trace the real flow before picking a rung.
- Input validation at trust boundaries.
- Error handling that prevents data loss.
- Security.
- Accessibility.
- Platform-specific calibration (clocks drift, sensors read off — the platform is never the spec ideal).
- Anything explicitly requested.

## Verification

Non-trivial logic leaves ONE runnable check behind — the smallest thing that fails if the logic breaks. An assert-based demo/self-check or one small test file. No frameworks, no fixtures. Trivial one-liners need no test.
