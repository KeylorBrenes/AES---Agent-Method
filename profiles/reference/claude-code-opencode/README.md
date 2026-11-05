# Implementación de referencia — Claude Code + OpenCode

> **AES 1.2.0:** esta referencia cubre los controles de 1.1. La CI con las novedades de 1.2.0 (CI por criterio, comandos de verificación, compuerta de estabilización, aprobaciones validadas, verificación antes de integrar), los scripts y la skill del orquestador están en [`../claude-code-subagents/`](../claude-code-subagents/), y su CI no depende del harness. De aquí se mantiene lo propio de OpenCode y el ejemplo de pruebas holdout. Integrar ambas espera a un experimento con OpenCode como programador (RFC-002, cambio 4).

Implementación concreta de las tres capas de control de AES 1.1.0 (`standard/06` §9) para un proyecto donde:

- **Claude Code** actúa como orquestador (y puede alojar a QA y al verificador como sesiones separadas);
- **OpenCode** ejecuta los roles de programador y, opcionalmente, verificador;
- **GitHub** aloja el repositorio, la CI y la protección de rama.

Es un punto de partida, no un perfil prescriptivo. Los comandos usan `npm`; sustitúyelos por los de tu stack.

> Verificado contra la documentación pública a noviembre de 2026. OpenCode v2 cambió la sintaxis de permisos (`permissions` como lista de reglas `action`/`resource`/`effect`). Comprueba la versión que tengas instalada antes de copiar `opencode.json`.

## Contenido

| Archivo | Capa | Función |
|---|---|---|
| `opencode.json` | L1 | Agentes `programmer` y `verifier`: rutas protegidas no editables, comandos permitidos, verificador sin edición. |
| `.claude/settings.json` | L1 + L2 | Reglas `deny` de edición y registro de hooks. |
| `.claude/hooks/protect-paths.sh` | L2 | `PreToolUse`: bloquea (código 2) escrituras a rutas protegidas. |
| `.claude/hooks/require-green.sh` | L2 | `Stop`: impide terminar con pruebas rojas, una sola vez (`stop_hook_active`). |
| `ci/aes-guard.sh` | L3 | Guardián: rutas protegidas, superficie de cambio, dependencias, pruebas borradas, marcadores de trampa. |
| `.github/workflows/aes.yml` | L3 | Ejecuta el guardián **desde la base**, restaura la suite de aceptación desde la base y corre la suite holdout desde un repo privado. |
| `.github/CODEOWNERS` | L3 | Exige tu aprobación para cambios a rutas protegidas. |
| `AGENTS.md` | — | Ejemplo de instrucciones persistentes breves y estructurales. |

## Por qué L1 y L2 no bastan

El permiso `edit` de OpenCode cubre las herramientas de edición, escritura y parche, pero una terminal permisiva puede escribir el mismo archivo con `sed` o `cat >`. Los hooks de Claude Code solo ven las herramientas que interceptan. Ambos son **fricción útil**: evitan la mayoría de los desvíos y devuelven un mensaje claro al agente. La garantía la da L3: aunque el agente modifique `tests/acceptance/` en su rama, la CI ejecuta la versión de `main` y el guardián marca el cambio.

## Puesta en marcha

1. Copia estos archivos a la raíz de tu proyecto (respetando las rutas).
2. Sustituye `@tu-usuario` en `CODEOWNERS` y los comandos `npm` por los de tu stack.
3. En GitHub, protege `main` con **dos rulesets separados**. GitHub exige cumplir todos los rulesets que aplican, y el bypass de uno no salta el otro:
   - **`main-ci`, sin bypass para nadie:** *Restrict deletions*, *Block force pushes*, *Require status checks to pass* (`guard-and-tests`) con *Require branches to be up to date*.
   - **`main-aprobacion`:** *Require a pull request before merging* con 1 aprobación, *Require review from Code Owners* y *Dismiss stale approvals*. Bypass: *Repository admin* en modo **For pull requests only**, para que puedas fusionar tus propios PR (nadie puede aprobar su propio PR).

   No pongas todo en un solo ruleset con bypass: el bypass salta **todas** sus reglas, incluido el check obligatorio, y permite fusionar con la CI en rojo. Así ocurrió en el sandbox de AES (FL-003).

   Con *Require review from Code Owners*, los PR de los agentes deben tener un autor distinto de ti; ver el punto 8.
4. Crea las etiquetas `aes:markers-approved` y `aes:deps-approved`. Solo tú las aplicas, tras revisar la justificación. El workflow reacciona a `labeled`/`unlabeled`, así que poner o quitar una etiqueta relanza la CI. Limitación conocida: el workflow comprueba que la etiqueta exista, no **quién** la puso. Mientras eso no se valide, revisa el historial del PR.
5. Pruebas holdout (obligatorias en T3):
   - crea un repositorio privado aparte para ellas;
   - define la variable de repositorio `AES_HOLDOUT_REPO` (`owner/repo`) y el secreto `AES_HOLDOUT_TOKEN` (token de solo lectura a ese repo);
   - el entorno del programador **no** recibe ese token.
6. Convención de ramas:
   - `task/US-005/TASK-014` para el programador. El workflow deriva de ella la superficie `specs/US-005/TASK-014.scope`, que el orquestador publica en `main` antes de delegar, y aplica el guardián.
   - `qa/US-005` para la suite de aceptación y `spec/US-005` para historias y superficies. Estas ramas tocan rutas protegidas por diseño, así que no pasan por el guardián: las controla CODEOWNERS y requieren tu aprobación.
   - Si el programador abre un PR con otro nombre de rama, el guardián no se ejecuta, pero CODEOWNERS sigue bloqueando cualquier cambio a rutas protegidas. Para cerrar ese hueco, añade una regla de protección que solo permita fusionar ramas `task/*`, `qa/*` y `spec/*`.
7. Instala `jq` donde corran los hooks.
8. **Identidad de los agentes sin permiso de workflows.** En un evento `pull_request`, GitHub ejecuta el workflow tal como está *en la rama del PR*. Si el agente pudiera editar `.github/workflows/aes.yml` en su rama, podría borrar el paso del guardián y el check saldría verde. Por eso los agentes publican con una **GitHub App** propia que tiene permisos de *Contents* y *Pull requests* y **sin** permiso de *Workflows*: GitHub rechaza el push si toca `.github/workflows/`.
   - Crea la app en *Settings → Developer settings → GitHub Apps*, instálala solo en el repo y genera la llave en ***Credentials → Key pairs → New key*** (GitHub movió esta opción; antes estaba en *Private keys* de la página General).
   - Sus PR aparecen como `<app>[bot]`, así que puedes aprobarlos como Code Owner.
   - Los tokens duran 1 hora y se generan al momento con la llave.
   - Implementación probada (script del token, *credential helper* de git y `gh` con la identidad de la app): `docs/agent-identity.md` y `.claude/scripts/` en [aes-sandbox-gastos](https://github.com/KeylorBrenes/aes-sandbox-gastos).
   - No uses una cuenta bot ni un token personal *fine-grained*: las cuentas nuevas pueden quedar suspendidas por el antiabuso de GitHub, y los tokens *fine-grained* no acceden a repos de otra cuenta personal aunque seas colaborador.
9. **Windows.** Los hooks son bash: instala Git for Windows. Claude Code los ejecuta con Git Bash, y los scripts normalizan rutas `H:\...`. Usa un `.gitattributes` con `*.sh text eol=lf`; con CRLF los scripts fallan. El *sandbox* de la terminal de Claude Code, que impide escribir fuera del directorio de trabajo, **no está disponible en Windows nativo, solo en WSL 2**. Sin él, nada impide que un agente escriba fuera del repo; en el sandbox de AES pasó (FL-002). Para proyectos con algo sensible en el disco, trabaja en WSL 2 con el sandbox activo.

## Flujo con estas piezas

```
Orquestador (Claude Code)
  ├─ publica en main: specs/US-005/US-005.md, TASK-014.md, TASK-014.scope
  ├─ QA (sesión separada): tests/acceptance/US-005.* + holdout en repo privado
  │     └─ RED confirmado contra main → PR → tú apruebas (CODEOWNERS)
  ├─ Programador (OpenCode, agente programmer, worktree task/US-005/TASK-014)
  │     └─ baseline → RED/GREEN/REFACTOR → commits struct:/feat: → PR
  ├─ CI: guardián (desde main) + aceptación (desde main) + holdout
  ├─ Verificador (OpenCode agente verifier o Claude Code en sesión nueva)
  │     └─ re-ejecuta, prueba manual agéntica, informe PASS/FAIL/BLOCKED
  └─ Tú: informe + evidencias (+ código en T3) → Accepted / Rejected
```

Invocación típica del programador desde el orquestador (ajusta la sintaxis a tu versión de OpenCode):

```bash
git worktree add ../wt-TASK-014 -b task/US-005/TASK-014 main
cd ../wt-TASK-014
opencode run --agent programmer "$(cat specs/US-005/TASK-014.md)"
```

El orquestador entrega al verificador el diff (`git diff main...task/US-005/TASK-014`), la historia, el contrato de interfaz, la salida de la CI y el guardián. **No** le entrega el reporte narrativo del programador como fuente de verdad.

## Probar el guardián localmente

```bash
BASE_REF=main TASK_SCOPE_FILE=specs/US-005/TASK-014.scope bash ci/aes-guard.sh
```

Escenarios cubiertos (probados al publicar esta versión): cambio dentro de la superficie (OK), archivo fuera de la superficie, modificación de la suite de aceptación, `it.skip`/`eslint-disable`/`catch` vacío, cambios en `package.json`, prueba eliminada, superficie inexistente en la base.
