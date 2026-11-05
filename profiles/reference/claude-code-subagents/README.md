# Implementación de referencia — Claude Code con subagentes

Implementación de AES 1.2.0 con **Claude Code** como único harness: la sesión principal es el orquestador y los roles `qa`, `programmer`, `mechanic` y `verifier` son subagentes con su propio contexto, modelo y permisos. GitHub aloja el repositorio, la CI y la protección de rama.

Sale del experimento [aes-sandbox-gastos](https://github.com/KeylorBrenes/aes-sandbox-gastos), una app de control de gastos en .NET 10 + React donde se aplicó AES con agentes reales en cuatro elementos (EN-001, US-001, CH-001, US-002). Lo que dice «probado» se usó ahí; lo que dice «simulación» se probó con repositorios y datos de prueba al publicar esta versión, pero todavía no en un ciclo real.

Es un punto de partida, no un perfil prescriptivo. Las partes del stack (.NET + React) están marcadas.

## Contenido

| Archivo | Capa | Función | Estado |
|---|---|---|---|
| `.claude/agents/{qa,programmer,mechanic,verifier}.md` | L1 | Subagentes: herramientas, modelo y contrato de cada rol | Probado |
| `.claude/settings.json` | L1 + L2 | Denegaciones y registro de hooks | Probado |
| `.claude/hooks/role-guard.sh` | L2 | `PreToolUse` de edición: qué puede escribir cada rol (orquestador sin código; QA solo pruebas, plan y `.verify`; programador y mecánico solo su superficie; verificador nada) | Probado |
| `.claude/hooks/bash-guard.sh` | L2 | `PreToolUse` de terminal: escrituras evidentes a rutas prohibidas; los subagentes no publican ni cambian de rama | Probado |
| `.claude/hooks/subagent-gate.sh` | L2 | `SubagentStop`: ningún rol termina con servidores vivos; programador y mecánico, además, con el guardián y `ci/validate.sh` en verde | Probado |
| `.claude/scripts/with-servers.sh` | — | Arranca los servidores con datos temporales, ejecuta un comando y los detiene siempre; falla si el puerto está ocupado | Probado en Windows y Linux (la lectura de `.claude/aes.env`: simulación) |
| `.claude/scripts/aes-note.sh` | — | Notas del orquestador con la hora real; `clear` las vacía tras el cierre | Probado (`clear`: simulación) |
| `.claude/scripts/gh-app-token.sh`, `git-credential-aes-app.sh`, `agent-gh.sh` | L3 | Identidad de los agentes: GitHub App sin permiso de workflows | Probado |
| `.claude/skills/aes-cycle/SKILL.md` | — | Procedimiento del orquestador, con plantillas de delegación | Probado (caminos T1 y lote: simulación) |
| `.claude/aes.env` | — | Puertos y comandos de servidores del proyecto | — |
| `ci/aes-guard.sh` | L3 | Guardián: rutas protegidas, superficie, dependencias, pruebas borradas, marcadores | Probado |
| `ci/red-check.mjs` | L3 | RED confirmado (todas ejecutadas y fallando) y trazabilidad criterio → prueba | RED probado; trazabilidad: simulación |
| `ci/aes-ctx.sh` | L3 | Qué ejecuta la CI según la rama: criterios de la tarea, regresión, comandos de verificación | Por criterio: probado; `.verify`: simulación |
| `ci/defect-gate.sh` | L3 | Compuerta de estabilización: lee la severidad de los defectos del backlog desde `main` | Simulación |
| `ci/run-verify.sh` | L3 | Comandos de verificación: RED en la especificación, verde en tareas, cierre y regresión | Simulación |
| `ci/label-approver.sh` | L3 | Quién puso cada etiqueta de aprobación (no la identidad de los agentes) | Simulación |
| `ci/validate.sh` | — | Validaciones del stack (ejemplo .NET + React) | Probado |
| `.github/workflows/aes.yml` | L3 | Un único check `aes` con todo lo anterior; scripts siempre desde `main` | Versión anterior probada; esta, en simulación |
| `.github/CODEOWNERS` | L3 | Tu aprobación para rutas protegidas | Probado |
| `CLAUDE.md` | — | Ejemplo de instrucciones persistentes breves | — |

## Puesta en marcha

1. **Copia** estos archivos a la raíz de tu proyecto, respetando las rutas. Sustituye `@tu-usuario` en `CODEOWNERS`, los comandos de `.claude/aes.env`, `ci/validate.sh` y la sección `STACK` del workflow.
2. **Añade a `.gitignore`:** `.aes/` (notas del orquestador) y `.claude/settings.local.json` (credenciales).
3. **Copia la DoR/DoD** de AES (`standard/08-definition-of-ready-and-done.md`) a `docs/aes/`, para que los agentes la tengan en el repo.
4. **Backlog:** la tabla de `docs/backlog.md` debe tener las columnas `ID`, `Severidad` y `Estado`. La severidad (`Crítica`, `Alta`, `Media`, `Menor`) solo se rellena en los defectos; el resto lleva `—`. La compuerta lee esa tabla desde `main`.
5. **Regresión:** crea `specs/active-stories.txt` (un ID por línea; empieza vacío). El orquestador añade cada elemento en su cierre.
6. **Identidad de los agentes: GitHub App** sin permiso de *Workflows*. Así ningún agente puede editar la CI para saltarse el guardián, y sus PR aparecen como `<app>[bot]`, que tú puedes aprobar.
   - Créala en *Settings → Developer settings → GitHub Apps* con permisos de *Contents* y *Pull requests* (lectura y escritura) y nada más. Instálala solo en el repositorio.
   - La llave se genera en ***Credentials → Key pairs → New key***. Guárdala fuera del repo.
   - Copia `.claude/settings.local.example.json` a `.claude/settings.local.json` y rellena el App ID, el Installation ID, la ruta de la llave (con `/`) y, para que los commits lleven la autoría del bot, el *slug* y el ID del usuario bot (`gh api "/users/<slug>%5Bbot%5D" --jq .id`).
   - Prueba: `bash .claude/scripts/gh-app-token.sh | cut -c1-4` debe imprimir `ghs_`.
   - No uses una cuenta bot ni un token personal *fine-grained*: las cuentas nuevas pueden quedar suspendidas por el antiabuso de GitHub, y los tokens *fine-grained* no acceden a repos de otra cuenta personal.
7. **Protección de `main` con dos rulesets.** GitHub exige cumplir todos los que aplican, y el bypass de uno no salta el otro:
   - **`main-ci`, sin bypass para nadie:** *Restrict deletions*, *Block force pushes*, *Require status checks to pass* (`aes`) con *Require branches to be up to date*.
   - **`main-aprobacion`:** *Require a pull request before merging* con 1 aprobación, *Require review from Code Owners* y *Dismiss stale approvals*. Bypass: *Repository admin* en modo **For pull requests only**, para que puedas integrar tus propios PR.

   Un único ruleset con bypass permite integrar con la CI en rojo: el bypass salta todas sus reglas. Pasó en el sandbox (FL-003).
8. **Etiquetas:** crea `aes:deps-approved`, `aes:markers-approved` y `aes:verified`. Solo tú las pones.
9. **Variables del repositorio** (*Settings → Secrets and variables → Actions → Variables*):
   - `AES_APPROVERS`: tu login (o los logins autorizados, separados por coma). La CI acepta una etiqueta solo si la última vez la puso una de estas personas, nunca un `[bot]`. Sin esta variable, solo rechaza las que puso un bot.
   - `AES_MINOR_LIMIT` (opcional, por defecto 5): defectos Menores abiertos permitidos.
   - `AES_REQUIRE_VERIFIED` (opcional, por defecto `1`): exige `aes:verified` en las tareas.
10. **Activar el workflow:** la app no puede tocar `.github/workflows/`, así que lo subes tú en un PR propio.
11. Instala `jq` donde corran los hooks.

## Convención de ramas

| Rama | Quién | Qué ejecuta la CI |
|---|---|---|
| `spec/<ID>` | orquestador | build/test, RED de los comandos de verificación nuevos, regresión |
| `qa/<ID>` | orquestador + QA | compuerta (inicio), build/test, RED y trazabilidad de las pruebas de `<ID>`, RED de los comandos nuevos |
| `task/<ID>/<TASK>` | programador o mecánico | compuerta (solo Crítica), guardián, build/test, criterios de la tarea (`<TASK>.criteria`; sin él, el elemento completo), comandos de verificación, regresión, `aes:verified` |
| `spec/<ID>-close` | orquestador + mecánico | build/test, el elemento completo (debe ejecutarse y pasar), regresión |
| push a `main` | — | build/test, regresión, informe de la compuerta |

`<ID>` es el elemento del backlog: `US-`, `EN-` (pasan por la compuerta), `BUG-`, `CH-`, `ST-`, `SP-` (no pasan: corrigen o mantienen).

## Flujo de una tarea con verificación en L3

```
programador → PR task/<ID>/<TASK>
CI: todo verde salvo «PASS del verificador aprobado»   ← esperado, no es ciclo FAIL
orquestador → verifier → PASS
tú: lees el informe → pones aes:verified
CI se relanza (evento labeled) → verde → integras
un commit nuevo en la rama → la CI quita aes:verified (y las otras aprobaciones) → hay que volver a verificar
```

## Comandos de verificación

Para criterios que no se comprueban con una prueba de aceptación (configuración, herramientas, scripts): `specs/<ID>/<ID>.verify` o, en un lote, `specs/<ID>/BUG-NNN.verify`. Es un script bash que termina con 0 si el criterio se cumple. Lo escribe QA y lo apruebas tú, como una prueba.

```bash
# specs/CH-002/CH-002.verify — ejemplo
set -euo pipefail
grep -q '<clear />' nuget.config
dotnet restore --configfile nuget.config --no-cache >/dev/null
```

Si es imposible que falle antes del cambio, su primera línea es `# aes: no-red <motivo>` y tu aprobación debe ser explícita.

## Probar en local

```bash
BASE_REF=origin/main TASK_SCOPE_FILE=specs/US-005/TASK-014.scope bash ci/aes-guard.sh
BASE=origin/main bash ci/defect-gate.sh start US-006
EVENT=pull_request HEAD_BRANCH=task/US-005/TASK-014 BASE=origin/main bash ci/aes-ctx.sh
bash ci/run-verify.sh green origin/main specs/CH-002/CH-002.verify
```

## Windows

- Los hooks son bash: instala Git for Windows. Claude Code los ejecuta con Git Bash, y `lib.sh` normaliza rutas `H:\...`.
- Usa `.gitattributes` con `*.sh text eol=lf`; con CRLF los scripts fallan.
- El aislamiento de la terminal de Claude Code (*sandbox*) **solo existe en WSL 2**. En Windows nativo, nada impide que un agente escriba fuera del repo (FL-002 del sandbox). Si el disco tiene algo sensible, trabaja en WSL 2 con el sandbox activo, o decláralo como excepción en el perfil (AES 06 §9).

## Límites conocidos

- Las capas L1 y L2 son fricción, no garantía: la terminal puede escribir lo que el hook de edición bloquea. La garantía es la CI (L3).
- El clasificador de permisos del modo automático de Claude Code actúa como una capa L1 adicional, no configurada por el proyecto. En el sandbox denegó acciones demasiado amplias (detener todos los procesos `dotnet`/`node`).
- Las pruebas holdout no están implementadas en esta referencia; la implementación `claude-code-opencode` muestra cómo ejecutarlas desde un repositorio privado.
