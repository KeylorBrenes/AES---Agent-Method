# Implementación de referencia — Claude Code con subagentes

Implementación de AES 1.4.0 con **Claude Code** como harness del orquestador: la sesión principal es el orquestador (en el modelo más capaz disponible, porque también decide el diseño de cada tarea) y los roles `qa`, `programmer`, `mechanic` y `verifier` son subagentes con su propio contexto, modelo y permisos, o, según el binding, corren en **OpenCode** con otro proveedor (sección «Roles en OpenCode»). GitHub aloja el repositorio, la CI y la protección de rama.

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
| `.claude/scripts/aes-board.mjs` | — | Vistas del backlog desde `docs/backlog.md`: tablero HTML autocontenido (`.aes/board.html`) o JSON para un adaptador (GitHub Projects, Trello, GitLab) | Simulación |
| `.claude/scripts/aes-outline.sh` | — | Resumen estructural (archivos y firmas públicas, sin implementaciones) para que el orquestador decida el diseño con hechos | Simulación |
| `.claude/scripts/aes-wt.sh` | — | Checkouts propios por rol (worktrees): `open`, `close`, `run`, `delegate`. El checkout principal se queda en `dev` | Simulación |
| `.claude/hooks/worktree-create.sh`, `worktree-remove.sh` | L2 | El subagente con `isolation: worktree` trabaja en la rama de trabajo real (la que indicó el orquestador con `delegate`); sin indicación, no arranca | Simulación (falta confirmar en Claude Code el formato del evento) |
| `.claude/scripts/aes-note.sh` | — | Notas del orquestador con la hora real; `clear` las vacía tras el cierre | Probado (`clear`: simulación) |
| `.claude/scripts/gh-app-token.sh`, `git-credential-aes-app.sh`, `agent-gh.sh` | L3 | Identidad de los agentes: GitHub App sin permiso de workflows | Probado |
| `.claude/skills/aes-cycle/SKILL.md` | — | Procedimiento del orquestador, con plantillas de delegación | Probado (caminos T1 y lote: simulación) |
| `.claude/skills/aes-{inception,debugging,security-review,design-note}/` | — | Skills del núcleo de AES, copiadas de `skills/` en la raíz del repo de AES (no se editan aquí) | Pendiente de uso real |
| `.claude/aes.env` | — | Puertos y comandos de servidores del proyecto | — |
| `ci/aes-guard.sh` | L3 | Guardián: rutas protegidas, superficie, dependencias, pruebas borradas, marcadores | Probado |
| `ci/red-check.mjs` | L3 | RED confirmado (todas ejecutadas y fallando) y trazabilidad criterio → prueba | RED probado; trazabilidad: simulación |
| `ci/aes-ctx.sh` | L3 | Qué ejecuta la CI según la rama y el destino: rutas válidas a `dev` y `main`, criterios de la tarea, regresión, comandos de verificación, release y back-merge | Por criterio: probado; lo demás: simulación |
| `ci/defect-gate.sh` | L3 | Compuerta de estabilización: lee la severidad de los defectos del backlog de la rama destino; fase `release` para liberar | Simulación |
| `ci/run-verify.sh` | L3 | Comandos de verificación: RED en la especificación, verde en tareas, cierre y regresión | Simulación |
| `ci/label-approver.sh` | L3 | Quién puso cada etiqueta de aprobación (no la identidad de los agentes) | Simulación |
| Paso SAST del workflow | L3 | Semgrep con reglas OWASP sobre lo nuevo de cada tarea: `ERROR` falla la tarea; el resto se registra como defectos | `--baseline-commit` (solo hallazgos nuevos) y `--error` por severidad: probados con Semgrep 1.184 en local; el workflow, en simulación |
| `ci/validate.sh` | — | Validaciones del stack (ejemplo .NET + React) | Probado |
| `.github/workflows/aes.yml` | L3 | Un único check `aes` en `dev` y `main` con todo lo anterior, más «main contenido en dev»; scripts siempre desde la rama destino | Versión de 1.1 probada; esta, en simulación |
| `.github/CODEOWNERS` | L3 | Tu aprobación para rutas protegidas | Probado |
| `CLAUDE.md` | — | Ejemplo de instrucciones persistentes breves | — |
| `opencode.json`, `.opencode/plugin/aes-guard.js`, `.claude/scripts/aes-oc.sh` | L1, L2 | Roles en OpenCode (binding en `.claude/aes.env`): agentes con el mismo contrato, permisos, plugin que ejecuta los mismos hooks, delegación con compuerta y registro de costo | Simulación con modelo falso |

## Puesta en marcha

Hay dos partes: lo que se hace **una vez por cuenta de GitHub** (a mano, unos minutos) y lo que se hace **en cada proyecto** (un comando).

### Una vez por cuenta

#### 1. Herramientas

| Herramienta | Para qué |
|---|---|
| git | Todo |
| bash, openssl, curl | Hooks y scripts de AES; el token de la app. En Windows vienen con Git for Windows (Git Bash) |
| [gh](https://cli.github.com) | `setup-repo.sh` y los PR de los agentes |
| jq | Hooks de AES y `setup-repo.sh` |
| Node.js LTS | Tablero (`aes-board.mjs`), archify y las pruebas de aceptación |

**Windows** (PowerShell; después, cierra y abre Git Bash para que tome el PATH nuevo):

```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id jqlang.jq -e
winget install --id OpenJS.NodeJS.LTS -e
```

Usa siempre **Git Bash** para los scripts de AES: Claude Code ejecuta los hooks con él.

**Linux:**

```bash
# Fedora
sudo dnf install git gh jq nodejs openssl curl
# Debian / Ubuntu (gh, desde el repositorio oficial: https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
sudo apt install git jq nodejs npm openssl curl
```

**Comprueba:** `git --version && gh --version && jq --version && node --version && openssl version`

**Sesión de gh** con los permisos que necesita `setup-repo.sh`:

```bash
gh auth login                 # GitHub.com → HTTPS → iniciar sesión en el navegador
gh auth refresh -s workflow   # permiso para subir el workflow de la CI
gh auth status                # en «Token scopes» deben aparecer repo y workflow
```

#### 2. GitHub App de los agentes

Los agentes publican ramas y abren PR con la identidad de una GitHub App, no con la tuya. La app **no tiene permiso de *Workflows***: así ningún agente puede editar la CI para saltarse el guardián, y sus PR aparecen como `<slug>[bot]`, que tú apruebas. Se crea una vez y sirve para todos tus proyectos.

1. En GitHub: tu foto → ***Settings → Developer settings → GitHub Apps → New GitHub App***.
2. **Nombre:** uno único en GitHub, por ejemplo `aes-agent-<tu-usuario>`. El *slug* (el nombre en minúsculas y con guiones) aparece en la URL de la app, `github.com/apps/<slug>`.
3. **Homepage URL:** cualquiera, por ejemplo la URL de tu perfil.
4. **Webhook:** desmarca *Active*. AES no lo usa.
5. **Permissions → Repository permissions:**
   - *Contents*: **Read and write**;
   - *Pull requests*: **Read and write**;
   - *Metadata*: Read-only (GitHub lo marca solo);
   - **nada más**. En particular, *Workflows* se queda en *No access*. Sin permisos de cuenta ni de organización.
6. **Where can this GitHub App be installed?** *Only on this account*. Pulsa ***Create GitHub App***.
7. En la página *General* de la app, anota el **App ID**.
8. **Llave privada:** ***Credentials → Key pairs → New key*** (en la interfaz anterior, *Private keys → Generate a private key*). Se descarga un `.pem`. Muévelo fuera de cualquier repositorio:
   - Windows: `C:/Users/<tú>/.aes/aes-agent.pem`;
   - Linux: `~/.aes/aes-agent.pem`, con `chmod 600`.

   Nunca la subas a git ni la pegues en un chat. Si se filtra, revócala en esa misma pantalla y genera otra.
9. **Instala la app:** menú lateral ***Install App*** → tu cuenta → ***Only select repositories***. Elige uno cualquiera (por ejemplo, el sandbox); `setup-repo.sh` añade cada proyecto nuevo. El **Installation ID** es el número al final de la URL de la instalación: `github.com/settings/installations/<id>`.
10. **`~/.aes/app.env`:** cópialo de `scripts/aes-app.env.example` del repo de AES y rellena `AES_APP_ID`, `AES_APP_INSTALLATION_ID`, `AES_APP_PRIVATE_KEY` (ruta con `/`) y `AES_BOT_SLUG`. El ID del usuario bot lo consulta el script (`gh api "users/<slug>%5Bbot%5D" --jq .id`).

No uses una cuenta bot ni un token personal *fine-grained*: las cuentas nuevas pueden quedar suspendidas por el antiabuso de GitHub, y los tokens *fine-grained* no acceden a repos de otra cuenta personal.

#### 3. Skills de terceros (opcional)

Clónalas en una versión fija, por ejemplo en `~/.aes/skills/`, y añade sus carpetas a `AES_VENDOR` en `app.env`:

```bash
mkdir -p ~/.aes/skills && cd ~/.aes/skills
git clone https://github.com/tt-a1i/archify.git && git -C archify checkout <tag>
git clone https://github.com/pbakaus/impeccable.git && git -C impeccable checkout <tag>
# en app.env:
# AES_VENDOR="~/.aes/skills/archify;~/.aes/skills/impeccable/.claude/skills/impeccable"
```

Para actualizarlas, cambias de versión ahí y ejecutas `install-aes.sh <proyecto> --upgrade --vendor <carpeta>` en cada proyecto.

### Cada proyecto nuevo

Lo más simple es `aes-new` (README principal de AES, «Empezar un proyecto nuevo»): pregunta en la terminal y llama a `setup-repo.sh` de la versión que elijas. Sin preguntas, desde una copia de AES en la versión (tag) que quieres usar:

```bash
./scripts/setup-repo.sh <tu-usuario>/<repo> --create private   # o public; sin --create si ya existe
# con roles en OpenCode: --opencode opencode/deepseek-v4.1-flash-free (o AES_OPENCODE_MODEL en app.env)
```

Al terminar, abre Claude Code en la carpeta del proyecto con el modelo más capaz (`/model opus`) y pide empezar el proyecto: el orquestador usa la skill `aes-inception` (entrevista, backlog con releases, arquitectura, ADR del stack, dirección visual y EN-001, en un PR a `dev` que apruebas tú). Después, EN-001 con `aes-cycle`.

- `--dry-run` muestra lo que haría sin cambiar nada.
- Se puede repetir: cada paso comprueba antes y se salta si ya está hecho. Si algo falló a medias (por ejemplo, la app sin acceso), lo arreglas y lo vuelves a ejecutar.
- En repos **privados**, los rulesets necesitan GitHub Pro o Team. Con GitHub Free, usa un repo público.
- Las semillas que dependen del stack (`.claude/aes.env`, `ci/validate.sh`, la sección `STACK` del workflow) se adaptan en EN-001.

### Qué hace el script, paso a paso

Es también el manual para hacerlo a mano.

1. **Comprueba** git, gh (con `repo` y `workflow`), jq y `~/.aes/app.env`.
2. **Crea y clona** el repositorio.
3. **Instala AES** con `./scripts/install-aes.sh <carpeta> --vendor <skill>…`. Copia estos archivos, las skills del núcleo, la DoR/DoD, `AES-CORE.md` y las plantillas en `docs/aes/`, crea `specs/active-stories.txt` y añade a `.gitignore` `.aes/`, `.claude/settings.local.json` y `.claude/worktrees/`.
   - Los **archivos de AES** (hooks, scripts, skills del núcleo, scripts de la CI, `docs/aes/`) no se editan en el proyecto: `--upgrade` los sobrescribe y `--check` comprueba que coinciden con la versión.
   - Los **archivos semilla** (subagentes, `settings.json`, `aes.env`, el workflow, `CODEOWNERS`, `ci/validate.sh`, `CLAUDE.md`) son del proyecto. Al actualizar, si AES cambió una semilla, la nueva queda al lado como `<archivo>.aes-new` para que la compares.
4. **Rellena** `CODEOWNERS` con tu usuario y crea `.claude/settings.local.json` (credenciales de la app y autoría de los commits como `<slug>[bot]`; no va a git). Comprobación manual del token: `bash .claude/scripts/gh-app-token.sh | cut -c1-4` debe imprimir `ghs_`.
5. **Commit inicial en `main`** con lo instalado (solo si `main` todavía no existe en GitHub) y **crea `dev`** desde `main` (`git push origin main:dev`). El workflow entra en ese commit: la app no puede tocar `.github/workflows/`, así que cualquier cambio posterior en él lo subes tú.
6. **Ajustes del repositorio:** `dev` como rama por defecto (los PR apuntan a `dev` sin pensarlo), *merge commit* y *squash* permitidos, *rebase* no, y borrado de las ramas integradas.
7. **Tres rulesets.** GitHub exige cumplir todos los que aplican, y el bypass de uno no salta otro:
   - **`ramas-ci`** (`main` y `dev`), **sin bypass para nadie:** *Restrict deletions*, *Block force pushes*, *Require status checks to pass* (`aes`) con *Require branches to be up to date*.
   - **`aprobacion-dev`** y **`aprobacion-main`:** *Require a pull request before merging* con 1 aprobación, *Require review from Code Owners* y *Dismiss stale approvals*. Bypass: *Repository admin* en modo **For pull requests only**, para que puedas integrar tus propios PR. Métodos permitidos: en `main`, solo *merge commit* (releases y hotfixes); en `dev`, *squash* (ramas de trabajo) y *merge commit* (back-merges). Si tu plan no permite limitar los métodos, el script lo avisa: elige bien en cada PR, porque un back-merge integrado con *squash* rompe la comprobación «main contenido en dev» del siguiente release.

   Un único ruleset con bypass permite integrar con la CI en rojo: el bypass salta todas sus reglas. Pasó en el sandbox (FL-003).
8. **Etiquetas** `aes:deps-approved`, `aes:markers-approved` y `aes:verified` (solo tú las pones) y la **variable** `AES_APPROVERS`. Las demás variables son opcionales (*Settings → Secrets and variables → Actions → Variables*):
   - `AES_APPROVERS`: los logins autorizados, separados por coma. La CI acepta una etiqueta solo si la última vez la puso una de estas personas, nunca un `[bot]`.
   - `AES_MINOR_LIMIT` (por defecto 5): defectos Menores abiertos permitidos.
   - `AES_REQUIRE_VERIFIED` (por defecto `1`): exige `aes:verified` en las tareas.
   - `AES_SAST` (`0` lo desactiva) y `AES_SAST_CONFIG` (por defecto `p/owasp-top-ten`): el paso de SAST.
   - `AES_UI_DETECT`: el detector de interfaz, si impeccable está instalada. Por defecto solo anota en el PR; `block` hace que los hallazgos fallen la tarea; `0` lo desactiva.
9. **Acceso de la app** al repositorio (`PUT /user/installations/<id>/repositories/<repo>`; a mano: *Settings → Applications → tu app → Configure → Repository access*) y comprobación de su token.

## Convención de ramas

Las ramas de trabajo nacen de `dev` y van a `dev`. Las de un hotfix (`BUG-NNN`) nacen de `main` y van a `main`. La CI rechaza cualquier otra ruta hacia `main`.

| Rama | Quién | Qué ejecuta la CI |
|---|---|---|
| `spec/<ID>` | orquestador | build/test, RED de los comandos de verificación nuevos, regresión |
| `qa/<ID>` | orquestador + QA | compuerta (inicio), build/test, RED y trazabilidad de las pruebas de `<ID>`, RED de los comandos nuevos |
| `task/<ID>/<TASK>` | programador o mecánico | compuerta (solo Crítica), guardián, build/test, criterios de la tarea (`<TASK>.criteria`; sin él, el elemento completo), comandos de verificación, regresión, `aes:verified` |
| `spec/<ID>-close` | orquestador + mecánico | build/test, el elemento completo (debe ejecutarse y pasar), regresión |
| `dev` → `main` (release) | orquestador abre, tú integras con merge commit | compuerta (sin exenciones), «main contenido en dev», regresión completa |
| `main` → `dev` (back-merge) | orquestador abre, tú integras con merge commit | regresión completa |
| push a `dev` o `main` | — | build/test, regresión, informe de la compuerta; en `dev`, aviso si falta un back-merge |

`<ID>` es el elemento del backlog: `US-`, `EN-` (pasan por la compuerta), `BUG-`, `CH-`, `ST-`, `SP-` (no pasan: corrigen o mantienen).

## Checkouts por rol (worktrees)

El checkout principal se queda en `dev`. Cada rol trabaja en su propio worktree de la rama de trabajo, en `.claude/worktrees/`:

```
orquestador: git branch --no-track task/US-005/TASK-014 origin/dev
             bash .claude/scripts/aes-wt.sh delegate task/US-005/TASK-014
             → llama al subagente programmer (isolation: worktree)
hook WorktreeCreate: abre .claude/worktrees/task-US-005-TASK-014 en esa rama
                     y copia .claude/settings.local.json (la identidad de la app)
programmer: trabaja y hace commit en su worktree
hook WorktreeRemove: cierra el worktree si está limpio; los commits quedan en la rama
orquestador: publica la rama; para el verificador, otro delegate → worktree limpio
```

- Una rama solo puede estar en un worktree a la vez (regla de git): el orquestador cierra el suyo (`aes-wt.sh close`) antes de delegar en la misma rama.
- Los roles se ejecutan de uno en uno. En paralelo, dos worktrees arrancarían servidores en los mismos puertos.
- Cada worktree necesita sus dependencias (`npm ci`, `dotnet restore`): la primera ejecución de cada rol es más lenta.
- Si quieres más archivos locales en cada worktree (por ejemplo, un `.env`), añádelos a `AES_WT_LOCAL_FILES` en `aes-wt.sh`.

## Roles en OpenCode (binding, AES 06 §12)

El orquestador se queda en Claude Code; QA, el programador y el mecánico pueden correr en [OpenCode](https://opencode.ai) con otro proveedor (por ejemplo, DeepSeek). El verificador se queda en Claude: revisa mejor un modelo de otra familia. Todo es opcional: con el binding en `claude` (el valor por defecto), nada de esto se usa.

### Puesta en marcha

1. **OpenCode** 1.18.30 o posterior (`opencode --version`). No pide cuenta.
2. **Proveedor.** Una de estas:
   - **DeepSeek de pago:** crea una clave en platform.deepseek.com y recarga saldo (PayPal o tarjeta; es prepago, así que el saldo es tu tope). En OpenCode, `/connect` → `deepseek` → pega la clave, o define `DEEPSEEK_API_KEY` en el entorno. Modelo: `deepseek/deepseek-flash`.
   - **Gratis por tiempo limitado:** OpenCode ofrece algunos modelos sin costo, sin cuenta. `opencode/deepseek-v4.1-flash-free` declara cero retención y sin entrenamiento; otros gratuitos (Big Pickle, MiMo, Nemotron…) sí guardan o entrenan con tus datos: no los uses con código que no quieras compartir. Revisa las condiciones en opencode.ai/docs/zen antes de elegir.
3. **Binding** en `.claude/aes.env`, por rol:
   ```bash
   AES_BIND_QA="opencode:deepseek/deepseek-flash"
   AES_BIND_PROGRAMMER="opencode:deepseek/deepseek-flash"
   AES_BIND_MECHANIC="opencode:deepseek/deepseek-flash"
   AES_BIND_VERIFIER="claude"
   ```
   Y el precio de lista para estimar el costo (`AES_OC_LIST_PRICE`, `AES_OC_PEAK_UTC`): ya viene con los de `deepseek-flash`.
4. **Prueba:** `opencode run -m deepseek/deepseek-flash "Responde OK"`. El orquestador hace la misma comprobación al arrancar cada sesión.

### Cómo delega el orquestador

`bash .claude/scripts/aes-oc.sh run <rol> <rama> -- "<plantilla con sus datos>"`, en segundo plano. El script:

1. abre el worktree de la rama y lo marca como activo;
2. ejecuta `opencode run --agent <rol> -m <modelo>` ahí, **sin** las credenciales de la GitHub App ni de `gh` en el entorno;
3. aplica la compuerta de fin de rol (`subagent-gate.sh`: servidores, guardián, `ci/validate.sh`, cambios sin commit); si falla, reanuda la sesión **una** vez con el motivo, como un hook `SubagentStop`;
4. guarda los eventos y la sesión en `.aes/runs/<rama>/` y una fila en `.aes/costs.csv`;
5. imprime el estado, los commits, los archivos, el costo y el reporte del rol; cierra el worktree si quedó limpio.

`bash .claude/scripts/aes-oc.sh report [<ID>]` resume tokens y costo por elemento y rol.

### Controles

| Capa | Claude Code (subagente) | OpenCode |
|---|---|---|
| Contrato | `.claude/agents/<rol>.md` | El mismo archivo, cargado con `{file:…}` en `opencode.json` |
| L1 | `permissions` de `settings.json` | `permission` por agente en `opencode.json`: rutas protegidas, `git push`/`gh`, red, preguntas y subagentes en `deny`; skills solo las del rol. En `opencode run`, lo que quedaría en *ask* se rechaza solo |
| L2 | Hooks `role-guard.sh`, `bash-guard.sh` | `.opencode/plugin/aes-guard.js`, que ejecuta **los mismos** hooks (`AES_ROLE` lo pone el script) y quita credenciales del entorno de la terminal |
| Fin de rol | Hook `SubagentStop` | `aes-oc.sh` ejecuta `subagent-gate.sh` y reanuda una vez |
| L3 | CI | La misma CI |
| Fuera del repo | Sin sandbox en Windows nativo (FL-002) | OpenCode rechaza por defecto leer o escribir fuera del proyecto (`external_directory`) |

Comprobado con un modelo simulado (un servidor compatible con la API de OpenAI que pide herramientas programadas): escritura en `tests/acceptance/`, redirección de la terminal a una ruta protegida, escritura fuera de la superficie y `git push` quedan bloqueados con el mensaje del hook, y el modelo lo recibe y sigue; la compuerta reanuda la sesión y el arreglo pasa; el costo coincide con el precio de lista y se duplica en horario caro.

### Límites conocidos

- **Costo estimado, no facturado.** OpenCode conoce solo el precio barato de DeepSeek; el script aplica el recargo por horario (`AES_OC_PEAK_UTC`). La cifra que manda es la de la página *Billing* del proveedor.
- **Primera ejecución en cada worktree:** OpenCode instala la dependencia de plugins en `.opencode/` (la ignora él solo en git). Tarda más la primera vez.
- **Windows:** el plugin ejecuta `bash`; si OpenCode no lo encuentra en el PATH, define `AES_BASH` con la ruta de Git Bash (`C:/Program Files/Git/bin/bash.exe`).
- **Skills personales:** OpenCode también ve las skills de tu usuario (`~/.claude/skills/`); `opencode.json` las niega todas salvo las del rol.
- **Paralelo:** como con los subagentes, un rol a la vez hasta que el perfil resuelva puertos y datos por checkout (06 §10).

## Grafo de código con Graphify (opcional, en piloto)

[Graphify](https://github.com/Graphify-Labs/graphify) construye un grafo del código con tree-sitter, en local y sin modelo, y puede servirle al orquestador como hecho adicional para la nota de diseño (AES 10 §5). Se usa como **herramienta** (06 §6.2), desde la terminal:

```bash
uv tool install graphifyy           # o pipx install graphifyy
graphify update .                   # primer grafo, local y sin modelo
graphify hook install               # lo reconstruye en segundo plano tras cada commit y checkout;
                                    # instalado en el checkout principal, cubre también los worktrees
```

- Añade `graphify-out/` a `.gitignore`.
- **No uses `graphify watch`:** deja un proceso vivo entre roles (06 §10). El hook de git basta.
- Para la nota de diseño solo cuentan como hechos las relaciones que Graphify marca como extraídas del código, no las inferidas.
- No instales su integración con el asistente (`graphify install`) sin probarla antes: añade su propio hook de lectura a Claude Code, que tiene que convivir con los de AES. Es lo que queda por comprobar en el sandbox.
- Regístralo en el perfil como cualquier skill o herramienta de terceros.

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
BASE_REF=origin/dev TASK_SCOPE_FILE=specs/US-005/TASK-014.scope bash ci/aes-guard.sh
BASE=origin/dev bash ci/defect-gate.sh start US-006
EVENT=pull_request HEAD_BRANCH=task/US-005/TASK-014 TARGET=dev BASE=origin/dev bash ci/aes-ctx.sh
bash ci/run-verify.sh green origin/dev specs/CH-002/CH-002.verify
git merge-base --is-ancestor origin/main origin/dev && echo "main contenido en dev"
```

## Windows

- Los hooks son bash: instala Git for Windows. Claude Code los ejecuta con Git Bash, y `lib.sh` normaliza rutas `H:\...`.
- Usa `.gitattributes` con `*.sh text eol=lf`; con CRLF los scripts fallan.
- El aislamiento de la terminal de Claude Code (*sandbox*) **solo existe en WSL 2**. En Windows nativo, nada impide que un agente escriba fuera del repo (FL-002 del sandbox). Si el disco tiene algo sensible, trabaja en WSL 2 con el sandbox activo, o decláralo como excepción en el perfil (AES 06 §9).

## Límites conocidos

- Las capas L1 y L2 son fricción, no garantía: la terminal puede escribir lo que el hook de edición bloquea. La garantía es la CI (L3).
- El clasificador de permisos del modo automático de Claude Code actúa como una capa L1 adicional, no configurada por el proyecto. En el sandbox denegó acciones demasiado amplias (detener todos los procesos `dotnet`/`node`).
- Las pruebas holdout no están implementadas en esta referencia; la implementación `claude-code-opencode` muestra cómo ejecutarlas desde un repositorio privado.
