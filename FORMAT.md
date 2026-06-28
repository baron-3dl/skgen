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
Behavioral where it takes judgment.

### Pins
A handful of concrete (input, reference output) cases. The reference is what good
output looks like for that input, the gold the compile converges to. Compiling
runs the candidate skill on each input, scores the output against the reference
and the checks, and tunes the steering until the cases pass. Without pins there
is nothing to iterate toward, and the compile is just authoring.

## Compiling tunes steering against the pins

Compiling is a loop, and the loop is the point. The compiler resolves the binds
against the local target, then starts from minimal steering and tunes it: run the
candidate skill on the pinned inputs blind to the references, score how far each
output varies from its reference and the checks, rewrite the steering to close
the largest gaps, run it again. It repeats until the cases pass or it has shown
this target cannot reach them. It emits the SKILL.md and a compile report
recording the score at each round, from the weak seed to convergence, so the
tuning is visible. Different model, different steering, same output. It fails loud
two ways: a bind it cannot resolve, or a target that cannot reproduce the pinned
outputs to spec. Installing someone else's source and recompiling your own when
the model moves are the same act.
