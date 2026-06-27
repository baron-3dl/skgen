# `.skill.src`: a portable skill source

A SKILL.md is a text file, but it behaves like a dynamically-linked binary. As
you develop it, it picks up implicit dependencies on your context: your
CLAUDE.md, your memories, your tools, your paths. On your machine those
references resolve and it works. On anyone else's they resolve to something
different or to nothing, so the output drifts. The dependencies were never
declared, so it does not fail loud like a missing shared library. It quietly
produces the wrong thing.

A `.skill.src` is what travels. It is the symbol table the SKILL.md never had: an
explicit dependency list that links each dependency on purpose, **carried** ones
statically (bundled in, the same everywhere) and **bound** ones dynamically
(resolved against the recipient).

- **Carried** is the content that defines the output. It travels whole, inlined
  into the source, so the output is reproduced identically anywhere: a voice
  profile, gold examples, the corrections that say what good output is. You do
  not leave this as a blank for the recipient to fill. You bake it in.
- **Bound** is a genuinely local dependency that should differ per target: which
  tracker closes an item, which deploy tool to call. Declared as a requirement,
  resolved against the recipient's context at compile time.

A pure-reproduction skill (a voice) is all carried, no binds, so it produces the
same output everywhere. An adaptive skill (commit messages) carries its method
and binds the local tracker. Most skills are a mix.

## Sections

### Intent
One or two lines: what the skill is for.

### Carried
The invariant payload, inlined in full. Whatever the output depends on that the
recipient will not independently have: the behavior definition, reference
examples of correct output, the facts the behavior leans on. This is the part
that makes the output reproducible. It is the content itself, inlined, never a
pointer to a file the recipient lacks.

### Bound
The local dependencies, if any. Each carries an id and a `requires` line naming
the capability in plain words. Empty for a pure-reproduction skill.

### Checks
What the compiled skill's output must satisfy: the author's corrections, kept as
tests. Mechanical where you can see it by eye (no em-dashes, subject under 60).
Behavioral where it takes judgment, verified by running the compiled skill and
comparing its output to the carried examples.

## Compile is re-derivation, not substitution

The compiler reads the carried definition, examples, and checks, resolves the
binds against the local target, then **re-derives** the steering its own model
and harness need to reproduce the carried behavior. It iterates its drafts
against the carried checks and examples until the output matches. Different
model, different steering, same output. It fails loud two ways: a bind it cannot
resolve, or a target model that cannot reproduce the carried behavior to spec.
Installing someone else's source and recompiling your own when the model moves
are the same act.
