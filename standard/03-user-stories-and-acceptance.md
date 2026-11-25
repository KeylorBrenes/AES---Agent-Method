# 03 — User stories and acceptance

## 1. Two documents: the story and the technical plan

Each refined story has **two** documents, written for different readers:

| Document | For whom | Language | Lifetime |
|---|---|---|---|
| **The story** (`US-NNN.md`) | The human owner, and anyone who wants to know what the product does | The customer's, not the programmer's: what is achieved and how it is checked, without tables, classes, endpoints or patterns | Permanent |
| **The technical plan** | The agents: orchestrator, QA, programmer, verifier | Technical: interface contract, design note, tasks, surfaces | Deleted at close, after consolidating what has future value (§1.2) |

The human owner cares about what the story does, what is left out, how one knows it works and that it works; not what the methods are called or which pattern was used. Mixing both readers in one document makes the human sign details that are not theirs to sign, and makes the agents take business language as a technical specification.

### 1.1 Content of the story

- title in the format of its type (02 §3) and `Depends on:`;
- relevant context and rules, in business terms;
- acceptance criteria in customer language (§2);
- out of scope (§4);
- **plan**: how it will be built, told as to a customer (what the user will see first, what comes next, what is left for another story);
- the orchestrator's **suggestions**: what it considers the best path and why, and which alternatives it discarded, also in customer language;
- priority, story points and track (02 §8); relevant risks;
- status and who decides;
- decision log (§8).

A good criterion in this part reads like this: "Given I am a visitor, when I sign up with a valid email and a password of at least 8 characters, then my account is created and I enter the app signed in". Not like this: "Create the `users` table, a `POST /auth` endpoint and issue a JWT".

### 1.2 Content of the technical plan

- the interface contract against which the acceptance tests are written, when the story touches an observable boundary (05 §2.1);
- the design note of each task (10 §5);
- tasks, with their change surface and the criteria they turn green (04 §2);
- the acceptance test plan (05).

At the item's **close**, before deleting the technical plan, what has value for future stories moves to where it is kept: patterns and decisions not to use something, to the design catalogue (10 §6); conventions that apply to several stories, to an ADR (01 §4). The rest is deleted: it stays in the version-control history if it is ever needed. Acceptance tests and verification commands are **not** part of the plan: they are the regression suite and are kept.

Fields must not be filled with empty text. An item may stay in `Draft` until there is enough information.

## 2. Acceptance criteria

Criteria must express observable results, not unnecessary internal details. They must be:

- clear and not contradictory;
- checkable through an action, a result or an inspection;
- tied to the goal and the scope;
- specific about permissions, errors and limits when relevant;
- independent of a particular implementation unless there is an approved technical constraint.

In the story, criteria are written in structured natural language (Given / When / Then) and in the user's terms. The observable detail the tests need (selectors, routes, response codes) goes in the technical plan's interface contract, not in the criterion.

## 3. Negative cases and limits

Where they apply, criteria SHOULD cover:

- invalid or incomplete input;
- missing data;
- duplicates and conflicts;
- users without permissions;
- errors from external services;
- **failure of every action that writes** (save, edit, delete, send): what the user sees if the response is not successful and if the network fails, and which transitions clear that error state;
- boundary states and concurrency;
- compatibility with existing behaviour;
- accessibility, privacy and security.

Not every scenario applies to every story. QA must briefly explain why a relevant risk scenario is left out.

The failure of an action that writes MUST have a criterion in every story with a user interface. In the AES sandbox, both `FAIL` cycles of one story came from the same gap: no criterion said what happened when saving or deleting failed, and when the error message was added nobody listed what cleared it.

## 4. Out of scope

Exclusions are mandatory when there is a reasonable risk of scope creep. They must name nearby features the agent might implement "for convenience" but that are not approved.

In T2 and T3 the "Out of scope" section MUST NOT be empty. Implementing features nobody asked for, even when it looks like the reasonable next step, is one of the most frequent drift signals in agents; explicitly naming what is excluded is the cheapest way to prevent it.

## 5. Ambiguity and assumptions

Agents must not invent product behaviour. They must:

- ask for a human decision on ambiguities that affect visible behaviour, data, security, costs, integrations, compliance or irreversible decisions;
- record as an assumption a decision that is low-risk, reversible and consistent with existing patterns;
- choose the simplest, most consistent alternative when the detail is local and does not change the product contract;
- report the assumption in the execution report.

**QA assumptions** deserve their own rule. When writing the tests, QA has to fix details the contract does not state (the type of control for a field, a format, what happens in an edge case). If those assumptions reach the suite without a decision, QA defines the product and nobody signed it. Therefore:

- QA MUST list in the test plan everything it had to assume;
- each assumption becomes contract (a recorded decision, §8) or is rejected **before** the story becomes `Ready`;
- no open assumption passes the DoR.

The user must not be interrupted for trivial internal decisions that the standard already delegates to the technical team.

## 6. Traceability

Each acceptance criterion must be linked to one or more scenarios/tests or to an explicit justification for manual verification. Each task must reference the story and the criteria it helps satisfy.

Traceability SHOULD be machine-checkable:

- each acceptance test carries the ID of its story and of its criterion (for example, the tags `@US-002` and `@US-002-AC-03`, and `AC-03` at the start of the title);
- each task declares the criteria it turns green (04 §2), so that CI runs only those (05 §12);
- every test is derived from an approved criterion. If QA sees a gap, it proposes a new criterion; it does not write a test without a criterion.

A criterion that describes behaviour the code **already has** cannot show RED. Its verification is the **regression** suite of the story that owns that behaviour (05 §2.4), and the criterion says so: "Verification: regression of US-001".

A list of tests without links to the requirements does not count as sufficient traceability.

## 7. Changes to the story

Once the story is `Ready`, changes to scope, expected behaviour or acceptance criteria require change control. Editorial corrections that do not change the meaning can be made without re-approval, leaving history when the tool allows it.

## 8. Decision log

Each story has a "Decisions" section. Each resolved ambiguity and each assumption turned into contract is a row:

| ID | Question | Options | Decision | Who and when | Impact |
|---|---|---|---|---|---|
| D-01 | Which category stays selected when an edit is cancelled? | Back to the initial one / the last one stays | Back to the initial one | Human owner, 2026-11-05 | AC-12 modified |

Rules:

- The decision enters the story **in the same PR** that uses it (refinement or tests). Approving that PR is the human owner's signature.
- "Impact" states what changed: a new or modified criterion, the interface contract, an ADR, or "none".
- A decision that applies to more than one story moves up to an ADR (01 §4).
- A decision that turns out to rest on a false fact is corrected **in its row**, with a date and a reason; it is not deleted.
- Decisions the orchestrator makes by applying a permanent rule of the human (02 §9.3) are also recorded, citing the rule.
