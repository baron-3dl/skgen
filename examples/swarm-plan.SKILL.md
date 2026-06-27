---
name: swarm-plan
description: Decompose a design into a dispatch-ready item tree with typed agents using rigor-attenuated swarm decomposition. Use when planning a feature for parallel agent execution.
argument-hint: [--rigor <tier>] [design doc path or description]
---

Decompose a design into a dispatch-ready work item tree. Run Pass 0 to size the
rigor, then run the applicable refinement passes. Build the tree in `rd`. Stop
before any execution; the user approves the plan first.

**Input:** $ARGUMENTS is a design doc path or a problem description. If it is a
path, read the file as the design. Otherwise extract the design from conversation
context.

## Resolved local bindings

- **Tracker = `rd`** (this machine, v0.10.x). Command forms used below:
  - Create item: `rd create "<outcome title>" --priority p1 --type task`
  - Create child: `rd create "<title>" --priority p1 --type task --parent-id <parent-id>`
  - Add dependency: `rd dep add <blocked-id> <blocker-id>` (the blocked/child item first, its blocker second)
  - Ready queue: `rd ready`
  - Dependency tree: `rd dep tree <parent-id>`
- **Agent registry = `.claude/agents/`** in this project. This project has none, so
  the registry falls back to the standard set at
  `~/projects/resonant/docs/practice/agents/` (implementer, reviewer, sweeper-*,
  veracity-adversary, designer, planner, etc.). In Pass 5, `ls` the project dir
  first, then the fallback dir, to confirm a spec exists for every `agent-type` you
  assigned.
- **Routing = by work kind** (no project-specific routing table here): implementation
  to `implementer`, code review to `reviewer`, sweeps to `sweeper-<focus>`, mock /
  test-fidelity challenge to `veracity-adversary`, design questions to `designer`.
- **Execution mechanism** (for downstream `/swarm-dispatch`, not this skill): the
  harness Workflow/Task tools spawn the typed agents. This skill only plans.

The cardinal rule: **decompose by outcome, never by implementation step.** Each item
is a verifiable end state (what the user sees, what the system does, what query
returns what), never "build X" or "code exists." Bad: "Build the filtering layer."
Good: "Physical tasks don't appear in the agent work queue." Every item must be
outcome-defined, one-session-sized, and self-contained (an agent with zero history
can execute it from the description alone).

## Pass 0: Rigor Attenuation (run first, always emits a dispatchable DAG)

Scale rigor to the **cost of getting the work wrong**, not the apparent size. Inputs:
the request, related `rd` items, a 30-second repo scan. Ask nothing unless genuinely
ambiguous. Compute three signals, take their max, add the modifier, clamp:

- **Blast radius**: 1 file = trivial; 2-5 files = small; 6+ files or crossing core
  package boundaries = standard; >20 files or >3 packages = heavy.
- **Reversibility**: additive-only = trivial; in-place mutation, no external contract
  = small; interface/config/CLI contract change = standard; schema migration / public
  API / on-disk format = heavy.
- **Adversarial surface** (floors): none = trivial; rd state / a coordination protocol's internals / signing /
  test-gate = standard floor; auth / payment / secrets / user data / security-labeled
  = heavy floor.
- **Coverage modifier**: prod code changes a path with no test coverage, +1 tier
  (once; trivial only bumps to small).

`rigor = clamp(max(blast, reversibility, adversarial) + coverage, trivial..heavy)`.

| Tier | DAG shape | Passes applied |
|---|---|---|
| trivial | one implementer leaf | 1, 5 |
| small | implementer → reviewer | 1, 2, 5 |
| standard | implementer → reviewer → veracity-adversary | 1–3.5, 5 |
| heavy | implementers, reviewers, veracity, five sweeps, optional upstream design | all |

Annotate the parent with `rigor: <tier>`. Report the tier and dominating signal
("blast=small, coverage bump → standard"), then proceed to Pass 1 regardless. Honor
`--rigor <tier>` if the user passed it.

## Pass 1: Outcome Mapping

Build the first-draft tree. Apply only the construction steps your Pass 0 tier
admits, per the tier table (reviewers at rigor ≥ small, veracity-adversary at
rigor ≥ standard, the five sweeps and per-item security reviews only at heavy).
1. Read the design fully; list every distinct outcome.
2. Create one **implementation item** per outcome (`agent-type: implementer`), title
   stating the outcome. Description carries: the **done condition** (verifiable state
   of the world), design reference, spec/file references, **constraints** (what NOT to
   do), and **artifact type** (`code` | `spec` | `ops` | `design`; default `code`).
3. At rigor ≥ small, add **review children** scaled by yield: 1 reviewer minimum
   (combined correctness + integration); 2 when the item touches a shared interface, security-adjacent code,
   or has high cascade risk; 3+ only for unusual risk, justified. Each review depends
   on its implementation item.
4. At rigor ≥ standard, for each implementation wave, add a **veracity audit item**
   (`agent-type: veracity-adversary`) running in-wave; the wave cannot merge until its
   findings resolve.
5. At heavy, for security-critical surfaces (auth, crypto, invite/token, concurrent mutation),
   add a **security review child** (`agent-type: sweeper-security`, opus) targeting
   TOCTOU, auth bypass, data races, audit gaps.
6. At rigor=heavy, add the five parent-level **sweeps** (security, bugs, deadcode,
   antipatterns, testcoverage), each depending on all implementation items.
7. Add an **e2e-verification** item only when the design spans 3+ independently-built
   components, integration can't be verified by composing unit tests, or workflows
   cross service boundaries.
8. Wire deps: sequential outcomes block each other; all children block the parent.
9. **Status discipline**: never pre-open blocked items; let `rd` auto-block on
   `rd dep add`. After wiring, `rd ready` must show only the parent + actionable
   leaves (≤ ~5 per wave).

Quality gate: every item answers "what does done look like?" and "who does this work?"

## Pass 2: Context Isolation (rigor ≥ small)

Apply the **compaction test** to every item: can an agent with zero history execute
it cold? Split items that are too large (needs >~10 files to grasp scope; multiple
independent done conditions; spans unrelated subsystems; description >~500 words).
Make each description self-contained: paths to read/modify, interface contracts, and
a mandatory **test-depth** annotation, one of: `feature` (requires integration
tests), `bugfix` (requires regression tests through the real pipeline), `refactor`
(requires existing integration tests pass), `test-only` (the item only adds or
changes tests, and those new tests exercise real, unmocked code paths); never blank,
never "unit tests". Maximize parallelism: split falsely sequential items, factor out
shared prerequisites. Annotate each item with a model tier (haiku/sonnet/opus).

Quality gate: no item needs another item's implementation details, only its interface
contract.

## Pass 3: Standards Enforcement (rigor ≥ standard; skip below)

Each implementation item must specify: **TDD** (write the failing test that defines
the done condition, implement to pass, run scoped tests green); **SRP** (one coherent
change; "and also" means two items); **SOLID**; **YAGNI** (nothing the design didn't
ask for); project conventions. **Enforcement items bundle their proof**: any gate /
guard / validator item must include both the test that it rejects bad input and the
test that it allows good input, same implementer, same dispatch.

Quality gate: each item tells the agent to write a test first and to avoid
over-engineering.

## Pass 3.5: Veracity Challenge (rigor ≥ standard; opus; skip below)

For every implementation item, ask: what would a sonnet implementer mock to close
this fast? (Usually the external integration, DB, API, service boundary.) Rewrite the
done condition so mocking is impossible ("test hits the real sandbox, sends a real
payment, verifies state in the database"). Create **prerequisite items** for anything
a human must provision (credentials, sandbox accounts, services) before the wave; when
the agent can't provision it, that prerequisite is itself the deliverable and goes to
the human first. Flag any done condition not expressible as a ground-source-truth
test.

Quality gate: no done condition is satisfiable by mocking the primary interface under
test.

## Pass 4: System Validation (opus; never downgrade)

Coverage: every design requirement maps to an item (create the missing).
Hallucination: every item maps to a requirement (remove the orphan). Interface
consistency: producers and consumers agree on contracts. Dependency integrity: no
circular/missing/phantom deps. Integration surface: each integration point has a
review or verification item. Mock blast radius: annotate `mock-scope` on items that
change a mocked interface. Agent-type validation: each item's type matches its work.

Quality gate: every requirement has ≥1 item, every item has ≥1 requirement, every
item has the right agent type.

## Pass 5: Dispatch Readiness

Cold-start simulation per item. **Agent-type matching**: `ls .claude/agents/` (then
the fallback `~/projects/resonant/docs/practice/agents/`); confirm a spec exists for
each assigned type, else map to the closest or flag. Model tiers: implementer=sonnet
(opus for complex architecture), reviewer=sonnet, sweeper=sonnet, designer/veracity-
planning=opus. Failure-cascade analysis: items blocking the most downstream work get
higher priority/tier. Final per-item annotation: agent type, model tier, key deps.

Quality gate: for every item the orchestrator knows what agent, what model, what deps.

## Present and stop

Top-level summary only, never the full DAG:

```
Parent: <id>: <title>  [rigor: <tier>]
Children:
  <id>: <title> [agent-type, model-tier]
  ...

Total items: N
By agent type: implementer ×N, reviewer ×N, sweeper ×N
Critical path: N items (~N waves)
Full DAG: rd dep tree <parent-id>
```

Then STOP. Do not dispatch. The user reviews and approves. Output the next step:

```
Plan ready for review. <total> items, ~<waves> waves.
When approved, dispatch: /swarm-dispatch [--strategy worktree|shared] [--workers N] <parent-id>
```

If the user flags a pass, re-run from there forward (structural→Pass 1, sizing→Pass 2,
standards→Pass 3, coverage→Pass 4, dispatch→Pass 5).
