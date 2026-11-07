# Changelog

## [1.3.0] — sin publicar (rama `release/1.3.0`)

Se acumulan aquí los cambios que propone el responsable humano antes de retomar el sandbox. Justificación: [`docs/rfc/RFC-003-aes-1.3.0.md`](docs/rfc/RFC-003-aes-1.3.0.md).

### Añadido
- **Ramas `main` y `dev` obligatorias** en todo proyecto (07 §7, principio 19): `main` es lo liberado, `dev` lo integrado y la base de todo el trabajo. Sin variante «solo `main`» ni *feature flags*.
- **Release** `dev → main` como gate humano propio (07 §8): compuerta de estabilización, `main` contenido en `dev`, regresión completa, merge commit, sin periodo mínimo de uso. Estado nuevo `Released` (00 §6). Plantilla `release.md`.
- **Hotfix y back-merge** (07 §9): un defecto de algo liberado, de cualquier severidad, puede corregirse desde `main` si el responsable humano lo decide; después de cada integración en `main`, back-merge a `dev` con merge commit.
- **Checkout propio por rol** (06 §10): el orquestador se queda en `dev` y cada rol trabaja en su propio checkout de la rama de trabajo.
- DoD de hotfix y de release (08 §7–8).
- **Capítulo 10 — Principios de diseño y patrones**: nivel 1 de principios siempre obligatorios en todo código (responsabilidad única, lógica separada de la E/S, dependencias recibidas, acceso a datos agrupado, contratos en las fronteras, errores explícitos, Liskov, interfaces pequeñas, visibilidad mínima, configuración fuera del código), cada uno con su síntoma; nivel 2 de patrones condicionales con «cuándo sí» y «cuándo no»; la prueba de tres condiciones para decidir el nivel (principio 20).
- **Orquestador como diseñador senior** en el modelo más capaz disponible (06 §11): escribe una nota de diseño por tarea a partir de hechos (artefactos, catálogo de diseño y resumen estructural), incluido lo que no se hace; el programador no añade patrones fuera de la nota y el verificador revisa el diff contra ella y contra el nivel 1. Plantillas `design-note.md` y `design-catalog.md`; script `aes-outline.sh`.
- Implementación de referencia: `aes-wt.sh` y hooks `WorktreeCreate`/`WorktreeRemove` para que cada subagente trabaje en un worktree de la rama real; `aes-base.sh`; CI en `dev` y `main` con comprobación de rutas, «main contenido en dev», release y back-merge; compuerta en fase `release`; skill con release, hotfix y back-merge.

## [1.2.0] — 2026-11-05

Primera versión con evidencia de agentes reales: cuatro elementos ejecutados en [aes-sandbox-gastos](https://github.com/KeylorBrenes/aes-sandbox-gastos) (EN-001, US-001, CH-001, US-002), con Claude Code como orquestador y subagentes por rol. Cambio MINOR: añade reglas y endurece controles sin romper la estructura. Justificación y evidencia: [`docs/rfc/RFC-002-aes-1.2.0.md`](docs/rfc/RFC-002-aes-1.2.0.md).

### Añadido
- **Compuerta de estabilización** (02 §9, principio 17): todo defecto lleva severidad (Crítica, Alta, Media, Menor). Una historia nueva no pasa a `Ready` con defectos Críticos, Altos o Medios abiertos, ni con más Menores que el límite del perfil; un Crítico detiene todo. Los defectos se corrigen en un **lote de estabilización**, en una sola sesión, sin funcionalidad nueva.
- **Registro de decisiones** por historia (03 §8, principio 18): cada ambigüedad resuelta es una fila `D-NN` con quién, cuándo e impacto. Los **supuestos de QA** se deciden antes de `Ready` (03 §5).
- **Camino corto T0/T1** (04 §10) y DoR propia para T1 (08 §2). **Comandos de verificación** (`.verify`) para criterios que no se prueban con aceptación (05 §12).
- **Tareas por criterio**: cada tarea declara los criterios que deja en verde y la CI ejecuta solo esos más la regresión (04 §2, 05 §12). Qué ejecuta la CI en cada fase (05 §12).
- **Pruebas de caracterización** (05 §2.4), **aislamiento de datos** en las pruebas (05 §2.5) y pruebas inestables como defecto de severidad Alta (05 §6).
- **Criterio de fallo** obligatorio para cada acción que escribe (03 §3) y transiciones que limpian cada estado (04 §2).
- **Acciones denegadas y rodeo por delegación** (06 §6.1), **estado entre roles** (06 §10), **modelo real por rol** en la evidencia (06 §11).
- **Verificación antes de integrar**, exigida en L3; aprobaciones en la CI que validan **quién** aprobó (06 §8).
- **Evidencia en su fuente** (00 §7) y log de la CI como prueba de qué se ejecutó (05 §9).
- Rol opcional **Mecánico** (00 §5, 06 §2) y su contrato.
- **Evidencia del proceso y métricas** por elemento; notas con hora real (09 §6–7).
- Plantillas nuevas: `defect.md`, `stabilization-batch.md`, `harness-findings.md`.
- **Implementación de referencia `claude-code-subagents`**, a partir del sandbox: subagentes, hooks por rol, skill del orquestador, scripts de identidad (GitHub App), notas y servidores, y una CI con guardián, RED con trazabilidad, CI por criterio, comandos de verificación, compuerta de estabilización, aprobaciones validadas e invalidadas tras commits nuevos, y verificación (`aes:verified`) antes de integrar.

### Cambiado
- DoR y DoD reescritas con las reglas nuevas; DoD propia para lotes de estabilización (08).
- RED confirmado exige que **todas** las pruebas se ejecuten, comprobado por herramienta; se define el «RED de arranque» (05 §2.2).
- Presupuesto de diff separado en producción y pruebas (02 §6).
- Un hallazgo tras un `PASS` que el humano manda corregir cuenta como ciclo `FAIL`; una CI que solo espera una aprobación prevista no (04 §9).
- Convenciones que valen para más de una historia suben a un ADR (01 §4); copia local de DoR/DoD en cada proyecto (01 §2).
- Rulesets separados, identidad propia de los agentes y aislamiento del sistema de archivos, ahora en el estándar (06 §9).
- Guardián: las fuentes de paquetes y herramientas cuentan como dependencias; exclusión estrecha del código generado (05 §10).
- Plantillas de historia, tarea, plan de aceptación, informe de verificación y perfil actualizadas; contratos de orquestador, QA, programador, verificador y arquitecto actualizados.

### Pendiente (sigue en el RFC)
- Binding de roles para otro harness (OpenCode o un motor local), aislamiento del sistema de archivos con evidencia, y elección del modelo del orquestador con más datos.

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
