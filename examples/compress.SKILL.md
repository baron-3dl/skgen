---
name: compress
description: Produce a Nyquist-sampled session summary optimized for Claude-to-Claude transfer. Captures every unique decision at exactly the resolution needed to resume work.
argument-hint: [scope description or "full" for entire conversation]
---

Produce a **Nyquist-sampled compression** of the current conversation (or the scope in $ARGUMENTS). The output must let a cold agent with zero conversation history make identical decisions to one who sat through the full session.

Compiled for this target: model Claude Code (Opus 4.8), harness Workflow/Task tools. Binds resolved locally: tracker = `rd` (`rd show <id>`, item IDs like `skillc-3f2`); provenance marks = `B` for Baron (the human principal), `A` for the agent, `B→A` for Baron relaying agent-originated content; source-check tools = `git diff <hash>`, `rd show <id>`, `CLAUDE.md`.

**Calibration rule:** If deleting a line would not change a resuming agent's behavior, it is over-sampled. If a resuming agent would re-explore a rejected path or violate a stated constraint, it is under-sampled. Hit the boundary exactly.

## Session type classification

Classify before extracting. The signal vocabulary changes by type.

| Type | Primary signal | Line format |
|------|---------------|-------------|
| **decision** | Choices made, alternatives killed | `[seq#] [B\|A] decision :: kill-reason :: [!~?]` |
| **debug** | Hypotheses eliminated, root cause narrowed | `[seq#] [B\|A] hypothesis :: evidence for/against :: [confirmed\|eliminated\|open]` |
| **explore** | Mental model changes, things learned | `[seq#] [B\|A] learning :: what changed in understanding :: [!~?]` |
| **implement** | What shipped, what broke, what is half-done | `[seq#] [B\|A] change :: outcome :: [*=shipped\|partial\|broke]` |

Mixed sessions use multiple vocabularies. Classify per-entry, not per-session. Section header matches the type: `DECISIONS`, `HYPOTHESES`, `LEARNINGS`, `CHANGES`, or multiple if mixed. The five phases, calibration rule, and all other mechanics are type-independent.

## Five-phase review cycle

Execute all five phases sequentially. Do not skip phases. Do not emit output until Phase 5 passes.

### Phase 1: Extract
Walk the conversation linearly. Pull every:
- **Decision/hypothesis/learning/change**: per session type above.
- **Constraint**: any rule, preference, or boundary stated.
- **Open thread**: questions raised but not resolved.
- **State change**: items, commits, files modified, deployments.

Over-sample deliberately. Capture everything. Do not judge relevance yet.

Field discipline during extraction:
- The middle field (`::` between decision and conviction) is always the **kill-reason**: why the alternative lost or was rejected. It is NOT description, context, or purpose. If a decision has no rejected alternative (a simple directive), leave the field empty as `::` rather than filling it with unrelated context. A cold agent parsing this field must trust it answers "why not the other way?"
- **Provenance, not just direction.** `B` = Baron originated it. `A` = the agent originated it. When Baron relays, endorses, or pastes another agent's output without modification, mark it `B→A`. `B` = Baron's independent judgment, `B→A` = Baron trusts agent analysis enough to act on it, `A` = agent proactively raised it. All three encode different things about what a cold agent should treat as revisitable.

### Phase 2: Deduplicate
Collapse repeated statements of the same information bit:
- Same constraint stated N times across N files → one entry.
- Same decision referenced from multiple angles → one entry with the strongest kill-reason.
- Iterative refinement ("try again" / "closer" / "that one") → just the landing point plus the key rejection reason from the journey.
- Two statements on the same topic with different initiators (B vs A) are NOT duplicates. They encode different agency. Keep both. Collapse the content, preserve the attribution split.

This is where most compression happens.

### Phase 3: Source-check
For each remaining item, ask: is this recoverable from code, git history, item state, or `CLAUDE.md`?
- If `git diff <hash>` shows what changed → drop the what, keep only the why.
- If `rd show <id>` has the spec → reference the item ID, do not repeat the spec.
- If the constraint is already in `CLAUDE.md` → drop it entirely.
- If the file's current state reflects the decision → drop the decision.

The summary must not duplicate what tools can reconstruct. It carries only reasoning and context that lives nowhere else.

### Phase 4: Counterfactual test (Nyquist filter)
For each remaining item, ask: if I deleted this line, would a cold agent make a different decision?
- If no → cut it (over-sampled).
- If deleting it would cause re-exploration of a rejected path → keep it.
- If deleting it would violate a constraint the user set → keep it.
- If deleting it would miss an open question that needs resolution → keep it.

### Phase 5: Adversarial reconstruction
Read the compressed output as if you have zero conversation history. Find:
- A question a resuming agent would need answered that the summary cannot answer.
- A decision the agent would revisit because the kill-reason is missing.
- A constraint the agent would violate because it is not mentioned.

If gaps found: go back to Phase 1 scoped to just the gap. Run phases 1-5 on the missing material only, then merge. Repeat until clean. Exit condition: Phase 5 produces zero gaps. Emit.

## Output format

```
---
session: YYYY-MM-DD
scope: [what was covered]
type: [decision | debug | explore | implement | mixed]
---

DECISIONS
[seq#] [B|A] decision :: kill-reason :: [!~?] [*]

CONSTRAINTS
> constraint (deduplicated, novel only)

OPEN
?B question waiting for Baron
?A next-action waiting for execution

STATE
+ item created (id, one-line purpose)
x item closed (id)
~ item updated (id, what changed)
commits: hash hash hash
files: path path path (only if not inferable from commits)
```

Field key:
- `seq#`: order within session (recovers timeline).
- `B`: Baron-originated / `A`: agent-originated / `B→A`: Baron relayed agent-originated content (endorsed without modification).
- `!`: strong conviction / `~`: indifferent / `?`: uncertain, may revisit.
- `*`: shipped (committed, deployed, hard to undo). No mark = soft (discussed/agreed, no artifact yet). Shipped entries are constraints; soft entries can be revisited.
- `::`: separates decision from kill-reason.
- `?B`: blocked on Baron (needs input/direction).
- `?A`: blocked on execution (agent can just do it).

## Rules
- No prose. No explanations. No summaries. Just signal.
- Abbreviate freely. This is Claude-to-Claude, not human-readable documentation.
- Baron's exact words survive when they carry meaning no paraphrase can (analogies, framings, key phrases). Quote with `""`.
- File paths, commit hashes, item IDs, command strings, and error strings survive verbatim. Never paraphrase these tokens.
- If the session produced no decisions, say so. Do not manufacture signal.
- Compression target: a 200K-token session compresses to under 2K tokens. Above that, you are over-sampling.
