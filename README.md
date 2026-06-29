# skillc

A skill that works great for you often comes out worse for someone else, because while
you were getting it right it quietly started leaning on your setup: your saved
instructions, your memory, your tools. skillc ships a skill as one self-building file
that rebuilds itself on whoever receives it and checks its own output against examples
you approved, so it either reproduces your quality or says plainly that it could not.
Like a self-extracting archive: the file you send contains both the contents and the
unpacker.

## Use it

skillc is itself a skill. Install it so Claude can run the builder:

    git clone https://github.com/baron-3dl/skillc ~/.claude/skills/skillc

**Author a shareable skill.** Do this in Claude Code, where your working skill, your
CLAUDE.md, your memory, and your tools all live, because the builder runs your skill in
that real setup to harvest examples. Tell Claude:

    build a self-building skill from <your skill>

Claude follows `seed/builder.skill.md`: it lifts your skill, runs it on a handful of
inputs you pick (including the break-prone ones), and shows you each output. You
approve, edit, or reject each one (the only manual step). It buckets the approved pairs
by behavioral move, holds a few back as acceptance examples, declares any genuinely
local dependencies as binds, distills your corrections into checks, and writes one
file: `<name>.selfbuild.SKILL.md`.

**Share it.** Send that one file. There is nothing else to ship. The receiver drops it
in `~/.claude/skills/<name>/`, uploads it on the claude.ai skills page, or keeps it in
a repo's `.claude/skills/`.

**Use one you received.** Install it and use the skill normally. The first time, before
its first answer, it runs its own rebuild recipe (`seed/rebuild.skill.md`): it resolves
any binds against your tools, rebuilds its instructions against the author's build
examples in your session, scores the held-back acceptance examples, and states one line:

    Built. Build examples matched 4 of 4, acceptance score 0.9. Ready.

or, honestly, `Built, but could not reach the author's quality here ...` with the gap,
or `Cannot build: this skill needs <tool>, which is not available here.` Then it
answers, checking each answer against the checks before sending.

---

## Why this exists

A finished `SKILL.md` behaves like a dynamically-linked binary: as you develop it, it
picks up undeclared dependencies on your context, and on anyone else's machine those
resolve to something different or to nothing. It does not fail loud like a missing
shared library; it just quietly produces the wrong thing. The fix is to ship source
that rebuilds in place, declaring every dependency on purpose: carry the ones that
define the output (bundled in, the same everywhere), bind the ones that are genuinely
local (resolved against the receiver, and failed loud when missing).

## How it works

**The author (one sitting, one manual step).** You point the builder at your working
skill, hand it a few real inputs, and it runs your skill in your setup and shows you the
outputs. You approve, edit, or reject each (you never write a gold answer from scratch;
you bless the good ones). Approved pairs become **build examples**, grouped by behavioral
move; a few novel ones are held back as **acceptance examples**. The quality you get is
proportional to how many good examples you put in. That is your lever.

**What gets shipped** is one file containing: the definition of good output inlined in
full; any local dependencies as binds in plain words; the build examples; the held-back
acceptance examples; the checks (the hard rules, kept from your corrections); and the
rebuild recipe.

**The receiver**, on first use, runs the recipe before answering: resolve binds (stop and
name any required one that is missing), rebuild instructions until the build examples
reproduce, override any local setting that fights the skill (the carried definition is
the authority), acceptance-test the held-back examples for the honest transfer score,
report one line, cache, then run, checking every answer against the checks before sending.

**What the receiver sees** is one of three outcomes:
- **"Built. Build examples matched N of M, acceptance score 0.84. Ready."** Use it.
- **"Built, but could not reach the author's quality here. Closest: [text]. Missing: [the gaps]."** Honest failure; they know not to trust it, and why.
- **"Cannot build: this skill needs [tool], which is not available here."** Stops instead of producing something wrong.

**Who pays what.** The author pays once: approving examples, and an optional pre-ship
check (rebuild against a clean setup, report the score). The receiver pays a little on
first use, then caches. The expensive validation never runs on the receiver.

The full model, section by section, is in `FORMAT.md`.

## What is in the repo

- `SKILL.md`: how Claude operates skillc.
- `FORMAT.md`: the self-building file, section by section, and the carry/bind and
  validation models.
- `seed/builder.skill.md`: the author-side procedure.
- `seed/rebuild.skill.md`: the canonical rebuild recipe, stamped into every shared file
  and runnable by hand. It is the one part that is trusted by reading, not by rebuilding.
- `examples/`: worked self-building skills you can read and run.
  - `voice.selfbuild.SKILL.md`: pure carry, no binds (a writing voice).
  - `explain-plainly.selfbuild.SKILL.md`: pure carry, two behavioral moves.
  - `commit-message.selfbuild.SKILL.md`: adaptive, binds the local ticket tracker.
  - `skillc.selfbuild.SKILL.md`: skillc hosting itself (the builder, self-building).
  - `*.proof.md`: the cold-run evidence for each.

The `*.skill.src` and `*.compile.md` files are the earlier two-step model (ship source,
compile separately) that the self-building file supersedes.

## Proven, cold

Every example was tested in a fresh session that had never seen this project, scored by
a blind judge:

- `voice` rebuilt itself and answered in voice at **0.90**. Under a session profile that
  said "be concise, professional, no profanity," it **overrode the profile** and still
  scored **0.90**; the same content with no rebuild recipe caved at 0.04.
- `explain-plainly` was produced end to end by the builder, then rebuilt itself cold and
  explained a bloom filter at **0.95**.
- `commit-message`, in a session with no tracker, **failed loud** ("Cannot build: this
  skill needs ticket-link"), instead of guessing a ticket and shipping a wrong commit.
- **skillc hosts itself.** Packaged as a self-building file, it rebuilt its own builder
  and emitted valid self-building skills across Opus, Sonnet, and Haiku, and under a
  hostile "summarize the boilerplate" profile it **overrode** while stamping the recipe
  verbatim. The loop closed: a file it emitted then rebuilt itself and ran correctly.
