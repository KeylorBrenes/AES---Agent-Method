# RFC-005 — AES 2.1.0: cutting the process with the five-step algorithm

**Status:** Accepted (2026-11-26).
**Base:** AES 2.0.1
**Expected change type:** MINOR. Projects upgrade with `install-aes.sh --upgrade`; the only behaviour a project may want to keep is the `aes:verified` label, available with `AES_REQUIRE_VERIFIED=1`.

## Evidence

US-001 in aes-todo (create the account the first time) took **3 h 50 min of wall-clock** with 0 FAIL cycles. Its records (`docs/retrospectives/US-001.md`, FL-006, FL-007):

| Part | Time | Cause |
|---|---|---|
| The human between gates | ~1 h 15 min | 8 PRs to merge, 16 decisions, 2 surface amendments, demo |
| CI | 41–60 min | every PR waits for the full run (7–9 min per task) |
| Orchestrator (Opus) | 43 min of API, 83 % of the cost | preparing, reviewing, classifying, and computing metrics by hand at close |
| OpenCode | 41 min, of which 13 are the model | 28 min running commands, above all a 3.5-minute acceptance suite run several times |

The models were not the slow part. The time went into **serial waits**, repeated eight times, and work that produced nothing. The first task also reached **2075 lines in 4 commits**, which the owner could not review.

## Method

The five steps attributed to SpaceX, applied in order: question every requirement, delete, simplify, accelerate, automate. Automation comes last on purpose: nothing below automates a step that could be deleted.

## 1. Question every requirement

| Requirement | Origin | Decision |
|---|---|---|
| A separate PR for the story before the tests PR | 1.3.0: the owner signs the criteria before QA writes | **Merged into one PR** (owner, 2026-11-26). The questions are asked and answered in conversation first and recorded as D-NN; the owner signs story, tests and tasks together. If a criterion changes in review, QA redoes those tests in the same PR. 03 §8 |
| Every QA assumption asked to the owner | FL-001 of the first sandbox | **Only the visible ones** (owner). QA marks each one visible or internal; the orchestrator decides the internal ones and lists them in the PR for veto. Six of US-001's eight changed nothing the user could notice. 03 §5 |
| The `aes:verified` label plus the merge | 1.2.0: agents must not fake a PASS | **Merging is the approval** (owner). The orchestrator publishes the verifier's report on the PR; the label stays available with `AES_REQUIRE_VERIFIED=1`. Trade-off accepted: CI no longer proves a verification happened. 06 §8 |
| A PR per task | Review and guard per task | **Kept**, with smaller tasks (owner): a real production budget, single-layer tasks, a commit per criterion or piece. 04 §2–3 |
| An "indicative" diff budget | 1.0 | **A limit.** The guard fails above the budget plus a tolerance (25 %); `aes:budget-approved` is the exception, splitting the task is the rule. 02 §6 |
| Every task except the last turns an acceptance criterion green | 1.2.0, per-criterion CI | **Relaxed.** A task can write `none` in its criteria and turn green the technical tests of its design note. This was the cause of the 2075-line task: a criterion with an interface forced server and web into one task. 04 §3, 05 §12 |

## 2. Delete

- A mid-cycle PR to record a note (#23 for FL-007): notes wait for the close. 09 §7
- The hand-written criterion → test matrix: `red-check.mjs` prints it from the titles and tags, with each failure's first line. 05 §2.2
- The mechanic at close: transcribing notes is a script (`aes-note.sh consolidate`). 09 §7
- The orchestrator computing times and costs: three extra commits of the most expensive model on US-001's close. A script does it (`aes-metrics.mjs`). 09 §6
- The surface amendments (#21, #24) are prevented at the source: the design note lists the tests the task obliges to change, and they go into the surface (FL-006). 10 §5

## 3. Simplify

- `aes-cycle` went from ~4,700 to ~2,500 words: the normal path of a story, with `references/` for OpenCode, T1/T0 and release/hotfix, read only when needed. The orchestrator loads it every session, and its cache reads dominated the cost.
- The task template has a commit plan and a production budget; the design note, the tests the task obliges to change.

## 4. Accelerate

- QA and the programmer run only the criterion they are touching, and the full suite once at the end. 05 §2.2
- The orchestrator drafts the design notes while QA works in the background.
- Project-level, not AES: cache the build in CI and reuse the compiled server in the acceptance fixture (aes-todo P5).

## 5. Automate

- `aes-metrics.mjs`: the metrics row from OpenCode's run events, `costs.csv` and the CI runs, with what only the human knows passed in.
- `aes-note.sh consolidate`: findings into `docs/harness-findings.md`, failures into FL-NNN entries.
- The guard's budget check, in CI and in the end-of-role gate.
- `aes-ctx.sh` and the workflow agree on verification command names for one criterion (`<ID>-AC-NN.verify` or `AC-NN.verify`), aes-todo P4.

## Expected result

For a story like US-001: about **1 h to 1 h 30 min** of wall-clock, 4 PRs instead of 8, one round of questions, and tasks the owner can review commit by commit. To be measured on US-002.

## Left open

- SAST for Rust (`p/owasp-top-ten` has no Rust rules) and `semgrep` denied to the programmer in OpenCode (aes-todo P3): a project setting, to be checked in US-002.
- One PR per story with tasks as verified commit ranges: rejected for now (owner) as a large CI change; reconsider if the PR count is still the bottleneck after 2.1.
