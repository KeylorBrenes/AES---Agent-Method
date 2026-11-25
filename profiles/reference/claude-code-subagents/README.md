# Reference implementation — Claude Code with subagents

An implementation of AES 2.0.0 with **Claude Code** as the orchestrator's harness: the main session is the orchestrator (on the most capable model available, because it also decides each task's design) and the `qa`, `programmer`, `mechanic` and `verifier` roles are subagents with their own context, model and permissions, or, according to the binding, they run in **OpenCode** with another provider (section "Roles in OpenCode"). GitHub hosts the repository, the CI and the branch protection.

It comes out of the [aes-sandbox-gastos](https://github.com/KeylorBrenes/aes-sandbox-gastos) experiment, an expense-tracking app in .NET 10 + React where AES was applied with real agents on four items (EN-001, US-001, CH-001, US-002), and was hardened in [aes-todo](https://github.com/KeylorBrenes/aes-todo) (Rust + React). What says "tested" was used there; what says "simulation" was tested with test repositories and data when publishing a version, but not yet in a real cycle.

It is a starting point, not a prescriptive profile. The stack-specific parts (.NET + React) are marked.

**Language.** AES and this implementation are written in English. The project's artifacts (stories, plans, reports, backlog, board) are written in the project language, `AES_LANG` in `.claude/aes.env` (`en` or `es`). The scripts read backlogs, task files and reports in either language.

## Contents

| File | Layer | Function | Status |
|---|---|---|---|
| `.claude/agents/{qa,programmer,mechanic,verifier}.md` | L1 | Subagents: tools, model and contract of each role | Tested |
| `.claude/settings.json` | L1 + L2 | Denials and hook registration | Tested |
| `.claude/hooks/role-guard.sh` | L2 | Edit `PreToolUse`: what each role can write (orchestrator without code; QA only tests, plan and `.verify`; programmer and mechanic only their surface; verifier nothing) | Tested |
| `.claude/hooks/bash-guard.sh` | L2 | Terminal `PreToolUse`: obvious writes to forbidden paths; subagents do not publish or switch branches | Tested |
| `.claude/hooks/subagent-gate.sh` | L2 | `SubagentStop`: no role finishes with servers alive; programmer and mechanic, also, with the guard and `ci/validate.sh` green | Tested |
| `.claude/scripts/with-servers.sh` | — | Starts the servers with temporary data, runs a command and always stops them; fails if the port is taken | Tested on Windows and Linux (reading `.claude/aes.env`: simulation) |
| `.claude/scripts/aes-board.mjs`, `aes-board.html` | — | Backlog views from `docs/backlog.md`: a self-contained HTML board (`.aes/board.html`: a "Next" sign with the phrase for the orchestrator, gate, dependencies, releases, metrics and a naming guide) or JSON for an adapter (GitHub Projects, Trello, GitLab) | Tested |
| `.claude/scripts/aes-outline.sh` | — | Structural outline (files and public signatures, without implementations) so the orchestrator decides the design with facts | Simulation |
| `.claude/scripts/aes-wt.sh` | — | Each role's own checkout (worktrees): `open`, `close`, `run`, `delegate`. The main checkout stays on `dev` | Tested |
| `.claude/hooks/worktree-create.sh`, `worktree-remove.sh` | L2 | The subagent with `isolation: worktree` works on the real work branch (the one the orchestrator named with `delegate`); with no branch named, it does not start | Tested |
| `.claude/scripts/aes-note.sh` | — | The orchestrator's notes with the real time; `clear` empties them after the close | Tested (`clear`: simulation) |
| `.claude/scripts/gh-app-token.sh`, `git-credential-aes-app.sh`, `agent-gh.sh` | L3 | The agents' identity: a GitHub App without the workflows permission | Tested |
| `.claude/scripts/aes-workflow.sh` | L3 | The human runs it: applies on a branch the workflow the orchestrator prepared in `docs/ci/`, with the human's identity | Tested |
| `.claude/scripts/aes-bind.sh` | — | A role's effective binding for a task: the "Model level" of its specification (`standard`, `high`, or a concrete binding) resolved with `AES_BIND_<ROLE>_<LEVEL>` from `aes.env` | Simulation |
| `.claude/scripts/aes-doctor.sh` | — | Environment check before delegating: tools, the app's permissions, OpenCode (version, options, that the model answers) and the stack (`AES_DOCTOR_CHECKS`, with minimal builds) | Tested |
| `.claude/skills/aes-cycle/SKILL.md` | — | The orchestrator's procedure, with delegation templates | Tested (T1 and batch paths: simulation) |
| `.claude/skills/aes-{inception,debugging,security-review,design-note}/` | — | AES core skills, copied from `skills/` at the root of the AES repo (not edited here) | Inception and design note: tested |
| `.claude/aes.env` | — | The project language, ports and server commands, role bindings, environment checks | — |
| `ci/aes-guard.sh` | L3 | Guard: protected paths, surface, dependencies, deleted tests, markers | Tested |
| `ci/red-check.mjs` | L3 | Confirmed RED (all run and failing) and criterion → test traceability | Tested |
| `ci/aes-ctx.sh` | L3 | What CI runs by branch and target: valid routes to `dev` and `main`, the task's criteria, regression, verification commands, release and back-merge | Per criterion: tested; the rest: simulation |
| `ci/defect-gate.sh` | L3 | Stabilization gate: reads the defects' severity from the target branch's backlog; `release` phase to release | Tested |
| `ci/run-verify.sh` | L3 | Verification commands: RED in the specification, green in tasks, close and regression | Simulation |
| `ci/label-approver.sh` | L3 | Who put on each approval label (not the agents' identity) | Simulation |
| The workflow's SAST step | L3 | Semgrep with OWASP rules on what each task adds: `ERROR` fails the task; the rest is recorded as defects | `--baseline-commit` (only new findings) and `--error` by severity: tested with Semgrep 1.184 locally; the workflow step, in simulation |
| `ci/validate.sh` | — | The stack's validations (.NET + React example) | Tested |
| `.github/workflows/aes.yml` | L3 | A single `aes` check on `dev` and `main` with all of the above, plus "main contained in dev"; scripts always from the target branch | Used in aes-todo; release and back-merge paths: simulation |
| `.github/CODEOWNERS` | L3 | Your approval for protected paths | Tested |
| `CLAUDE.md` | — | An example of brief persistent instructions | — |
| `opencode.json`, `.opencode/plugin/aes-guard.js`, `.claude/scripts/aes-oc.sh` | L1, L2 | Roles in OpenCode (binding in `.claude/aes.env`): agents with the same contract, permissions, a plugin that runs the same hooks, delegation with a gate and cost recording | Tested with DeepSeek |

## Getting started

There are two parts: what is done **once per GitHub account** (by hand, a few minutes) and what is done **in each project** (one command).

### Once per account

#### 1. Tools

| Tool | What for |
|---|---|
| git | Everything |
| bash, openssl, curl | AES hooks and scripts; the app's token. On Windows they come with Git for Windows (Git Bash) |
| [gh](https://cli.github.com) | `setup-repo.sh` and the agents' PRs |
| jq | AES hooks and `setup-repo.sh` |
| Node.js LTS | The board (`aes-board.mjs`), archify and the acceptance tests |

**Windows** (PowerShell; afterwards, close and reopen Git Bash so it picks up the new PATH):

```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id jqlang.jq -e
winget install --id OpenJS.NodeJS.LTS -e
```

Always use **Git Bash** for the AES scripts: Claude Code runs the hooks with it.

**Linux:**

```bash
# Fedora
sudo dnf install git gh jq nodejs openssl curl
# Debian / Ubuntu (gh, from the official repository: https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
sudo apt install git jq nodejs npm openssl curl
```

**Check:** `git --version && gh --version && jq --version && node --version && openssl version`

**gh session** with the permissions `setup-repo.sh` needs:

```bash
gh auth login                 # GitHub.com → HTTPS → sign in with the browser
gh auth refresh -s workflow   # permission to push the CI workflow
gh auth status                # "Token scopes" must include repo and workflow
```

#### 2. The agents' GitHub App

The agents publish branches and open PRs with the identity of a GitHub App, not yours. The app **has no *Workflows* permission**: that way no agent can edit the CI to get past the guard, and their PRs appear as `<slug>[bot]`, which you approve. It is created once and serves all your projects.

1. On GitHub: your picture → ***Settings → Developer settings → GitHub Apps → New GitHub App***.
2. **Name:** one that is unique on GitHub, for example `aes-agent-<your-user>`. The *slug* (the name in lowercase and with hyphens) appears in the app's URL, `github.com/apps/<slug>`.
3. **Homepage URL:** any, for example your profile's URL.
4. **Webhook:** uncheck *Active*. AES does not use it.
5. **Permissions → Repository permissions:**
   - *Contents*: **Read and write**;
   - *Pull requests*: **Read and write**;
   - *Metadata*: Read-only (GitHub sets it by itself);
   - **nothing else**. In particular, *Workflows* stays at *No access*. No account or organization permissions.
     When an item needs to change a workflow (for example, the STACK section in EN-001), the orchestrator leaves the new file in `docs/ci/` on a branch and you apply it from your terminal with `bash .claude/scripts/aes-workflow.sh <branch>`: it shows the diff, commits with your identity and publishes it. If you gave the app *Workflows*, `aes-doctor.sh` and `setup-repo.sh` warn about it.
6. **Where can this GitHub App be installed?** *Only on this account*. Press ***Create GitHub App***.
7. On the app's *General* page, note the **App ID**.
8. **Private key:** ***Credentials → Key pairs → New key*** (in the older interface, *Private keys → Generate a private key*). A `.pem` is downloaded. Move it out of any repository:
   - Windows: `C:/Users/<you>/.config/aes/aes-agent.pem`;
   - macOS and Linux: `~/.config/aes/aes-agent.pem`, with `chmod 600`.

   Never push it to git or paste it into a chat. If it leaks, revoke it on that same screen and generate another one.
9. **Install the app:** side menu ***Install App*** → your account → ***Only select repositories***. Choose any one (for example, the sandbox); `setup-repo.sh` adds each new project. The **Installation ID** is the number at the end of the installation's URL: `github.com/settings/installations/<id>`.
10. **The app's data:** `aes-new` asks you for it the first time and stores it in `~/.config/aes/app.env`. By hand: copy it from `scripts/aes-app.env.example` in the AES repo and fill in `AES_APP_ID`, `AES_APP_INSTALLATION_ID`, `AES_APP_PRIVATE_KEY` (path with `/`) and `AES_BOT_SLUG`. The script looks up the bot user's ID (`gh api "users/<slug>%5Bbot%5D" --jq .id`).

Do not use a bot account or a *fine-grained* personal token: new accounts can be suspended by GitHub's anti-abuse systems, and *fine-grained* tokens cannot access repos of another personal account.

#### 3. Third-party skills (optional)

`aes-new` offers them and downloads them by itself, at their latest published version. For `setup-repo.sh`, clone them at a fixed version, for example in `~/.config/aes/skills/`, and add their folders to `AES_VENDOR` in `app.env`:

```bash
mkdir -p ~/.config/aes/skills && cd ~/.config/aes/skills
git clone https://github.com/tt-a1i/archify.git && git -C archify checkout <tag>
git clone https://github.com/pbakaus/impeccable.git && git -C impeccable checkout <tag>
# in app.env:
# AES_VENDOR="~/.config/aes/skills/archify/archify;~/.config/aes/skills/impeccable/.claude/skills/impeccable"
```

To update them, change the version there and run `install-aes.sh <project> --upgrade --vendor <folder>` in each project.

### Each new project

The simplest way is `aes-new` (the main AES README, "Start a new project"): you download it into the project's folder, it asks in the terminal and calls `setup-repo.sh`. Without the GitHub App, use personal mode (`--personal`). Without questions, from a copy of AES at the version (tag) you want to use:

```bash
./scripts/setup-repo.sh <your-user>/<repo> --create private --lang en   # or public; without --create if it already exists
# with roles in OpenCode: --opencode deepseek/deepseek-flash (or AES_OPENCODE_MODEL in app.env)
```

When it finishes, open Claude Code in the project's folder with the most capable model (`/model opus`) and ask to start the project: the orchestrator uses the `aes-inception` skill (interview, backlog with releases, architecture, stack ADR, visual direction and EN-001, in a PR into `dev` that you approve). Then, EN-001 with `aes-cycle`.

- `--dry-run` shows what it would do without changing anything.
- It can be repeated: each step checks first and is skipped if it is already done. If something failed halfway (for example, the app without access), you fix it and run it again.
- In **private** repos, rulesets need GitHub Pro or Team. With GitHub Free, use a public repo.
- The stack-dependent seeds (`.claude/aes.env`, `ci/validate.sh`, the workflow's `STACK` section) are adapted in EN-001.

### What the script does, step by step

It is also the manual for doing it by hand.

1. **Checks** git, gh (with `repo` and `workflow`), jq and `~/.config/aes/app.env` (except in personal mode).
2. **Creates and clones** the repository.
3. **Installs AES** with `./scripts/install-aes.sh <folder> --vendor <skill>…`. It copies these files, the core skills, the DoR/DoD, `AES-CORE.md`, the templates and the license in `docs/aes/`, creates `specs/active-stories.txt` and adds `.aes/`, `.claude/settings.local.json` and `.claude/worktrees/` to `.gitignore`. It sets `AES_LANG` in `.claude/aes.env`.
   - The **AES files** (hooks, scripts, core skills, CI scripts, `docs/aes/`) are not edited in the project: `--upgrade` overwrites them and `--check` checks that they match the version.
   - The **seed files** (subagents, `settings.json`, `aes.env`, the workflow, `CODEOWNERS`, `ci/validate.sh`, `CLAUDE.md`) belong to the project. When upgrading, if AES changed a seed the project had adapted, the new one is left beside it as `<file>.aes-new` for you to compare.
4. **Fills in** `CODEOWNERS` with your user and creates `.claude/settings.local.json` (the app's credentials and commit authorship as `<slug>[bot]`; it does not go to git). Manual check of the token: `bash .claude/scripts/gh-app-token.sh | cut -c1-4` must print `ghs_`.
5. **Initial commit on `main`** with what was installed (only if `main` does not exist on GitHub yet) and **creates `dev`** from `main` (`git push origin main:dev`). The workflow goes into that commit: the app cannot touch `.github/workflows/`, so you push any later change to it yourself.
6. **Repository settings:** `dev` as the default branch (PRs target `dev` without thinking about it), *merge commit* and *squash* allowed, *rebase* not, and deletion of merged branches.
7. **Three rulesets.** GitHub requires meeting every one that applies, and the bypass of one does not skip another:
   - **`ci-branches`** (`main` and `dev`), **with no bypass for anyone:** *Restrict deletions*, *Block force pushes*, *Require status checks to pass* (`aes`) with *Require branches to be up to date*.
   - **`approval-dev`** and **`approval-main`:** *Require a pull request before merging* with 1 approval, *Require review from Code Owners* and *Dismiss stale approvals*. Bypass: *Repository admin* in **For pull requests only** mode, so you can merge your own PRs. Allowed methods: on `main`, only *merge commit* (releases and hotfixes); on `dev`, *squash* (work branches) and *merge commit* (back-merges). If your plan does not allow limiting the methods, the script warns about it: choose carefully in each PR, because a back-merge merged with *squash* breaks the "main contained in dev" check of the next release.
   - Repositories set up before 2.0.0 have the same rulesets under their Spanish names (`ramas-ci`, `aprobacion-dev`, `aprobacion-main`); the script recognizes them and does not duplicate them.

   A single ruleset with a bypass allows merging with CI red: the bypass skips all its rules. It happened in the sandbox (FL-003).
8. **Labels** `aes:deps-approved`, `aes:markers-approved` and `aes:verified` (only you put them on) and the **variable** `AES_APPROVERS`. The other variables are optional (*Settings → Secrets and variables → Actions → Variables*):
   - `AES_APPROVERS`: the authorized logins, comma-separated. CI accepts a label only if the last time it was put on by one of these people, never by a `[bot]`.
   - `AES_MINOR_LIMIT` (5 by default): open Minor defects allowed.
   - `AES_REQUIRE_VERIFIED` (`1` by default): requires `aes:verified` on tasks.
   - `AES_SAST` (`0` turns it off) and `AES_SAST_CONFIG` (`p/owasp-top-ten` by default): the SAST step.
   - `AES_UI_DETECT`: the interface detector, if impeccable is installed. By default it only annotates the PR; `block` makes findings fail the task; `0` turns it off.
9. **The app's access** to the repository (`PUT /user/installations/<id>/repositories/<repo>`; by hand: *Settings → Applications → your app → Configure → Repository access*) and a check of its token.

## Branch convention

Work branches start from `dev` and go to `dev`. A hotfix's (`BUG-NNN`) start from `main` and go to `main`. CI rejects any other route to `main`.

| Branch | Who | What CI runs |
|---|---|---|
| `spec/<ID>` | orchestrator | build/test, RED of the new verification commands, regression |
| `qa/<ID>` | orchestrator + QA | gate (start), build/test, RED and traceability of the tests of `<ID>`, RED of the new commands |
| `task/<ID>/<TASK>` | programmer or mechanic | gate (Critical only), guard, build/test, the task's criteria (`<TASK>.criteria`; without it, the whole item), verification commands, regression, `aes:verified` |
| `spec/<ID>-close` | orchestrator + mechanic | build/test, the whole item (it must run and pass), regression |
| `dev` → `main` (release) | the orchestrator opens it, you merge with a merge commit | gate (no exemptions), "main contained in dev", full regression |
| `main` → `dev` (back-merge) | the orchestrator opens it, you merge with a merge commit | full regression |
| push to `dev` or `main` | — | build/test, regression, gate report; on `dev`, a warning if a back-merge is missing |

`<ID>` is the backlog item: `US-`, `EN-` (they go through the gate), `BUG-`, `CH-`, `ST-`, `SP-` (they do not: they fix or maintain).

## Checkouts per role (worktrees)

The main checkout stays on `dev`. Each role works in its own worktree of the work branch, in `.claude/worktrees/`:

```
orchestrator: git branch --no-track task/US-005/TASK-014 origin/dev
              bash .claude/scripts/aes-wt.sh delegate task/US-005/TASK-014
              → calls the programmer subagent (isolation: worktree)
WorktreeCreate hook: opens .claude/worktrees/task-US-005-TASK-014 on that branch
                     and copies .claude/settings.local.json (the app's identity)
programmer: works and commits in its worktree
WorktreeRemove hook: closes the worktree if it is clean; the commits stay on the branch
orchestrator: publishes the branch; for the verifier, another delegate → a clean worktree
```

- A branch can only be in one worktree at a time (a git rule): the orchestrator closes its own (`aes-wt.sh close`) before delegating on the same branch.
- The roles run one at a time. In parallel, two worktrees would start servers on the same ports.
- Each worktree needs its dependencies (`npm ci`, `dotnet restore`): each role's first run is slower.
- If you want more local files in each worktree (for example, an `.env`), add them to `AES_WT_LOCAL_FILES` in `aes-wt.sh`.

## Roles in OpenCode (binding, AES 06 §12)

The orchestrator stays in Claude Code; QA, the programmer and the mechanic can run in [OpenCode](https://opencode.ai) with another provider (for example, DeepSeek). The verifier stays in Claude: a model from another family reviews better. All of it is optional: with the binding at `claude` (the default value), none of this is used.

### Getting started

1. **OpenCode** 1.18.30 or later (`opencode --version`). It asks for no account.
2. **Provider.** One of these:
   - **Paid DeepSeek:** create a key at platform.deepseek.com and top up the balance (PayPal or card; it is prepaid, so the balance is your cap). In OpenCode, `/connect` → `deepseek` → paste the key, or define `DEEPSEEK_API_KEY` in the environment. Model: `deepseek/deepseek-flash`.
   - **Free for a limited time:** OpenCode offers some models at no cost, with no account. `opencode/deepseek-v4.1-flash-free` declares zero retention and no training; other free ones (Big Pickle, MiMo, Nemotron…) do store or train on your data: do not use them with code you do not want to share. Check the terms at opencode.ai/docs/zen before choosing. The free plan cuts long sessions off at its usage limit: use it only for trying things out.
3. **Binding** in `.claude/aes.env`, per role:
   ```bash
   AES_BIND_QA="opencode:deepseek/deepseek-flash"
   AES_BIND_PROGRAMMER="opencode:deepseek/deepseek-flash"
   AES_BIND_MECHANIC="opencode:deepseek/deepseek-flash"
   AES_BIND_VERIFIER="claude"
   ```
   And the list price to estimate the cost (`AES_OC_LIST_PRICE`, `AES_OC_PEAK_UTC`): it already comes with `deepseek-flash`'s.
4. **Model levels** (06 §12.1): a task can ask for `**Model level:** high — <reason>`, which resolves to `AES_BIND_<ROLE>_HIGH` (for example `claude:sonnet` for the programmer and `claude:opus` for the verifier). The human approves the level with the tasks.
5. **Check:** `bash .claude/scripts/aes-doctor.sh`. It checks OpenCode's version and options and that each bound model answers.

### How the orchestrator delegates

`bash .claude/scripts/aes-oc.sh run <role> <branch> -- "<template with its data>"`, in the background. The script:

1. opens the branch's worktree and marks it as active;
2. runs `opencode run --agent <role> -m <model>` there, **without** the GitHub App's or `gh`'s credentials in the environment, with the project language in the prompt;
3. applies the end-of-role gate (`subagent-gate.sh`: servers, guard, `ci/validate.sh`, uncommitted changes); if it fails, it resumes the session **once** with the reason, like a `SubagentStop` hook;
4. stores the events and the session in `.aes/runs/<branch>/` and a row in `.aes/costs.csv`;
5. prints the status, the commits, the files, the cost and the role's report; it closes the worktree if it is clean.

`bash .claude/scripts/aes-oc.sh report [<ID>]` summarizes tokens and cost per item and role.

### Controls

| Layer | Claude Code (subagent) | OpenCode |
|---|---|---|
| Contract | `.claude/agents/<role>.md` | The same file, loaded with `{file:…}` in `opencode.json` |
| L1 | `permissions` in `settings.json` | `permission` per agent in `opencode.json`: protected paths, `git push`/`gh`, network, questions and subagents at `deny`; only the role's skills. In `opencode run`, whatever would be *ask* is rejected by itself |
| L2 | Hooks `role-guard.sh`, `bash-guard.sh` | `.opencode/plugin/aes-guard.js`, which runs **the same** hooks (`AES_ROLE` is set by the script) and removes credentials from the terminal's environment |
| End of role | `SubagentStop` hook | `aes-oc.sh` runs `subagent-gate.sh` and resumes once |
| L3 | CI | The same CI |
| Outside the repo | No sandbox on native Windows (FL-002) | OpenCode rejects reading or writing outside the project by default (`external_directory`) |

Tested first with a simulated model (an OpenAI-compatible server that requests scripted tools): writing in `tests/acceptance/`, redirecting the terminal to a protected path, writing outside the surface and `git push` are blocked with the hook's message, and the model receives it and continues; the gate resumes the session and the fix passes; the cost matches the list price and doubles in the expensive slot. Then in aes-todo with `deepseek/deepseek-flash` (see `docs/case-study.md` in the AES repo).

### Known limits

- **Estimated cost, not billed.** OpenCode only knows DeepSeek's cheap price; the script applies the time-slot surcharge (`AES_OC_PEAK_UTC`). The figure that counts is the one on the provider's *Billing* page.
- **First run in each worktree:** OpenCode installs the plugin dependency in `.opencode/` (it ignores it in git by itself). It takes longer the first time.
- **Windows:** the plugin runs the hooks with the same bash that runs `aes-oc.sh` (Git Bash, converted to a Windows path), not with the `bash` on the PATH, which with WSL installed may be WSL's. To use another one, define `AES_BASH`.
- **Personal skills:** OpenCode also sees your user's skills (`~/.claude/skills/`); `opencode.json` denies them all except the role's.
- **Parallel:** as with the subagents, one role at a time until the profile solves ports and data per checkout (06 §10).

## Code graph with Graphify (optional, in pilot)

[Graphify](https://github.com/Graphify-Labs/graphify) builds a graph of the code with tree-sitter, locally and without a model, and can serve the orchestrator as an additional fact for the design note (AES 10 §5). It is used as a **tool** (06 §6.2), from the terminal:

```bash
uv tool install graphifyy           # or pipx install graphifyy
graphify update .                   # first graph, local and without a model
graphify hook install               # rebuilds it in the background after each commit and checkout;
                                    # installed in the main checkout, it also covers the worktrees
```

- Add `graphify-out/` to `.gitignore`.
- **Do not use `graphify watch`:** it leaves a process alive between roles (06 §10). The git hook is enough.
- For the design note only the relationships Graphify marks as extracted from the code count as facts, not the inferred ones.
- Do not install its assistant integration (`graphify install`) without testing it first: it adds its own read hook to Claude Code, which has to coexist with AES's. That is what remains to be checked in the sandbox.
- Register it in the profile like any third-party skill or tool.

## Flow of a task with verification in L3

```
programmer → PR task/<ID>/<TASK>
CI: everything green except "Verifier PASS approved"   ← expected, not a FAIL cycle
orchestrator → verifier → PASS
you: read the report → put on aes:verified
CI restarts (labeled event) → green → you merge
a new commit on the branch → CI removes aes:verified (and the other approvals) → it must be verified again
```

## Verification commands

For criteria that are not checked with an acceptance test (configuration, tools, scripts): `specs/<ID>/<ID>.verify` or, in a batch, `specs/<ID>/BUG-NNN.verify`. It is a bash script that exits with 0 if the criterion is met. QA writes it and you approve it, like a test.

```bash
# specs/CH-002/CH-002.verify — example
set -euo pipefail
grep -q '<clear />' nuget.config
dotnet restore --configfile nuget.config --no-cache >/dev/null
```

If it is impossible for it to fail before the change, its first line is `# aes: no-red <reason>` and your approval must be explicit.

## Trying it locally

```bash
BASE_REF=origin/dev TASK_SCOPE_FILE=specs/US-005/TASK-014.scope bash ci/aes-guard.sh
BASE=origin/dev bash ci/defect-gate.sh start US-006
EVENT=pull_request HEAD_BRANCH=task/US-005/TASK-014 TARGET=dev BASE=origin/dev bash ci/aes-ctx.sh
bash ci/run-verify.sh green origin/dev specs/CH-002/CH-002.verify
git merge-base --is-ancestor origin/main origin/dev && echo "main contained in dev"
```

## Windows

- The hooks are bash: install Git for Windows. Claude Code runs them with Git Bash, and `lib.sh` normalizes `H:\...` paths.
- Use `.gitattributes` with `*.sh text eol=lf`; with CRLF the scripts fail.
- Claude Code's terminal isolation (*sandbox*) **only exists in WSL 2**. On native Windows, nothing prevents an agent from writing outside the repo (FL-002 in the sandbox). If the disk has something sensitive, work in WSL 2 with the sandbox on, or declare it as an exception in the profile (AES 06 §9).

## Known limits

- Layers L1 and L2 are friction, not a guarantee: the terminal can write what the edit hook blocks. The guarantee is CI (L3).
- The permission classifier of Claude Code's automatic mode acts as an additional L1 layer, not configured by the project. In the sandbox it denied overly broad actions (stopping every `dotnet`/`node` process).
- Holdout tests are not implemented in this reference.
