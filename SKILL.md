---
name: skillc
description: Author a skill as a single self-building file. Use when the user wants to turn a skill that works for them into a shareable file that rebuilds and tests itself on whoever receives it.
---

skillc ships a skill as one self-building file: the source plus the recipe to
rebuild it, like a self-extracting archive. The engine is Claude itself, no separate
program and no service. The carried definition is the authority for correct output,
and the rebuild recipe is the instructions Claude follows on the receiver to
reproduce the author's approved examples before the first answer. Read `FORMAT.md`
for the file's data model and the carry/bind distinction before you build.

## Build a shareable skill

The user made a skill the normal way and wants to share it. Follow
`seed/builder.skill.md`. In short:

1. **Lift** the skill: its intent, the corrections the author gave, and the behavior
   the conversation converged on. Read the author's local context to see what the
   behavior leans on.
2. **Classify** each dependency carry vs bind. Carry it when a different value on
   someone else's machine would make the output wrong by the author's judgment, so
   it must travel inlined in full. Bind it when the author wants it local (their
   tracker, their paths). Ask when unsure.
3. **Harvest and approve examples**, the only manual step. Get a few real inputs the
   author cares about, including break-prone ones, run the author's working skill on
   them in the author's own setup, and show the outputs. The author approves, edits,
   or rejects each. Approved pairs become examples.
4. **Bucket** the build examples by the kind of thing the skill does, the behavioral
   move, and set aside a few approved pairs on novel inputs as acceptance examples,
   held back and never used to rebuild.
5. **Declare** the binds in plain words. **Distill** the corrections into checks,
   mechanical where a rule is visible by eye and behavioral where it takes judgment.
6. **Emit** the self-building file: the carried definition inlined in full, the
   binds, the checks, the build-example buckets, the acceptance examples, and the
   rebuild recipe from `seed/rebuild.skill.md` embedded at the top.

The failure to avoid is turning the thing that defines the output into a blank to
fill locally. Carry it.

## The shared file rebuilds itself, so there is no separate build step

Do not hand someone a finished result. The file you emit carries its own rebuild
recipe (the canonical procedure in `seed/rebuild.skill.md`), so the receiver runs
nothing by hand. The first time they use the skill, before its first answer, the
embedded recipe rebuilds the skill against the receiver's model and environment,
tests it against the author's approved examples, scores the held-back acceptance
examples, and reports plainly: built (with the acceptance score), honest-failure
(the closest it got and the specific gaps), or cannot-build (the missing required
bind, by name). It caches the rebuilt instructions so it does not redo the work, and
it checks every answer against the checks before sending. The receiver drops the
file in their skills folder or uploads it the way any skill travels. No service, no
registry, no build command on their side.
