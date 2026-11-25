# 00 — AES Core governance and principles

## 1. Purpose

AES defines a reproducible process for producing correct, maintainable and verifiable software with people and AI agents. The goal is not to maximize documents or code-generation speed: it is to deliver useful behaviour, within the approved scope, with sufficient evidence of quality.

## 2. Mandatory principles

1. **Value before activity.** Work is organized around outcomes for users or justified technical needs, not around the amount of code or documents.
2. **Progressive planning.** The vision and the architectural boundaries are set early; implementation detail is added when the work gets close and there is enough information.
3. **One source of truth.** Approved requirements, acceptance criteria and current decisions must have an identifiable location. Chat messages do not replace the project's artifacts.
4. **Explicit scope.** Each user story defines what is included and, when relevant, what is excluded. Agents MUST NOT widen the scope on their own initiative.
5. **Small, verifiable tasks.** A task must produce a concrete result, have clear limits and be checkable without having to accept a large amount of unrelated work.
6. **Tests from the requirement.** Acceptance criteria are defined before implementing. Technical tests accompany development.
7. **Independent verification.** The agent that implements cannot approve its own work. Verification is based on artifacts and evidence, not on the implementer's report.
8. **Security through permissions.** Important restrictions are enforced technically through Git, the operating system, containers, permissions, CI and branch protection; not only through prompts. A control only counts as technical if the agent cannot disable or bypass it from its own environment (see 06 §9, the L1/L2/L3 layer model).
9. **Deliberate simplicity.** What exists is reused, and abstractions, dependencies, layers or features are not added without a demonstrable need.
10. **Traceability proportional to risk.** Important changes must be traceable from the requirement to the evidence. Trivial changes do not require bureaucracy.
11. **Transparent uncertainty.** Agents must distinguish verified facts, assumptions, risks and what has not been verified.
12. **Human approval of reserved decisions.** Agents may recommend; they cannot take over product decisions, material scope changes, critical risks or human acceptance.
13. **The acceptance test is the executable specification.** Prose explains the intent; the protected acceptance suite makes it enforceable. When a prose specification and an approved acceptance test disagree, the discrepancy is a specification defect resolved through change control. No agent decides on its own which of the two prevails.
14. **Executed evidence, not narrated evidence.** Only output captured by CI, or by a tool that runs and records the command, counts as evidence. A summary written by an agent is context, not evidence.
15. **Proportional process.** The size of the process depends on the track of the change (02 §8). A trivial change does not go through the cycle of a high-risk story, and a high-risk change is not treated as trivial.
16. **Continuous improvement of the harness.** Agent failures are recorded and turned into controls (09). The same mistake must not depend on someone remembering it.
17. **Stability before progress.** New functionality is not built on top of known defects. Defects are classified by severity and fixed before starting the next story, except minor ones (02 §9). Fixing an old defect while building something new mixes two changes and produces new defects.
18. **Every decision is signed.** Every ambiguity that affects the product is resolved with a recorded decision: who, when, which options there were and what changed (03 §8). What nobody explicitly decided is not a decision, even if a test or an agent has already fixed it.
19. **What is stable is separate from what is being built.** The main branch only contains what has been released; everything else is first integrated into a development branch (07 §7). A fix to something released starts from what was released, not from what is under construction.
20. **Fixed principles, patterns with a reason.** Level-1 design principles apply always, to all code; patterns, only with a present reason, and deciding not to use them counts as much as deciding to use them (10). None of them is requested through a generic instruction: they are requested through rules, symptoms and a concrete design note.
21. **Vertical slices, atomic stories, detail just in time.** Each story is a single user capability, built end to end (data, server, interface) and checkable the same day; never a whole layer before the next one. The backlog is planned complete but shallow at the start, and the technical detail of each story is decided when its turn comes (02 §3, §7).

## 3. Adaptability

AES Core is common across projects. Each project may adapt:

- language, framework, database and providers;
- folder structure and tracking tools;
- build, lint, analysis and test commands;
- coverage thresholds and stack-specific controls;
- models, harnesses, MCP servers, skills and available tools;
- the language its artifacts are written in (`AES_LANG`); AES itself is written in English.

A project MUST NOT weaken security controls, verification independence, acceptance-test protection, traceability of relevant changes or the approval of reserved decisions without a documented exception.

## 4. Exceptions

An exception to a SHOULD/MUST rule must record:

- the affected rule;
- reason and context;
- risks introduced;
- mitigation or compensating control;
- who approved it;
- expiry date or condition, if any.

An exception must not be presented as normal compliance with the standard. Exceptions to fundamental controls MUST be approved by the project's human owner.

## 5. Roles and authority

The names may change with the tools, but the responsibilities must be kept:

- **Product owner / human:** defines goals and priorities; approves material scope changes, reserved decisions and product acceptance.
- **Orchestrator:** coordinates the process, prepares context, delegates work, keeps states and enforces gates. It is the senior designer: it decides the patterns of each task (10 §5), so it runs on the most capable model available. It does not invent requirements or approve itself.
- **Architect:** analyses structure and technical consequences; proposes decisions and ADRs. The orchestrator may take this role.
- **Test designer / QA:** turns approved criteria into acceptance scenarios and tests; protects their integrity.
- **Programmer:** implements bounded tasks and the technical tests it is allowed to write.
- **Mechanic (optional):** makes mechanical, bounded changes (non-functional configuration, renames, formatting, consolidating notes) with no new logic. It allows that work to be assigned to a cheaper model.
- **Independent verifier:** checks the result against requirements and evidence; does not modify the code under review.
- **CI and deterministic tools:** run repeatable controls. Their results are kept as evidence.

In a small project one person or model may take more than one role, but implementation and approval/verification must stay separate. If the same model is reused, the verification run must be new, with separate context and read-only permissions.

## 6. Work states

Projects SHOULD use, at least, states equivalent to:

- `Draft`: still being defined.
- `Ready`: meets the Definition of Ready.
- `In Progress`: implementation underway.
- `In Review`: waiting for review or verification.
- `Blocked`: depends on a decision, resource or fix.
- `Ready for Acceptance`: technical gates passed; human acceptance is missing where it applies.
- `Accepted`: accepted by the corresponding authority and integrated into the development branch (07 §7).
- `Released`: integrated into the main branch through a release (07 §8) or a hotfix (07 §9).
- `Rejected`: not accepted; needs a fix or a rethink.
- `Deferred`: postponed, with a reason.

`Done` must not be used as a synonym for "the agent finished writing code".

## 7. Evidence and claims

An agent MUST NOT claim that a test passed if it did not run it and does not have the result. If a test could not be run, it is reported as `NOT RUN` or `BLOCKED`, with the reason. Results must include the command or procedure, the relevant environment and summarized output when possible.

Every claim about the repository or the product is checked **at its source**, not in a reflection of it:

- versioned content, in what is versioned (`git show`, `git cat-file`), not in the working copy, which may differ (for example, in line endings);
- implemented behaviour, in the code or by running it, not in the tests that describe it or in the implementer's report;
- what ran in CI, in the run's log, not in the colour of the check.

The rule applies to agents and also to the records written by the human or an assistant: a record written from memory is an assumption until it is checked.

## 8. Proportional human review

AES does not expect the human owner to read every line of code, but it does not allow nobody to review anything either. Human review moves **from the code to the contracts**: if the human is not going to read the code, they MUST read and approve the acceptance tests, because they are the only thing the process trusts without intermediaries.

| When | What the human reviews | T0 | T1 | T2 | T3 |
|---|---|---|---|---|---|
| Before | Acceptance criteria and exclusions | — | ✓ | ✓ | ✓ |
| Before | Acceptance tests (scenarios and key assertions) | — | ✓ | ✓ | ✓ |
| Before | Interface contract / ADR | — | — | if it changes | ✓ |
| Before | Recorded decisions and resolved QA assumptions (03 §8) | — | ✓ | ✓ | ✓ |
| After, before merging | Verification report and evidence (outputs, screenshots) | — | ✓ | ✓ | ✓ |
| After | Severity of the defects found (02 §9) | if any | if any | if any | if any |
| After | CI guard alerts (surface, cheating) | if any | if any | if any | ✓ |
| After | Code | quick read of the diff | optional | only flagged areas | **risk areas, mandatory** |
| After | Their own demonstration or functional test | — | — | ✓ | ✓ |

In T3 there is no responsible way to skip the human review of sensitive code (authentication, authorization, data, payments, migrations). The project profile may tighten this table, never relax it without a documented exception.
