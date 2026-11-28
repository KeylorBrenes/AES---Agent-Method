# Project profiles

Profiles adapt AES Core to the type of product and stack. They do not replace AES Core or reduce its fundamental controls.

Create `project-profile.md` using `templates/project-profile.template.md`. You can add specialized profiles (web, backend, mobile, desktop, embedded, data) once the concrete requirements are known.

No prescriptive stack profile is included: the technology must be chosen for each project and documented with its commands, protected paths and quality standards.

## Reference implementations

- [`reference/claude-code-subagents/`](reference/claude-code-subagents/) **(2.2.0)**: Claude Code as the orchestrator's harness, with the orchestrator in the main session and QA, programmer, mechanic and verifier as subagents or, according to the binding, in OpenCode with another provider. It comes out of the [aes-sandbox-gastos](https://github.com/KeylorBrenes/aes-sandbox-gastos) and [aes-todo](https://github.com/KeylorBrenes/aes-todo) sandboxes. It includes the subagents, hooks per role, the orchestrator's skill, the full CI (guard, RED with traceability, CI per criterion, verification commands, stabilization gate, validated approvals, verification before merging, SAST, a second code review with Open Code Review), the agents' identity with a GitHub App, the backlog board, the environment check and the task graph for running tasks in parallel.

The `claude-code-opencode` implementation (1.1, with holdout tests run from a private repository) was removed in 2.0.0: its CI had fallen behind, and OpenCode roles are now part of `claude-code-subagents`. It is still available at the `v1.6.0` tag.

A reference implementation shows how to meet the controls; it does not require using those tools.
