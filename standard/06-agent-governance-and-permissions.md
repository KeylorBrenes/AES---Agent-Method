# 06 — Agent governance and permissions

## 1. Goal

Separate responsibilities, limit context and restrict each agent's actions to reduce drift, conflicts, leaks and self-approval.

## 2. Base roles

### Human product owner

- approves the vision, priorities and product criteria;
- resolves material ambiguities;
- approves material changes of scope, cross-cutting architecture, security and irreversible decisions;
- accepts the product/feature according to the project profile.

### Orchestrator

- keeps the state of the backlog and the cycle;
- assigns agents and gives them the minimum sufficient context;
- checks that the task meets the DoR;
- controls dependencies, limits and gates;
- aggregates evidence and reports blockers;
- does not alter requirements to accommodate an implementation;
- is the **senior designer**: it decides each task's level-2 patterns in a design note, from facts and not from another agent's account (10 §5).

### Architect

- inspects the current architecture;
- identifies impacts, alternatives and risks;
- proposes changes and ADRs;
- does not impose material changes without approval.

### QA / Test designer

- derives scenarios from approved criteria;
- creates and maintains the protected suite in an authorized space/flow;
- checks traceability and negative cases;
- does not implement the functionality it is defining as acceptance.

### Programmer

- implements assigned tasks;
- adds the technical tests it is allowed to;
- does not modify acceptance contracts or approve its own work;
- reports assumptions, deviations and blockers.

### Mechanic (optional)

- runs mechanical tasks within a change surface: non-functional configuration, renames, formatting, consolidating notes and metrics;
- has the programmer's permissions, limited to its task;
- if the task requires deciding behaviour or designing, it stops with `BLOCKED`: that task is not mechanical.

### Verifier

- inspects the specification, the diff and the evidence;
- runs or reviews tests according to its permissions;
- looks for non-compliance, regressions, risks and over-engineering;
- is read-only with respect to the code under review;
- does not change the scope or silently fix the work.

## 3. Base permission matrix

The exact enforcement is defined in the profile, but the intent must not change:

| Resource/action | Orchestrator | Architect | QA | Programmer | Verifier |
|---|---|---|---|---|---|
| Read the repository | Yes | Yes | Yes | Yes | Yes |
| Propose requirements | Yes | Advises | Advises | No | No |
| Approve product scope | No, recommends | No | No | No | No |
| Propose an ADR | Yes | Yes | No | May suggest | May point out |
| Approve a reserved ADR | No | No | No | No | No |
| Write protected acceptance tests | No, coordinates | No | Yes, authorized flow | No | No |
| Modify production code | As needed/configured | Not by default | No | Yes, within the task | No |
| Modify unit/integration tests | Not by default | No | May review | Yes, within the task | No |
| Write/read holdout tests | Coordinates, does not read | No | Yes, authorized flow | **No** (not even read) | Runs them |
| Publish a task's change surface | Yes, on the protected branch | Advises | No | No | No |
| Modify CI/protections | Not without authorization | No | No | No | No |
| Modify `AGENTS.md`, hooks, skills, permissions | Proposes; needs human approval | No | No | No | No |
| Run tests | Yes | Yes | Yes | Yes | Yes |
| Approve its own work | No | No | No | No | No |
| Issue a verification report | Does not replace it | May contribute | May contribute | No | Yes |

The mechanic, when there is one, has the programmer's column.

## 4. Verifier isolation

The verifier must start a separate run and receive directly:

- the relevant original request;
- the approved user story and acceptance criteria;
- the applicable ADRs/contracts;
- the real diff and the inspected commit/branch;
- the original CI and test results;
- verification instructions.

It must not receive, as a source of truth, the programmer's private reasoning, self-assessment or promotional summary. It may read the code and the artifacts it needs to check the result.

Independence depends mainly on the separation of permissions, context and evidence. Using another provider/model can add diversity, but it does not replace those controls.

The orchestrator may add **points of attention**: concrete, checkable facts (a commit, a file, a behaviour change it noticed), never conclusions. The verifier treats them as hypotheses it checks itself.

Verification happens **before merging**. Verifying afterwards (for example, because something was merged by mistake) is an incident that is recorded, and it loses information: with squash merges, the verifier no longer sees the individual commits.

The verifier MUST re-run the validations instead of accepting the programmer's, run the holdout tests when they exist and perform the agentic manual test that corresponds to the track (05 §11). It also watches for the drift signals Kent Beck describes in *Augmented Coding: Beyond the Vibes*:

1. loops: repetitive or unnecessary code, or the agent stuck repeating attempts;
2. functionality nobody asked for, even if it looks like the reasonable next step;
3. any sign of cheating, such as disabling, deleting or weakening tests.

Any of the three is reason enough for `FAIL`.

Each finding the verifier reports carries an origin, a **type** (a defect: it breaks something written, citing the rule; or a specification gap: nothing written decides it) and a proposed severity. What is done with it is decided by the rule of 02 §9.3, not by the verifier. In a **re-verification**, the manual test is limited to what the cycle changed plus a short regression pass (05 §11).

## 5. Minimum sufficient context

The orchestrator must deliver relevant information, not the whole chat history or the repository indiscriminately. The package usually includes: task, story, related criteria, relevant architecture/ADRs, contracts and conventions, relevant paths and validation commands.

Agents must state what information is missing. They must not fill gaps by inventing APIs, structures or rules.

The context delivered SHOULD be **structural** (exact commands, paths, change surface, affected tests, contracts) and not **generic procedural** (04 §2).

### 5.1 Persistent instructions (`AGENTS.md`, `CLAUDE.md` and equivalents)

- MUST NOT contain generic process instructions ("use TDD", "write clean code", "run the relevant tests"). They add no information and consume context.
- SHOULD be brief and contain: build/test/lint commands, forbidden paths, architectural constraints, conventions a linter does not catch and observed agent failures.
- SHOULD start late and grow **one entry per real mistake** worth recording (09).
- In large repositories they SHOULD point to the relevant files instead of copying their content.
- They live in protected paths: the programmer cannot modify them.

## 6. Tools, MCP, skills and hooks

- **Harness:** runs the agent's loop and controls context/tools.
- **MCP:** exposes external tools or resources.
- **Skills:** reusable instructions/procedures for an agent.
- **Hooks:** automate actions on defined events.
- **CLI/API:** allow delegating to another process or service.

The project profile defines the concrete implementations. A skill does not grant permissions. An MCP server must not expose more privileges than needed. Hooks do not replace CI or review.

Skills:

- SHOULD be built **after** evaluating the agent on representative tasks and seeing where it fails, not in advance (09).
- MUST be installed only from trusted sources. Third-party ones are audited before use: included files, scripts, dependencies and any instruction that connects to untrusted external networks.

### 6.1 Denied actions and workarounds by delegation

When a permission, a hook or a harness classifier denies an action to an agent, the agent may try to get it another way: another command, or asking another agent to do it. The latter is a **workaround by delegation**, and no technical control detects it: in the AES sandbox, two subagents asked the orchestrator to stop processes they had been denied permission to stop.

Rules:

- A denied action is `BLOCKED` **for the human owner**, with the exact action that is needed.
- No agent performs an action that was denied to another role, even if it does have the permission.
- The orchestrator records the case and passes it to the human; it does not resolve it.

### 6.2 Skill types and the AES core

Skills strengthen the methodology if they fit into it, and paralyse it if they compete with it. AES distinguishes three types:

| Type | What it is | Rule |
|---|---|---|
| **Technique** | How to do an activity well: debugging, security review, writing a design note | Assigned to the roles that do that activity. It MUST NOT contradict an AES gate, contract or permission |
| **Tool** | Wraps a deterministic analysis (static analysis, code graph) | What the tool detects deterministically SHOULD run in CI (L3); the skill helps interpret and fix, it is not the control |
| **Workflow** | Orchestrates the whole cycle: plans, execution, review, closing branches | MUST NOT be installed alongside AES. Two methodologies giving instructions about the same thing make the agent pick a different one each time |

Rules for every skill:

- **Pinned and reviewed version:** it is copied into the repository at a specific version, inside a protected path, and the human owner reviews it. No plugins or skills that update themselves: a silent update changes the agents' instructions without approval.
- **Registered in the profile:** origin, version or commit, licence, who reviewed it and which roles use it.
- **No network calls of its own:** a skill's update notices, auto-updates and telemetry are disabled in the project (environment variable or configuration). An update is a version change, and it goes through a PR like any other. Downloads the package itself pins in its version and verifies with hashes it ships, like a lockfile, are accepted. A call that cannot be disabled (for example, a catalogue of options) is recorded in the profile, used only with the human owner present, and never sends the project's code or data.
- **No servers or processes left alive** after the step that opened them finishes (§10). If the skill starts them, the step ends by stopping them.
- **Installed with AES:** the AES installer copies the core and the registered third-party skills, at their pinned version, so that none is left behind when AES is installed or upgraded.
- **Included hooks and scripts** are reviewed as the project's own code, and follow the other rules (for example, no processes left alive between roles, 06 §10).
- **Its output is not evidence** unless it runs a command and shows the real output (00 §7).
- **Few per role:** each available skill takes up context; a role loads the ones its work needs.

AES keeps a **core of its own skills** (`skills/` in the AES repository), written for its gates and contracts, in the open Agent Skills format. They are not mandatory: a project may use equivalent ones if they meet the rules above. When a third-party skill is good but of the workflow type, or depends on others from its package, an own skill is written using it as a reference, with attribution and respecting its licence.

## 7. Secrets and environments

Agents must not print, copy into reports or include in commits secrets, credentials, tokens, real personal data or environment files. Test environments must use synthetic or anonymized data when possible. Agents receive credentials only if their task needs them, with least privilege.

## 8. Mandatory human approvals

The following require prior human approval:

- a material change of vision, scope or product behaviour;
- a cross-cutting or hard-to-reverse architectural decision;
- a change in authentication, authorization, security or the handling of sensitive data;
- a destructive migration or an irreversible action on data;
- a significant external cost or a new paid service;
- a change to the permission policies, CI or protected suite;
- an exception to a fundamental control;
- final acceptance of a feature/product when the profile requires it.

Routine, local and reversible details can be delegated if they respect the architecture and the conventions.

When the approval is expressed in CI (for example, with a PR label that authorizes dependencies or markers), CI SHOULD check **who** gave it: an authorized person, not the agents' identity. A label the agents' identity can apply is not an approval. If the platform does not allow checking it, an approved review is used instead.

**Independent verification** is a merge condition that must not depend on anyone's memory. The verifier's `PASS` SHOULD remain as evidence that CI or branch protection requires before merging a task (for example, a verification label that only the human owner can apply after reading the report, checked as in the previous paragraph). In the AES sandbox, a task was merged before the `PASS` when the orchestrator's prompt did not mention it, and the rule was followed in the next story only because the prompt said so.

## 9. Layered control model

A harness permission is not the same as a control the agent cannot bypass. Example: in OpenCode, the `edit` permission covers the edit, write and patch tools, but a permissive terminal can write the same file with `sed` or a redirection.

A control is only considered **technical** (principle 8) if the agent **cannot disable or bypass it from its own execution environment**. AES distinguishes three layers:

| Layer | Where it lives | What it does | Can the agent bypass it? |
|---|---|---|---|
| **L1 — Harness** | Harness permissions (for example `opencode.json`, Claude Code permissions) | Denies editing paths, limits commands. | Partially (terminal, editable configuration). It is **friction**, not a guarantee. |
| **L2 — Hooks** | Harness hooks (`PreToolUse`, `Stop`, plugins) | Blocks writes to protected paths; prevents finishing with red tests. | Only if it can edit the hook configuration, which must be protected in L1 and L3. |
| **L3 — Outside the agent** | CI from a trusted ref, branch protection, CODEOWNERS, read-only mounts, separate repositories | Runs the protected suite from the main branch; checks integrity, surface and cheating markers. | **No.** It is the only layer that counts as a gate. |

Rules:

- The fundamental controls (protection of the acceptance suite, verification independence, protected paths, change surface) MUST exist in L3.
- The harness configuration, the hooks, CI and the persistent instructions MUST live in paths the programmer cannot edit (L1) and whose modification makes CI fail (L3).
- The programmer SHOULD work in a worktree or container where the holdout suite does not exist and the visible suite is mounted read-only.
- If CI is defined in files of the repository itself, a branch can modify its own workflow to skip the guard. The credentials used to publish programmer branches MUST NOT have permission to modify workflows (on GitHub, a token without the *Workflows* permission), or the platform MUST impose the workflow from outside the branch (for example, organization-level required workflows). Workflow changes are applied by the human, with their own identity.
- L1 or L2 MUST NOT be presented as sufficient for a fundamental control.
- If the human owner needs to be able to merge their own changes (nobody can approve their own PR), the permission to skip the approval MUST NOT reach the required checks. On GitHub: two rulesets, one with the checks and no bypass, another with the approval and a bypass for PRs only. A single ruleset with a bypass allows merging with CI red; in the AES sandbox it happened.
- Agents publish with an **identity of their own**, different from the human's, and their commits carry that same authorship. That way the human's approval is real and the history distinguishes who wrote what.
- **File-system isolation:** an agent's terminal can write outside the repository, and none of the three layers detects it. If the disk holds something sensitive, the roles that write SHOULD work in an isolated environment (container, virtual machine or the harness's terminal sandbox); otherwise the profile declares it as an exception.

`profiles/reference/` contains a reference implementation of the three layers.

## 10. State between roles

A role must not leave anything the next one could take as its own: listening servers, processes, test data or temporary files inside the repository. If the acceptance suite reuses a server another role left alive, it can pass against old code; in the AES sandbox, a verifier's servers blocked the next programmer's build.

Each role that reads or writes a work branch SHOULD do so in **its own checkout** of that branch (for example, a git *worktree*), not in the orchestrator's checkout:

- the orchestrator stays on `dev` and does not switch branches; the roles do not inherit its unversioned files, nor it theirs;
- the verifier reviews a clean copy of the branch, not the one the programmer just used;
- local files a role needs that are not versioned (its identity's credentials, local configuration) are copied into the checkout explicitly, never versioned;
- if several roles work at the same time, each checkout needs its own ports and data; until the profile solves it, roles run one at a time.

- Servers are started with a tool that always stops them when it finishes and that **does not reuse** someone else's server: if the port is in use, it fails.
- When each role finishes, a control checks that nothing was left listening on the project's ports (L2 in the reference implementation; in CI, every run starts clean).
- If an agent cannot stop something it started, it is a denied action (§6.1).

## 11. Model and harness per role

The profile declares which harness and which model each role uses. The **orchestrator** MUST run on the most capable model available: it decides the design (10 §5), classifies tracks, severities and findings, and is the only role that sees the whole cycle. The other roles can use cheaper models because they receive broken-down instructions and their work is verified. The evidence of each item (09 §6) records the **actual** model of each role in that run, not the declared one: if they change, cost and quality comparisons between items are not valid.

## 12. Roles in another harness

A role MAY run in a different harness from the orchestrator's (for example, the orchestrator in Claude Code and the programmer in OpenCode with another provider), as long as the profile declares it in its role table (§11) and the following hold:

1. **The same contract.** The role receives the same instructions as in the main harness, from the same file; there is no second version that drifts.
2. **Equivalent L1** (§9): harness permissions that deny the protected paths, publishing (push, PR), the network the role does not need and interactive questions. In a headless run, an action that would ask for confirmation MUST be rejected, never approved on its own.
3. **Equivalent L2 or a declared gap:** the same checks as the main harness's hooks, preferably by running the same scripts. If the harness does not allow one, the profile records it as a known gap.
4. **Unchanged L3:** CI and the end-of-role gate (servers, guard, validations) apply the same way, because they do not depend on the harness.
5. **No publishing credentials** in the role's environment: the orchestrator publishes (§10).
6. **Cost per delegation:** each run records the model, tokens (input, output, reasoning, cache) and estimated cost at the provider's list price, including time-of-day surcharges, even if the model is used for free. The item's retrospective summarizes cost per role (09 §6).
7. **Tested version and checked environment:** the profile records which versions of the other harness the delegation was tested with, and before delegating it is checked that the harness accepts what the delegation uses and that the model responds. A harness version change must not be discovered as a role that never ran.
8. **A provider plan suited to the task:** a free plan, or one with a short usage window, MUST NOT be used for tasks that compile or last longer than its window; a cut halfway through a task leaves work without a gate. The cost row is recorded even when the provider fails.
9. **Data outside the main provider:** the profile records which provider receives each role's code and context, and its retention and training terms. A project with sensitive data does not delegate to a provider that retains or trains on it.

### 12.1 Model level per task

A role's binding is a default, not an obligation for all of its tasks. A task MAY request another **model level** (for example, "high") or a specific binding, when what it asks exceeds what the default model does well:

- **a very large context that has to be read in full:** a legacy schema or database, an old module, a dump of records;
- **reasoning across many pieces:** a data migration with rules, a concurrency, security or protocol change;
- **repeated failures at the standard level** caused by code defects (not by the specification): after two such FAIL cycles, the orchestrator MAY propose the high level for the next one.

The orchestrator proposes the level in the task's specification, with the reason, and the human approves it together with the tasks. Without a reason, a task uses the standard level: the high level costs more and uses up the main provider's limits. The profile defines which binding each level has for each role; the verifier of a high-level task MAY also move up a level. When the programmer and the verifier end up in the same model family, the profile notes it as a gap in the SHOULD below.

If the task sees **real data** (a production or legacy database, records with personal data), the chosen level MUST respect point 9: if the provider of that level retains or trains on what it receives, the task works with the schema and an anonymized sample, or another provider is chosen.

The verifier SHOULD run on a model family different from the programmer's: a model reviewing its own kind of mistakes catches them less well.
