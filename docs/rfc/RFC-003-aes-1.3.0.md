# RFC-003 — AES 1.3.0

**Estado:** En curso. Se van incorporando los cambios que propone el responsable humano; el sandbox queda pausado hasta publicarla.
**Base:** AES 1.2.0
**Tipo de cambio esperado:** MINOR. El modelo de ramas cambia el flujo de los proyectos existentes: migrarlos exige crear `dev` y ajustar la CI (ver «Migración»).

## 1. Ramas `main` y `dev`, release, hotfix y back-merge — 00, 02, 05, 07, 08

**Problema.** Con una sola rama, todo lo que se integra queda como producto. Una épica de varias historias, o una funcionalidad que hay que usar una semana antes de confiar en ella, no tiene dónde vivir sin estar en `main`. Y un arreglo de algo ya liberado se hace sobre lo que está en construcción, así que puede arrastrar a `main` código a medias.

**Decisiones del responsable humano (2026-11-06):**

| Pregunta | Decisión | Motivo |
|---|---|---|
| ¿`dev` por defecto o siempre? | **Siempre**, también en proyectos pequeños | Una sola regla es más simple. `dev` no cambia el trabajo de los agentes; *trunk* con *feature flags* añade contexto, decisiones y código condicional |
| ¿Qué severidades pueden ir por hotfix? | **Todas**; el responsable decide la ruta de cada defecto | Limitarlo a Crítica y Alta impediría arreglar ya un defecto Medio que importa por otra razón |
| ¿El release exige un periodo mínimo de uso? | **No** | La evidencia es la aprobación humana del PR de release, después de usar `dev` lo que el responsable considere. Un plazo fijo es una aproximación y una opción más que configurar |

**Cambio.**
- `main` (lo liberado) y `dev` (lo integrado), ambas protegidas con la misma CI. Ramas de trabajo cortas desde `dev`; ninguna rama permanente de features ni de bugs (la «rama de bugs» propuesta se resuelve con ramas `hotfix` cortas desde `main`, que no se desfasan).
- Release `dev → main`: notas, compuerta de estabilización, comprobación de que `main` está contenido en `dev`, regresión completa, **merge commit**. Estado `Released`.
- Hotfix: ramas de trabajo de un `BUG-NNN` que nacen de `main` y vuelven a `main`.
- Back-merge `main → dev` con merge commit después de cada integración en `main`. La comprobación del release convierte el olvido en un fallo de la CI en lugar de en un defecto reintroducido.
- *Squash* solo en las ramas de trabajo: con *squash* en el release, los commits de `main` no existirían en `dev` y la comprobación fallaría siempre.

## 2. Checkout propio por rol (worktrees) — 06 §10

**Problema.** En el sandbox, el orquestador cambiaba de rama en el único checkout y los roles compartían archivos sin versionar y servidores (FL-007).

**Cambio.** El orquestador se queda en `dev`. Cada rol trabaja en su propio checkout de la rama de trabajo. En la referencia: `isolation: worktree` en los subagentes, más un hook `WorktreeCreate` que abre el worktree en la rama real (la que indica el orquestador con `aes-wt.sh delegate`) y copia la identidad de la app, que está fuera de git. Sin indicación, el hook falla y el subagente no arranca.

**Pendiente de comprobar en el sandbox:** que Claude Code use el hook `WorktreeCreate` también para los subagentes, el formato exacto de su evento y el `cwd` que recibe `SubagentStop` desde un worktree. Si algo no coincide, la referencia falla cerrada: el subagente no arranca, o el hook de rol lo bloquea por no estar en una rama de tarea.

## 3. Principios de diseño, patrones y el orquestador como senior — 00, 04, 06, 08, 10

**Problema.** Un modelo de nivel junior aplica un patrón si se le pide, pero no sabe cuándo conviene ni cuándo no. Pedirle «aplica SOLID» o «escribe código limpio» no le da información nueva: es ruido. Y no aplicar ningún principio porque el código es pequeño produce el refactor caro el día que crece.

**Decisiones del responsable humano (2026-11-06):**

| Pregunta | Decisión |
|---|---|
| ¿Quién decide los patrones? | El **orquestador**, que actúa como diseñador senior y por eso corre en el modelo más capaz disponible (Opus o equivalente). No se crea un rol nuevo; el orquestador puede ocupar también el de arquitecto |
| ¿Con qué decide? | Con **hechos**: artefactos, ADRs, catálogo de diseño y un resumen estructural generado por herramienta (archivos y firmas públicas). No lee implementaciones ni se basa en la descripción del programador |
| ¿Cuándo? | Obligatorio en T2/T3 al dividir en tareas, antes de `Ready`; y a demanda, cuando el programador se detiene con una pregunta de diseño |
| ¿Qué es obligatorio siempre? | Los principios del **nivel 1**, en todo código, también en scripts. Los patrones del **nivel 2**, solo con razón presente |

**Cómo se decide el nivel.** Un principio es de nivel 1 si aplicarlo hoy no cuesta casi nada, aplicarlo después cuesta cada vez más y es local. Los del nivel 1 son los que hacen barato añadir un patrón después: por ejemplo, si el acceso a datos de cada funcionalidad está en un solo lugar, introducir un repositorio el día que haga falta toca ese lugar y nada más.

**Cambio.** Capítulo 10 con las dos tablas (síntoma de incumplimiento en el nivel 1; «cuándo sí / cuándo no» en el nivel 2), la nota de diseño por tarea con lo que no se hace explícito, el catálogo de diseño del proyecto, la verificación del diff contra la nota y el nivel 1, y lo detectable por linter en la CI.

**Consecuencia para RFC-002, cambio 9:** queda decidido que el orquestador corre en el modelo más capaz disponible, aunque el A/B de US-002 mostró que Sonnet respetaba los gates: el motivo nuevo es el diseño, que el A/B no evaluó.

## 4. Skills: núcleo propio y reglas de integración — 05 §7, 06 §6.2, 10

**Problema.** Hay skills de terceros muy útiles (depuración sistemática, SAST, grafos de código), pero algunas son metodologías completas que competirían con AES, otras dependen de su paquete, y cualquiera puede cambiar sola si se instala como plugin que se actualiza.

**Decisiones del responsable humano (2026-11-06):** las skills no son obligatorias, pero AES tiene un núcleo fuerte que potencia la metodología sin paralizarla. Las buenas ideas de terceros se reescriben como skills propias de AES, con atribución. Lo determinista va a la CI. Lo demás de la propuesta, aprobado.

**Cambio.**
- Tres tipos: **técnica** (se asigna a roles), **herramienta** (lo determinista va a la CI; la skill interpreta) y **flujo** (no se instala junto a AES).
- Reglas: versión fija, revisión humana, registro en el perfil, hooks y scripts revisados como código propio, salida no es evidencia sin comando real, pocas por rol.
- Núcleo en `skills/`: `aes-debugging` (de `systematic-debugging` de obra/superpowers, adaptada a RED, superficie y circuit breaker), `aes-security-review` (Semgrep con OWASP, clasificación de hallazgos y tabla de severidad) y `aes-design-note` (cómo escribe el orquestador la nota de diseño).
- SAST en la CI: un hallazgo nuevo `ERROR` falla la tarea; los demás se registran como defectos. La regla de qué severidad bloquea la tomé por defecto (el responsable aprobó «lo demás» sin elegir); cambiarla es una variable de la CI.
- Type-driven design dentro del capítulo 10 en lugar de una skill.
- Graphify como herramienta opcional: hook de git (se reconstruye en segundo plano tras cada commit y checkout; instalado en el checkout principal, cubre los worktrees), sin `watch` (dejaría un proceso vivo), y sin su integración con el asistente hasta probarla en el sandbox.

**Descartado:** las skills de flujo de Superpowers (`brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `using-git-worktrees`, `finishing-a-development-branch`, `using-superpowers`): duplican el ciclo de AES.

## 5. Historias atómicas, cortes verticales y la historia en lenguaje de cliente — 00, 01, 02, 03, 04, 08, 10

**Problema.** Los agentes (y muchos equipos) construyen por capas: toda la base de datos, luego todo el servidor, luego toda la interfaz. Se tarda semanas en descubrir que algo no servía. Las metodologías que planifican todo por adelantado llegan a lo mismo por otra vía: sobreingeniería y alucinaciones. Y una historia grande, aunque sea «una cosa», hace que el agente pierda el control y que sea difícil depurar y verificar.

**Decisiones del responsable humano (2026-11-07):**

| Tema | Decisión |
|---|---|
| Cortes | Cada historia es un corte vertical completo (datos, servidor, interfaz); el primer elemento es un *walking skeleton* |
| Formato | Título «Como [usuario], quiero [capacidad], para [beneficio]» obligatorio; formato propio para enablers |
| Atomicidad | Una capacidad del usuario que se verifica sola, no un solo verbo. Obligatoria: lo grande se divide siempre, también lo que es «una cosa» pero grande por dentro (señales: 8 puntos o más, más de 3 tareas) |
| Planificación | Backlog completo pero superficial al inicio; detalle técnico cuando llega cada historia |
| Documentos | La historia, en lenguaje de cliente, se conserva; el plan técnico se elimina al cerrar, después de consolidar |
| Tablero | `backlog.md` como única fuente (sin atarse a GitHub); vistas generadas en una sola dirección: tablero HTML propio y adaptadores opcionales |
| Atajos | Prohibido el código provisional («todo en `App.tsx` y después refactorizamos»): cada pieza en su archivo desde el primer commit. Evidencia: el formulario de US-001 del sandbox terminó en `App.tsx` |

## Migración de un proyecto en 1.2.0

1. `git push origin main:dev` y hacer `dev` la rama por defecto.
2. Aplicar los rulesets a `dev` y `main`; en `main`, solo merge commit.
3. Copiar el workflow, `ci/` y `.claude/` de la referencia 1.3.0; añadir `.claude/worktrees/` a `.gitignore`.
4. Los elementos ya cerrados quedan como `Released` (ya están en `main`).
5. Crear `docs/design-catalog.md` con los patrones que el proyecto ya usa y lo que ya se decidió no usar (por ejemplo, «sin repositorio sobre EF Core»).
6. Copiar las skills de `skills/` a `.claude/skills/` y registrarlas en el perfil; desinstalar cualquier plugin de flujo de terceros.
7. Pasar `docs/backlog.md` al formato de `templates/backlog.md` (columnas `Tipo`, `Requiere`, `Puntos`) y reescribir los títulos de las historias abiertas en el formato «Como… quiero… para…».
