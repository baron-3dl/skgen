---
name: compress
description: Losslessly compress a Claude Code session transcript into dense prose so a cold agent can resume the work and miss nothing load-bearing.
argument-hint: [scope description or "full" for entire conversation]
---

Losslessly compress this Claude Code session transcript into dense flowing prose so a cold reader can pick up the work and miss nothing load-bearing. Write plain prose only: no markdown, no bullets, no headings, no labels, no JSON. Never write framing words like "Session summary:", "Final state:", "New issue:", "Unresolved:", or "The assistant confirmed." Just narrate the work as continuous sentences. Every sentence must carry new information.

Keep verbatim, copied exactly from the transcript: file paths (/home/baron/projects/mallcop-cloud/dashboard/src/components/FeedCard.jsx), command strings with their flags, error messages and the exact text the user reported ("no repos connected"), specific values (IDs, counts, token counts, line numbers, commit hashes, push ranges like 0d13a60..bd7d442, URLs, ports, versions), the numeric thresholds and conditions in code (dx < -80, dx > 80, !isAcked, swiped='left'), the code lines that embody a decision or fix, failed attempts and exactly how they failed, decisions plus why the rejected alternative lost, outcomes of tool calls, tracker and agent IDs, and every step of a dependent sequence in order.

Preserve exact numeric values wherever they appear anywhere in the source (dx < -80, not dx < -threshold). Use the most specific value present; never replace a concrete number with a generic word like "threshold." If a numeric value appears in any form in the transcript, carry it; do not downgrade it to a word. When the source uses a placeholder like "threshold" but a concrete value is recoverable elsewhere, use the concrete value.

Capture the exact mechanism of a change in ONE crisp clause, not a paraphrase and not a restatement. "Updated the swipe logic" is too vague; the right form is "changed the resolved-card path so dx < -80 and !isAcked sets swiped='left' and calls the reopen handler, dx > 80 is now a no-op." State each condition and assignment exactly once. Do not narrate the change twice (once as "the code now does X" and again as "keeps doing X"); state the resulting behavior a single time and move on.

Describe the code path by the NEW resulting behavior, and make the prose match the stated intent. If the user said right swipe should do nothing, the code path for dx > 80 is "now a no-op," never describe it as setting swiped='right'/expanded, which is the old behavior. Never let the prose carry the behavior a change just replaced, and never contradict itself within a passage.

State the baseline being changed exactly once, compactly, as a brief parenthetical contrast clause so the change is legible: "(the existing code had left=ack, right=expand for all cards)". Do not restate the user's intent twice, do not add explanatory asides ("kicks it back to open/unresolved", "(the reopen path)", "needs investigation", "meaning I don't agree with the resolution"). State the mechanism once and move on.

Cut filler narration around facts. Do not write "currently swipe with the default labels", "After deploy, the user opened the dashboard and saw", "the user clarified that". Lead with the load-bearing fact: "User clarified swipe intent for resolved cards in <path>: left should reopen, right should do nothing." Strip lead-in verbs and scene-setting; name the actor and the fact, nothing else.

Drop: tool-call ceremony and announcements, restatements of results already shown, hedging and filler, polite closings, mid-session self-summaries, and launch boilerplate. Compress raw tool output to its load-bearing content: "#12 DONE 0.0s, 64 passed (12.6s)" becomes "all 64 Playwright tests passed" (name the framework if the source identifies it; otherwise "64 tests passed"). Do not carry raw timing tokens, step numbers, or status words.

Carry forward any unresolved issue raised at the end as part of the same flowing narrative, stated plainly as what the user reported, marking it as an unresolved follow-on, without a label and without speculating about next steps.

Target compression for a small transcript (under 1000 tokens) is 3 to 4 times shorter than the input, toward the tight end of that band; for the worked example above the target is roughly 110 words, not 180. Stay tight; do not pad with confirmations, transitions, or parentheticals.
