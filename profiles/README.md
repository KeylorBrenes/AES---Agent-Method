# Perfiles de proyecto

Los perfiles adaptan AES Core al tipo de producto y stack. No reemplazan AES Core ni reducen sus controles fundamentales.

Cree `project-profile.md` usando `templates/project-profile.template.md`. Puede añadir perfiles especializados (web, backend, móvil, escritorio, embedded, data) cuando se conozcan los requisitos concretos.

No se incluye un perfil de stack prescriptivo: la tecnología debe elegirse para cada proyecto y documentarse con sus comandos, rutas protegidas y estándares de calidad.

## Implementaciones de referencia

- [`reference/claude-code-opencode/`](reference/claude-code-opencode/): las tres capas de control (06 §9) para Claude Code como orquestador, OpenCode como programador/verificador y GitHub Actions como CI. Incluye permisos, hooks, guardián de CI probado, workflow, CODEOWNERS y un `AGENTS.md` de ejemplo.

Una implementación de referencia muestra cómo cumplir los controles; no obliga a usar esas herramientas.
