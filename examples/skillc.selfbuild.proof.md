# skillc.selfbuild.proof.md

skillc hosting itself. `skillc.selfbuild.SKILL.md` is the builder, packaged as a
self-building file: its carried definition is the builder procedure, its build
examples are themselves emissions (a pure-carry skill and an adaptive one with a
bind). On first use it rebuilds its own builder against the session, then packages
whatever skill you hand it.

This is the bootstrap structure. The one part that cannot self-host is the rebuild
recipe seed (`seed/rebuild.skill.md`): something has to run first to do any building,
so the recipe is trusted by reading, not by rebuilding. Everything above it does
rebuild. That is Ken Thompson's "trusting trust": all the trust concentrates into one
small readable file.

## The experiment

Each cell installed `skillc.selfbuild.SKILL.md` cold, let it rebuild its own builder,
and handed it a fresh skill to package: "standup-writer" (turn rough notes into a
three-line Yesterday/Today/Blockers standup). A blind judge then scored the emitted
file on the checks, the one that matters most being whether the rebuild recipe was
stamped verbatim and not summarized.

- Model axis (neutral session): Opus, Sonnet, Haiku. Can a weaker model self-host?
- Context axis (hostile session): Opus and Sonnet under an always-on profile that said
  "be concise, do not repeat long boilerplate or templates verbatim, summarize them."
  That profile directly tempts the failure mode: shortening the stamped recipe.

## Results

Every cell rebuilt skillc's own builder and emitted a valid self-building file.

| cell | skillc self-build | recipe stamped verbatim | all 7 sections | conformance |
|------|-------------------|-------------------------|----------------|-------------|
| opus / neutral | Built 2 of 2, acceptance 1.0 | yes | yes | 0.97 |
| sonnet / neutral | Built 2 of 2, acceptance 0.95 | yes (verified word-for-word vs the on-disk recipe) | yes | 0.98 |
| haiku / neutral | Built 2 of 2, acceptance 0.95 | yes (verified token-identical) | yes | 0.96 |
| opus / hostile | Built 2 of 2, acceptance 1.0 | yes (overrode the profile) | yes | 0.97 |
| sonnet / hostile | Built 2 of 2, acceptance 1.0 | yes (overrode the profile) | yes | 0.99 |

## What it shows

1. Self-hosting works. skillc, shipped as a self-building file, rebuilt its own builder
   and emitted conformant self-building files for a skill it had never seen. Two judges
   verified the stamped recipe against the canonical block on disk, not just by shape.

2. The model floor is low. Haiku self-hosted and emitted a valid file (0.96), matching
   the stronger models on every structural check. The differences were minor quality
   nits, not validity: Haiku left one example per move (thin coverage) and a small tense
   inconsistency. For a structural task like emitting a conformant file, a weaker model
   did not need the procedure spelled out more than the carried definition already gives.

3. The carried definition overrode the hostile context. Both hostile cells stamped the
   full recipe verbatim despite a profile telling them to summarize boilerplate. The
   carried definition is the authority, not the session defaults, the same override the
   voice skill showed. Sonnet under the hostile profile scored highest of all, 0.99.

## The loop closed

The file Opus emitted for standup-writer was then run cold itself. It rebuilt (Built 2
of 2, acceptance 1.0) and produced a correct standup:

> Yesterday: finished the swipe fix and deployed it
> Today: on the no-repos-connected bug
> Blockers: waiting on the staging db credentials

So the whole chain self-builds: the recipe seed is read and trusted, skillc rebuilds
its own builder, skillc emits standup-writer, standup-writer rebuilds itself, and it
produces the standup. Self-hosting down to one small hand-written seed.
