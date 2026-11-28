# 02 — Backlog and estimation

## 1. Hierarchy

AES uses this logical hierarchy:

`Product Goal / Vision → Epic → User Story → Task/Subtask → Test/Evidence`

Defects (`Bug`), technical items (`Enabler`), maintenance items (`Chore`), stabilization batches (§9.4) and research activities (`Spike`) can appear as item types related to the backlog. They must not be disguised as user stories if they do not represent user value.

Defects, chores and findings left for later are **first-class backlog items**: they have an ID, a criterion, a track and, if they are defects, a severity. A note in a document or in a PR comment is not a backlog item and gets lost.

## 2. Product goal and Epics

- The **product goal** states the overall outcome sought.
- An **Epic** groups a broad capability that must be broken down into deliverable stories.
- An Epic may have hypotheses, risks, metrics and dependencies, but it does not need detailed tasks from the start.

## 3. User stories

A user story represents a need or behaviour with identifiable value for a user or actor. Its **title** MUST have this format:

> As a [type of user], I want [capability], so that [benefit].

> As a user, I want to record a pending payment, so that I don't forget it.

Other items have their own format, because no user asks for them:

| Type | Title format | Example |
|---|---|---|
| Enabler | To [story or goal], we need [technical capability] | For the payment stories to be testable end to end, we need the app running with database, API and web |
| Defect | [Wrong behaviour, in one sentence] | An amount "abc" says "required" instead of "invalid" |
| Chore | [Maintenance change] so that [reason] | Pin the package sources so that restoring does not depend on the machine |

Each story includes verifiable acceptance criteria and scope limits, and declares with `Depends on:` the items that must be finished before it (for example, `Depends on: US-001`).

### 3.1 Atomic stories

A story MUST be **atomic**: a single user capability that can be demonstrated on its own, and that does not contain another capability that could also be demonstrated on its own. It is not measured by verbs: "create tasks and see them in my list" is one capability, because creating without seeing cannot be checked; "sign up and create tasks" is two.

- An "and" joining two user goals in the "I want" is the signal that it must be split.
- Epics and large features exist, but only as a grouping: they are implemented as atomic stories, never in one go.
- Reason: an atomic story can be verified, audited, measured and debugged. A story that involves many features at once is harder to debug, makes the agent lose control of its context and hallucinate, and delays the moment of checking that what was built is useful.

A story can be atomic for the user and still be large inside. Two objective signals force it to be split:

1. **When estimating:** 8 points or more (§5).
2. **When designing:** if the orchestrator cannot split it into **at most 3 tasks**, each within the production diff budget and turning criteria green (04 §3). Larger tasks are not made: the story is split (§10).

### 3.2 Vertical slices

Each story is a **complete vertical slice**: the minimum part of each layer (data, server, interface) for the capability to really work and be usable. A whole layer is not built before the next: "the whole database, then the whole server, then the whole interface" takes weeks to show that something was not useful, and a vertical slice shows it the same day.

- The data schema grows story by story: each story brings the migration it needs, and nothing more.
- The project's first item is a **walking skeleton**: an enabler that leaves the application running end to end with a trivial case (for example, a page that shows the status of the API, which in turn reads the database), with CI already green. The following stories thicken that skeleton.
- The same applies inside a story: first the thinnest end-to-end path, then the rules and the edge cases.

## 4. Prioritization

Priority and estimation are different dimensions. Each project SHOULD declare a simple scale, for example `P0` critical, `P1` high, `P2` normal and `P3` low. Priority represents order/value, not effort.

Prioritization considers value, urgency, risk, dependencies and cost of delay when relevant. Agents may recommend priorities, but the product owner approves significant changes.

## 5. Estimating user stories

AES uses relative story points with the Fibonacci sequence:

`1, 2, 3, 5, 8, 13`

Points express a relative combination of effort, complexity and uncertainty compared with other stories of the same project. They do NOT represent hours, days, individual productivity or a date commitment.

Guidance:

- **1:** a very small, known, low-risk change.
- **2:** small, with few dependencies and clear behaviour.
- **3:** moderate complexity, known scope.
- **5:** several parts or scenarios, but understood.
- **8:** too large for an atomic story: it MUST be split before refinement (§3.1, §10).
- **13:** too large or uncertain to plan with confidence: it is split or investigated with a Spike.

A story of 8 or more does not go to refinement: it is split into stories with verifiable value, or a Spike is created when uncertainty prevents splitting it responsibly.

Estimation must be based on the approved scope and on the project's historical references. It must not be used to compare people, models or teams.

## 6. Task size

Tasks do not need story points. They must be small, observable and verifiable. Their size is determined by the clarity of the result, the change surface, dependencies and ease of testing, not by an artificially precise duration.

A task SHOULD:

- produce one identifiable main result;
- have a concrete scope and limits;
- be implementable and debuggable without coordinating many independent changes;
- have a clear way to be validated;
- avoid mixing different responsibilities;
- be small enough to understand what failed if its test fails.

A task MUST be split if it contains several independent results, combines unrelated responsibilities, spans too many components without reason, has hidden dependencies or cannot be verified in a focused way.

No universal limit in hours is set. If a task looks large, it is split by verifiable result, not arbitrarily into fragments that make no sense on their own.

Heuristics specific to tasks run by agents (the profile adjusts them):

- the task SHOULD be completable in **a single session with fresh context**, without compaction;
- the resulting diff MUST be reviewable in one go. The task's **production budget** is a limit, not an estimate (04 §3): the profile sets it (for example, 300 lines), CI fails the task when it is exceeded by more than the profile's tolerance, and going over it requires the human's approval. In aes-todo, an "indicative" budget of 300 ended in a 2075-line PR the owner could not review (FL-007);
- the budget is estimated **separately for production code and for tests**. The deviation that requires justification is the production one: a single number punishes testing well (in the AES sandbox, 60% of a 474-line task were unit tests);
- the task SHOULD touch a single coherent change surface (04 §2).

## 7. Continuous refinement: planning on two levels

Planning has two levels, and the detail arrives late on purpose:

1. **At the start of the project** (light, during inception, 01 §2): product vision, stack, and a **complete but shallow backlog**: every known story needed to reach the complete app, each with its title in the standard format, a value line, `Depends on:`, a rough estimate and the release it targets. No detailed criteria, design or tasks.
2. **When each story's turn comes** (detailed): criteria, decisions, out of scope, technical plan and tasks. Only then, because that is when what the previous stories taught is known.

The initial backlog will change: reordering, splitting, merging or discarding stories is part of the process, not a planning failure. Only the upcoming stories need to fully meet the DoR.

A detailed plan for months of work must not be frozen if the later stories depend on discoveries not yet made.

## 8. Proportional tracks

AES does not apply the same process to every change. A known criticism of spec-driven development tools is that they turn small changes into a cascade of documents. AES avoids that cost by classifying each work item into a **track** that sets the minimum artifacts and gates.

| Track | When | Minimum artifacts | Prior human gate |
|---|---|---|---|
| **T0 — Trivial** | Typo, copy, non-functional configuration, patch update without an API change | Task + green CI | None |
| **T1 — Bug / chore** | Wrong existing behaviour, or a small change with a verifiable criterion (functional configuration, tool, script) | Item with severity (if a defect) and criterion + a **protected** reproduction check that fails (RED): an acceptance test or a verification command (05 §12) + task. Short path in 04 §10 | Approve that the check describes the correct behaviour |
| **T2 — Story** | New behaviour of known scope | Story, criteria, interface contract (if there is a new boundary), acceptance suite with confirmed RED, tasks | Approve criteria and acceptance tests |
| **T3 — High risk** | Authentication, authorization, sensitive data, payments, migrations, architectural or public-contract change | All of T2 + ADR + mandatory holdout tests + Spike if there is uncertainty | Criteria, tests, ADR; human review of the risky code afterwards |

Rules:

- The orchestrator proposes the track; the human owner may change it.
- **Moving up** a track during the work is automatic as soon as a new risk appears. **Moving down** requires a recorded justification.
- A T1 always starts with a check that reproduces the defect (or the absence of the change) and fails before the fix. If no check fails beforehand (for example, a configuration that already works by chance in the environment), the item declares it as "no RED", with the reason, and the human owner explicitly approves it.
- Defects found during verification or agentic manual testing (05 §11) that do not belong to what the task adds are recorded as T1, with a severity (§9).
- The risk levels of 07 §2 map as follows: `Low` → T0/T1/T2 by type; `Medium` → T2; `High`/`Critical` → T3.

## 9. Defects: severity and the stabilization gate

### 9.1 Severity

Severity measures the damage of the defect; priority (§4), the order in which it is worked on. They are independent. Every recorded defect has a severity:

| Severity | When | Examples |
|---|---|---|
| **Critical** | Data loss or corruption, a security flaw, the application does not start, the main flow is unusable, or CI on `dev` or `main` is red | A saved expense is lost; a user sees another user's data; `main` does not compile |
| **High** | An already accepted acceptance criterion stops being met, or an important flow fails with no reasonable workaround. A **flaky test** in the suite that runs on the main branch is High: it can turn everyone red | Editing an expense does not save; a regression test fails 1 in 3 runs |
| **Medium** | Wrong behaviour with a workaround, or in a secondary flow; a message or an error response that leads the user to a wrong conclusion | An amount `abc` says "required" instead of "invalid"; a badly encoded body returns `500` instead of `400` |
| **Minor** | Cosmetic or presentational, with no effect on data or on the user's decisions | A different thousands separator; two panels open at once with no consequence |

The orchestrator proposes the severity with the evidence of the finding; the human owner confirms or changes it. Lowering the severity of an already recorded defect is a recorded decision (03 §8), with a reason. Projects written in Spanish may use the Spanish names (Crítica, Alta, Media, Menor); the tools accept both.

### 9.2 Stabilization gate

A new story or enabler (T2/T3) **cannot become `Ready`** while the backlog has any open defect of **Critical, High or Medium** severity, or while the number of open **Minor** defects exceeds the profile's limit (5 by default).

- A **Critical** defect also stops all work in progress, including the active story: no code change is merged into `dev` or `main` except its fix. Exception: if the defect belongs to the task in progress, it is treated as a `FAIL` cycle of that task (04 §9).
- A **High or Medium** defect found during a story does not stop it: the story finishes, and the next one does not start until it is fixed.
- **Minor** defects may stay open within the limit. When it is exceeded, they are fixed in a batch before continuing.
- An "open" defect is any that is not `Accepted` (fixed and accepted), `Released` or `Rejected` (it was not a defect). `Deferred` counts as open: postponing a defect does not fix it.
- The only ways to open the gate are fixing the defects or a documented exception (00 §4). Absorbing a defect into the next story is an exception, not a normal path: it mixes fixing the old with building the new.

The same gate is evaluated when **releasing** (07 §8): a release does not ship with open Critical, High or Medium defects, or with more Minor ones than the limit. A defect in something already released can be fixed through a hotfix or through `dev`, at the human owner's choice (07 §9).

The profile may tighten the gate (for example, a lower limit for minor defects), never relax it without a documented exception. The gate SHOULD be implemented in CI (L3), reading the backlog from the protected branch; the reference implementation does so.

### 9.3 What is a defect and what is not

- A verifier `FAIL`, or a red CI check, is a `FAIL` cycle of the task (04 §9).
- After a `PASS`, each finding comes with an **origin** (from the task or pre-existing) and a **type** (defect: it breaks something written; specification gap: nothing written decides it). The default rule:

  | Finding after a PASS | What is done |
  |---|---|
  | From the task, a defect, **Medium or higher** severity | A `FAIL` cycle of the task, before merging |
  | From the task, a **Minor** defect | A backlog defect (`BUG-NNN`, of the story in progress). The human may ask to fix it now as a `FAIL` cycle |
  | From the task, a **specification gap** | Not a cycle. The specification is fixed: the note at close and the design catalogue. If the behaviour must change, it is a Minor backlog defect or a criterion of a later story |
  | Pre-existing | A backlog defect with a severity |

- The findings of CI's **second review** (05 §7.1) are a model's claims: a new critical one is a red check (a `FAIL` cycle, or the human dismisses it as a false positive); high and medium ones enter this table only once the verifier confirms them; low ones are discarded or recorded as Minor.
- A Minor finding that appears **in a re-verification**, outside what the last cycle changed, goes to the backlog: it does not open another cycle. This way a task does not spend its 3 cycles polishing details while the stabilization gate (§9.2) already limits how many Minor defects accumulate.
- A finding about **already accepted or pre-existing** behaviour is a defect: it is recorded with an ID, severity, story of origin, reproduction and criterion, even if it is found during another story.
- The human owner may replace this rule in the profile with a **permanent rule** of their own. The orchestrator applies it, records each classification as a decision and shows it to the human, who may change it before merging.

### 9.4 Stabilization batch

The defects that close the gate are fixed together in a **stabilization batch**: a backlog item (for example, `ST-NNN`) that groups the defects of a story and those associated with it.

- A batch is worked on in **a single orchestrator session**, without mixing in new functionality.
- It follows the T1 path (04 §10): a specification PR with the defects, their severity and their criterion; the reproduction checks with RED; tasks grouped by change surface; verification; close.
- The batch's reproduction checks join the regression suite when it closes, like those of a story.
- A defect the batch fails to fix stays open, and the gate stays closed.

## 10. How to split a story

Ways to split a large story, from the most common to the least. Each resulting part is still atomic, vertical and has value of its own.

| Way | When | Example |
|---|---|---|
| **Happy path first, rules later** | The story has validations, errors and edge cases | "Sign up with email and password and land signed in" first; "see a warning if the email already exists" later |
| **By data or rule variation** | The same capability applies to several types, currencies, channels or roles | One payment type now, the others later |
| **By flow steps** | The user completes stages separately | "Add a payment" and "mark a payment as done" |
| **By operation** | Create, view, edit and delete can be demonstrated separately | "Record an expense" and "edit an expense" |
| **Non-functional later** | Performance, caching, pagination, export | "See my payments" first; "see my payments paginated" when there are many |
| **Spike** | The big thing is the uncertainty, not the work | Find out how to authenticate against a provider before planning sign-in |
| **Enabler** | A technical piece is unavoidable and several stories need it | The authentication infrastructure, with its own verifiable criterion (a command or a minimal end-to-end case), never "the whole database" |

A split story keeps its order with `Depends on:`. If no way leaves it at 3 tasks or fewer, the problem is usually design or uncertainty: ask the human owner or open a Spike.

## 11. The backlog as a file, and its views

The backlog lives in **a file in the repository** (for example, `docs/backlog.md`), which is the single source of truth. It does not depend on any service, travels with the code and goes through PRs, so every change carries the human owner's signature. CI reads it (the stabilization gate, 02 §9) and agents read it without external tools.

The format MUST be a table with these columns, in any order:

| Column | Content |
|---|---|
| `ID` | `US-NNN`, `EN-NNN`, `BUG-NNN`, `CH-NNN`, `ST-NNN`, `SP-NNN`, `REL-NNN` |
| `Type` | Story, Enabler, Defect, Chore, Batch, Spike, Release |
| `Title` | In the format of its type (§3) |
| `Depends on` | Comma-separated IDs, or `—` |
| `Points` | Fibonacci (§5), or `—` |
| `Priority` | The profile's scale (§4) |
| `Severity` | Defects only (§9.1); the rest, `—` |
| `Status` | 00 §6 |

Two columns are optional and SHOULD be used from inception: `Epic`, the user action the story belongs to (§2), and `Release` (for example, `REL-001`), the release it targets (§12). With them, the backlog is also the story map: Epics on one axis, releases on the other.

A project written in Spanish may use the Spanish column names (`Tipo`, `Título`, `Requiere`, `Puntos`, `Prioridad`, `Severidad`, `Estado`); the tools accept both. The status values are always the ones in 00 §6.

For the human owner, a table in a file is not the best way to see where the project is going. **Views** (a board) are generated from the file, in one direction only:

- the reference implementation generates a self-contained HTML board, with no service at all;
- optional adapters publish the same backlog to GitHub Projects, Trello, GitLab or another board. Changing tools means changing the adapter, not the methodology;
- what is moved in a view does not flow back to the file: it is requested from the orchestrator and goes through a PR.

## 12. Releases as the planning horizon

AES plans by **releases**, not sprints. A release is a set of stories that together give a result the user can use, and it is released when it is complete and the stabilization gate allows it (§9.2, 07 §8). There is no fixed duration: with agents, the pace is set by human approval and CI, not by the calendar.

- **Inception defines the releases** (01 §2): the first one is the minimum that is already useful; the following ones, what is known to come next. Each has a one-sentence goal and a list of stories.
- **Only the release in progress is committed.** The following ones are a forecast: they are reordered with what the first one teaches.
- **Moving a story to another release** is a backlog change and goes through a PR. If the release in progress grows, the normal thing is to move stories to the next one, not to wait.
- The points accepted per release (§5) help forecast the next ones. They are not a target and are not compared across projects.
