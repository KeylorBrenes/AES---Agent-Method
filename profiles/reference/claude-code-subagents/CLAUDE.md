# [Project] — project instructions

Project managed with **AES 2.0.0** (https://github.com/KeylorBrenes/AES---Agent-Method).

## At the start of each session
- **If `docs/backlog.md` does not exist, the project has no planning yet:** before anything else, use the `aes-inception` skill and ask the human for the idea (in blocks of concrete questions). Do not write code or create stories without it.
- If it exists, continue with what the human asks; to advance a backlog item, the `aes-cycle` skill.
- Project language: `AES_LANG` in `.claude/aes.env`. Everything you and the roles write (stories, plans, reports, backlog, messages to the human) is in that language.

## Branches
- `main`: what is released. `dev`: what is integrated and the base of all work. Only releases (`dev → main`) and defect hotfixes (`BUG-NNN`) reach `main`, and after each one a back-merge `main → dev` is done (merge commit).
- The main checkout stays on `dev`; each role works in its own worktree (`.claude/scripts/aes-wt.sh`).

## Roles
- The **main session** is the AES orchestrator, on the most capable model available (it is the senior designer): to advance a backlog item, use the `aes-cycle` skill. One item per session.
- The `qa`, `programmer`, `mechanic` and `verifier` roles follow their own contract in `.claude/agents/`. They run as Claude Code subagents or in OpenCode, according to `AES_BIND_*` in `.claude/aes.env` (the OpenCode ones are delegated with `.claude/scripts/aes-oc.sh`).
- AES core skills in `.claude/skills/`: `aes-inception` (orchestrator, when starting the project or on an idea that does not fit in the backlog), `aes-cycle` (orchestrator), `aes-design-note` (orchestrator), `aes-debugging` and `aes-security-review` (programmer). Third-party ones are in `docs/aes/skills.lock`; if impeccable is there, the interface follows `DESIGN.md`, and changing the visual direction is the human's decision. No third-party workflow skill (plans, execution, closing branches) is installed alongside them.
- Hooks in `.claude/hooks/` restrict what each role writes. If one blocks you, do not get around it or ask another agent: report BLOCKED for the human.

## Structure
- `src/`: [application]. `tests/[unit]/`: technical tests (programmer).
- `tests/acceptance/`: acceptance tests (**QA only**).
- `specs/<ID>/<ID>.md`: the story, in the customer's language; it is kept. `specs/<ID>/plan.md`, `TASK-*`, `acceptance-test-plan.md`: the technical plan, deleted at close. `*.verify`: verification commands, kept (**orchestrator, QA and human**).
- `docs/backlog.md`: the single source of the backlog; the board `.aes/board.html` is generated from it, by itself, after each `git pull` (local hook; by hand: `node .claude/scripts/aes-board.mjs`).
- `docs/`: brief, architecture, ADRs, design catalogue, profile, backlog (with defect severity), findings, `docs/aes/` (DoR/DoD).

## Commands
- Validations: `bash ci/validate.sh`
- Acceptance of an item: `npm --prefix tests/acceptance test -- --grep "@US-001(?![\w-])"`
- Guard: `BASE_REF=origin/dev TASK_SCOPE_FILE=specs/<ID>/<TASK>.scope bash ci/aes-guard.sh`
- Stabilization gate: `BASE=origin/dev bash ci/defect-gate.sh start <ID>`
- Servers for manual tests: `bash .claude/scripts/with-servers.sh [--web] -- <command>`

## Protected paths
`tests/acceptance/`, `specs/`, `ci/`, `.github/`, `.claude/`, `.opencode/`, `docs/ci/`, `opencode.json`, `CLAUDE.md`.

## Conventions the linter does not catch
- [One line per real project convention: date and amount formats in the API, errors, forbidden patterns.]
- Commits: `struct:` (no behaviour change) or `feat:` / `fix:` / `test:` / `docs:` / `chore:`. Never mixed.
- Atomic, vertical stories, with the title "As a… I want… so that…"; no provisional code and no "refactor later".
- Acceptance tests: the item's and the criterion's tag (`{ tag: ['@US-001', '@US-001-AC-03'] }`) and the criterion ID at the start of the title.

## Observed failures
[One entry per real mistake worth recording (AES 09). Starts empty.]
