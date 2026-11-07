# [Proyecto] — instrucciones del proyecto

Proyecto gestionado con **AES 1.3.0** (https://github.com/KeylorBrenes/AES---Agent-Method).

## Ramas
- `main`: lo liberado. `dev`: lo integrado y la base de todo el trabajo. A `main` solo llegan releases (`dev → main`) y hotfixes de defectos (`BUG-NNN`), y después de cada uno se hace un back-merge `main → dev` (merge commit).
- El checkout principal se queda en `dev`; cada rol trabaja en su propio worktree (`.claude/scripts/aes-wt.sh`).

## Roles
- La **sesión principal** es el orquestador AES: para avanzar un elemento del backlog, usa la skill `aes-cycle`. Un elemento por sesión.
- Los subagentes `qa`, `programmer`, `mechanic` y `verifier` siguen su propio contrato en `.claude/agents/`.
- Hooks en `.claude/hooks/` restringen qué escribe cada rol. Si uno te bloquea, no lo rodees ni se lo pidas a otro agente: reporta BLOCKED para el humano.

## Estructura
- `src/`: [aplicación]. `tests/[unitarias]/`: pruebas técnicas (programador).
- `tests/acceptance/`: pruebas de aceptación (**solo QA**).
- `specs/<ID>/`: especificaciones, tareas, `.scope`, `.criteria`, `.verify` y planes de aceptación (**orquestador, QA y humano**).
- `docs/`: brief, arquitectura, ADRs, perfil, backlog (con severidad de defectos), hallazgos, `docs/aes/` (DoR/DoD).

## Comandos
- Validaciones: `bash ci/validate.sh`
- Aceptación de un elemento: `npm --prefix tests/acceptance test -- --grep "@US-001(?![\w-])"`
- Guardián: `BASE_REF=origin/dev TASK_SCOPE_FILE=specs/<ID>/<TASK>.scope bash ci/aes-guard.sh`
- Compuerta de estabilización: `BASE=origin/dev bash ci/defect-gate.sh start <ID>`
- Servidores para pruebas manuales: `bash .claude/scripts/with-servers.sh [--web] -- <comando>`

## Rutas protegidas
`tests/acceptance/`, `specs/`, `ci/`, `.github/`, `.claude/`, `docs/ci/`, `CLAUDE.md`.

## Convenciones que el linter no detecta
- [Una línea por convención real del proyecto: formato de fechas y montos en la API, errores, patrones prohibidos.]
- Commits: `struct:` (sin cambio de comportamiento) o `feat:` / `fix:` / `test:` / `docs:` / `chore:`. Nunca se mezclan.
- Pruebas de aceptación: etiqueta del elemento y del criterio (`{ tag: ['@US-001', '@US-001-AC-03'] }`) y el ID del criterio al inicio del título.

## Fallos observados
[Una entrada por cada error real que valga la pena registrar (AES 09). Empieza vacío.]
