---
name: skillc
description: Compile and author portable skill sources. Use when the user wants to compile a .skill.src into a SKILL.md for this machine, or turn a skill they made into a shareable .skill.src.
---

skillc treats a SKILL.md as a dynamically-linked binary and ships skills as source
(`.skill.src`) that compiles in place. Read `FORMAT.md` for the source format and
the carry/bind model before either operation.

## Compile a `.skill.src` into a SKILL.md

The user has a `.skill.src` and wants it working on this machine. Follow
`seed/compiler.skill.md`. In short: resolve the source's binds against the local
context (CLAUDE.md, memories, MCP servers, paths) and fail loud on any you cannot
resolve; re-derive the steering this model and harness need to reproduce the
carried behavior; verify by running the compiled skill against the carried
checks; emit the SKILL.md and a short report of what bound to what.

## Build a `.skill.src` from a skill

The user made a skill the normal way and wants to share it. Follow
`seed/builder.skill.md`. In short: classify each dependency as carry (it defines
the output, so inline it in full) or bind (it is local, so declare it as a
requirement); distill the corrections into checks; emit the `.skill.src`. Never
hand someone the SKILL.md; it is bound to this machine.
