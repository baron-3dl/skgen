# skillc

## The problem
A skill that works great for you often comes out worse for someone else. While you
were getting it right, it quietly started leaning on your personal setup: your saved
instructions, your memory, the tools you have. The other person does not have those,
so the output drifts, and nothing warns them. It just gets quietly worse.

## The idea
Do not ship the finished skill. Ship a file that rebuilds the skill on the other
person's machine and checks its own output against examples you approved. It either
reproduces your quality, or it tells them plainly that it could not. Like a
self-extracting archive: the thing you send contains both the contents and the
unpacker.

---

## 1. What the author does (one sitting, one manual step)
You already have a skill that works for you. You run the builder and:

1. Point it at your working skill.
2. Hand it a few real inputs you care about, including the ones where it tends to break.
3. It runs your actual skill, in your setup where it works, on those inputs and shows you the outputs.
4. You approve, edit, or throw out each output. The ones you approve become the **examples** (approved input/output pairs). This approval is the only hand work in the whole process. You never write a "correct answer" from scratch; you bless the good ones your skill already produces.
5. It collects a few **extra inputs** the same way and sets them aside, unused, as an acceptance test.

You end up with two groups:
- **Build examples**, grouped by the kind of thing the skill does.
- **Acceptance examples**, held back and never used to build, only to test.

The quality you get is proportional to how many good examples you put in. That is
your lever, not a number we impose.

## 2. What data gets produced
One self-contained file. Inside it:

- **The definition of good output**, in full: the actual content (the voice description, the rules, the reference material, whatever defines a good result). Plain text, included, not a link.
- **A list of any genuinely local things it needs**, in plain words ("a tool that closes a ticket"), so the other side can match them to their own tools. Often this list is empty.
- **The build examples** (input to approved output), grouped by type.
- **The acceptance examples**, kept separate.
- **The checks**: the hard rules the output must follow (no em-dashes, lead with the point, and so on).
- **The rebuild recipe**: short instructions telling the receiving machine how to rebuild and test itself.

## 3. What gets shipped
That one file. It is an ordinary skill file, so it travels the way skills already
do: drop it in the skills folder, upload it on the web app's skills page, or just
send it. No service, no account, no registry, no special infrastructure. The only
thing unusual about it is that it carries its own rebuild-and-test recipe.

---

## 4. What happens on the receiver's side
The first time they use it, before it answers anything, the file runs its recipe:

1. **Check for the local tools it needs.** If it says it needs "a tool that closes a ticket," it looks for the receiver's equivalent. If something required is missing, it stops and names what is missing. It does not guess and it does not silently substitute.

2. **Rebuild.** It writes instructions for itself that make the receiver's AI reproduce the approved build examples. It tests them: generate output for each example, compare to the approved output, and where it misses, rewrite the instructions and try again, until the examples come out right or it has shown they cannot here. This runs in the receiver's real environment, so it accounts for the receiver's own saved instructions and settings. If those fight the skill (say they have "always be formal, no slang" turned on), the rebuild explicitly overrides them, because the author's definition is the authority, not the local defaults.

3. **Acceptance test.** Once the build examples come out right, it runs the held-back acceptance examples, the ones it never saw while rebuilding, and scores whether the output lands in the same quality and obeys the checks. Because these were not used to rebuild, this is the honest "did it actually transfer" number, not "did it memorize the examples."

4. **Report.** It states plainly what happened (next section).

5. **Run.** From then on it uses the rebuilt instructions, and on every real answer it checks the output against the hard rules before sending, fixing any violation. It saves the rebuilt version so it does not redo the work every time.

## 5. What the receiver sees
One of three plain outcomes:

- **"Built. Build examples matched N of M, acceptance score 0.84. Ready."** Use it.
- **"Rebuilt, but could not reach the author's quality here. Closest it got: [text]. Missing: [the specific gaps]."** Honest failure. They know not to trust it, and why.
- **"Cannot build: this skill needs [tool], which is not available here."** Stops on a missing dependency instead of producing something wrong.

---

## Who pays what
- **The author pays once, up front:** approving examples, and an optional pre-ship check where the builder rebuilds against a clean setup and reports the acceptance score, so they know it will transfer before sending. If they provided several examples per type, the builder can also run a rotating leave-one-out check that points at which type is thin and needs more examples. Heavy, and author-only.
- **The receiver pays a little on first use:** the rebuild does a few rounds of generate-and-check, then caches the result. The expensive validation never runs on their side; they get the cheap single acceptance score and the per-answer rule check.

That is the whole system: approve examples, ship one file, it rebuilds and grades
itself where it lands, and it tells the truth about whether it worked.

---

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

## What is in the repo

- `SKILL.md`: how Claude operates skillc.
- `FORMAT.md`: the self-building file, section by section, and the carry/bind and
  validation models.
- `seed/builder.skill.md`: the author-side procedure (lift, harvest-and-approve, bucket,
  declare binds, distill checks, emit).
- `seed/rebuild.skill.md`: the canonical rebuild recipe, stamped into every shared file
  and runnable by hand.
- `examples/`: worked self-building skills you can read and run.
  - `voice.selfbuild.SKILL.md`: pure carry, no binds (a writing voice).
  - `explain-plainly.selfbuild.SKILL.md`: pure carry, two behavioral moves.
  - `commit-message.selfbuild.SKILL.md`: adaptive, binds the local ticket tracker.
  - `voice.selfbuild.proof.md`: the cold-run evidence.

The `*.skill.src` and `*.compile.md` files are the earlier two-step model (ship source,
compile separately) that the self-building file supersedes.

## Proven, cold

Every example was tested in a fresh session that had never seen this project, scored by
a blind judge:

- `voice` rebuilt itself and answered in voice at **0.90**. Under a session profile that
  said "be concise, professional, no profanity," it **overrode the profile** and still
  scored **0.90**; the same content with no rebuild recipe caved to the profile at 0.04.
- `explain-plainly` was produced end to end by the builder (which rejected one harvested
  output as jargon and rewrote it), then rebuilt itself cold and explained a bloom filter
  at **0.95**.
- The per-answer check caught and rewrote a banned construction on novel prompts, twice.
- `commit-message`, installed in a session with no tracker, **stopped and reported**
  "Cannot build: this skill needs ticket-link (the local issue tracker), which is not
  available here," instead of guessing a ticket and shipping a wrong commit.
