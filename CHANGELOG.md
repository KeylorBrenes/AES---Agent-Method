# Changelog

## [1.1.2] — 2026-11-02

Correcciones en la implementación de referencia (`profiles/reference/claude-code-opencode/`), encontradas al ejecutar AES con agentes reales en [aes-sandbox-gastos](https://github.com/KeylorBrenes/aes-sandbox-gastos), historia EN-001. Sin cambios normativos: las reglas que salgan del experimento irán a la 1.2.0 (RFC-002).

### Corregido
- **El hook `protect-paths.sh` no protegía nada en Windows.** Comparaba rutas con `\` contra patrones con `/`, así que las escrituras a `tests/acceptance/` pasaban. Ahora normaliza rutas de Windows (`H:\`, `h:/`, `/h/`) y es insensible a mayúsculas en la unidad.
- **Los hooks se registraban con `$CLAUDE_PROJECT_DIR`**, frágil con rutas de Windows. Ahora se invocan con `bash "$(git rev-parse --show-toplevel)/…"`.
- **El workflow ignoraba las etiquetas de aprobación.** Faltaban los eventos `labeled`/`unlabeled`: poner `aes:deps-approved` no relanzaba la CI, y un re-run repite el evento original, sin la etiqueta.
- **El guardián no trataba las fuentes de paquetes como dependencias.** Un `.npmrc` o un `nuget.config` que apunte a otro registro pasaba sin aprobación. Ahora cuentan como cambio de dependencias: `nuget.config`, `.npmrc`, `.yarnrc(.yml)`, `pip.conf`.
- **Guía de protección de rama:** un solo ruleset con bypass permite fusionar con la CI en rojo, porque el bypass salta todas las reglas. Ahora se indican dos rulesets: `main-ci` sin bypass y `main-aprobacion` con bypass solo para la aprobación.
- **Guía de identidad de los agentes:** GitHub App en lugar de un token *fine-grained* o una cuenta bot. Incluye la nueva ubicación de las llaves (*Credentials → Key pairs*).
- **Windows:** nota sobre Git Bash, finales de línea y el *sandbox* de la terminal (solo en WSL 2).

## [1.1.1] — 2026-11-02

### Corregido
- 06 §9: las credenciales que publican ramas de programador no deben poder modificar workflows; de lo contrario una rama puede editar su propio workflow y saltarse el guardián. Documentado también en la implementación de referencia.
- Workflows de referencia actualizados a `actions/checkout@v7` y `actions/setup-node@v7`.

## [1.1.0] — 2026-11-02

Refinamiento a partir de la experiencia práctica con agentes de código y de las fuentes citadas en `docs/rfc/RFC-001-aes-1.1.0.md`. Cambio MINOR: añade reglas y endurece controles existentes sin romper la estructura.

### Añadido
- **Modelo de controles en capas L1/L2/L3** (06 §9): un control solo cuenta como técnico si el agente no puede esquivarlo desde su entorno; los controles fundamentales deben existir en L3.
- **Tracks proporcionales T0–T3** (02 §8): el proceso se ajusta al tamaño y riesgo del cambio para evitar burocracia en cambios pequeños.
- **Contrato de interfaz** antes de escribir pruebas de aceptación (05 §2.1).
- **RED confirmado**: cada prueba de aceptación nueva debe fallar contra la base por la razón esperada antes de implementar (05 §2.2).
- **Pruebas holdout** inaccesibles al programador; obligatorias en T3 (05 §2.3).
- **Guardián de CI**: superficie de cambio, rutas protegidas, dependencias, pruebas borradas y marcadores de trampa (05 §10).
- **Prueba manual agéntica** por el verificador para T2/T3 (05 §11).
- **Commits estructurales vs. conductuales** (04 §8).
- **Circuit breaker** tras 3 ciclos FAIL e higiene de contexto (04 §9).
- **Revisión humana proporcional** por track (00 §8).
- Principios 13–16: prueba como especificación ejecutable, evidencia ejecutada, proceso proporcional y mejora continua del harness.
- Nuevo capítulo **09 — Mejora continua del harness** y plantilla `templates/agent-failure-log.md`.
- Reglas para instrucciones persistentes (`AGENTS.md`/`CLAUDE.md`) y skills (06 §5.1, §6).
- Implementación de referencia `profiles/reference/claude-code-opencode/` con scripts probados.
- `scripts/build-core.sh` para generar el documento consolidado y `docs/ci/validate.yml`, workflow de validación del propio repositorio (moverlo a `.github/workflows/` para activarlo).

### Cambiado
- Tareas: campos obligatorios de track, superficie de cambio, comandos exactos, pruebas afectadas y presupuesto de diff (04 §2).
- Programador: baseline de pruebas al inicio de cada sesión (04 §4).
- Verificador: re-ejecuta validaciones, ejecuta holdout y vigila las señales de desvío de Kent Beck (06 §4).
- DoR/DoD de historias y tareas actualizadas con los nuevos gates (08).
- Contratos de los cinco agentes y plantillas de tarea, historia, plan de aceptación, informe de verificación y perfil.
- `AES-CORE-1.0.0.md` sustituido por `AES-CORE.md`, generado desde `standard/`.

### Corregido
- El README apuntaba a `profiles/project-profile.template.md`; la plantilla está en `templates/`.

## [1.0.0] — 2026-11-01

Primera versión del Agentic Engineering Standard.

- Define principios y jerarquía de planificación.
- Establece Epics, Historias de Usuario, tareas pequeñas y trazabilidad.
- Adopta Story Points relativos con escala Fibonacci: 1, 2, 3, 5, 8 y 13.
- Establece Definition of Ready y Definition of Done.
- Integra ATDD, TDD, pruebas de integración, E2E y verificación independiente.
- Define límites de permisos y responsabilidades para agentes.
- Introduce gestión de riesgos, cambios, excepciones y aceptación humana.
