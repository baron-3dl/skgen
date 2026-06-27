---
name: swarm-dispatch
description: Execute an approved item tree by fanning typed agents over the ready set via the harness Workflow tool, adapting the plan between waves. Use after the plan is approved.
argument-hint: [--strategy worktree|shared] [--workers N] [parent item ID]
---

Execute the approved item tree as a typed swarm. You are the orchestrator: a
planning-dispatching loop, not a static executor.

This SKILL.md is compiled for this target. The abstract capabilities the
method needs resolve here as:
- **MECH (parallel execution)** = the harness **Workflow tool**. You author a
  self-contained JS script with `agent(prompt, { schema, model, effort, isolation })`,
  `parallel(thunks)` (barrier fan-out), and `pipeline(items, stage1, stage2)` (per-item,
  no inter-item barrier). `isolation: 'worktree'` gives an agent its own git worktree.
  The script is pure JS: it CANNOT run `bash`, `rd`, or `gh`. Concurrency cap ~16.
- **TRACK (work-tracker)** = **rd** (v0.10.0). All work-graph mutations run in the
  main loop only. The Workflow never calls rd.
- **VCS (version control)** = **git** + the **`gh pr`** merge queue. The main loop
  creates `work/<id>` branches, opens and merges PRs with `gh pr ... --squash`
  through the queue (serialize on `main`; never push to `main` directly), and deletes
  merged branches. The Workflow never runs git or gh.
- **DESIGN-REVIEW (adversarial design review)** = the local **/escalation-design**
  skill (three-pass adversarial review). Architecture escalations and escalating
  red-baseline fixes route into it; it rules, or opens an `rd gate` for human input.
- **REGISTRY (agent specs)** = `.claude/agents/*.md` in this project; this project
  defines none, so fall back to the standard set at
  `~/projects/resonant/docs/practice/agents/` (implementer, reviewer, veracity-adversary,
  sweeper-*). If an item needs a type with no spec, escalate to the user.
Coordination, gates, and assignment ride on **rd** and the Workflow tool's
structured returns. There is no separate coordination substrate: claims are
authoritative and visible cross-session on rd, and per-wave results cross back as
schema-validated Workflow returns.

**Input:** $ARGUMENTS. Parse `--strategy worktree|shared` (default worktree),
`--workers N` (default 3, cap ~16), and a trailing parent item ID (else use the
tree from conversation context).

Item tree:
!`rd dep tree $ARGUMENTS 2>/dev/null || echo "No item ID provided, use the tree from conversation context"`

Available agents:
!`ls .claude/agents/*.md 2>/dev/null | xargs -n1 basename 2>/dev/null || echo "none in project; fall back to ~/projects/resonant/docs/practice/agents/"`

## rd command reference (MAIN LOOP ONLY)

| Operation | Command |
|-----------|---------|
| Ready set | `rd ready --json` |
| Dep tree | `rd dep tree <id>` |
| Show | `rd show <id>` |
| Claim | `rd claim <id>` |
| Progress | `rd progress <id> --notes "..."` |
| Close done | `rd done <id> --reason "..."` |
| Close fail | `rd fail <id> --reason "..."` |
| Add dep | `rd dep add <child> <blocker>` |
| Human gate | `rd gate <id> --gate-type <type> --description "..."` |
| Gates / approve | `rd gates` / `rd approve <id> --reason "..."` |

rd `claim`/`done`/`fail`/`gate`/`dep add` are yours alone. Agents inside the
Workflow may post `rd progress` for live visibility; nothing else.

## Authority boundary (non-negotiable)

All claim/close/fail/gate/dependency mutations are the orchestrator's, applied in
the main loop from the Workflow's structured return. **Agents never close items.**
The only thing crossing from an agent back to you is a schema-validated value.

## One agent per item, typed dispatch

Each `agent()` call works exactly one item and returns one schema-validated result,
then exits. No long-lived workers. Read the item's agent-type annotation, look up
the spec in REGISTRY, and author the matching call (implementer / reviewer /
sweeper / veracity-adversary). Wave composition shifts as the tree drains: early
waves implementers, later waves reviewers and sweepers.

## Strategies

- **worktree** (default): implementers run with `isolation: 'worktree'`, edit in an
  isolated worktree, return a branch name. You merge branches in the main loop.
- **shared**: omit isolation; agents edit the shared repo. Use only when the wave's
  items touch disjoint files (the plan's merge-face grouping guarantees it).

## Result schema (every implementer agent returns this)

```json
{
  "type": "object", "additionalProperties": false,
  "properties": {
    "item_id": {"type":"string"}, "branch": {"type":"string"},
    "tests_green": {"type":"boolean"}, "has_schema_change": {"type":"boolean"},
    "summary": {"type":"string"},
    "findings": {"type":"array","items":{"type":"object"}},
    "test_decisions": {"type":"array","items":{"type":"object"}},
    "escalation": {"type":"object","properties":{
      "category":{"type":"string","enum":["architecture","scope","interface","dependency"]},
      "question":{"type":"string"}}, "required":["category","question"]}
  },
  "required": ["item_id","branch","tests_green","has_schema_change","summary","test_decisions"]
}
```

Reviewer/sweeper agents return `{ findings: [ { file, location, severity, category, description } ] }`.

## The loop

```
1. SETUP: rd dep tree <parent>. Record swarm start to .telemetry/swarm-dispatch.jsonl.
   Resolve optional read-only design context for workers.

2. LOOP:
   a. rd ready --json -> the actionable set.
   b. WAVE PLANNING: compute dep depth per item; find the critical path (longest
      chain to completion); prioritize critical-path items. Report:
      "Wave N: dispatching X items. Critical path: A -> B -> C (N hops)."
   c. CHECK PRIOR GATE: if an async gate from a previous wave is running, check it:
      green -> continue; red -> halt, create a fix item, dispatch it now;
      still running -> proceed (optimistic pipelining).
   d. BASELINE: run the full suite (Bash). GREEN -> record, proceed.
      RED -> Red Baseline Resolution; DO NOT DISPATCH on red.
   e. CLAIM + BUILD WORK-LIST: per wave item: rd claim <id>; read agent-type, look
      up REGISTRY spec (escalate if missing); assemble
      { item_id, agent_type, model_tier, effort, test_depth, mock_scope,
        item_context, design_context }; append a dispatch_start telemetry entry.
   f. AUTHOR + RUN THE WORKFLOW (MECH):
      - implementer items -> pipeline(items, implementer, veracity): stage 1 returns
        the result schema; stage 2 challenges test_decisions and returns a verdict.
        Implementers get isolation:'worktree' under worktree strategy.
      - reviewer/sweeper items -> parallel(...) returning the findings schema.
      - mixed wave -> both, merged in the return.
      - model/effort per agent: sonnet + low effort for implementers/reviewers/
        sweepers; OPUS for veracity (the judging/security tier); never Fable 5 for
        security/exploit work.
      - the script dedups findings in-script, builds a compact summary, and RETURNS
        the structured per-item array (results + verdicts + escalations). It does
        NOT return raw payloads.
      - Invoke the Workflow tool with args = { items: <work-list> }.
   g. INGEST: per item { item_id, branch, tests_green, has_schema_change, summary,
      findings, test_decisions, veracity_verdict, escalation? }. Append a
      dispatch_complete telemetry entry (outcome, wall-clock, per-agent tokens from
      the Workflow's per-agent usage).
   h. ROUTE ESCALATIONS: architecture -> /escalation-design; scope -> rd gate (or
      rule if within authority); interface -> route to a peer with context or rule;
      dependency -> rd dep add to re-sequence. Fold the ruling into item context and
      re-dispatch in a later wave.
   i. VERACITY GATE (unconditional for any wave with implementer items): per verdict:
      "clean" -> mergeable. "proven-inability" + filed prerequisite -> mergeable
      (create the prerequisite item if named and missing). "unresolved" -> DO NOT
      MERGE; re-dispatch the implementer with the finding as a constraint; loop
      until clean or proven-inability. To waive: rd gate <id> --gate-type
      veracity-waive --description "...". You may NOT waive your own oversight.
   j. ASSESS (completeness critic / adaptive planning): reviewer bug -> rd create
      implementation item; sweeper gap -> rd create test item; integration surprise
      -> rd create design item. Scale rigor to size; wire deps with rd dep add.
   k. APPLY OUTCOMES: merged -> rd done; unrecoverable red -> rd fail; escalated ->
      leave claimed (re-enters via h). Per branch: gh pr (create if only a branch
      was pushed) -> integration gate -> gh pr merge --squash -> delete branch ->
      rd done. Never push to main directly.
   l. INTEGRATION GATE (conditional + async; see below).
   m. REPEAT from (a).

3. WHEN rd ready is empty AND no finding/verdict/escalation is unresolved:
   FINAL GATE: full suite synchronously (Bash). Mandatory, never skipped.
   rd done <parent> --reason "Swarm complete: N items, N waves, strategy <mode>. CI green."
   Write the per-swarm telemetry summary.
```

## Verify pattern 1: adversarial verify (in-wave, mandatory)

Veracity is the stage-2 thunk of the per-item `pipeline`, run at OPUS. It receives
the implementer's returned `test_decisions` and challenges every mock: does the
test hit ground source truth, or mock away the thing under test? Per challenged
mock, demand a real test or a proof of inability. Verdict:
`{ item_id, verdict: "clean"|"unresolved"|"proven-inability",
   challenged_mocks: [ { mock, why_inadequate } ], prerequisite_filed: "..." }`.
"It is too hard" / "it would take too long" are NOT proven-inability. Because
`pipeline` has no inter-item barrier, veracity runs concurrently with other items'
implementers. The gate is enforced in the main loop (step i); the script reports.

## Verify pattern 2: loop until dry

The parent closes only when all of: rd ready is empty, every review/sweep finding
became a new item or was dismissed with a reason, and no veracity verdict is
"unresolved". A drained ready set alone is not done.

## Verify pattern 3: completeness critic (adaptive planning)

Findings are how the swarm discovers what the plan missed. Each becomes a new rd
item wired into the tree for the next wave. Small fix -> add item + dispatch;
medium gap -> mini decomposition; major issue -> full decomposition to the user.

## Integration gate (main loop; the Workflow cannot run tests/git)

| Level | When | Action | Blocks? |
|-------|------|--------|---------|
| SKIP  | all changes isolated, no has_schema_change | none | No |
| ASYNC | shared code / multi-package, next wave independent | push ref, run full suite via `Bash run_in_background:true` or CI, check next iteration | No |
| SYNC  | final wave, OR prior async gate red, OR critical paths (auth/billing/data) | full suite, block until green | Yes |

After merge: final wave -> SYNC; prior async red -> SYNC; has_schema_change ->
ASYNC; multi-package/shared -> ASYNC; all isolated -> SKIP. The final gate is
never skipped.

## Red baseline resolution

A red baseline halts the swarm. Fix trivially if you can (import error, config
drift); else author a single-item fix Workflow (`pipeline([fixItem], implementer)`)
with the failing test as the constraint at priority 0; green -> re-baseline and
resume; red/escalation -> /escalation-design, which rules or opens
`rd gate <parent> --gate-type other` for human input. NEVER: file-and-continue,
note "pre-existing failure" and proceed, skip the test, or close as "already
failing". A flaky baseline test is a quality defect: rd create it, make it
deterministic (not retries/timeouts), and treat as red if it blocks.

## Multi-session coordination

Orchestrators coordinate through rd (claims are authoritative and visible
cross-session, so a claimed item never appears in another's ready set) and the git
PR merge queue (serialize on main; never push directly). A peer's schema change
surfaces as a baseline failure here and goes through Red Baseline Resolution.
Human-visible gates ride on `rd gates`.

## Telemetry

Write per-swarm summary to `.telemetry/swarm-dispatch.jsonl` and per-item
start/complete events to `.telemetry/swarm-dispatch-beads.jsonl`. Before writing,
verify dispatch_start count == dispatch_complete count, and derive veracity metrics
from the returned verdicts (not prose). If any verdict is "unresolved", the swarm
MUST NOT close.

## Worker replacement

Poor output (shallow, missed constraints) -> re-author the `agent()` call at a
higher model/effort and re-run. Log the escalation in the item.
