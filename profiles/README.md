# Perfiles de proyecto

Los perfiles adaptan AES Core al tipo de producto y stack. No reemplazan AES Core ni reducen sus controles fundamentales.

Cree `project-profile.md` usando `templates/project-profile.template.md`. Puede añadir perfiles especializados (web, backend, móvil, escritorio, embedded, data) cuando se conozcan los requisitos concretos.

No se incluye un perfil de stack prescriptivo: la tecnología debe elegirse para cada proyecto y documentarse con sus comandos, rutas protegidas y estándares de calidad.

## Implementaciones de referencia

- [`reference/claude-code-subagents/`](reference/claude-code-subagents/) **(1.2.0)**: Claude Code como único harness, con el orquestador en la sesión principal y QA, programador, mecánico y verificador como subagentes. Sale del experimento [aes-sandbox-gastos](https://github.com/KeylorBrenes/aes-sandbox-gastos). Incluye subagentes, hooks por rol, skill del orquestador, CI completa (guardián, RED con trazabilidad, CI por criterio, comandos de verificación, compuerta de estabilización, aprobaciones validadas, verificación antes de integrar) e identidad de agentes con una GitHub App.
- [`reference/claude-code-opencode/`](reference/claude-code-opencode/) (1.1): Claude Code como orquestador, OpenCode como programador/verificador y GitHub Actions como CI. Incluye permisos de OpenCode, hooks, guardián, workflow con pruebas holdout desde un repositorio privado, CODEOWNERS y un `AGENTS.md` de ejemplo. Su CI no tiene las novedades de 1.2.0: tómalas de `claude-code-subagents`.

Una implementación de referencia muestra cómo cumplir los controles; no obliga a usar esas herramientas.
