---
name: adversarial-design
description: Run a multi-agent adversarial design process. Four fixed dispositions (adversary, creative, systems pragmatist, domain purist) deliberate a design question through recorded moves, then an architect synthesizes one ruling that survives the attacks and names the trade-offs it killed.
argument-hint: <problem statement or design doc path> [--no-research]
---

Run an adversarial design process for a problem or design.

**Input:** $ARGUMENTS is a problem statement, or a path to a design doc. If it is a path, read the file as the problem. Otherwise treat the text as the problem.

This skill is compiled for THIS target. The two local dependencies are resolved:
- **Deliberation substrate** -> the campfire `design-deliberation` convention (`cf` is on PATH). It records every move (propose, challenge, concede, convergence, rule, synthesize) as a durable, attributed, replayable log. If `cf` is unavailable at run time, fall back to a single durable file at `.design/<short-name>.deliberation.md` with one timestamped, disposition-attributed entry per move. Do not silently drop the record: the record is a required output.
- **Agent dispatch** -> the harness Workflow/Task tools. Run each disposition as its own background agent so it holds its context across rounds; run the architect as a separate agent after the four. Delegate to a matching spec in `.claude/agents/<disposition>.md` when one exists; otherwise dispatch the disposition with the standing instructions inlined below. If multi-agent dispatch is unavailable, you may play the dispositions in-session, but each must be argued in full and to its own standing rules, and each move must still be recorded to the substrate.

You are the orchestrator. You seed the question, dispatch the dispositions, drive rounds, dispatch the architect, and surface the ruling. You never collapse a disposition into agreement to move faster.

---

## Phase 1: Seed

1. Pick a short name for the design. Identify source material the team must read (the doc at the path, the code it touches, the framework spec).
2. Pick the domain framework for the purist. Default to Resonant Product Theory (`~/projects/resonant/docs/specs/rpt.md`, core insight: "the optimization system lives inside the product, not outside it"). If the problem names another framework, use it. You must hand the purist four things or it cannot run: framework name, primary source path, key sections, one-sentence core insight.
3. Open the substrate and post the seed proposal:
   ```bash
   design_cf=$(cf create --description "design: <short-name>" --convention design-deliberation --json | jq -r .id)
   cf "$design_cf" propose --disposition disposition:architect \
     --question "<problem statement>" \
     --proposal "<source paths, domain framework + core insight, initial direction, trade-offs already known>"
   ```
   Keep the returned message id; it is the `target_message` the first challenges aim at.

## Phase 2: Research (skip on `--no-research`)

Dispatch 3-4 parallel research agents (cheap tier) to read the source material and drop short briefs in `docs/design-team/`. Skip when the team already has the context or the problem is small.

## Phase 3: The four dispositions

Dispatch the four as independent background agents, each holding its own context across rounds. Each reads the seed and the source, then posts through the convention. The dispositions are fixed roles with hard invariants. Inline these into every dispatch; the invariants are what make this adversarial instead of four agents agreeing.

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

Each disposition posts with the convention, targeting the message it answers:
```bash
cf "$design_cf" challenge --target_message <id> --disposition disposition:<adversary|creative|pragmatist|purist> \
  --challenge "<specific weakness, with citation/scenario/LOC as the role requires>" \
  --alternative "<sketched alternative, if the role offers one>"
cf "$design_cf" concede --target_message <id> --disposition disposition:<role> --reasoning "<what convinced you>"
```
Drive rounds: each disposition reads the others' latest moves and responds. The adversary escalates open attacks; the creative answers them with mechanisms; the pragmatist prices them; the purist tests them against the source. Run until each disposition posts `convergence`:
```bash
cf "$design_cf" convergence --disposition disposition:<role> \
  --summary "<where this disposition lands>" --open_questions "<remaining, one per flag>"
```

## Phase 4: Architect synthesis

Dispatch the architect (strongest tier) only AFTER the four have posted, never during.
1. Read the whole deliberation: `cf read "$design_cf" --all`.
2. The architect rules each open question, then synthesizes. Use the moves:
   ```bash
   cf "$design_cf" rule --question "<the question>" \
     --ruling "<what to do, the reasoning, which challenges accepted, which alternatives rejected and why>" \
     --dissent_acknowledged "<unresolved dissent that was overruled, with reason>"
   cf "$design_cf" synthesize --design "<self-contained design an implementer can execute>" \
     --rulings_referenced "<rule message ids>"
   ```
3. The ruling MUST name the trade-offs it killed: the alternatives that were on the table, which it rejected, and why. Every adversary attack must be addressed in the synthesis: resolved with a mechanism, or recorded as a permanent constraint. A synthesis that lists only what was chosen, with no killed alternatives, is incomplete: send it back.
4. Present the design to the operator.

## Phase 5: Feedback

If the operator pushes back: post their feedback as a new `propose` from the architect, message the live dispositions to re-evaluate (they hold their prior context, so no replay), have the architect re-rule and re-synthesize. Minor wording fixes: edit the doc, do not wake the team. Approve when the operator approves.

## Phase 6: Completion

1. Convergence: post a final `propose` ("CONVERGE, design approved"), let each disposition post its `convergence` and exit.
2. Persist the design-campfire id so downstream work can find it: append `<!-- design-campfire: $design_cf -->` to the design doc and write `$design_cf` to `.campfire/designs/<doc-basename>`.
3. Commit the design doc and design-team artifacts. Report: attacks raised / resolved / permanent, operator iterations, rounds.
4. Output the next step: `/swarm-plan --design-campfire $design_cf <design-doc-path>`.

---

## What good looks like
- All four dispositions are represented and each genuinely adversarial: the adversary lands a specific cited attack; the creative answers with a sketched mechanism; the pragmatist cites code or concrete LOC; the purist cites the source by section. None reduces to vague agreement.
- It ends in exactly one synthesized ruling that names the trade-offs it killed: rejected alternatives and the reason for each.
- The deliberation is recorded in the substrate, readable move by move, each move attributed to a disposition.
- Every adversary attack is carried to a final state in the record: resolved (with mechanism), permanent constraint (with reason), or open.
- No em-dash. No "not X but Y" construction.
