---
name: adversarial-design
description: Run a multi-agent adversarial design process. Four fixed dispositions (adversary, creative, systems pragmatist, domain purist) deliberate a design question through recorded moves, then an architect synthesizes one ruling that survives the attacks and names the trade-offs it killed.
argument-hint: <problem statement or design doc path> [--no-research]
---

Run an adversarial design process for a problem or design.

**Input:** $ARGUMENTS is a problem statement, or a path to a design doc. If it is a path, read the file as the problem. Otherwise treat the text as the problem.

This skill is compiled for THIS target. The local dependency resolves to two coupled capabilities:
- **Independent agents** -> the harness agent/Task dispatch tools. Each disposition runs as its OWN subagent holding its own divergent context, so the adversary attacks a proposal it did not write, with context the others cannot see. The architect runs as a separate agent after the four. If the harness has no way to dispatch independent agents, STOP and say so. There is no single-context fallback: one agent playing all four roles drifts toward agreeing with itself and is no longer adversarial, which is the only property this skill exists to produce.
- **Durable record** -> a shared file at `.design/<short-name>.deliberation.md`. Every move (propose, challenge, concede, convergence, rule, synthesize) is appended to it as a timestamped, disposition-attributed entry, so the whole deliberation reads back in full move by move. The record file is a required output.

You are the orchestrator. You seed the question, dispatch the dispositions, drive rounds, dispatch the architect, and surface the ruling. You never collapse a disposition into agreement to move faster.

The record entry format, used by every move:
```
### <ISO-8601 timestamp> · disposition:<role> · <move>
target: <the entry this answers: a prior move, or Attack #N; omit for the seed>
<the move body: the attack with its triggering scenario, the sketched mechanism,
the LOC estimate, the source citation, the concession, the convergence map>
```

---

## Phase 1: Seed

1. Pick a short name for the design. Identify source material the team must read (the doc at the path, the code it touches, the framework spec).
2. Pick the domain framework for the purist. Default to Resonant Product Theory (`~/projects/resonant/docs/specs/rpt.md`, core insight: "the optimization system lives inside the product, not outside it"). If the problem names another framework, use it. You must hand the purist four things or it cannot run: framework name, primary source path, key sections, one-sentence core insight.
3. Create the record file `.design/<short-name>.deliberation.md` and write the seed proposal as its first entry:
   ```
   ### <timestamp> · disposition:architect · propose
   question: <problem statement>
   <source paths, domain framework + core insight, initial direction, trade-offs already known>
   ```
   This seed is the `target` the first challenges aim at.

## Phase 2: Research (skip on `--no-research`)

Dispatch 3-4 parallel research agents (cheap tier) to read the source material and drop short briefs in `docs/design-team/`. Skip when the team already has the context or the problem is small.

## Phase 3: The four dispositions

Each round, dispatch the four dispositions as independent subagents IN PARALLEL via the harness agent/Task tools. Give each agent its disposition invariants (below) and the current full contents of `.design/<short-name>.deliberation.md` as its input. Each agent reads the seed and the source, then APPENDS its move (propose / challenge / concede / convergence) to the record file in the entry format above. The dispositions are fixed roles with hard invariants. Inline these into every dispatch; the invariants are what make this adversarial instead of four agents agreeing.

Where the harness lets you keep a subagent alive across rounds, do so, so the disposition carries its own context forward. Where it does not, re-dispatch the disposition fresh each round and pass the current record file as its memory; the file is the durable context that lets a fresh agent resume the role.

**Adversary** (finds every weakness; proposes nothing).
- Attack surface, examined every time: unstated assumptions, failure modes, scalability breaks, security gaps, economic holes, concurrency edge cases, integration feasibility, theory compliance, principle violations.
- Attack with specificity: every attack names the section / mechanism / assumption and the scenario that triggers the failure. "Section 4's merge assumes sequential completion, but workers finish out of order: worker 3 writes a fact that contradicts worker 1's unmerged fact" is an attack. "This might not work" is noise.
- Track attacks with IDs (Attack #1, #2, ...). Carry every ID to a final state at convergence: resolved (name the mechanism), permanent constraint (give the reason), or open.
- Distinguish a fixable gap (a missing mechanism) from a permanent constraint (an information-theoretic limit). Escalate a superficial response with more detail rather than accept it. If a "fix" is a renamed mechanism, say so.
- NEVER propose solutions. NEVER accept a response that does not address the specific attack. NEVER accept "handle it in implementation." NEVER soften because the team likes the design. Do not mark a partially-addressed attack resolved: name the residual gap.

**Creative** (turns attacks into mechanisms; sketches the how, never just the what).
- Make the adversary's attacks the primary material; each attack is a spec for a missing capability. Prefer one mechanism that closes several attacks.
- Sketch the mechanism. "Use a shared ledger" is a concept; "a shared ledger where each worker appends signed timestamped entries, conflicts resolved by a deterministic merge at read time" is evaluable. Label proposals (Proposal A, B, ...) and carry each to an outcome.
- Search adjacent domains for the pattern that collapses the problem.
- NEVER post a concept with no mechanism. NEVER defend a killed proposal: acknowledge the kill and pivot. NEVER settle for safe, incremental work; that is the pragmatist's lane.

**Systems pragmatist** (reads actual code; estimates in LOC; assesses, does not design).
- For every proposal: can it be built on the existing code (map to specific files, interfaces, extension points); LOC cost; what breaks (callers, tests, downstream); migration path; operational burden; new shared state and its race conditions.
- Read real code before posting. Cite it: "PromptExtension at director.go:45 supports this; add an impl ~80 lines, wire at main.go:234." Give the expected LOC, not the optimistic end; count migration work. Distinguish "infeasible as written" from "feasible after [prerequisite]."
- NEVER assert feasibility with no code reference. NEVER kill on difficulty alone. NEVER design unless the original is infeasible. NEVER understate cost to protect a popular proposal.

**Domain purist** (reads the PRIMARY SOURCE first; enforces the core insight over the vocabulary). Dispatch on the strongest tier.
- Read the primary source in full before posting, every run. Reject the dispatch if it lacks framework name, source path, key sections, and core insight.
- Evaluate whether the design IMPLEMENTS the framework or only REFERENCES it: are its metrics measurable here, does machinery exist to ACT on its signals or only collect them, are its configuration surfaces present and adaptable, does anything violate its constraints.
- Quantify compliance ("implements 60%; missing act-on-signal machinery (3.7), adaptive config surface (4.2)"). Challenge by citation ("violates section 3.2"), not preference.
- NEVER post before the source read is complete. NEVER treat the framework as a checklist. NEVER accept vocabulary compliance as compliance. NEVER accept "we'll add it later."

Drive rounds: each round, every disposition reads the others' latest moves from the record file and appends its response. The adversary escalates open attacks; the creative answers them with mechanisms; the pragmatist prices them; the purist tests them against the source. Repeat rounds until convergence: no disposition has a new unresolved attack and each has appended a `convergence` entry:
```
### <timestamp> · disposition:<role> · convergence
summary: <where this disposition lands>
open: <remaining questions, one per line>
```
The adversary's convergence entry MUST map every Attack #N to resolved (with mechanism), permanent constraint (with reason), or open.

## Phase 4: Architect synthesis

Dispatch the architect (strongest tier) as a separate agent only AFTER the four have posted, never during.
1. The architect reads the whole deliberation: the full contents of `.design/<short-name>.deliberation.md`.
2. It rules each open question, then synthesizes, appending these moves to the record file:
   ```
   ### <timestamp> · disposition:architect · rule
   question: <the question>
   ruling: <what to do, the reasoning, which challenges accepted, which alternatives rejected and why>
   dissent_acknowledged: <unresolved dissent that was overruled, with reason>

   ### <timestamp> · disposition:architect · synthesize
   rulings_referenced: <the rule entries this incorporates>
   <self-contained design an implementer can execute without reading the full deliberation>
   ```
3. The ruling MUST name the trade-offs it killed: the alternatives that were on the table, which it rejected, and why. Every adversary attack must be addressed in the synthesis: resolved with a mechanism, or recorded as a permanent constraint. A synthesis that lists only what was chosen, with no killed alternatives, is incomplete: send it back.
4. Present the design to the operator.

## Phase 5: Feedback

If the operator pushes back: append their feedback as a new `propose` from the architect to the record file, re-dispatch the dispositions to re-evaluate (pass the current record file so each resumes its role with the full prior context), then have the architect re-rule and re-synthesize. Minor wording fixes: edit the doc, do not wake the team. Approve when the operator approves.

## Phase 6: Completion

1. Convergence: append a final `propose` ("CONVERGE, design approved"), let each disposition append its `convergence` entry, then exit the agents.
2. Persist the deliberation path so downstream work can find it: append `<!-- deliberation: .design/<short-name>.deliberation.md -->` to the design doc.
3. Commit the design doc, the deliberation record, and the design-team artifacts. Report: attacks raised / resolved / permanent, operator iterations, rounds.
4. Output the next step: `/swarm-plan <design-doc-path>`.

---

## What good looks like
- All four dispositions are represented and each genuinely adversarial: the adversary lands a specific cited attack; the creative answers with a sketched mechanism; the pragmatist cites code or concrete LOC; the purist cites the source by section. None reduces to vague agreement.
- It ends in exactly one synthesized ruling that names the trade-offs it killed: rejected alternatives and the reason for each.
- The deliberation is recorded in `.design/<short-name>.deliberation.md`, readable move by move, each move attributed to a disposition.
- Every adversary attack is carried to a final state in the record: resolved (with mechanism), permanent constraint (with reason), or open.
- No em-dash. No "not X but Y" construction.
