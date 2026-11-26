# 04 — Task design and execution

## 1. Purpose of a task

A task turns part of an approved user story or enabler into a concrete, checkable change. It is not an open instruction such as "finish the module" or "improve the code".

## 2. Mandatory fields

Every task ready to run MUST specify:

- ID and a result-oriented title;
- the related user story/enabler;
- goal and expected result;
- included scope and relevant exclusions;
- dependencies and contracts it must respect;
- track (02 §8);
- **change surface**: file globs the task may modify;
- constraints and permissions;
- **exact validation commands** (not descriptions such as "run the relevant tests");
- **affected regression tests** (test map), when they can be generated or inferred;
- **criteria it turns green**: the criterion (or defect) IDs this task satisfies. The task's CI runs only those plus the regression suite; the **last** task of the story runs the whole story (05 §12). A single-layer task (§3) declares `none` and turns green the technical tests its design note lists;
- **production budget**, a limit (02 §6), and an estimate for tests;
- **commit plan**: the order of the commits, one per criterion or per piece of the design note, each with its tests, so that each can be reviewed on its own;
- **model level** (06 §12.1): standard by default, or a higher level with its reason;
- **design note** (10 §5) in T2/T3: pieces, responsibilities, pattern (or absence of a pattern) and what is not done;
- if the task introduces a **state** (error, loading, editing), the transitions that create it and those that clear it;
- completion condition.

The change surface is not a suggestion: CI compares the diff against it (05 §10). A file modified outside the surface is a `FAIL` unless there is a recorded approval. The surface is published on the protected branch **before** the task is delegated, so the programmer cannot widen it.

### Why exact commands and not process instructions

The TDAD study (Alonso, Yovine and Braberman, arXiv:2603.17973; master's thesis, Universidad ORT Uruguay) measured that adding generic TDD instructions to an agent's guidance increased its regression rate from 6.08% to 9.94%, while giving it a map of which tests each file affects reduced it to 1.82%. The study used an open model (Qwen3-Coder 30B) and only Python, so AES does not adopt the figure but the principle: **concrete structural information instead of generic procedures**.

## 3. Size and divisibility

A task is small enough if an agent can understand its goal, implement it, inspect the diff and run its validation without having to accept several independent results as one indivisible block.

A story has **at most 3 tasks**. If it does not fit, the story is too large and is split (02 §3.1, §10), instead of making larger tasks.

Tasks are split **by criteria** by default (vertical slices that turn criteria green). When a criterion does not fit in the production budget end to end, it is split **by layer**: the earlier tasks (for example, the server) turn green the technical tests their design note lists, with `none` in their criteria file, and the task that completes the slice turns the criterion green. Without that option, a criterion with an interface forced server and web into a single task: in aes-todo, US-001's first task reached 2075 lines (FL-007).

The production budget is a limit (02 §6). The orchestrator estimates it **per piece** of the design note, both ends of a new function included (server and web) and the test cases the note requires; if the sum goes over the limit, the task is split before `Ready`, not justified afterwards.

Signals to split:

- more than one observable result with no necessary dependency;
- logic, interface, migration and deployment grouped only for convenience;
- several modules or contracts modified with no common reason;
- many acceptance conditions that can fail independently;
- high technical uncertainty;
- being unable to describe a focused test.

Do not split until the tasks become artificial, valueless or dependent on speculative details. Keep technical cohesion and an executable sequence.

## 4. Execution contract

The programmer receives a bounded context package: the approved story, the task, the related criteria, the relevant architecture/ADRs, API/data contracts and the project's conventions.

The programmer MUST:

1. **run the existing suite first** and record the baseline (tests that were already failing before touching anything), so as not to "fix" pre-existing failures or take credit for them;
2. inspect the relevant code before changing it;
3. briefly describe the approach when the change is not trivial;
4. implement only the task's scope, within its change surface;
5. add or adjust the technical tests it is allowed to, following RED/GREEN/REFACTOR where it applies (05 §3);
6. separate structural and behavioural commits (§8);
7. run the task's exact validation commands;
8. inspect its own diff to detect unrelated files or changes;
9. leave the environment as it found it: no server, process or data that the next role could take as its own (06 §10);
10. deliver a report with modified files, tests run, results, risks and decisions/assumptions.

The programmer MUST NOT:

- modify approved criteria or protected acceptance tests;
- alter CI, permissions, policies or agent configuration to make its task easier;
- hide, skip or silence failing tests;
- widen the scope with unrelated refactors;
- add dependencies without justification and the required approval;
- hand-edit code generated by tools (for example, migrations): it is regenerated;
- introduce a pattern, an abstraction or a piece the design note does not contemplate: if it thinks one is needed, it stops with `BLOCKED` and the design question;
- remove a guard marker it did not write (for example, a `#pragma` in generated code) so the control stops flagging it: it reports it;
- claim that something works without evidence of execution.

## 5. Dependencies and parallelism

Tasks may run in parallel only if their files, contracts and dependencies allow independent work. The orchestrator must identify write conflicts and define the integration.

Separate branches or worktrees SHOULD be used for concurrent agents. Two agents writing to the same files at the same time without explicit coordination is not allowed.

## 6. Blockers

If the agent discovers a dependency, a contradiction or a necessary change outside the scope, it must stop that part, explain the blocker and propose options. It must not resolve it by unilaterally widening the task.

A **denied action** (by a permission, a hook or a harness classifier) is also a blocker. The agent ends with `BLOCKED` and states the exact action it needs **from the human owner**. It does not try it another way or ask another agent to do it: that is a workaround by delegation (06 §6.1).

## 7. Closing a task

A task can move to review when:

- the expected result is implemented;
- the applicable tests were run;
- the diff is bounded and reviewed;
- no temporary changes or secrets remain;
- the execution report is complete.

Closing a task does not mean the user story is accepted.

## 8. Structural and behavioural commits

Based on *Tidy First* (Kent Beck).

- Each commit MUST be **structural** (reorganizes code without changing behaviour; all tests green before and after) **or behavioural** (changes behaviour). Never both.
- Mandatory prefixes: `struct:` for structural; `feat:`, `fix:` or `test:` for behavioural. The profile may map them to Conventional Commits.
- A structural change outside the task's surface is out of scope, even if it improves the code. It is proposed as a task of its own.

Effect: a `struct:` commit is reviewed by checking that the tests stay green; human and verifier attention concentrates on the behavioural ones.

## 9. Circuit breaker and context hygiene

- Each task MUST run in a **new session**. The context of a previous task is not reused.
- A `FAIL` cycle is: a CI run that is red because of the change, a verifier `FAIL`, or a finding after a `PASS` that the human owner orders fixed before merging (02 §9.3). It is not: a red CI run that is only waiting for a planned human approval (for example, the dependency label).
- If the same task accumulates **3 `FAIL` cycles** (CI or verifier), it stops. There is no automatic fourth attempt. The orchestrator classifies the cause and decides:
  - badly specified or too large task → back to refinement;
  - incorrect acceptance test → change control with QA (05 §6);
  - design problem → architect or Spike;
  - model or harness limitation → reassign, raise the task's model level (06 §12.1) or escalate to the human owner.
- If the agent repeats the same failed approach twice in a row, the orchestrator SHOULD restart the context with a written summary of what was learned instead of compacting it: compaction keeps the wrong assumptions.
- The profile may lower the 3-cycle threshold; raising it requires a documented exception.

## 10. Short path for T0 and T1

T0 and T1 do not go through a story's cycle, but they are not improvised either. Minimum steps:

| Step | T0 | T1 (defect, chore or stabilization batch) |
|---|---|---|
| Backlog item | Yes | Yes, with a severity if it is a defect (02 §9) and with the story of origin |
| Specification | The task | A specification PR with the item, its criterion and the surface. Approving it is the human gate |
| Reproduction check | — | A protected acceptance test or a **verification command** (05 §12), with RED confirmed; or "no RED" declared and approved (02 §8) |
| QA | No | Only if the check is a new acceptance test |
| Tasks | One | The minimum, grouped by surface; each declares which defects it turns green |
| CI | Guard + validations | Guard + validations + the item's check + regression |
| Verifier | No (unless the profile requires it) | Yes, running the check itself |
| Close | Status in the backlog | Status, check added to the regression suite, findings recorded |

A T1 that, while being worked on, turns out to touch new behaviour or a T3 risk moves up a track (02 §8).

## 11. Orchestrator sessions

- The orchestrator works on **one story, enabler or batch per session**. Carrying the context of another item makes every turn more expensive and mixes decisions; in the AES sandbox, accumulated context was most of the cost of each story.
- Mechanical writing (consolidating notes, metrics tables) SHOULD be done by a script; what cannot be scripted, by a cheap role (the mechanic). The orchestrator does not do it (09 §6–7).
