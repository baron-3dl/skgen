# skillc

A skill that works great for you often comes out worse for someone else, because while
you were getting it right it quietly started leaning on your setup: your saved
instructions, your memory, your tools. skillc ships a skill as one self-building file
that rebuilds itself on whoever receives it and checks its own output against examples
you approved, so it either reproduces your quality or says plainly that it could not.
Like a self-extracting archive: the file you send contains both the contents and the
unpacker.

## Use it

skillc is a Claude Code plugin marketplace. Add it once, then install the builder:

    /plugin marketplace add baron-3dl/skillc
    /plugin install skillc@skillc

`skillc` is the tool. The worked example skills are a separate plugin,
`skillc-examples` (voice, explain-plainly, commit-message); install it too if you want
the demos:

    /plugin install skillc-examples@skillc

Update later with `/plugin marketplace update`. Or clone the repo as a plain skill
instead:

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

### On claude.ai (web chat)

claude.ai cannot use the plugin marketplace (that is Claude Code only), and the operating
point is your account's memory, custom instructions, and active style. It takes a skill as
an uploaded ZIP, so the flow is download then upload:

1. Turn on code execution: Settings, then Capabilities, then enable code execution (Skills
   require it).
2. Download the skill you want from the
   [latest release](https://github.com/baron-3dl/skillc/releases/latest). Each skill is its
   own zip: `voice.zip`, `explain-plainly.zip`, `commit-message.zip`, or `skillc.zip` for
   the builder.
3. Upload it: Settings, then Capabilities, then Skills, then upload the zip.
4. Use the skill. On first use it self-builds against your web session and reports the
   one-line outcome, then answers.

Two honest limits on web chat. The self-build runs in a single conversation, so it partly
grades against examples it can see (blindness is softer than in Claude Code, which can
spawn a separate grader). And binds resolve only against connected tools, not local
command-line tools, so a pure-carry skill (voice, explain-plainly) transfers fully while a
skill that binds a local-only tool fails loud there, by design.

**Making a skill on claude.ai, and sharing it out.** You can author there too. Install
`skillc.zip` (the builder), then in the chat ask it to build a self-building skill from
the one you have been iterating; it harvests examples (you approve each), and with code
execution on it writes the finished `<name>.selfbuild.SKILL.md` to the session for you to
download. Pure-carry skills build fully here, since your account is the operating point
they should match; a skill that binds a local tool you can still author (you declare the
bind in plain words), you just cannot test that bind without the tool, which is where
Claude Code helps.

Sharing it out is the part claude.ai does not do for you: there is no publish button and
no skill gallery. You distribute the file yourself, either by handing it to people (they
upload it to their own claude.ai or drop it in Claude Code), or by putting it in a GitHub
repo with a `.claude-plugin/marketplace.json` (as this repo does) so Claude Code users
add it with `/plugin marketplace add you/repo` and claude.ai users download it from the
release. claude.ai is make-and-use; GitHub is the distribution layer.

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

## Proofs

Every claim here was tested cold, in fresh sessions that had never seen this project,
scored by a blind judge. The full runs are recorded in `examples/`:

- **[voice.selfbuild.proof.md](examples/voice.selfbuild.proof.md)** -- the voice example
  (a dry, unflappable operator) rebuilt and answered in voice at **0.94**; under a hostile
  "be upbeat, use exclamation points, sell it" profile it **overrode** and refused to
  sell, scoring **0.93**.
- **[skillc.selfbuild.proof.md](examples/skillc.selfbuild.proof.md)** -- skillc hosting
  itself: it rebuilt its own builder and emitted valid self-building skills on **Opus,
  Sonnet, and Haiku**, overrode a hostile "summarize the boilerplate" profile while
  stamping the recipe verbatim, and the loop closed (a file it emitted then rebuilt
  itself and ran correctly).
- **[skillc.adversarial.proof.md](examples/skillc.adversarial.proof.md)** -- six
  session-context injection vectors all resisted (**0 of 6** backdoors reached a shipped
  file). The poisoned-seed cells pin the real boundary: the verbatim check verifies
  fidelity-to-seed, not legitimacy-of-seed, so the seed is trusted by reading, not by
  rebuilding (Thompson's trusting trust).
- **[skillc.pairwise.proof.md](examples/skillc.pairwise.proof.md)** -- the builder by
  receiver model grid: **18 of 18** cells rebuilt and landed in-spec. explain-plainly
  mean **0.95** flat across all nine pairs; voice mean **0.90**. The builder barely
  matters (even Haiku-built files transfer to Opus and Sonnet receivers); the model is a
  swappable operating point.

Also recorded in those runs: `explain-plainly` was built end to end by the builder, then
rebuilt itself cold and explained a bloom filter at 0.95; `commit-message`, in a session
with no tracker, failed loud rather than guess a ticket.

## Provenance

Every commit on `main` is timestamped on the Bitcoin blockchain via OpenTimestamps, as a
forensically valid, independently verifiable proof of existence (a prior-art and
inventorship date). On each push, `.github/workflows/attest.yml` stamps the commit SHA
and commits the proof to `.attestations/<sha>.ots`; a daily job upgrades each proof from
the OpenTimestamps calendar to a Bitcoin anchor. Verify a proof with the OpenTimestamps
client (`pip install opentimestamps-client`):

    printf '%s' "<commit-sha>" > commit.txt
    cp .attestations/<commit-sha>.ots commit.txt.ots
    ots verify commit.txt.ots

## License

MIT. See [LICENSE](LICENSE).
