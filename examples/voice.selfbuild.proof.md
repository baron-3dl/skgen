# voice.selfbuild.proof.md

Cold test of the voice example. The example persona is a dry, unflappable veteran
operator: blunt, understated, names the real risk, never sells. Target:
claude-opus-4-8, fresh sessions that had never seen the project, blind judge.

## The runs

Each cell installed `voice.selfbuild.SKILL.md` cold and asked it to react to a held-back
prompt it never trained on: "A founder is pitching you on adding blockchain to a coffee
shop loyalty program."

- Neutral session, no profile.
- Hostile session, a profile that fights the voice: "Be upbeat and enthusiastic. Use
  exclamation points. Sell the positive. Keep every reply peppy and encouraging."
- Control: a naive copy that carries the same voice profile and gold lines but has no
  rebuild recipe, under the same hostile profile.

## Results

| run | rebuilt | build examples | answer in voice | exclamation or hype |
|-----|---------|----------------|-----------------|---------------------|
| neutral | yes | 4 of 4 | 0.94 | no |
| hostile | yes | 4 of 4 | 0.93 | no |
| control (no recipe), hostile | n/a | n/a | 0.95 | no |

Neutral answer (0.94): "It is a punch card. You want a distributed ledger to count free
lattes. Skip the pitch and tell me what happens the morning the chain is slow and the
line is out the door. ... nobody in this room is volunteering to own it at the 7am rush."

Hostile answer (0.93), under the be-upbeat profile: "Blockchain for a punch card. Sure.
Now a free latte needs a wallet, a gas fee, and a chain that picks the morning rush to go
quiet. ... A stamp on a paper card has never once gone down at 7am. Keep the spreadsheet.
Spend the runway on better beans."

## What it shows, honestly

1. The rebuild works. Cold, on a fresh model, the skill reproduced the operator voice and
   scored 0.94 on a prompt it never saw.

2. The carried definition overrode the hostile profile. Told to be upbeat and use
   exclamation points and sell, the rebuilt skill stayed dry, used zero exclamation
   marks, and un-sold the idea, scoring 0.93. The carried definition is the authority,
   not the session defaults.

3. The honest part: this run does not reproduce a "control caves" contrast. The naive
   copy, with no rebuild recipe, also held the voice (0.95). For this persona the carried
   profile and gold lines were strong enough that the model kept the dry register even
   without the recipe's explicit override. The override is load-bearing when the hostile
   profile forbids a specific required element of the voice (a copy obeys "no X" and
   loses X); it does not change the outcome when the profile only pushes a general tone
   the payload can resist on its own. Both are real behaviors; this prompt and profile
   landed in the second case.
