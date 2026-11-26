# 07 — Change, risk and release

## 1. Change control

New information can justify changing a story or a decision. The change is recorded; the goal is not silently rewritten.

A change of scope or criteria after `Ready` requires:

1. describing what changed and why;
2. identifying the impact on architecture, tasks, tests, estimate and dependencies;
3. updating the affected artifacts;
4. obtaining the corresponding approval;
5. running the DoR again for the affected part.

Editorial corrections without a semantic change do not require a full cycle.

## 2. Risk

Each story must identify its relevant risks. At least, evaluate whether it touches:

- authentication, authorization or trust boundaries;
- personal, financial or sensitive data;
- payments, billing or external providers;
- migrations, deletion or data integrity;
- APIs or contracts used by other systems;
- concurrency, performance or availability;
- deployment, recovery or continuity.

The profile may use `Low`, `Medium`, `High` and `Critical` levels, with defined controls. High/Critical items require a reinforced review and human approval according to the type of risk, and are treated as track T3 (02 §8): mandatory holdout tests and human review of the code in the risk areas.

## 3. Blockers and failures

When a validation fails, the orchestrator stops the affected gate from advancing, classifies the failure and assigns a bounded fix. Dependent work is not marked as done. Repeated failures on the same task trigger the circuit breaker (04 §9).

A blocker must include: what is missing, why it blocks, the available evidence, options and who can resolve it.

When a story is blocked because it needs something that is not in its scope (another story, a decision, a technical piece), the scope is **never widened silently**. The human owner chooses between:

1. **widening** the story through change control (§1), if what is missing is small and part of the same result;
2. marking it `Blocked` by the missing item, which moves ahead in the backlog;
3. **splitting** it, delivering now the part that does not depend on what is missing;
4. opening a **Spike** (01 §7), if what is missing is knowledge.

The choice is a decision recorded in the story (03 §8).

## 4. Integration

Every change must be integrated through the project's mechanism (pull request, merge request or equivalent). Review:

- the scope of the diff;
- conflicts and compatibility;
- tests and CI;
- migrations and rollback where they apply;
- configuration and secrets;
- the necessary documentation and observability.

Changes must not be merged just because an agent finished its task.

A task is not merged without the verifier's `PASS`, even if CI is green (06 §8). A task's PR is merged with a **merge commit**, so its commit plan (04 §2) reaches `dev` as it was reviewed: one commit per criterion or piece, which `git log` and `git bisect` can still tell apart. Specification and close PRs, which are documentation, can be squashed. Before adding commits to a PR's branch, check that the PR is still open: pushing to a branch that was already merged and deleted recreates it with work nobody will review.

## 5. Release

Releasing follows the project profile and the release process (§8), and must consider, where they apply:

- version and change notes;
- migrations and a recovery plan;
- configuration per environment;
- monitoring and alerts;
- a rollback or mitigation strategy;
- human approval for high-risk changes.

Accepting a user story does not automatically authorize deploying to production.

## 6. Defects

Defects are recorded with a severity and managed with the stabilization gate (02 §9): a Critical defect stops everything; a High or Medium one prevents starting the next story; Minor ones accumulate only up to the profile's limit. Defects are fixed in stabilization batches, in their own session, without being mixed with new functionality.

## 7. Branches: `main` and `dev`

Every AES project MUST have two permanent, protected branches:

| Branch | Contains | Receives |
|---|---|---|
| `main` | What has been released: stable, verified and accepted as product | Only releases from `dev` (§8) and hotfixes (§9) |
| `dev` | What has been integrated: accepted stories, batches and finished tasks, not yet released | Each item's work branches (specification, tests, tasks, close) and back-merges from `main` (§9) |

Rules:

- The rule is the same for small and large projects. There is no "`main` only" variant, and no *feature flags* as a substitute: a flag is conditional code an agent can write wrongly, and checking that something stays off requires reading the code. Git provides the isolation.
- `dev` MUST always be green, with the same CI and the same protection as `main`. It is the base of all new work.
- Work branches are **short-lived**: they start from `dev` (or from `main`, for a hotfix) and disappear when merged. There are no permanent feature or bug branches: a long-lived branch drifts and brings back the conflicts that were meant to be avoided.
- An epic of many stories is built on `dev` and reaches `main` when the human owner releases it. `main` never receives half-finished functionality.
- The stabilization gate (02 §9) is evaluated on `dev` to start stories, and on the release candidate to release.

## 8. Release (`dev` → `main`)

A release is a PR from `dev` to `main`. It is a human gate of its own, distinct from accepting each story: accepting a story says it meets its criteria; releasing says the whole can be used as a product.

Before opening it:

- the release notes are prepared (template `templates/release.md`): which items ship, which known defects remain and how to roll back;
- the stabilization gate is open on `dev`;
- `main` is contained in `dev` (§9): every previous hotfix is already back in `dev`.

The release PR:

- runs the full regression suite of `dev`;
- MUST fail if `main` has commits that `dev` does not (in git: `main` is not an ancestor of `dev`). That way a hotfix that did not return to `dev` cannot be lost or reintroduce the defect;
- is merged with a **merge commit**, not a *squash*. With a squash, `main`'s commits stop existing in `dev`, the previous check always fails and every release brings conflicts. Squash is reserved for work branches;
- is approved and merged by the human owner. There is no minimum period of use: the owner uses `dev` as much as they consider necessary, and their approval of the PR is the evidence that they did.

After merging it:

- the included items become `Released`;
- `main` is back-merged into `dev` (§9), because the release commit only exists in `main`;
- the version is marked according to the profile (for example, with a tag).

## 9. Hotfix and back-merge

A **hotfix** fixes a defect in something already in `main`, without going through what is under construction in `dev`.

- The human owner decides the route of each defect in something released, whatever its severity: **hotfix** (ships now, from `main`) or **`dev`** (ships with the next release). The decision is recorded in the defect (03 §8). The orchestrator proposes; hotfix is usual for Critical or High, but it is not a rule.
- A hotfix is a T1 item (04 §10) whose work branches start from `main` and are merged into `main`. Only defects (`BUG-NNN`) can take this route: no functionality reaches `main` without going through `dev`.
- Its reproduction check joins `main`'s regression suite when it closes, like any item's.

The **back-merge** brings `main` into `dev`. It MUST be done right after every merge into `main` (hotfix or release):

- it is a PR from `main` to `dev`, merged with a **merge commit**, so that `dev` has exactly the same commits. No *cherry-pick* or second PR with the same fix: they create different commits with the same change and conflicts in the next release;
- if there are conflicts, they are resolved in that PR, with `dev`'s regression suite as evidence;
- the hotfix's reproduction check reaches `dev` with the back-merge: if `dev` did not have the fix, its own CI would turn red.
