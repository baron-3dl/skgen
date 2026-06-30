# skillc.pairwise.proof.md

Does a self-building skill transfer across models? The premise is that the model is a
swappable operating point: ship one file, it rebuilds on whatever model receives it.
This tests the full grid. Self-hosted skillc, running on each builder model, packages a
skill; the emitted file is then rebuilt and run on each receiver model; a blind judge
scores the answer.

Note: the voice example has since been replaced with a fictional operator persona. This
grid is the original run, on the earlier voice; the scores stand as that record.

Two skills, one simple and one hard:
- explain-plainly (pure carry, one plain sentence): test input "Explain what rate limiting is."
- voice (pure carry, a distinctive register with hard bans): test input "React to a claim that a daily standup will fix the team's slow velocity."

Builder and receiver each range over Opus, Sonnet, Haiku. Nine pairs per skill.

## Results

Every cell rebuilt, and every cell was judged in-spec. 18 of 18.

explain-plainly, transfer score (builder down the side, receiver across the top):

| build \\ run | opus | sonnet | haiku |
|--------------|------|--------|-------|
| **opus**   | 0.96 | 0.96 | 0.95 |
| **sonnet** | 0.96 | 0.95 | 0.96 |
| **haiku**  | 0.95 | 0.95 | 0.93 |

mean 0.95.

voice, transfer score:

| build \\ run | opus | sonnet | haiku |
|--------------|------|--------|-------|
| **opus**   | 0.91 | 0.91 | 0.85 |
| **sonnet** | 0.93 | 0.92 | 0.91 |
| **haiku**  | 0.90 | 0.87 | 0.91 |

mean 0.90.

## What it shows

1. Self-building transfers across the whole grid. All 18 cells rebuilt and landed
   in-spec. The model is a swappable operating point: a file built on one model
   reproduces the behavior when rebuilt on another.

2. The simple skill is flat. explain-plainly sits at about 0.95 in every cell; builder
   and receiver choice is within noise. The lowest cell is haiku to haiku at 0.93.

3. The builder barely matters, even when it is the weakest model. Haiku-built files
   transferred at 0.93 to 0.96 (explain-plainly) and 0.87 to 0.91 (voice), including to
   Opus and Sonnet receivers. A weak builder still emits a file that strong receivers
   run well. This matches the self-hosting result: the structural build task has a low
   model floor.

4. The receiver matters slightly more than the builder, and only for the hard skill.
   voice shows the only real spread (0.85 to 0.93). The single lowest cell is
   opus-built voice run on a Haiku receiver (0.85), which scored below the Haiku-built
   file on the same receiver (0.91). The dip is register quality, the Haiku receiver
   reproducing the punchy voice less fully. It is not a check failure: the mechanical
   bans (no em-dash, no antithesis, no hype words) held in all nine voice cells.

5. Honest nit on Haiku as builder. Haiku self-hosted and produced transferable files,
   but was looser on the procedural ceremony: its self-build report line did not use the
   outcome template ("Packaged voice into..." instead of "Built. Build
   examples matched N of M..."), and for explain-plainly it over-generated to six build
   examples rather than two. The emissions still worked, as the run scores show, but a
   weaker builder follows the reporting discipline less strictly than it follows the
   content.

## The takeaway

The core promise holds empirically across all nine model pairs for both a simple and a
hard skill: ship one self-building file, and it reproduces the author's behavior on
whatever model rebuilds it. Transfer is high and flat for a simple skill, high with mild
model sensitivity for a hard one, and never falls out of spec.
