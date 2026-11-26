# 09 — Continuous improvement of the harness

## 1. Goal

Turn the agents' observed failures into permanent controls, so that the same mistake does not depend on someone remembering it or on repeating an instruction in every session.

Anthropic recommends building skills **after** evaluating: running the agent on representative tasks, observing where it fails and closing those gaps incrementally. Simon Willison describes the same principle as the "compound step": each project ends with a retrospective that improves the instructions of the following runs. AES formalizes both.

## 2. Agent failure log

Each project MUST keep `docs/agent-failure-log.md` (template in `templates/agent-failure-log.md`).

A failure is recorded when an agent:

- implements functionality nobody asked for or leaves its change surface;
- tries to weaken, skip or modify tests;
- claims results it did not run;
- enters fix loops or triggers the circuit breaker (04 §9);
- invents APIs, structures or requirements;
- introduces unjustified complexity, dependencies or abstractions;
- repeats a project-convention mistake.

Each entry describes the symptom, how it was detected, the probable cause and the control that was added. Judgements about the model are not recorded, only observable facts.

## 3. Compound retrospective

When each T2/T3 story and each stabilization batch closes, and at least once per group of T0/T1 work, the orchestrator MUST:

1. review the new entries in the log;
2. identify patterns (a failure repeated twice is a pattern);
3. **attribute each FAIL cycle** to its origin before proposing anything: a code defect, a gap in the specification or design note, or the harness/environment. "The model is too weak" is a conclusion the records must support, not the first hypothesis;
4. propose **one control per pattern**, choosing the hardest reasonable one, in this order:
   1. a test or check in CI (L3);
   2. a hook (L2);
   3. a harness permission (L1);
   4. a template section or a skill with a specific procedure;
   5. a line in `AGENTS.md`/`CLAUDE.md`;
5. present the proposal to the human owner, who approves or rejects it (06 §8);
6. after applying it, record in which later task it was verified that the failure does not repeat.

A line in the persistent instructions is the weakest control: the agent can ignore it or lose it when context is compacted. It is used when there is no reasonable way to automate the detection.

The retrospective is brief: patterns, one control per pattern and open decisions. The detail is already in the findings log and the failure log; copying it into the retrospective doubles the orchestrator's writing cost.

## 4. Evaluating harness changes

Changes to persistent instructions, skills, hooks or permissions SHOULD be checked with at least one representative task before being considered good. An instruction that does not change the observed behaviour is removed: it takes up context without contributing.

## 5. Hygiene of the persistent instructions

- Periodically review `AGENTS.md`/`CLAUDE.md` and remove entries already covered by a harder control.
- Keep the file brief; if it grows, move procedures into skills and leave only the pointer.
- Do not accumulate contradictory rules: a new entry that contradicts another explicitly replaces it.

## 6. Process evidence and metrics

Besides the failure log, each project SHOULD keep a **process findings log** (`docs/harness-findings.md`, template in `templates/harness-findings.md`): friction, confirmations that a control worked, control gaps and costs. It is the raw material of the retrospectives and of the change proposals to AES.

For each closed item (story, enabler, batch) a metrics row is recorded:

| Item | Start | End | Actual model per role | FAIL cycles | Human interventions | Control blocks | Cost | API time | Total time |
|---|---|---|---|---|---|---|---|---|---|

- **Actual model per role:** the one that ran, not the one the profile declares (06 §11).
- **Human interventions:** every time the human decided, approved, corrected or unblocked something.
- **Control blocks:** from hooks, permissions and harness classifiers, separately. A control that never blocks may be working or may be untested; a control that blocks a lot may be badly calibrated.
- **Cost:** the one the harness reports, per model. If only the human can look it up, the orchestrator asks for it at close.

The row is **computed by a script** from what the harness already records (run events, costs, CI runs), with what only the harness or the human knows passed in as data (Claude's cost, FAIL cycles, interventions). The orchestrator does not compute times or costs by hand: in aes-todo it spent three extra commits of the most expensive model on US-001's close breaking down times and costs per subagent.

## 7. Notes during the cycle

- Findings, failures and decisions are noted **at the moment**, with the real time a command gives, not a time written by the agent. In the AES sandbox, the orchestrator wrote estimated times, some ahead of the clock.
- Notes in progress live outside version control (for example, `.aes/`) and are consolidated into the versioned logs when the item closes. That way they do not slip into task PRs, where the guard would reject them for being outside the surface.
- Creating, consolidating and clearing the notes is done by a script, not a role: transcribing rows into the versioned logs is mechanical, and if a role cannot write to that folder, consolidation must not depend on it being able to. Only the decisions stay for the orchestrator, who numbers them in the item.
- A note is never its own PR in the middle of a cycle: it waits for the close.
