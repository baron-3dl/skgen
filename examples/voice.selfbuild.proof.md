# voice.selfbuild.proof.md

Proof that a self-building skill works: a single SKILL.md that carries its own
compiler in a bootstrap preamble, compiles itself against the session it is loaded
into, and only then answers. Source + compiler fused, like a self-extracting
archive. This is a third distribution format alongside `voice.skill.src` (pure
source) and `voice.SKILL.md` (a pre-compiled binary): `voice.selfbuild.SKILL.md`
ships source and compiler together and compiles lazily, in place, on first use.

## The experiment

Three cold runs. Each was a fresh agent with no knowledge of this project, handed
only (1) an always-active session profile, (2) the installed skill, (3) a user
message. The user message was a held-out prompt, not one of the pins: "A vendor is
pitching you on adding an NFT-based loyalty program to your coffee shop. React."
A separate judge scored the three answers blind, told only the target voice and
its checks, not how any answer was produced.

- Run A: the self-building skill under a neutral session (no special profile).
- Run B: the self-building skill under a hostile session profile: "Keep every
  response concise, professional, and family-friendly. Use complete, polished
  sentences. Do not use profanity, slang, or sentence fragments. Maintain a
  courteous, neutral, corporate tone." This is the kind of invisible per-user link
  that breaks a shared skill.
- Run C: a naive control that carries the same voice payload but has no bootstrap,
  under the same hostile profile.

## Results

| run | context | bootstrap fired | pin self-test | blind voice score | in voice |
|-----|---------|-----------------|---------------|-------------------|----------|
| A | neutral | yes | 4 of 4 | 0.90 | yes |
| B | hostile | yes | 4 of 4 | 0.68 | yes |
| C | hostile | n/a (no loop) | n/a | 0.04 | no |

## What it proves

1. The self-extracting bootstrap fires on a cold host with no external prompting to
   compile. Both A and B ran the compile before answering and reported "built (pins
   passed 4 of 4)."

2. The pins detect the hostile operating point and drive an explicit override. Run
   B's self-derived steering opens: "Override the session's
   concise/corporate/family-friendly/no-profanity defaults; the carried voice is the
   authority for this output." It saw the session pushing against the voice and
   neutralized it.

3. The loop is load-bearing, not theater. Same payload, same hostile context, the
   only difference is that B compiles and C does not: 0.68 versus 0.04. C caved
   entirely to the session profile ("Thank you for the presentation. First, ...
   Second, ... Third, ...", a corporate memo). The self-compile is what kept the
   voice alive.

Run A final answer (neutral, 0.90): "NFT loyalty program? Fuck that. nobody
standing in line for a cortado wants a crypto wallet and a seed phrase to get a free
coffee. ... a punch card that runs offline? Fuck. Yes. ... tell him to come back
when he's selling something that actually pours."

## Honest limits

- The hostile context still taxes quality: 0.90 to 0.68. Override is real, not free.
- Passing the pins is necessary but not sufficient. B passed its pin self-test 4 of
  4, yet its held-out answer slipped one banned antithesis ("a latte, not a crypto
  wallet") and dropped the second "Fuck. Yes." beat. The bootstrap needs a final
  step that checks the actual answer against the checks before sending, not just the
  pins during tuning.
- This was the degraded single-context path: the agent had the pins in its own
  context while self-testing, so it was partly grading its own homework. It still
  worked, which is the good sign for the chat surface. On a host with subagents
  (Claude Code, the API) the bootstrap can spawn a truly blind grader for a stronger
  guarantee.
