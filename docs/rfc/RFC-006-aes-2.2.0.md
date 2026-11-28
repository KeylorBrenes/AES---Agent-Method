# RFC-006 — AES 2.2.0: a code review with scaffolding, and tasks in parallel

**Status:** Accepted (2026-11-27).
**Base:** AES 2.1.0
**Expected change type:** MINOR. Projects upgrade with `install-aes.sh --upgrade`. Nothing turns on in CI until the human sets the secret of the second review; the delegation mode needs only npm.

## Problem

1. **The verifier's review of the diff depends on its attention.** Its contract says "review the diff with the checklist": nothing forces it to read every file, nothing records which ones it read, and its checklist is the same for Rust, TypeScript or a workflow. A file it skips leaves no trace.
2. **The checklist arrives late.** The programmer meets the review rules when the verifier reports them, as a `FAIL` cycle: about 30 minutes each in aes-todo.
3. **The cycle is serial.** In US-001 the models were not the slow part; the waits were, one after another (RFC-005). With 2.1 the PRs are smaller, but the verifier still waits for the programmer and the next task waits for both.

## Proposal

### A. Open Code Review in delegation mode (05 §7.1)

[Open Code Review](https://github.com/alibaba/open-code-review) (Alibaba, Apache-2.0) separates the deterministic part of a review from the model's: it decides which files of a diff are reviewed (and why the others are not) and which checklist applies to each one (about 70 languages, plus the project's rules in `.opencodereview/rule.json`). In **delegation mode** it calls no model and opens no connection: the host agent reviews with its own model and reports coverage. It is the same idea as AES (determinism × agent), applied to a step AES had left to the agent.

- **Verifier:** `aes-ocr.sh plan` gives the file-by-file review plan; it reviews every file with its group's checklist plus its contract's, test files included (OCR leaves them out by default; AES does not), and reports **coverage**. Coverage below 100 % without a reason per skipped file is not a `PASS` (08 §4).
- **Programmer:** `aes-ocr.sh rules <scope>` gives the checklist of its surface **before** coding (the owner chose this over a full self-review at the end: the same prevention for the cost of a read, not of a model pass). If US-002's `FAIL` cycles come from things the checklist already said, a final self-review is reconsidered with that data.
- **Project rules** (01 §2.3, item 12): a seed with the level-1 principles (10 §3) and a line the orchestrator replaces at inception with the project's conventions. `.opencodereview/` is a protected path: the programmer cannot weaken what it is reviewed with.

### B. A second review in CI, optional (05 §7.1, 02 §9.3)

OCR in native mode reviews the task's diff with a model of its own, with the story and the task as context, annotates the PR and keeps one summary comment. Its value is independence, so its model should be from a family that is neither the programmer's (DeepSeek in aes-todo) nor the verifier's (Claude); the owner noted that this depends on the budget of the month, so it is **configurable, with no default**: any provider, Claude included, and without a token the step is skipped with a warning.

What blocks (the owner's question: should a Medium bug reach production?):

| Finding | What is done |
|---|---|
| New **critical** | CI red. Real → a `FAIL` cycle; a false positive → the human dismisses it with `aes:review-dismissed` |
| **High**, **Medium** | To the verifier as points of attention; a confirmed one follows 02 §9.3 (a task defect Medium or higher is a `FAIL` cycle before merging) |
| **Low** | Discarded or recorded as Minor |

A model's severity is a claim, not a fact: blocking on every High would turn its false positives into 30-minute cycles. The effect the owner wants already holds: no confirmed Medium is merged, and the release gate (02 §9.2) lets no open Medium reach `main`.

### C. The task graph and the pipeline (04 §5)

- Each task declares `Depends on:` — `none`, `TASK-NNN` (its code: after its merge) or `TASK-NNN (contract)` (only the note's interface: it starts at once; its PR opens after the dependency is merged and the branch updated with `dev`).
- `aes-graph.mjs` says which tasks start now and whether the surfaces of those that would run together can touch the same file (conservative: if it cannot rule it out, they do not run together).
- **Pipeline:** while the verifier checks one task, the programmer is already on the next one.
- **One task, one programmer:** the owner proposed several programmers on one task; a task is the smallest unit, with one surface, so work that can be shared out is two tasks, and the orchestrator splits it. Several items at once also stays out: one item per session.
- **Shared machine resources:** worktrees do not isolate ports. `aes-lock.sh servers` makes the commands that start servers take turns (acceptance, `with-servers.sh`); the end-of-role gate and `aes-oc.sh` no longer blame a role for ports held by that lock.
- After each merge, the other open task branches get `dev` merged in and CI runs again; their `PASS` holds if the merge was clean and CI is green.

## Cost

The owner asked whether many threads cost the same as one. The work costs about the same; each extra agent adds a **fixed start** (contract, `CLAUDE.md`, story, note, reading the code it touches: tens of thousands of input tokens) and the orchestrator writes one more brief. With DeepSeek that start costs cents, so parallelism is nearly free in money and saves wall-clock. Its real limits are the dependencies between tasks, the semantic conflicts that git does not show, the shared machine (ports, builds: with Rust each worktree builds on its own) and the owner's queue of PRs. Expected gain: modest per story (3 tasks at most, often dependent by layer); the pipeline is the larger part. It is measured on US-002.

## Audit of the tool (06 §6.2)

- Apache-2.0; telemetry off unless an OpenTelemetry endpoint is set (the scripts unset it).
- **The npm launcher updates itself by default** (`bin/ocr.js`, every 18 minutes): a self-updating tool is no longer the audited version. The scripts always set `OCR_NO_UPDATE=1`, and 06 §6.2 now requires self-updating off for every third-party tool.
- Fixed version (`AES_OCR_VERSION=1.14.4`), installed once in `.aes/tools/` with npm (registry integrity); the native binary comes as a platform package, Windows included.
- The second review sends the diff, the story and the task to the provider: the owner reviews its data terms before setting the secret.
- The benchmark in OCR's README (higher precision, about one ninth of the tokens) is the authors' own. AES treats it as a hypothesis for US-002, not as a fact.

## Not adopted

- OCR's GitHub Action: it posts inline comments for every finding; AES keeps one comment plus annotations and its own blocking rule, with the scripts taken from the protected branch.
- OCR's Claude Code command and skills: they would add a workflow outside AES's contracts (06 §6.2). The two CLI commands are enough.
- A full self-review by the programmer at the end, until US-002 shows it is needed.

## Measurement (US-002 in aes-todo)

Wall-clock per story against US-001; verifier coverage; `FAIL` cycles and whether their cause was in the checklist the programmer read; tasks that ran in parallel and minutes saved; false positives of the second review, if it is on.
