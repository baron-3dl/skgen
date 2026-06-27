# skgen: skills as source, compiled in place

A SKILL.md is a text file, but it behaves like a dynamically-linked binary.
Developing it embeds implicit dependencies on your context: your CLAUDE.md, your
memories, your tools, your paths. On your machine those references resolve and it
works. On anyone else's they resolve differently or not at all, so the output
drifts. And because the dependencies were never declared, it does not fail loud
like a missing shared library. It quietly produces the wrong thing.

skgen distributes skills as source instead. A `.skill.src` is the symbol table
the SKILL.md never had. It makes the dependencies explicit and links each one on
purpose: it carries what defines the output (linked statically, the same
everywhere) and binds what is local (linked dynamically, resolved against the
recipient). You compile it against your own setup and get a SKILL.md that works
for you. The compiler is Claude Code itself. No runtime, no inference endpoint,
no API keys, no dependencies. The cost is whatever your Claude Code already
bills.

## The model

A `.skill.src` separates two kinds of dependency (full spec in FORMAT.md):

- **Carried**: the content that defines the output. It travels whole, inlined in
  the source, so the output reproduces identically anywhere. A voice profile,
  gold examples, the corrections that say what good output is.
- **Bound**: a genuinely local thing that should differ per target. Which tracker
  closes a work item, which tool deploys. Declared as a requirement, resolved
  against your context at compile time.

A voice skill is all carried, so it produces the same voice on anyone's machine.
A commit-message skill carries its method and binds your local tracker. Most
skills are a mix.

Compiling is re-derivation. The compiler reads the carried definition, resolves
the binds against your setup, then writes the steering your model and harness
need to reproduce the carried behavior, checking its own output against the
carried checks until it matches. Different model, different steering, same
output. It fails loud two ways: a bind it cannot resolve, or a model too weak to
reproduce the behavior to spec.

## Use it (everything runs in Claude Code)

Install a skill someone shared:

> Compile `examples/voice.skill.src` against this repo, following
> `seed/compiler.skill.md`.

Claude reads your CLAUDE.md, memories, MCP servers, and files, binds what is
local, re-derives the steering, verifies it, and writes the SKILL.md. If a bind
is missing it stops and names it.

Author and share your own:

> Following `seed/builder.skill.md`, turn the skill we just made into a
> `.skill.src`.

Claude lifts your draft and corrections into a source: it inlines what defines
the output and declares what is local. Share the `.skill.src`. Never share the
SKILL.md, because it is bound to your setup.

Recompile when your model changes by running the compiler again. Installing
someone else's source and recompiling your own are the same act.

## What's here

- `FORMAT.md`: the `.skill.src` format.
- `seed/builder.skill.md`: the build procedure (lift a skill into a source).
- `seed/compiler.skill.md`: the compile procedure (bind, re-derive, verify).
- `examples/*.skill.src`: five worked sources. Each has a `.SKILL.md` beside it
  showing what it compiled to in one environment. Yours will differ.
  - `voice`: pure carry. Reproduces one person's writing voice anywhere.
  - `compress`: carries a method, binds the local tracker IDs and conventions.
  - `adversarial-design`: carries the method, binds the deliberation substrate.
  - `swarm-plan`: carries the method, binds the tracker, agent registry, routing.
  - `swarm-dispatch`: carries the orchestration method, binds the parallel
    execution mechanism, and fails loud on a setup that lacks one.

The two seeds are themselves skills, so they could be distributed as source too.
The chain bottoms out at these hand-written, context-free seeds. They are the one
thing you trust by reading rather than by compiling, because a poisoned compiler
could hide a backdoor in everything it builds, including a fresh copy of itself.
Keep them small enough to read.
