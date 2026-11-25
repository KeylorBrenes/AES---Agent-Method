# 10 — Design principles and patterns

## 1. Goal

That code, small or large, can be understood, tested, debugged and grown without rewriting it, **without** adding structure nobody needs yet.

Telling a model "apply SOLID" or "write clean code" gives it no information it did not have: it adds noise. This chapter turns those principles into rules with a checkable symptom and an explicit boundary of when they do not apply, and gives someone with judgement the decision of which pattern to use in each case.

## 2. Two levels

A principle is **level 1 (always mandatory)** if it meets all three conditions:

1. **Applying it today costs almost nothing:** it adds no types, layers or indirection; it is a way of writing what was going to be written anyway.
2. **Applying it later costs more and more:** introducing it into existing code grows with the size of that code.
3. **It is local:** it does not force other modules to be designed around it.

What does not meet all three is **level 2 (conditional)**: it is applied only when there is a **present reason**, that is, real variants in the code, backlog stories that ask for it or an ADR. "Just in case" is not a present reason.

The two levels reinforce each other: level-1 principles are what make adding a level-2 pattern later a local change rather than a refactor of the whole code. That is why level 2 can wait without waiting being expensive.

## 3. Level 1: always mandatory principles

They apply to all of the project's code, in any language, scripts included. A violation is a verifier finding (from the task → a `FAIL` cycle). Exceptions are documented exceptions (00 §4).

| Principle | What it requires | Symptom of a violation |
|---|---|---|
| **Single responsibility** | Each function and each module does one thing. In a script: reading the input, processing and writing the output are different functions | A unit that changes for two reasons; a name with "and" or a vague one (`process`, `handle`, `utils`) |
| **Logic separate from input/output** | Business rules receive data and return data; they do not read files or call the network or the database | A rule that cannot be tested without bringing up the database, the server or the file system |
| **Dependencies received, not created** | What a piece needs it receives as a parameter or through its constructor; it does not create it inside or take it from a global. It does not require creating interfaces | A business rule that instantiates an HTTP client, a connection or a clock, or reads a global |
| **Data access grouped by feature** | A feature's queries and writes live together, in one place | The same query, or almost the same, spread over several files |
| **Explicit contracts at the boundaries** | What is exposed (API, CLI, events) has its own types, distinct from the internal ones | Changing an internal column or type changes the public response |
| **Explicit errors** | Fail early, with a message that says what and where; no error is silenced | An empty `catch`; returning `null`, `-1` or an empty string to signal an error |
| **Substitution (Liskov)** | If inheritance is used, a subclass works wherever its base is expected. Composition is the default | A subclass that throws "not supported", ignores or weakens a method of its base |
| **Small interfaces** | When an interface is created (for a level-2 reason), it contains only what its clients use. It is not a reason to create interfaces | An implementation with empty methods or methods that throw "not implemented" |
| **Minimal visibility** | Everything is private except what another piece needs to use | Public members used only inside their own module |
| **Configuration outside the code** | Addresses, paths, credentials and values that change per environment come from the environment or the configuration | A value from a specific environment written in the code |
| **Validate at the boundary and convert** ("parse, don't validate") | What comes in (request, file, argument) is validated once, at the boundary, and converted to a type that can no longer be invalid; the inside works with that type | The same validation repeated inside the system; internal functions that check again whether a value is null, empty or well-formed |
| **No provisional code** | A minimal slice is written with the structure it is going to have: each piece in the file and module it belongs to from the first commit, even if that means four two-line files instead of one six-line file. "We'll refactor it later" is not a plan | A file that piles up pieces of different responsibilities to get it working quickly (everything in `App.tsx`, the whole API in `Program.cs`); logic inside interface components or endpoints; comments such as "temporary", "for now", "TODO: move" |
| **Strict compiler checks** | The language's strict mode is on (for example, `strict` in TypeScript, nullable reference types and warnings as errors in C#, `set -euo pipefail` in bash) | Values that can be null without the type saying so; compiler warnings ignored |

What a stack linter can detect (maximum complexity and length per function and per file, one component per file, empty `catch` blocks, global variables, ShellCheck on scripts) SHOULD go to CI (L3): that way it stops depending on someone remembering it. The profile lists which level-1 rules its CI covers. Pending-work markers (`TODO`, `FIXME`, `HACK`) added by an agent are treated as guard markers (05 §10): they require human approval or a backlog item that resolves them.

Models tend toward the shortest path that makes something work, and that path is not usually the one that avoids rework. That is why this rule is not left to the agent's judgement: the design note says which file each piece goes in, and putting them together is a finding of the task (a `FAIL` cycle).

## 4. Level 2: conditional principles and patterns

| Principle or pattern | When yes | When not |
|---|---|---|
| **Open/closed** | The variation already exists: there are two or more real variants, or they are in the backlog | To "make future extensions easier" that nobody asked for |
| **DRY (don't repeat yourself)** | On the **third** repetition of the same knowledge, not of the same text | Two fragments that look alike but change for different reasons: unifying them creates the wrong abstraction |
| **Interface or abstraction** | There are two implementations, or the tests need to replace the dependency and the language does not allow it without an interface | A single implementation with no other in sight |
| **Repository** | Several data sources for the same aggregate, complex queries repeated across features, or an ADR that asks for it | On top of an ORM that already is a repository, with one source and simple queries |
| **Strategy** | Several ways of doing the same thing chosen at run time, already present or in the backlog | A single way, or two that do not change |
| **Observer / events** | Several independent consumers of the same fact, or decoupling modules that would otherwise call each other in a chain | A single known consumer: a direct call is clearer and easier to debug |
| **Factory** | Creation has real logic (choosing a type, validating, assembling several pieces) | A `new` with parameters |
| **Mediator, CQRS, command bus** | An ADR that justifies it by scale, auditing or separating read and write models | A CRUD |
| **Generics and plugins** | Three concrete cases that share the shape | The first case |
| **Own types for domain concepts** (*value objects*: an amount, an email, a period) | The concept has its own rules (range, format, rounding) that today are checked in more than one place, or a units mistake already caused a defect | A value without rules that is only carried around |
| **Impossible states unrepresentable** (discriminated unions, typed state machines) | An object with fields that only make sense in some states, and invalid combinations that have already appeared | Two or three simple states that an enum expresses well |

The table is not exhaustive. Every level-2 pattern is decided with the same question: **what present reason justifies it, and what would it cost to add it later if level 1 is respected?** If the answer to the second is "little", wait.

## 5. Design note

The **orchestrator** decides level 2 and acts as the team's senior designer. That is why it MUST run on the most capable model available (06 §11): choosing a pattern, and above all deciding not to use one, is reasoning, not writing.

**When:**

- in each T2/T3 story or enabler, when splitting into tasks and before `Ready`: one design note per task;
- on demand: if the programmer has a design question halfway through a task, it ends with `BLOCKED` and the question; the orchestrator answers with a new note or an amendment.

**What it decides with:** facts, not another agent's account (00 §7):

- the story, its criteria and the interface contract;
- the ADRs and the project's **design catalogue** (§6);
- a **structural outline** generated by a tool: the files and the public signatures, without the implementations' code; or, if the project uses one, a code graph generated by syntactic analysis, of which only the relationships extracted from the code count as facts, not the inferred ones;
- the programmer's question, if there is one.

**What it produces** (template `templates/design-note.md`):

- which pieces to create or change, where and with which responsibility each one;
- which level-2 pattern is used, with its present reason;
- **what is not done**, explicitly ("no interface is created for X: there is a single implementation"), with the same weight as what is;
- how level 1 is applied where it is not obvious (for example, where the logic ends and input/output begins);
- **the decisions the verifier will test**, so the programmer does not improvise them: for tasks that add or change API routes, the **API edges** (what an unsupported method, an unknown route and the trailing slash return for each prefix, with which error body, and which fallback covers them); for tasks with an interface, the **dynamic behaviour** (where focus goes after each state transition, which live regions exist from page load, which focus ring each type of element shows, whether a message reserves space, and which responses the technical tests must cover, including a success with an unexpected body).

The note goes in the task's specification and the human owner approves it with the rest of the tests-and-tasks PR. A decision that applies to more than one story moves up to an ADR (01 §4).

Every decision the note leaves open is a likely `FAIL` cycle: in aes-todo, the three FAIL cycles of one interface task came from focus, live regions and focus rings that the note did not specify; the same kind of task, with those decisions written, passed verification on the first attempt.

## 6. The project's design catalogue

Each project keeps `docs/design-catalog.md` (template `templates/design-catalog.md`): which level-2 patterns it uses, where, why and what it decided not to use. It is the project's design memory: without it, each design note decides the same thing again, or decides differently.

The orchestrator updates it when each item closes with what the design notes introduced.

## 7. Verification

- The design note is part of the task's contract: the verifier reviews the diff against it as it does against the change surface. A pattern the note does not authorize, or a piece with a responsibility other than the assigned one, is a finding.
- The verifier reviews the diff against the level-1 symptoms (§3).
- What a linter detects in CI does not need to be reviewed by hand; what it does not, does.
