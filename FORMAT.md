# The self-building skill file

A SKILL.md is a text file, but it behaves like a dynamically-linked binary. As you
develop it, it quietly picks up dependencies on your context: your CLAUDE.md, your
memories, your tools, your paths. On your machine those references resolve and it
works. On anyone else's they resolve to something different or to nothing, so the
output drifts. The dependencies were never declared, so it does not fail loud like a
missing shared library. It just quietly produces the wrong thing.

A self-building skill file is what travels instead. It is one ordinary skill file that
carries two things fused together: the material that defines good output, and the
recipe that rebuilds the skill from that material on the receiver's machine. Like a
self-extracting archive, the file you send contains both the contents and the
unpacker. The first time the receiver uses it, before it answers anything, it rebuilds
itself against the receiver's environment, tests itself against examples the author
approved, and reports plainly whether it reproduced the author's quality or could not.

## The file, top to bottom

1. Frontmatter: name and description, like any skill.
2. A short preamble and the rebuild recipe. The preamble says the skill builds itself
   before first use. The recipe is the same reusable block in every self-building skill
   (it is stamped in verbatim), and it refers by name to the sections below it.
3. Carried definition.
4. Binds.
5. Checks.
6. Build examples, grouped by behavioral move.
7. Acceptance examples.

The recipe comes first because the receiver runs it first. Everything after it is the
material the recipe reads.

## Carried definition

The content that defines good output, inlined in full: the voice description, the
rules, the reference material, the facts the behavior leans on. This is the authority
for correct output. It travels whole, baked into the file, so the output is reproduced
identically anywhere. You do not leave it as a blank for the receiver to fill, and you
do not link to a file the receiver lacks. You inline the content itself. When the
receiver's own settings fight the skill, this is what wins: the rebuild explicitly
overrides the local defaults, because the carried definition, not the local context,
is the authority.

## Binds

The genuinely local things the skill needs, each described in plain words ("a tool
that closes a ticket"), so the receiver can match each to its own equivalent. A bind
is a requirement, not a value: it names a capability and lets the receiver resolve it.
Empty when the skill needs nothing local. A pure-reproduction skill (a voice) has no
binds and produces the same output everywhere; an adaptive skill (a commit message
that closes a ticket) carries its method and binds the local tracker. If a required
bind cannot be matched on the receiver, the rebuild stops and names it rather than
guessing or substituting.

## Checks

The hard rules the output must obey, kept from the author's corrections as tests.
Mechanical where you can see it by eye (no em-dash, subject under sixty characters).
Behavioral where it takes judgment (leads with the point, reads like the same person
wrote it). The rebuild scores against the checks while it tunes, and every answer is
checked against them again before it is sent, because passing the build examples does
not by itself guarantee a clean answer on a new input.

## Build examples, grouped by behavioral move

Approved input-to-output pairs, where the output is what good looks like for that
input. They are grouped by the kind of thing the skill does, its behavioral moves (for
a voice: react to a foil, state a hard thesis, describe something bluntly). The rebuild
reproduces them: it writes instructions, runs them on each build input, scores the
output against the approved output and the checks, and rewrites until they pass.
Without build examples there is nothing to rebuild toward, and the rebuild is just
authoring. Grouping by move lets the rebuild see whether it reaches every kind of thing
the skill does, not just the average.

## Acceptance examples

A few approved pairs on novel inputs, held back and never used to rebuild. After the
build examples pass, the rebuild runs these and scores the output on tone and the
checks. Because these inputs were not used to rebuild, the score is the honest transfer
number: whether the skill actually generalized, not whether it memorized the build
examples.

## The carry vs bind decision

For every dependency the skill leans on, decide carry or bind:

- Carry it if a different value somewhere else would make the output wrong by the
  author's judgment. The definition of good output is always carried. Carrying is the
  static side: the same content travels bundled in the file and resolves identically
  everywhere.
- Bind it if the author wants it local, a genuinely per-target dependency that should
  differ on the receiver (which tracker closes an item, which deploy tool to call).
  Binding is the dynamic side: declared as a requirement, resolved against the receiver
  at rebuild time.
- Ask when unsure.

The failure to avoid is turning the thing that defines the output into a blank to fill
locally. That is the implicit dependency that breaks shared skills. Carry it.

## The validation model

Two gates, measured separately, plus an optional author-side check.

- Build examples are the install gate. The rebuild reproduces them on the receiver's
  machine and reports how many it matched, N of M. This is what the rebuild tunes
  toward, so it is necessary but not sufficient: matching the build examples shows the
  rebuild converged here, not that it transfers.
- Acceptance examples are the transfer score. They are held back from the rebuild and
  run only after the build examples pass, scored on tone and on the checks. Because
  the rebuild never saw them, their score is the honest measure of whether the skill
  generalized to new input. This is the number the receiver is shown.
- Author-side leave-one-out is optional, and only meaningful with several examples per
  move. Before shipping, the author can rebuild against a clean or different setup and
  rotate a hold-out within a move that has several examples, to flag where coverage is
  thin. Do not use leave-one-out as the main gate on a small, diverse set: holding out a
  move whose only example you removed measures redundancy, not transfer, and punishes
  the diversity you want. The held-back acceptance examples are the real transfer
  measure; leave-one-out only points at which move needs more examples.

## What the receiver sees

One of three plain outcomes, in one line:
- Built: the build examples matched and the acceptance test scored. Use it.
- Honest-failure: the rebuild could not reach the author's quality here, with the
  closest it got and the specific gaps. They know not to trust it, and why.
- Cannot-build: a required bind is missing, named. It stops instead of producing
  something wrong.
