# Changelog

## [1.4.1] — 2026-11-25

Correcciones de la primera prueba real de 1.4.0 (EN-001 de aes-todo: Rust + React en Windows, roles en OpenCode con DeepSeek). Cambio PATCH: corrige la delegación a OpenCode y ajusta reglas que, aplicadas al pie de la letra, hacían gastar ciclos FAIL en detalles. En EN-001, la mayoría de los ciclos y del costo del orquestador vino de esto, no del modelo de los roles: el verificador dio PASS en todas sus corridas, y los ciclos salieron de hallazgos Menores y de huecos de la nota de diseño.

### Corregido
- **`aes-oc.sh`** (FL-001, FL-002, FL-004, FL-005 de aes-todo):
  - sin `--dir` (OpenCode 2.2 ya no lo acepta; el script ya hace `cd` al worktree), y antes de ejecutar comprueba que `opencode run` acepta `--agent`, `--model`, `--format`, `--session` y `--title`;
  - solo analiza las líneas JSON de la salida de OpenCode y ya no corta la salida de jq con `head` (en Windows, `jq | head` fallaba con «writing output failed» y, con `pipefail`, el script salía con 2 sin compuerta ni costo);
  - un evento de error del proveedor (p. ej. 429 del plan gratuito) sale con 4 y lo explica; cualquier fallo del script **después** de que el rol terminó sale con el nuevo código **5** («compuerta pendiente») e imprime el comando para ejecutarla a mano;
  - la fila de `.aes/costs.csv` se registra siempre, también si OpenCode falla (estado `opencode-error`) o si el script falla después (`script-error`);
  - no arranca si hay servidores en `AES_PORTS` (código **6**: la compuerta de fin de rol fallaría, como pasó con los de la demo en el cierre);
  - copia `.aes/*-pending.md` al `.aes/` del worktree: OpenCode no deja leer fuera de él y el mecánico no podía consolidar las notas en el cierre (M1).
- `aes-wt.sh close` borra la carpeta vacía que dejaba en Windows.
- `aes-new`: las rutas que se pegan (llave `.pem`, carpeta del proyecto) se aceptan tal como las copia Windows, con comillas y barras invertidas, y se guardan como `C:/…`. Antes, «Copiar como ruta» hacía que la llave no se encontrara aunque existiera.

### Cambiado
- **02 §9.3, qué hacer con los hallazgos tras un PASS.** El verificador clasifica cada hallazgo por **tipo**: defecto (incumple algo escrito, citando la regla) o hueco de la especificación (nada escrito lo decide). Regla por defecto: un defecto de la tarea Media o mayor es un ciclo FAIL; uno Menor va al backlog salvo que el humano pida corregirlo ahora; un hueco corrige la nota y el catálogo, nunca es un ciclo; un Menor nuevo en una reverificación, fuera de lo que cambió el ciclo, va al backlog. La compuerta de estabilización ya limita cuántos Menores se acumulan. En EN-001, TASK-002 gastó sus 3 ciclos en Menores encadenados (cada arreglo de foco destapaba otro detalle) y aun así terminó con 3 defectos en el backlog.
- **Reverificación acotada:** tras un ciclo FAIL, el verificador repite toda la evidencia automática, pero la prueba manual cubre lo que cambió el ciclo y una pasada breve de regresión (plantilla **V1r** en `aes-cycle`). En EN-001, el verificador fue el 37 % del costo de Claude.
- **Plantilla de nota de diseño:** secciones «Bordes de la API» (405, ruta desconocida y barra final por prefijo, cuerpo de error, qué fallback los cubre) y «Comportamiento dinámico de la interfaz» (foco tras cada transición, regiones vivas, anillo por tipo de elemento, espacio reservado, respuestas que deben cubrir las pruebas). La skill `aes-design-note` las exige.
- **Plantilla del plan técnico:** un criterio que verifica el harness lleva sus cambios en un PR `spec/<ID>-ci` entre `qa/<ID>` y la primera tarea (en el PR de QA harían pasar su propio comando de verificación y la CI rechazaría el RED).
- **Programador:** el presupuesto de diff es un límite (más de un 25 % por encima se justifica en el reporte), no lee `.claude/aes.env` ni sale de su worktree, y lo que la nota no decide lo anota como supuesto, que el orquestador revisa antes de gastar una verificación.
- **CI:** `aes:deps-approved` se conserva en los commits siguientes que no cambian manifiestos ni lockfiles (`aes-guard.sh --deps-changed`). En EN-001 hubo que volver a ponerla 5 veces.
- **`aes-cycle`:** comprueba que la sesión se abrió en la raíz del proyecto; el orquestador edita rutas protegidas con Edit/Write, no por shell (el bash-guard lo bloquea); pide detener los servidores de la demo antes del cierre y `/clear` después; los códigos 5 y 6 de `aes-oc.sh`.
- **06 §12:** versiones probadas del otro harness y comprobación antes de delegar; un plan gratuito o con límite corto no sirve para tareas que compilan.
- `aes-new` recomienda `deepseek/deepseek-flash` (de pago) y deja el modelo gratuito como opción para probar.

### Añadido
- **`.claude/scripts/aes-doctor.sh`:** chequeo del entorno de una vez, antes de delegar: herramientas de AES, permisos de la GitHub App, OpenCode (versión, opciones de `aes-oc.sh`, que cada modelo del binding responde) y el stack con `AES_DOCTOR_CHECKS` en `aes.env`, incluidas compilaciones mínimas (`probe:rust`, `probe:dotnet`, `probe:node`) que detectan un compilador sin enlazador. `aes-cycle` lo ejecuta al arrancar y `aes-inception` añade las comprobaciones en cuanto se elige el stack. En EN-001, Rust y después el enlazador de MSVC se descubrieron por partes, con el programador en BLOCKED.
- **`.claude/scripts/aes-workflow.sh`:** el humano aplica desde su terminal, con su identidad, el workflow que el orquestador preparó en `docs/ci/`. La GitHub App sigue **sin** permiso de Workflows (06 §10): así ningún agente puede cambiar la CI que lo juzga. `aes-doctor.sh` y `setup-repo.sh` avisan si la app lo tiene.
- `gh-app-token.sh --permissions`.

## [1.4.0] — 2026-11-21

Roles en otro harness (el orquestador en Claude Code; QA, programador y mecánico en OpenCode con otro proveedor, como DeepSeek; el verificador en Claude) y proyectos nuevos con un solo script (`aes-new`). Cambio MINOR: con el binding en `claude`, un proyecto funciona como en 1.3.0. Justificación: [`docs/rfc/RFC-004-aes-1.4.0.md`](docs/rfc/RFC-004-aes-1.4.0.md).

Lo que el RFC marca como pendiente se probó con un modelo simulado, un `gh` simulado y remotos locales, pero todavía no con un modelo real, GitHub real ni macOS: el sandbox de la app de tareas es la primera prueba.

### Añadido
- **06 §12, roles en otro harness:** mismo contrato, L1 y L2 equivalentes (o hueco declarado), L3 sin cambios, ejecución sin interfaz que rechaza lo que pediría confirmación, sin credenciales de publicación, costo por delegación con precio de lista y recargo por horario aunque el modelo sea gratis, y registro del proveedor y sus condiciones de datos. El verificador, en otra familia de modelos que el programador.
- **Implementación de referencia:**
  - `opencode.json` con los agentes `programmer`, `mechanic` y `qa`, que cargan el mismo contrato de `.claude/agents/` (`{file:…}`), permisos por rol, skills limitadas al rol, sin red, sin preguntas ni subagentes, y tope de pasos;
  - `.opencode/plugin/aes-guard.js`: L2 que ejecuta los mismos `role-guard.sh` y `bash-guard.sh` y quita credenciales del entorno de la terminal;
  - `.claude/scripts/aes-oc.sh`: delegación (`run <rol> <rama>`) con worktree, compuerta de fin de rol con una reanudación, eventos y sesión en `.aes/runs/`, costo en `.aes/costs.csv`, y `report [<ID>]`. Un vigilante cierra OpenCode si, tras el cierre final del modelo, no llega nada en `AES_OC_IDLE` segundos (se vio a `opencode run` quedarse vivo después de terminar) y aplica `AES_OC_TIMEOUT` sin depender de `timeout`. En Windows, el plugin ejecuta los hooks con el mismo Git Bash que corre el script (`AES_BASH`), no con el `bash` del PATH, que con WSL puede ser otro;
  - binding por rol en `.claude/aes.env` (`AES_BIND_*`, precio de lista y franjas caras); el entorno tiene prioridad para una corrida;
  - `aes-cycle` delega según el binding, comprueba el modelo al arrancar y resume el costo en la retrospectiva.
- `.opencode/` y `opencode.json` son rutas protegidas (hooks, guardián de la CI, CODEOWNERS). El instalador los copia.
- `setup-repo.sh --opencode <proveedor/modelo>` (o `AES_OPENCODE_MODEL` en `app.env`): deja QA, programador y mecánico en OpenCode y comprueba que el modelo responde. Si se ejecuta desde dentro del repo de AES, el proyecto se crea al lado, no adentro.
- **`scripts/aes-new.sh`, proyecto nuevo sin preparación:** se baja a la carpeta del proyecto y se ejecuta ahí (macOS, Linux y Windows con Git Bash). Pregunta si el proyecto va en esa carpeta, el nombre (el de la carpeta), público (por defecto) o privado (comprueba el plan: en Free no hay reglas de rama), identidad de los agentes (GitHub App o modo personal; si falta la app, manda a la sección del README o pide sus datos), harness y modelo de los roles (Claude Code u OpenCode; Codex anunciado) y skills de terceros. Baja AES y las skills a una carpeta temporal, se aparta a `.aes/aes-new.sh` (fuera de git, para retomar si algo falla) y termina con «¿Empiezo ahora?», que abre Claude Code con Opus y arranca la incepción. Fuera del proyecto solo guarda la configuración de la cuenta en `~/.config/aes/`.
- **Modo personal** (`setup-repo.sh --personal`, `AES_IDENTITY=personal`): sin GitHub App, los agentes publican con la sesión de gh del humano; los rulesets exigen PR y CI en verde sin aprobación (GitHub no deja aprobar los propios PR), e integrar es la aprobación del humano. `agent-gh.sh` usa la sesión de gh en ese modo.
- `setup-repo.sh` inicializa el repositorio en una carpeta existente, no aborta si GitHub rechaza los rulesets (repos privados con Free: avisa y sigue), y no falla al reintentar si el commit inicial ya existe.
- `CLAUDE.md` de los proyectos: sin `docs/backlog.md`, lo primero de cualquier sesión es la incepción.
- **macOS:** los scripts que corren en la máquina del usuario funcionan con bash 3.2 y sin herramientas GNU (`timeout` → `gtimeout` o perl; `sha256sum` → `shasum`; `date -d` → jq; `netstat` sin `-o`; sin índices negativos de arrays). Revisado a mano; pendiente de probar en un Mac.
- README: «Empezar un proyecto nuevo», con `aes-new`.
- Plantilla de perfil: proveedor y condiciones de datos por rol, y huecos de control de los roles en otro harness.

### Cambiado
- `profiles/reference/claude-code-opencode/` queda obsoleta (se conserva por el ejemplo de pruebas holdout).

## [1.3.0] — 2026-11-08

Mejoras propuestas por el responsable humano después de los cuatro elementos del sandbox de gastos, antes de un sandbox nuevo (una app de tareas) que empieza por la incepción. Cambio MINOR: los proyectos en 1.2.0 migran creando `dev` y reinstalando con `install-aes.sh --upgrade` (RFC-003, «Migración»). Justificación: [`docs/rfc/RFC-003-aes-1.3.0.md`](docs/rfc/RFC-003-aes-1.3.0.md).

Lo que el RFC y el README de la referencia marcan como «simulación» se probó con repositorios y datos de prueba, pero todavía no en un ciclo real: worktrees por rol, la incepción, impeccable dentro del ciclo, el detector y el SAST en Actions, y `setup-repo.sh` contra GitHub.

### Añadido
- **Ramas `main` y `dev` obligatorias** en todo proyecto (07 §7, principio 19): `main` es lo liberado, `dev` lo integrado y la base de todo el trabajo. Sin variante «solo `main`» ni *feature flags*.
- **Release** `dev → main` como gate humano propio (07 §8): compuerta de estabilización, `main` contenido en `dev`, regresión completa, merge commit, sin periodo mínimo de uso. Estado nuevo `Released` (00 §6). Plantilla `release.md`.
- **Hotfix y back-merge** (07 §9): un defecto de algo liberado, de cualquier severidad, puede corregirse desde `main` si el responsable humano lo decide; después de cada integración en `main`, back-merge a `dev` con merge commit.
- **Checkout propio por rol** (06 §10): el orquestador se queda en `dev` y cada rol trabaja en su propio checkout de la rama de trabajo.
- DoD de hotfix y de release (08 §7–8).
- **Capítulo 10 — Principios de diseño y patrones**: nivel 1 de principios siempre obligatorios en todo código (responsabilidad única, lógica separada de la E/S, dependencias recibidas, acceso a datos agrupado, contratos en las fronteras, errores explícitos, Liskov, interfaces pequeñas, visibilidad mínima, configuración fuera del código), cada uno con su síntoma; nivel 2 de patrones condicionales con «cuándo sí» y «cuándo no»; la prueba de tres condiciones para decidir el nivel (principio 20).
- **Historias atómicas y cortes verticales** (02 §3, principio 21): título obligatorio «Como [usuario], quiero [capacidad], para [beneficio]» (y formatos propios para enablers, defectos y chores); `Requiere:`; una capacidad que se demuestra sola; 8 puntos o más, o más de 3 tareas, obliga a dividir; catálogo de formas de dividir (02 §10); esquema de datos que crece historia a historia; *walking skeleton* como primer enabler.
- **Planificación en dos niveles** (02 §7, 01 §2): backlog completo pero superficial al inicio; criterios, diseño y tareas cuando le toca a cada historia.
- **Historia y plan técnico separados** (03 §1): la historia, en lenguaje de cliente, se conserva; el plan técnico (contrato de interfaz, notas de diseño, tareas) se elimina en el cierre tras consolidar en el catálogo de diseño o un ADR. Plantillas `user-story.md` (reescrita), `technical-plan.md` y `backlog.md`.
- **Backlog como archivo con vistas generadas** (02 §11): formato fijo de columnas; tablero HTML sin servicios y JSON para adaptadores (`aes-board.mjs`).
- **Sin código provisional** (nivel 1, 10 §3): cada pieza en su archivo desde el primer commit; `TODO`, `FIXME` y `HACK` añadidos son marcadores del guardián.
- **Skills** (06 §6.2): tipos técnica, herramienta y flujo; las de flujo no se instalan junto a AES; versión fija, revisión humana y registro en el perfil. **Núcleo propio** en `skills/`: `aes-debugging` (basada en `systematic-debugging` de obra/superpowers, MIT), `aes-security-review` y `aes-design-note`; `scripts/sync-skills.sh` las copia a la referencia.
- **SAST en la CI** (05 §7): hallazgos nuevos de severidad alta fallan la tarea; el resto se registra como defectos. En la referencia, Semgrep con OWASP Top 10 y `nosemgrep`/`NOSONAR` como marcadores del guardián.
- Capítulo 10: «validar en la frontera y convertir» y el modo estricto del compilador pasan al nivel 1; tipos propios del dominio y estados irrepresentables, al nivel 2. Grafos de código (p. ej. Graphify) como fuente de hechos para la nota de diseño, solo con relaciones extraídas; en la referencia, como herramienta opcional en piloto.
- **Orquestador como diseñador senior** en el modelo más capaz disponible (06 §11): escribe una nota de diseño por tarea a partir de hechos (artefactos, catálogo de diseño y resumen estructural), incluido lo que no se hace; el programador no añade patrones fuera de la nota y el verificador revisa el diff contra ella y contra el nivel 1. Plantillas `design-note.md` y `design-catalog.md`; script `aes-outline.sh`.
- **Incepción** (01 §2): antes de escribir código, el orquestador entrevista al responsable del producto por temas (problema y usuarios, lo que el usuario hace, datos y reglas, restricciones, stack, primer release), en bloques de 2 a 5 preguntas concretas con opciones y recomendación, resumiendo después de cada bloque. Regla de parada; lo que no se sabe queda «por definir» o como Spike. Produce brief, backlog completo pero superficial con Epics y releases, arquitectura inicial con diagrama, ADR del stack, perfil y EN-001, en un único PR. Mini-incepción para ideas que no caben en el backlog. Skill del núcleo `aes-inception`.
- **Releases como horizonte de planificación** (02 §12): sin sprints; solo el release en curso está comprometido. Columnas opcionales `Epic` y `Release` en el backlog (02 §11), que lo convierten en mapa de historias; el tablero filtra por release y muestra su avance.
- **Instalador** `scripts/install-aes.sh`: instala, actualiza (`--upgrade`) o comprueba (`--check`) AES en un proyecto desde una versión fija: implementación de referencia, skills del núcleo, DoR/DoD, `AES-CORE.md` y plantillas en `docs/aes/`, versión en `docs/aes/VERSION`. Distingue archivos de AES (se sobrescriben) y semillas del proyecto (se dejan como `.aes-new` si AES las cambió). `--vendor` copia skills de terceros y anota versión y huella en `docs/aes/skills.lock`.
- **Skills de terceros sin consultas de red** (06 §6.2): los avisos de actualización se desactivan; actualizar es un PR. archify registrada como skill de herramienta recomendada para diagramas (en la referencia, `ARCHIFY_UPDATE_CHECK_DISABLED=1`).
- **Interfaz** (01 §2, 05 §7): bloque G de la entrevista (tono, accesibilidad, marca, restricciones visuales); dirección visual elegida por el humano en la incepción, como el stack; detector determinista de interfaz en la CI, que anota hasta que el perfil decida qué reglas bloquean. **impeccable** (Apache-2.0) como skill de terceros recomendada: `PRODUCT.md` desde el brief con una sola ronda de confirmación, dirección visual en su página de decisión con el humano presente, `shape` dentro del refinamiento, comandos por rol (el programador no cambia la dirección visual), `audit` del verificador y `impeccable detect --github` en la CI (`AES_UI_DETECT`).
- 06 §6.2: se aceptan las descargas fijadas y verificadas por huella del propio paquete; las consultas que no se pueden desactivar se registran y solo se usan con el humano presente; ninguna skill deja servidores vivos. El instalador copia `LICENSE`/`NOTICE` de las skills de terceros y deja impeccable sin telemetría, sin avisos de actualización y sin hook.
- **Puesta en marcha de un repositorio con un comando:** `scripts/setup-repo.sh <dueño/repo> [--create private|public] [--dry-run]` usa `gh` para crear y clonar el repo, instalar AES con las skills de terceros de la cuenta, rellenar `CODEOWNERS` y `.claude/settings.local.json`, hacer el commit inicial en `main`, crear `dev` como rama por defecto, fijar los métodos de integración, aplicar los rulesets (`ramas-ci`, `aprobacion-dev`, `aprobacion-main`), crear etiquetas y `AES_APPROVERS`, y dar acceso a la GitHub App. Idempotente. La configuración de la cuenta va en `~/.aes/app.env` (`scripts/aes-app.env.example`). El README de la referencia separa lo que se hace una vez por cuenta de lo que se hace por proyecto, y documenta cada paso para hacerlo a mano.
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
