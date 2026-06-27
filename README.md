# skgen

A SKILL.md behaves like a dynamically-linked binary. Writing one links it
invisibly against your context: your CLAUDE.md, memory, tools, paths. So it
drifts or breaks on anyone else's machine. skgen ships skills as source instead.
A `.skill.src` declares those dependencies and decides each one: carry it so it
is the same everywhere, or bind it so it resolves locally. You compile the source
against your own machine, in Claude Code. The model and the format are in
`FORMAT.md`.

## Use it

skgen is itself a skill. Install it so Claude can run it:

    git clone https://github.com/baron-3dl/skgen ~/.claude/skills/skgen

**Compile a source** someone shared, to get a SKILL.md for your machine. In Claude Code:

    compile path/to/foo.skill.src

Claude binds the source against your context, re-derives the steering your model
needs, checks the output, and writes the SKILL.md. A missing bind stops it and
names what is missing.

**Author a source** to share a skill you made. In Claude Code:

    build a .skill.src from <the skill>

Claude inlines what defines the output and declares what is local. Share the
`.skill.src`, never the SKILL.md.

## Layout

- `SKILL.md`: how Claude operates skgen.
- `FORMAT.md`: the `.skill.src` format and the carry/bind model.
- `seed/`: the builder and compiler procedures.
- `examples/`: five worked sources, each with its compiled `.SKILL.md`.
