# 05 — Testing and quality

## 1. Strategy

AES combines ATDD (Acceptance Test-Driven Development) and TDD (Test-Driven Development) with integration tests, end-to-end tests and static controls. The selection depends on the risk and the type of change.

## 2. ATDD: before implementing the story

For each user story, QA or an independent role MUST:

1. read the request and the approved story;
2. derive acceptance scenarios from the criteria;
3. identify the relevant positive, negative and boundary cases;
4. map each criterion to a test or a checking method;
5. check that the scenarios test behaviour, not an assumed implementation;
6. protect the approved version of the tests.

Acceptance scenarios must be available before declaring the implementation complete. When feasible, the automated tests are written before the implementation.

### 2.1 Interface contract before the tests

QA cannot write useful tests before the code exists if it does not know where to enter the system. When the story introduces or modifies an observable boundary, the order is:

1. approved acceptance criteria;
2. an **interface contract** proposed by the architect/orchestrator, in the story's technical plan (03 §1.2): the observable entry point the tests will use. By default, the system's external boundary:
   - HTTP/API: method, route, payload, codes and response shape;
   - CLI: command, arguments, output and exit code;
   - UI: flow and agreed stable selectors (for example, `data-testid`);
   - library: minimal public signatures;
3. acceptance tests written by QA against that contract.

Acceptance tests MUST exercise behaviour through the interface contract, not internal details. If the programmer needs to change the contract, the task becomes `BLOCKED` and is resolved through change control; the programmer does not adapt the tests. If the contract cannot be defined because of real uncertainty, a Spike runs first, and its result is precisely the contract.

### 2.2 Confirmed RED

A test that already passes before the change does not verify the new code: it may not be exercising the behaviour at all. The red step shows that the test is able to detect the missing functionality.

Before a story becomes `Ready`, QA MUST run the acceptance suite against the base branch and record that **each new test fails for the expected reason** (for example, "404 on `/notifications`", not "import error" or "timeout"). A new test that passes against the base is considered defective until justified. This record (`acceptance-baseline` in the test plan, or a CI artifact) is part of the story's DoR.

Confirmed RED also requires:

- that **all** the new tests were **executed**. A compilation, configuration or start-up error is not RED: it does not show that any assertion fails. Neither is a test that never ran (for example, because a serial mode stops the suite at the first failure) or a skipped test;
- that the check is made by a **tool**, the same one in QA's environment and in CI, over the run's report. "I ran them separately" is not evidence: in the AES sandbox, QA reported a RED with two tests that never ran, and the tool caught it;
- a single exception, the **bootstrap RED**: when the base has no application code yet (the first enabler), it is accepted that no test runs because there is nothing to start. The tool only allows it if the base has no code.

The criterion → test matrix is **generated** by the same tool from the test titles and tags, together with each test's result against the base and the first line of its failure. QA pastes that output into the test plan and does not write the matrix by hand (2.1): a hand-written matrix repeated what the tool already knew and could drift from it.

While working, QA and the programmer run **only the criterion they are touching** (by its tag, for example `@US-001-AC-03`) and the item's full suite once, at the end. In aes-todo, each run of US-001's suite took 3.5 minutes and was repeated several times: running commands took 28 of the 41 minutes of OpenCode work, against 13 of the model generating.

### 2.3 Visible and holdout tests

The acceptance suite SHOULD be split (MUST in T3) into:

- **visible**: the programmer can read and run them; they give it the feedback loop;
- **holdout**: variants of the same criteria with different data and cases, stored where the programmer's environment has no access (a separate repository, a branch without permissions or an unmounted directory). Only CI and the verifier run them.

When a holdout test fails, the programmer receives the criterion ID and the observed behaviour, **not the test code**. Goal: detect implementations tailored to the visible data (hard-coded values, special branches for the test case) without removing the feedback. Indicative proportion: 20–30% of the scenarios; the profile adjusts it.

### 2.4 Characterization tests

Sometimes a new criterion describes something the code **already does** (for example, the same error message in the create form that the new story requires in the edit form). Its test passes against the base, so it cannot show RED, and the rule of §2.2 would reject it along with the whole set.

Those tests are **characterization** tests: they document existing behaviour. Rules:

- they live in the suite of the story that **owns** that behaviour (with its tag, for example `@US-001`), and carry the new criterion's ID in the title for traceability;
- they run in the regression suite from the moment they are merged;
- the new criterion states "Checked with: regression of <ID>" and does **not** appear in any task's criteria file (§12), because it has no tests of its own to run;
- QA marks them as such in the plan, and the human owner approves them with the rest.

Tags that CI does not run are not invented: a test that never runs verifies nothing.

### 2.5 Data isolation

Acceptance tests run in parallel and share data (the same database, the same period, the same list). Each test MUST:

- create its own data and look it up by something only it uses (a unique marker in a text, its own period);
- not compare global totals or counts that other tests may change while it runs;
- not depend on the order of execution or on what another test left behind.

A test that sometimes fails is not noise: it is a High severity defect (02 §9) if it runs in the main branch's regression suite, because it can turn it red for everyone.

## 3. TDD: during implementation

For new or modified logic where practical, the programmer SHOULD follow:

1. **Red:** create a focused test that fails for the expected reason.
2. **Green:** implement the minimal change to make it pass.
3. **Refactor:** improve the structure without changing the behaviour, keeping all tests green.

Mechanical TDD is not required for changes where it does not yield a useful test (for example, some visual changes, documentation or configuration). In those cases the alternative verification method is documented.

## 4. Test layers

The project profile defines tools and commands. In general:

- **Unit:** isolated logic and edge cases.
- **Integration:** persistence, services, queues, APIs and boundaries between components.
- **Contract:** compatibility between consumers and providers.
- **E2E:** user flows that cross the relevant layers.
- **Acceptance:** the user story's criteria.
- **Regression:** existing behaviour that could be affected.
- **Non-functional:** security, performance, accessibility, resilience or other qualities according to risk.

Not every story needs every layer. Leaving out a relevant layer must be justified.

## 5. Protecting acceptance tests

The tests that express approved acceptance criteria are an independent contract and MUST be technically protected.

The programmer agent:

- may create and modify the unit/integration tests of its own change, within scope;
- may NOT modify or delete the protected acceptance suite to get a green result;
- may not change the workflows or CI configuration that run those tests.

Changes to protected tests require an approved change to the requirement or a demonstrated test fix, an independent review and the approval of an authorized owner.

CI MUST run the protected suite taken from the protected branch (or verify its integrity against a manifest stored there), never the version present on the agent's branch. This is a layer L3 control (06 §9). CODEOWNERS, branch protection, read-only mounts and separate repositories complement it.

Trusting the programmer's prompt is not enough, and neither are its harness's permissions: a permission that denies editing a file does not prevent writing it through the terminal.

## 6. Checking tests

If a test fails, the team must classify the cause before changing code or test:

- implementation defect;
- defect in the test;
- contradictory or incomplete requirement;
- environment/configuration;
- external dependency.

The agent must not delete, disable, weaken assertions or change expected data to hide a failure. Fixing a test is legitimate only if it is shown that the test contradicts the approved requirement or is technically wrong.

A **flaky** test (fails without a code change) is technically wrong. It is recorded as a defect (02 §9), QA fixes it through the authorized flow for protected tests, and its check is not a RED but evidence of stability: the number of runs that failed before and a series of runs without failure afterwards (the profile sets how many; for example, 10). Its fix does not change what the test requires.

## 7. Static quality and security

The project profile must declare the applicable tools and thresholds: formatting, lint, types, static analysis, dependencies, secrets, vulnerabilities and migrations. The thresholds must be reasoned for the project; AES does not impose a universal coverage percentage.

Changes that affect authentication, authorization, personal data, payments, secrets, trust boundaries or migrations require a reinforced review and the relevant negative tests.

**Static application security testing** (SAST, with rules mapped to OWASP and CWE) SHOULD run in each task's CI over what the task changes:

- a **new** high-severity finding in the diff fails the task: it is a finding of the task (a `FAIL` cycle);
- a new lower-severity finding and **pre-existing** findings do not block the task: the orchestrator records them as defects with a severity (02 §9), and the stabilization gate does the rest;
- a false positive is suppressed in the tool's configuration, with a reason, and like any guard marker it requires human approval (05 §10).

Checking dependencies for known vulnerabilities follows the profile's policy.

If the project has an interface, a **deterministic UI detector** (contrast, legibility, overflow, basic accessibility, deviations from the project's visual system) SHOULD run in each task's CI over the interface files it changes. While the project has not decided which rules block, its findings are noted in the PR and the orchestrator records them as defects; afterwards, the rules the profile declares blocking fail the task, like SAST. An agent's design reviews (critiques, style scores) are findings, not evidence (00 §7).

### 7.1 Code review: deterministic scaffolding and a second review

An agent's review of a diff depends on its attention: nothing forces it to read every file, and its checklist is the same whatever the language. The deterministic part of the review is given to a tool (in the reference implementation, Open Code Review at a fixed version), as with every control that can be code (00 §7):

- **Which files are reviewed:** every file of the diff is either reviewable or excluded with a reason (binary, generated, dependencies, an unsupported type). The verifier records each reviewable file as reviewed or skipped with a reason, and its report gives the **coverage** (total, reviewed, skipped, rate). Test files are reviewed too, with the verifier's own checklist, even if the tool leaves them out: weakened, disabled or tautological tests are what an agent's diff hides best.
- **The checklist of each file:** the rules of its language plus the **project's rules** (level-1 principles, 10 §3, and the conventions the linter does not catch), versioned in a protected path. The orchestrator writes the project's rules at inception (01 §2.3).
- **The same checklist, before and after.** The programmer reads the checklist of the files of its surface before writing code; the verifier reviews the diff with it. That way the checklist prevents defects instead of only finding them, and it costs a read, not another pass of a model.

This mode calls no model: the reviewer is the role that already reviews (the verifier), with its model. It adds no cost and sends no code anywhere.

A project MAY add a **second review** in each task's CI, in which the tool reviews the diff with a model of its own and the story and the task as context. Its value is independence, so its model SHOULD be from a family that is neither the programmer's nor the verifier's; the profile records which one it uses, and it may change it according to the budget. Each run costs tokens and sends the diff to that provider (06 §6.2). Its findings are treated like any reviewer's, with one difference, because the severity a model gives is a claim and not a fact:

- a new **critical** finding fails the task's CI. If it is real it is a `FAIL` cycle; if it is a false positive, the human dismisses it with an approval label, validated like the others (06 §8), and a new commit removes it;
- **high** and **medium** ones go to the verifier as points of attention, which it confirms with evidence or refutes. A confirmed one is a verifier finding and 02 §9.3 decides: a task defect of Medium or higher is a `FAIL` cycle before merging;
- **low** ones are discarded or recorded as Minor defects.

Without its credentials the step is skipped with a visible warning, and the verifier's review still runs: the second review complements the verifier, it never replaces it.

A CI step that is skipped is not a control. Reading the log of a passing run (§9) is how a step that silently never runs is detected: in aes-todo, the SAST step had been skipped on every run since it was added, because an unset CI variable made its condition false.

## 8. Coverage and mutation testing

Coverage is a signal, not proof of quality. The percentage must not be optimized at the expense of meaningful assertions.

Mutation testing SHOULD be applied to critical logic, authorization, sensitive calculations and areas where it matters to know whether the tests detect defects. Its use can be selective because of cost.

## 9. Evidence

Results are recorded with the command, status (`PASS`, `FAIL`, `NOT RUN`, `BLOCKED`), the relevant environment or version and a summary. Tests reported as run without output or verifiable evidence are not accepted.

Valid evidence is the output captured by CI or by a tool that runs the command and records its real output (for example, the `exec` pattern of Showboat described by Simon Willison). Recording the real output, instead of what the agent expected to happen, discourages faking results. Text written by an agent about what it ran is not evidence.

A green check does not prove that what was expected ran. CI MUST print what it ran (branch type, item, criteria or tags, number of tests), and the orchestrator and the human confirm it in the log before considering the gate passed. In the AES sandbox, a close went green without running a single test of its story.

Claims about the repository are checked at their source (00 §7).

## 10. CI guard: change surface and cheating detector

CI MUST include a guard that, at least:

1. **rejects changes to protected paths** (acceptance suite, specifications, CI, agent configuration, hooks, `AGENTS.md`/`CLAUDE.md`);
2. **compares the diff with the task's change surface**, read from the protected branch;
3. **rejects changes to dependency manifests and lockfiles** without approval;
4. **detects deleted test files**;
5. **looks for cheating markers in the added lines**:

| Signal | Examples |
|---|---|
| Skipped tests | `.skip(`, `xit(`, `xdescribe(`, `@Disabled`, `@Ignore`, `#[ignore]`, `pytest.mark.skip`, `[Fact(Skip=` |
| Silenced analysers | `eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `# type: ignore`, `#pragma warning disable`, `noqa` |
| Swallowed errors | empty `catch {}` or `catch (e) {}`, `except: pass` |

A match is not always cheating, but it always requires a justification in the task report and an explicit approval by someone other than the programmer. The profile adds the patterns of its own stack.

Two refinements learned in practice:

- **Dependencies** include package sources and local tools, not only manifests: changing where packages come from is as sensitive as changing a package (for example, `nuget.config`, `.npmrc`, `pip.conf`, `global.json`, tool manifests).
- **Code generated** by tools (for example, migrations) contains markers nobody wrote by hand. If the guard excludes it from the search, the exclusion MUST be narrow: a known location **and** the generation header, so that a hand-written header in another file does not hide a marker. Excluded files are listed in the output for the verifier.

Coverage of the touched files SHOULD be compared with the baseline; a drop is treated like a cheating marker.

## 11. Agentic manual testing

All tests passing does not guarantee that the program starts or that an interface element is visible. For T2 and T3 with a user interface or an API, the verifier MUST start the application and exercise the criteria's flows with the appropriate tool:

- APIs: development server and real requests (`curl` or equivalent);
- web interfaces: browser automation (for example, Playwright) with screenshots;
- CLIs and libraries: real execution, with temporary scripts outside the repository.

Outputs and screenshots are attached to the verification report. A defect found this way is classified (02 §9.3): if it belongs to what the task adds, it is a `FAIL` cycle; if not, it is recorded as T1 with a severity and fixed with RED/GREEN, so that a permanent automated check remains.

Additional rules:

- **No manual test, no `PASS`.** If the track requires it and the verifier could not do it, the result is `BLOCKED`, not `PASS`: automated tests, even passing, do not replace it. In the AES sandbox, a verifier skipped it because "the acceptance tests already use real servers".
- Manual testing uses **different data** from the automated tests.
- Servers are started and stopped with a tool that **always** stops what it started and only that, on its own temporary data, and that fails if the port is already in use instead of reusing someone else's server (06 §10).
- In a **re-verification** after a `FAIL` cycle, all the automated evidence is re-run, but the manual test covers what the cycle changed plus a short regression pass over the task's main flows.

## 12. What CI runs in each phase

CI decides which tests to run by branch type and target branch (`dev` or `main`, 07 §7). The profile sets the branch names; the intent is this:

| Phase | What it runs |
|---|---|
| Specification of a T1 with a verification command | The command, which **must fail** (RED), unless "no RED" was approved |
| An item's acceptance tests (`qa/<ID>`) | The item's tests, which **must run and fail** (RED, §2.2) |
| Task | Guard + validations + the criteria the task declares (or the whole item, if it is the last task; with `none`, only the technical tests and the regression, 04 §3) + regression |
| Item close | The whole item, which **must run and pass**, + regression |
| `dev` and `main` | Regression of every item closed on that branch |
| Release (`dev` → `main`) | Full regression + stabilization gate + `main` contained in `dev` (07 §8) |
| Back-merge (`main` → `dev`) | Full regression of `dev` |

Rules:

- Each task's criteria file is read from the **protected branch**, like the change surface.
- The regression suite includes the acceptance tests **and** the verification commands of every closed item.
- A **verification command** is a criterion that is not checked with an acceptance test (configuration, tools, scripts, build). It is a versioned script in the item's protected path that exits with code 0 if the criterion is met. It is treated as a protected test: whoever writes the tests writes it, the human approves it and CI runs it from the protected branch. Its name says which criterion it checks: `<ID>.verify` (the whole item), `<ID>-AC-NN.verify` or `AC-NN.verify` (one criterion, which can then be listed in a task's criteria file) and `BUG-NNN.verify` (one defect).
- Between merging an item's last task and merging its close, nothing else is merged into that branch (`dev`, or `main` in a hotfix): during that interval the regression suite does not include the item yet.
- The list of items in regression is a versioned file. It travels with releases and back-merges, so `main`'s regression covers what was released and `dev`'s, everything integrated.

## 13. Feedback speed

Agents run the same commands many times: a slow suite is paid on every run, by every role, and it keeps the human waiting between gates. In aes-todo, US-001 spent 28 of the 41 minutes of OpenCode work running commands, against 13 of the model generating, and each task's CI took 7 to 9 minutes. Speed is designed, like quality.

**General principles** (any stack):

- **Build once, reuse it.** CI builds once and every later step uses that build; the acceptance fixture starts the server already built, never compiles it per test.
- **Cache dependencies and builds** in CI, keyed by the lockfile.
- **Run what you touch.** While working, only the tests of the criterion or the module being changed; the full suite once, at the end (§2.2).
- **Start servers once per run**, not once per test, when data isolation (§2.5) allows it: each test creates its own data, so they can share a server.
- **Parallelize only what is isolated.** Parallel workers with shared data produce flaky tests (§6).
- **Measure it.** The metrics separate the model's time from the commands' time (09 §6); a retrospective that sees commands dominate proposes a feedback rule, not a different model.

**Feedback budget.** The profile sets it, for example: a focused test under 30 seconds, the item's acceptance suite under 2 minutes, a task's CI under 5 minutes. It is a target, not a gate: when a retrospective finds it exceeded, the fix is a feedback rule in the project (a cache, a reused build, a fixture change), tracked like any other control (09 §3).

**The project's feedback rules.** At inception, once the stack is chosen, the orchestrator translates the principles into concrete rules for that stack and writes them in the profile (for example, for Rust: a build cache in CI, `cargo build` once and the binary reused by the acceptance fixture; for .NET: `dotnet build` once and `--no-build` afterwards). EN-001 builds the CI and the fixture by them. They are the project's rules, not AES's.
