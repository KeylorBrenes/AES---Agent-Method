# RFC-004 — AES 1.4.0

**Estado:** En curso, rama `release/1.4.0`. Se prueba en el sandbox de la app de tareas.
**Base:** AES 1.3.0
**Tipo de cambio esperado:** MINOR. Todo es opcional: con el binding en `claude`, un proyecto funciona como en 1.3.0.

## 1. Roles en otro harness: Claude Code orquesta, OpenCode ejecuta — 06 §12, referencia

**Problema.** AES se declara independiente del harness, pero nunca se había probado un rol fuera de Claude Code (RFC-002, cambio 4, pendiente desde 1.2.0). Además, el costo del sandbox de gastos lo dominó Claude, y no se sabe cuánto costaría un proyecto con roles en un modelo mucho más barato.

**Decisiones del responsable humano (2026-11-12):**

| Tema | Decisión |
|---|---|
| Camino | OpenCode como harness de los roles delegados (no Claude Code apuntando a otro proveedor) |
| Orquestador | Claude Code con Opus 5.5 |
| Roles en DeepSeek | Programador, mecánico y QA |
| Verificador | Claude: revisar es trabajo de modelos frontera |
| Medición | Cuánto cuesta el proyecto completo de la app de tareas |
| Exploración | Ver a fondo el modo CLI y la API de OpenCode para saber qué se le puede pasar |

**Decisiones del orquestador, a revisar en el sandbox:**

- **Un solo contrato por rol.** `opencode.json` carga `.claude/agents/<rol>.md` con `{file:…}`. No hay una copia para OpenCode que se desfase.
- **L2 sin duplicar reglas.** El plugin `.opencode/plugin/aes-guard.js` traduce cada herramienta al formato de hook de Claude Code y ejecuta los mismos `role-guard.sh` y `bash-guard.sh`. Un cambio en una regla vale para los dos harness.
- **El script, no el modelo, tiene las credenciales.** `aes-oc.sh` ejecuta OpenCode sin las variables de la GitHub App ni de `gh`, y el plugin las quita también del entorno de la terminal. Publicar sigue siendo del orquestador.
- **Costo con precio de lista y recargo por horario**, aunque el modelo se use gratis: así el experimento mide lo que costaría el proyecto, no lo que costó una promoción.
- **Modo `run`, no servidor.** `opencode run --format json` da todo lo necesario (eventos, tokens, costo, sesión reanudable) sin dejar procesos vivos. La API del servidor (`opencode serve`, ~200 rutas con OpenAPI) permitiría que el orquestador conteste permisos y preguntas en vivo; queda como opción si el modo `run` se queda corto.

## 2. Lo que se encontró explorando OpenCode 1.19.5

Probado aquí con OpenCode 1.19.5 y un modelo simulado (un servidor compatible con la API de OpenAI que pide herramientas programadas), porque el entorno no llega a los proveedores.

| Pregunta | Resultado |
|---|---|
| ¿Qué pasa con un permiso en *ask* en `opencode run`? | Se **rechaza** solo («auto-rejecting»), y la sesión termina. `--auto` lo aprobaría: AES no lo usa |
| ¿Y uno en *deny*? | La herramienta falla con un mensaje, el modelo lo recibe y sigue trabajando |
| ¿Basta L1 con la terminal? | No: con `echo *` permitido, `echo x > tests/acceptance/y.ts` escribió en una ruta protegida. El plugin lo bloquea |
| ¿Un plugin puede bloquear? | Sí: `tool.execute.before` que lanza un error. Corre antes que los permisos y su mensaje llega al modelo |
| ¿Escribir fuera del proyecto? | Rechazado por defecto (`external_directory`), sin configurar nada. En Claude Code nativo de Windows no hay ese límite (FL-002) |
| ¿Lee las instrucciones del proyecto? | Sí: inyecta `CLAUDE.md` (si no hay `AGENTS.md`) |
| ¿Ve las skills de AES? | Sí: lee `.claude/skills/` del proyecto, y también las del usuario (`~/.claude/skills/`). Se limitan por rol con `permission.skill` |
| ¿Costo? | Cada paso (`step_finish`) trae tokens (entrada, salida, razonamiento, caché) y costo. Coincide con el precio configurado. Para DeepSeek trae el precio barato, sin el recargo por horario |
| ¿Credenciales? | `DEEPSEEK_API_KEY` en el entorno o `/connect`. No hay cuenta de OpenCode |
| ¿Primera ejecución? | Instala la dependencia de plugins en `.opencode/` de cada checkout (la ignora en git). Más lenta la primera vez |
| ¿Modelos gratis? | OpenCode Zen ofrece varios por tiempo limitado, sin cuenta. DeepSeek V4.1 Flash Free declara cero retención y sin entrenamiento; Big Pickle, MiMo, Flint, Iceman, Inkling y Nemotron pueden guardar o entrenar con los datos |

## 3. Pendiente de probar en el sandbox

- Un modelo real (DeepSeek) siguiendo el contrato: ¿respeta la superficie, hace RED → GREEN, reporta BLOCKED en lugar de rodear?
- El plugin en Windows (Git Bash en el PATH de OpenCode o `AES_BASH`).
- Costo real del proyecto frente al estimado, y frente al sandbox de gastos.
- Si 120 pasos por ejecución alcanzan, y si una reanudación de la compuerta basta.
- La calidad de QA en DeepSeek: ¿pruebas que no conocen la implementación y RED confirmado?

## 4. Proyecto nuevo sin preparación: `aes-new` — referencia

**Problema.** Empezar un proyecto exigía clonar AES, preparar `~/.aes/app.env` a mano y ejecutar `setup-repo.sh` con opciones. Para un tercero, o en otra máquina, es demasiado; y el clon de AES se mezclaba con los proyectos.

**Decisiones del responsable humano (2026-11-13):**

| Tema | Decisión |
|---|---|
| Uso | Plug and play: crear la carpeta del proyecto, bajar ahí el script y ejecutarlo; en macOS, Linux y Windows |
| Preguntas | Si el proyecto va en esa carpeta, nombre del repo (el de la carpeta), público (por defecto) o privado, harness y modelo; al final, «Empezar» |
| Repo de AES | Solo metodología y scripts; los proyectos no lo tocan ni necesitan un clon |
| Bot | Opcional: con GitHub App o en modo personal (recomendación del orquestador, aprobada) |
| El script después de usarse | Se aparta a `.aes/aes-new.sh`, fuera de git, para retomar (aprobado) |
| Empezar | En la misma terminal (aprobado) |
| macOS | Compatibilidad en este cambio (aprobado) |
| Incepción | Claude sabe que, sin planeamiento, primero pregunta por la idea |

**Decisiones del orquestador:** el script es un único archivo en `main`, no una rama aparte: una rama solo con el script tendría historia propia y no se versionaría con la metodología. Fuera del proyecto solo queda la configuración de la cuenta, en `~/.config/aes/` (la llave de la app no puede vivir en el repo).

**Comprobado aquí** (con un `gh` simulado y un remoto local): carpeta con solo el script, modo personal y OpenCode; el script no entra en el repo; reglas sin aprobación en modo personal; reejecución desde `.aes/aes-new.sh` después de un push fallido; «Empezar» lanza `claude --model opus` con el primer mensaje. **Pendiente:** GitHub real, macOS real.

## Migración desde 1.3.0

1. `./scripts/install-aes.sh <proyecto> --upgrade`: copia `.opencode/plugin/` y `aes-oc.sh`, y deja `opencode.json` y el nuevo `.claude/aes.env` como `.aes-new` si ya existían.
2. Añadir `.opencode/` y `opencode.json` a CODEOWNERS (si el proyecto ya adaptó el suyo).
3. Para usar OpenCode: instalarlo, conectar el proveedor y cambiar `AES_BIND_*`.
