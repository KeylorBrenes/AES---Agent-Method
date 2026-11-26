# 01 — Project initiation and architecture

## 1. Goal

Establish a shared understanding of the product and an architecture good enough to guide the increments, without designing every detail prematurely.

## 2. Inception: from idea to backlog

Before writing code, the product owner and the orchestrator **talk in natural language** until the idea is clear enough to plan. Inception produces the vision, the complete but shallow backlog, the initial architecture and the stack. It does not produce detailed criteria, task design or code: that comes when each story's turn comes (02 §7).

The orchestrator leads it, on the most capable model available (06 §11): this conversation produces the story split and the architecture decisions that everything else inherits.

### 2.1 The interview

The orchestrator asks **by topic, in short blocks of concrete questions**:

| Topic | What must become clear |
|---|---|
| Problem and users | Who uses the product, what they do today without it and what hurts |
| What the user does | The main actions, from start to finish (they will be the Epics of the story map) |
| Data and rules | What is stored, which rules constrain it, what happens in the odd cases |
| Constraints | Privacy, access, devices, language, deadlines, budget, integrations |
| Stack and operation | Technology preferences or constraints, where it runs, who maintains it |
| First release | What is the minimum that is already useful, and what can wait |
| Interface (if any) | Tone of the copy, accessibility, existing brand and assets, non-negotiable visual constraints |

Rules for the questions:

- **One block is one topic**, with 2 to 5 questions. Topics are not mixed, and the whole interview is not sent at once.
- **Each question is concrete and is answered in one or two sentences.** When there are reasonable options, the orchestrator proposes them with its recommendation, and the owner chooses or corrects. "What else do you need?" or "How do you imagine the app?" are not AES questions: they make the owner do the orchestrator's job.
- **Ask about behaviour, not technology**, except in the stack block. "Can a task have a due date?", not "Do we store a nullable `DateOnly`?".
- **Each block builds on the previous answers.** Before the next one, the orchestrator summarizes in three or four lines what it understood, so the owner can correct it in time.
- **What the owner does not know is not invented:** it stays "to be defined" in the brief (an assumption or uncertainty, with how it will be resolved), or it becomes a Spike (§7).

### 2.2 When to stop

The interview ends when:

1. each main user action has stories with a title in the standard format (02 §3), a value line, `Depends on:` and a rough estimate;
2. the first release is bounded: which stories go in and what observable result it gives;
3. there is enough information to choose the stack and describe the architecture of the walking skeleton;
4. what is missing is named as "to be defined" or as a Spike, with who will resolve it and when.

Questions do not continue in order to complete the detail of distant stories. That detail is asked during each story's refinement, when what the previous ones taught is already visible.

### 2.3 What it produces

1. **Project brief:** problem, users, goals, scope, out of scope, constraints, assumptions and uncertainties, risks, and the planned releases.
2. **Initial backlog, complete but shallow** (02 §7, §11): every known story needed to reach the product, grouped by Epic and assigned to a release. Stories pass the atomicity check (02 §3.1) from the start: splitting during inception is cheap, splitting halfway through implementation is not.
3. **Architecture overview** (§3) of the skeleton and the first stories, with a component diagram. The text is the source; the diagram is a view and is regenerated from it.
4. **Stack ADR** (§4): options considered and why one is chosen.
5. **Project profile:** stack, environment, commands, conventions, quality controls, agents, permissions, skills, tools and the project language (`AES_LANG`).
6. **Quality strategy:** test levels, CI and applicable controls.
7. **Visual direction** (if there is an interface): the product's visual system (colours, typography, components, tone), chosen by the human owner among concrete options, like the stack. The agent proposes and the human chooses; the agent does not decide it from the answers it got. EN-001 builds the interface with it already in place.
8. **EN-001, the walking skeleton** (02 §3.2), first in the backlog: the application running end to end, with CI green, on which the stories grow.
9. **A local copy of the rules the agents consult:** at least the DoR and DoD checklists (08) inside the repository (for example, `docs/aes/`), with the AES version they come from. An agent that only has the reference "AES 08" reviews the DoR from memory.
10. **The environment check** for the chosen stack (`AES_DOCTOR_CHECKS`), run before EN-001, so everything missing on the machine is requested in one round.
11. **The project's feedback rules** (05 §13): the general principles translated to the chosen stack, with the feedback budget, in the profile. EN-001 builds the CI and the acceptance fixture by them.

### 2.4 Approval and review

All of the above goes into **one inception PR**, approved by the human owner. Until then, nothing produced is a commitment; afterwards, changing it is normal and goes through a PR like any other backlog change.

When a new idea appears that does not fit the backlog (a new Epic, a change of users or scope), the orchestrator runs a **mini-inception**: only the affected blocks, with the same rules, and a PR that updates the brief, the backlog and, if needed, the architecture. A new story inside an existing Epic does not need a mini-inception: it is added to the backlog.

### 2.5 Existing project

When working on an existing project, the repository and the current behaviour are inspected first, and the interview starts with what the code does not say (what it is for, who uses it, what is missing). It is not assumed that the documentation is up to date or that the desired architecture matches the implemented one.

## 3. Minimum architecture content

The architecture document SHOULD cover, in proportion to the project:

- purpose, system boundaries and external actors;
- components/modules and responsibilities;
- dependencies and their direction;
- technology stack and relevant versions;
- persistence, main entities and data ownership;
- authentication, authorization and trust boundaries;
- integrations and external contracts;
- deployment, configuration and observability, where they apply;
- relevant non-functional constraints: performance, availability, privacy, accessibility, maintainability and security.

Defining classes, functions, tables or endpoints that are not needed yet is not required. The detailed design of a story is done during its refinement.

## 4. Architecture decisions (ADR)

An ADR SHOULD be created for decisions with material impact, hard reversal or cross-cutting effect, for example:

- choosing or replacing a fundamental technology;
- boundaries between modules or services;
- persistence or data-migration strategy;
- authentication/authorization;
- important integration contracts;
- scalability, security or deployment decisions;
- **conventions that apply to more than one story**: how input is validated, how errors are shown, which UI control is used for each data type, date and amount formats. If a convention is decided inside a story and applies to the next ones, it moves up to an ADR; otherwise the next story asks again, or the first agent that writes a test fixes it without anyone signing it.

An ADR must summarize context, decision, alternatives considered, consequences, risks, status and date. ADRs are not created for trivial local choices.

Accepted ADRs are the decision history. If a decision changes, a new ADR supersedes it; the past is not rewritten to hide the change.

## 5. Architectural evolution

Architecture is evolutionary. Before implementing a story, the architect/orchestrator MUST identify whether the change:

- fits within the existing boundaries;
- changes a contract or a dependency;
- introduces a new technology or dependency;
- affects security, data, performance or deployment;
- requires a human decision.

Local, reversible changes can be documented in the task or in the change history. Cross-cutting changes require an ADR and approval according to the project profile.

## 6. Rule against over-engineering

An agent MUST NOT create an abstraction, layer, service, microservice, generic system, internal framework, configuration mechanism or dependency "just in case".

Before proposing one, it must show:

1. which current requirement needs it;
2. why the existing solution is not enough;
3. which simpler alternatives were considered;
4. what maintenance cost it introduces.

The default option is the simplest solution that satisfies the approved requirements and keeps the architectural boundaries.

## 7. Research and spikes

When there is material technical uncertainty, a research `Spike` can be created. A Spike has a question, a time/effort limit set by the project, an evaluation method and an expected result (a decision, a throwaway prototype or evidence). A Spike must not automatically become production implementation.
