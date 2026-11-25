# Case study: aes-todo, the first project built with AES and a cheap executor model

**Question:** can a frontier model orchestrate and verify while a cheap model writes the tests and the code, without the result getting worse and without the frontier model's usage blowing up?

**Project:** [aes-todo](https://github.com/KeylorBrenes/aes-todo), a password-protected personal task list with projects, subtasks, tags and time tracking. Rust (Axum + SQLx + SQLite) on the server, React + TypeScript + Vite on the web, Playwright acceptance tests. Developed on Windows with Git Bash.

**Roles and models:**

| Role | Runs in | Model |
|---|---|---|
| Orchestrator (spec, design notes, delegation, classification) | Claude Code | Claude Opus |
| Verifier (independent, read-only) | Claude Code subagent | Claude Sonnet |
| QA (acceptance tests, RED) | OpenCode | DeepSeek V4.1 Flash |
| Programmer | OpenCode | DeepSeek V4.1 Flash |
| Mechanic (mechanical edits, closing chores) | OpenCode | DeepSeek V4.1 Flash |

Every number below comes from the project's own records: `docs/harness-findings.md`, `docs/agent-failure-log.md`, the retrospectives in `docs/retrospectives/`, Claude Code's `/cost` and the DeepSeek usage page.

## Item 1 — EN-001, the walking skeleton

The first item delivers the Axum server with SQLite serving the React app, one end-to-end test and a green CI. It worked, and it was expensive:

| Metric | Value |
|---|---|
| FAIL cycles | 5 (TASK-001: 2, TASK-002: 3) |
| Claude | USD 24.35 (Opus 19.43, Sonnet 4.90, Haiku 0.03) |
| DeepSeek | USD 0.17 |
| Duration | 11 h of wall-clock over 4 days, 55 min of API time |
| Blocks | 9 (hooks, permissions, provider limits, missing toolchain) |
| Leftover defects | 3 minor accessibility defects in the backlog |

The cheap model cost almost nothing. The problem was everything around it, which kept the expensive orchestrator busy.

## What actually failed

The tempting conclusion was "the cheap model is too weak". The records did not support it.

**1. The FAIL cycles were not failed verifications.** The verifier passed every run of TASK-002. The cycles came from a rule in the project profile that turned every minor finding about the task into rework. Worse, each fix exposed a finer detail of the same element: focus lost after a retry, then the browser's focus ring instead of the design system's, then a ring on non-interactive text, then a ring after a mouse click. The task spent all three cycles polishing and still ended with three minor defects.

**2. The design notes had gaps, and one was wrong.** The note did not specify where focus goes after each state change, which live regions exist, or which focus ring each kind of element uses. The API contract did not cover 405 responses or the trailing slash on `/api/`. The note also asked for the alert region to contain its button, which is the opposite of correct practice. Any model would have improvised there, and the verifier, testing with keyboard and screen reader, would have flagged it.

**3. The environment and the harness absorbed the orchestrator's time.**

- Rust was missing, and then the MSVC linker.
- The OpenCode delegation script broke on a newer OpenCode release (a removed flag) and on Windows (a `jq | head` pipe failing under `pipefail`).
- The provider's free tier cut two runs mid-task with HTTP 429.
- The agents' GitHub App lacked a permission.
- The dependency-approval label had to be re-applied five times, because any new commit removed it.

Each one meant Opus turns to diagnose, work around or run something by hand.

**4. What the cheap model did get wrong was small.** It overbuilt (about 340 production lines against a budget of 200), tried to read the harness configuration and to write outside its worktree (both denied by permissions), and picked a dependency version with default features that pulled in a vulnerable crate. None of that cost more than one cycle.

## Controls added

AES's rule is one new control per observed pattern, enforced by tooling where possible, not by asking the model to try harder.

| Version | Control | Pattern it addresses |
|---|---|---|
| 1.4.1 | Findings after a PASS are classified by **type** (code defect vs. spec gap) and severity. Only Medium+ code defects reopen a task. Minor ones go to the backlog. Spec gaps fix the note. | Rework loops on minor findings |
| 1.4.1 | Re-verification limited to what the cycle changed, plus a short regression pass | Verifier cost (37% of Claude usage) |
| 1.4.1 | Design note template with **API edges** (405, unknown route, trailing slash, error body) and **dynamic UI behaviour** (focus after each transition, live regions, focus ring per element type) | Spec gaps |
| 1.4.1 | `aes-doctor.sh`: one environment check before delegating, including a minimal compile per language (detects a compiler without a linker) | Environment discovered piece by piece |
| 1.4.1 | Delegation script hardened: probes the OpenCode CLI for the flags it needs, parses only JSON events, always records cost, distinct exit codes for "provider failed" and "role finished but gate pending" | Harness fragility |
| 1.4.1 | Dependency approval kept across commits that do not touch manifests or lockfiles | Repeated human approvals |
| 1.5.0 | **Model level per task**: a task can request a higher model with a stated reason, approved by the human | Not every task fits the cheap model |
| 1.5.1 | Backlog board regenerated by a git hook after every pull | Stale board |
| 1.5.2 | SAST and UI detector steps fixed. An unset GitHub Actions variable is `null`, and `null != '0'` evaluates to false, so both steps had been silently skipped since AES 1.3.0 | Found during the ST-001 review |

## Item 2 — ST-001, the stabilization batch

The three minor defects left by EN-001 were fixed as one stabilization batch, with the new design-note sections filled in.

| Metric | EN-001 | ST-001 |
|---|---|---|
| FAIL cycles | 5 | **0** |
| Claude | USD 24.35 | **USD 3.38** (Opus 2.58, Sonnet 0.80) |
| DeepSeek | USD 0.17 | USD 0.04 |
| Duration | 11 h over 4 days | **44 min**, one session |
| Blocks | 9 | 0 |
| Human interventions | about 30 (installs, approvals, classifications, merges) | 4 (one decision, two approvals, acceptance) |

The UI task, the same kind that took three cycles in EN-001, passed verification on the first attempt. The retrospective's first finding states it directly: a design note with the dynamic-behaviour table filled in prevents the interface FAIL cycles.

## What this does and does not show

- **It shows** that, in this project, the cheap executor was not the bottleneck. Specification quality, review rules and harness reliability were. Fixing those cut the frontier model's cost roughly sevenfold between the two items.
- **It does not yet show** the same on a new user story. ST-001 is a 2-point batch on an existing skeleton, while EN-001 included one-off setup. The fair comparison is the next stories (account creation, login, task CRUD), which are in progress.
- **It surfaced a silent CI gap** (the SAST step never ran) that green pipelines had hidden since AES 1.3.0. Reading the logs of a passing run is part of the review.

## Takeaways

1. **Attribute failures before switching models.** "The model is weak" was the first hypothesis and the wrong one; per-cycle records showed where the work went.
2. **Put the decisions the verifier will test into the spec.** Anything the note leaves open, the executor improvises and the verifier rejects.
3. **Make the review rule proportional.** A rule that reopens work for every minor finding turns a PASS into a loop.
4. **Controls over prompts.** Each fix above is a template section, a script check or a CI rule, so it holds on the next item and with a different model.
5. **Cost the whole loop, not the executor.** The executor was about 1% of the spend. The orchestrator's long session and the verifier's full re-runs were the rest.
