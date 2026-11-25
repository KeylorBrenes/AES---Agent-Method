# AES core skills

AES's own skills, written for its gates, contracts and roles (`standard/06` §6.2), in the open [Agent Skills](https://agentskills.io) format (`SKILL.md` with `name` and `description`). They are not mandatory: a project can use other equivalent ones if they meet the rules of 06 §6.2.

| Skill | Type | Role | When |
|---|---|---|---|
| [`aes-debugging`](aes-debugging/SKILL.md) | Technique | Programmer, mechanic; orchestrator when classifying | On any failure, before fixing: FAIL cycle, defect, flaky test |
| [`aes-security-review`](aes-security-review/SKILL.md) | Tool | Programmer; orchestrator when classifying | Before delivering a sensitive task, on a SAST finding in CI |
| [`aes-inception`](aes-inception/SKILL.md) | Technique | Orchestrator | When starting a project (no backlog) or on an idea that does not fit in the backlog (mini-inception) |
| [`aes-design-note`](aes-design-note/SKILL.md) | Technique | Orchestrator | When splitting a story into tasks; on a design question |

The cycle's flow is not here: it is the orchestrator's skill of each reference implementation (for example, `profiles/reference/claude-code-subagents/.claude/skills/aes-cycle/`), because it depends on the harness.

The skills are written in English; the artifacts they produce follow the project's language (`AES_LANG` in `.claude/aes.env`).

## Use in a project

The installer copies them with everything else, at the fixed AES version you run it from:

```bash
./scripts/install-aes.sh /path/to/project
```

Then register them in the project profile (origin, version, who reviewed them, which roles use them). Do not link them to a branch that changes: a skill that changes by itself changes the agents' instructions without approval.

## Recommended third-party skills

They are not part of AES and do not travel in this repository. If the project uses them, the installer copies them from a local folder at the version you have (`--vendor <folder>`) and records their version in `docs/aes/skills.lock`.

| Skill | Type | License | What for in AES | Mandatory adjustment |
|---|---|---|---|---|
| [impeccable](https://github.com/pbakaus/impeccable) | Technique + tool | Apache-2.0 (`LICENSE` and `NOTICE.md` are copied) | Interface design: product context (`PRODUCT.md`) and visual direction (`DESIGN.md`) at inception, `shape` when refining stories with an interface, building and polishing by the programmer inside the surface, the verifier's `audit` and the deterministic detector in CI | Telemetry, update notice and per-edit hook turned off (`.impeccable/config.json` and variables in `settings.json`). Its catalogue of visual directions cannot be turned off: only at inception, with the human present. Its engine is downloaded at a fixed version verified by checksum. Commands per role: see the reference's contracts |
| [archify](https://github.com/tt-a1i/archify) | Tool | MIT | Validated HTML diagrams from JSON (architecture, workflow, sequence, data flow, lifecycle): the inception's component diagram, design notes with a flow, an entity's lifecycle | Turn off its update notice (`ARCHIFY_UPDATE_CHECK_DISABLED=1`, 06 §6.2). The JSON is versioned; the HTML is generated in `.aes/` |

## Attribution

`aes-debugging` takes `systematic-debugging` from [obra/superpowers](https://github.com/obra/superpowers) (MIT license) as its reference.
