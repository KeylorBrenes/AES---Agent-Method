# Agentic Engineering Standard (AES)

**Versión:** 1.4.0 (en preparación, rama `release/1.4.0`)  
**Estado:** Estándar en uso  
**Idioma normativo:** Español  
**Propósito:** establecer un proceso de ingeniería consistente para desarrollar y mantener software con agentes de IA, sin depender de un proveedor, modelo, harness o stack específico.

## Qué es AES

AES es un estándar de trabajo para proyectos de software asistidos por agentes. Define cómo descubrir y planificar el producto, mantener la arquitectura, organizar el backlog, especificar historias, dividir tareas, probar, verificar, aprobar y registrar cambios.

AES no es un generador automático de requisitos ni una metodología de cascada. La planificación es progresiva: se define con mayor detalle el trabajo próximo y se conserva una visión suficiente del producto y de su arquitectura.

### Lo que AES intenta evitar

- Agentes que se van por las ramas, generan código de más o implementan lo que nadie pidió.
- Agentes que modifican, desactivan o borran pruebas para obtener un resultado verde.
- Procesos de especificación tan pesados que convierten un bug pequeño en una cascada de documentos.
- Tener que leer cada línea de código para confiar en el resultado.
- Arrastrar defectos de una historia a la siguiente, hasta que arreglar uno rompe otro.
- Que una funcionalidad a medias o un arreglo apresurado rompa lo que ya funcionaba.

### Cómo lo hace, en una frase

**Tú apruebas los contratos (criterios y pruebas de aceptación); un agente independiente escribe esas pruebas sin ver el código; el programador no puede tocarlas; la CI las ejecuta desde una copia que nadie puede alterar; un verificador independiente re-ejecuta todo y prueba la aplicación de verdad.**

## El ciclo

```
0. Compuerta de estabilización: ¿defectos abiertos?   [CI]
   └─ Crítico, Alto o Medio abierto → lote de estabilización antes de seguir
   Clasificar track (T0–T3)                          [orquestador → tú confirmas]
1. Historia atómica y vertical («Como… quiero… para…»), en lenguaje de cliente:
   criterios + fuera de alcance + plan + decisiones (D-NN)   [orquestador → tú apruebas]
2. Contrato de interfaz (si hay frontera nueva)       [arquitecto]
3. QA: pruebas visibles + holdout, cada una con su criterio
   → RED confirmado por herramienta → supuestos resueltos → rama protegida
                                                     [tú apruebas pruebas y supuestos]
4. Tareas por criterio: superficie, criterios que cierran, comandos exactos
   + nota de diseño por tarea (orquestador = senior, modelo más capaz)
5. Programador (sesión nueva por tarea):
   baseline → RED/GREEN/REFACTOR → commits struct:/feat: → reporte
6. CI (L3): criterios de la tarea + regresión desde ref confiable, holdout, guardián
7. Verificador (sesión limpia, solo lectura), ANTES de integrar:
   re-ejecución → prueba manual agéntica → PASS / FAIL / BLOCKED
   └─ 3 FAIL en la misma tarea → circuit breaker
   └─ hallazgos preexistentes → defectos con severidad en el backlog
8. Tú: informe → apruebas la verificación → integras
9. Cierre: demo (+ código en T3) → Accepted / Rejected → regresión en dev
10. Retrospectiva compuesta: registro de fallos → un control nuevo por patrón
11. Release cuando tú decides: dev → main (merge commit) → back-merge a dev
    Hotfix de algo liberado: ramas desde main → main → back-merge a dev
```

| Track | Para qué | Proceso mínimo |
|---|---|---|
| T0 | Errata, configuración no funcional | Tarea + CI |
| T1 | Bug, chore, lote de estabilización | Camino corto: comprobación de reproducción protegida (RED) + tareas |
| T2 | Funcionalidad nueva | Ciclo completo |
| T3 | Auth, datos, pagos, migraciones, arquitectura | Ciclo completo + ADR + holdout + revisión humana del código de riesgo |

## Principios de uso

1. Leer `standard/00-governance-and-principles.md` antes de iniciar un proyecto.
2. Declarar la versión de AES y completar un perfil para cada proyecto.
3. Adaptar las herramientas al proyecto; no cambiar los controles fundamentales sin una excepción documentada.
4. Usar las plantillas como punto de partida. No rellenar campos irrelevantes por formalidad.
5. Mantener la trazabilidad: objetivo → Epic → Historia de Usuario → criterios de aceptación → tareas → pruebas → evidencia → aceptación.
6. Trabajar en incrementos pequeños y verificables. No planificar en detalle trabajo lejano que aún depende de aprendizaje.

## Estructura

| Ruta | Contenido |
|---|---|
| `standard/` | Reglas normativas de AES Core (00–09). |
| `AES-CORE.md` | Las reglas de `standard/` consolidadas en un único documento (generado). |
| `templates/` | Plantillas: brief, arquitectura, ADR, backlog, epic, historia (lenguaje de cliente), plan técnico, tarea, nota de diseño, catálogo de diseño, release, defecto, lote de estabilización, plan de aceptación, informe de verificación, perfil, registro de fallos y registro de hallazgos. |
| `skills/` | Skills del núcleo de AES (depuración por causa raíz, revisión de seguridad, nota de diseño), en formato Agent Skills. |
| `agent-contracts/` | Responsabilidades, permisos y límites de cada rol: orquestador, arquitecto, QA, programador, mecánico y verificador. |
| `profiles/` | Perfiles de proyecto e implementaciones de referencia. |
| `profiles/reference/claude-code-subagents/` | Implementación de referencia de 1.2.0, salida del experimento con agentes reales (las piezas nuevas de 1.2.0, probadas en simulación): subagentes de Claude Code, hooks, skill del orquestador, CI completa (guardián, RED, CI por criterio, compuerta de estabilización, aprobaciones validadas) e identidad de agentes con una GitHub App. |
| `profiles/reference/claude-code-opencode/` | Implementación de referencia de 1.1: Claude Code como orquestador y OpenCode como programador, con pruebas holdout desde un repositorio privado. |
| `docs/rfc/` | Propuestas de cambio con su justificación y fuentes. |
| `scripts/` | Utilidades del repositorio. |

| Capítulo | Tema |
|---|---|
| 00 | Gobierno, principios, roles, estados, evidencia, revisión humana proporcional |
| 01 | Inicio del proyecto y arquitectura |
| 02 | Backlog (archivo y vistas), historias atómicas y verticales, cómo dividirlas, planificación en dos niveles, tracks T0–T3, severidad de defectos y compuerta de estabilización |
| 03 | Historia (lenguaje de cliente) y plan técnico (se elimina al cerrar), aceptación y registro de decisiones |
| 04 | Diseño y ejecución de tareas, commits, circuit breaker, camino corto T0/T1 |
| 05 | Pruebas: contrato de interfaz, RED confirmado, holdout, caracterización, aislamiento, guardián, prueba manual agéntica, qué ejecuta la CI |
| 06 | Gobierno de agentes, permisos, controles en capas L1/L2/L3, acciones denegadas, estado entre roles |
| 07 | Cambios, riesgos, liberación, ramas `main`/`dev`, release, hotfix y back-merge |
| 08 | Definition of Ready y Definition of Done |
| 09 | Mejora continua del harness, evidencia del proceso y métricas |
| 10 | Principios de diseño (siempre) y patrones (con razón presente); nota de diseño y catálogo |

## Palabras normativas

- **MUST / DEBE:** requisito obligatorio.
- **MUST NOT / NO DEBE:** prohibición.
- **SHOULD / DEBERÍA:** regla esperada; una excepción requiere razón registrada.
- **SHOULD NOT / NO DEBERÍA:** práctica que se evita salvo justificación.
- **MAY / PUEDE:** opción permitida.

Estas palabras describen la fuerza de la regla, no una herramienta particular.

## Empezar un proyecto nuevo

Con un solo script, `aes-new`, que pregunta lo necesario en la terminal y hace el resto. No hace falta clonar este repositorio: el script baja la versión de AES que elijas a `~/.aes/versions/` y no toca nada más. Tu clon de AES (si tienes uno) queda solo para trabajar en la metodología.

**Una vez:** descarga el script (en Windows, en Git Bash):

```bash
mkdir -p ~/.aes && curl -fsSL https://raw.githubusercontent.com/KeylorBrenes/AES---Agent-Method/main/scripts/aes-new.sh -o ~/.aes/aes-new.sh
```

**Cada proyecto:**

```bash
bash ~/.aes/aes-new.sh
```

El script:

1. comprueba git, gh, jq, node y Claude Code, y la sesión de gh (si falta el permiso `workflow`, te ofrece añadirlo);
2. comprueba la GitHub App de los agentes: si todavía no la creaste, te manda a [la sección del README](profiles/reference/claude-code-subagents/README.md#2-github-app-de-los-agentes) y sale; si existe y falta `~/.aes/app.env`, te pide sus datos y lo crea;
3. pregunta la versión de AES (por defecto, la última publicada), el nombre, el dueño, la visibilidad y la carpeta del proyecto;
4. pregunta dónde trabajan QA, el programador y el mecánico: Claude Code u OpenCode (con DeepSeek gratis, de pago u otro modelo). El orquestador y el verificador son siempre Claude;
5. ofrece las skills de terceros (archify, impeccable) y las baja en su última versión publicada, que queda fija;
6. crea el repositorio, instala AES, hace el commit inicial, crea `main` y `dev`, aplica rulesets, etiquetas y variables, da acceso a la app y configura los roles.

Recuerda tus respuestas para la próxima vez (`~/.aes/defaults.env`). Al terminar: `cd <proyecto> && claude`, `/model opus`, y cuéntale la idea (*«Quiero empezar el proyecto: una app de tareas para mí»*). El orquestador hace la incepción y abre un PR; después, una sesión por elemento: *«Avanza EN-001»*, *«Avanza US-001»*…

- Tablero del backlog: `node .claude/scripts/aes-board.mjs` → `.aes/board.html`.
- Costo de los roles en OpenCode: `bash .claude/scripts/aes-oc.sh report`.
- Si algo falla a medias, vuelve a ejecutar `aes-new` con las mismas respuestas: cada paso se salta lo que ya está hecho.

Sin preguntas, para automatizar: `scripts/setup-repo.sh <dueño/repo> [--create public|private] [--opencode <proveedor/modelo>]` desde una copia de AES. Para un proyecto que ya existe: `scripts/install-aes.sh <proyecto>` (con `--upgrade` actualiza y con `--check` comprueba). Herramientas y GitHub App, paso a paso: [README de la referencia](profiles/reference/claude-code-subagents/README.md#una-vez-por-cuenta).

### Qué hace AES en cada elemento

1. **Incepción** (01 §2), una vez: brief, backlog completo pero superficial con Epics y releases, arquitectura inicial, ADR del stack, dirección visual si hay interfaz y EN-001.
2. **EN-001**, el esqueleto que camina; después, release a release, refinando solo las historias próximas.
3. Para cada historia: criterios aprobados, contrato de interfaz, pruebas de aceptación con RED confirmado, tareas pequeñas con superficie de cambio, CI, verificación independiente y aceptación humana.
4. Cierre con la Definition of Done, retrospectiva y, antes de la historia siguiente, un lote de estabilización con los defectos Críticos, Altos y Medios.

Instalar AES en un proyecto que ya existe, sin `setup-repo.sh`: `./scripts/install-aes.sh <proyecto>` (con `--upgrade` actualiza y con `--check` comprueba).

## Versionado

AES utiliza versionado semántico:

- **MAJOR:** incompatibilidad en reglas fundamentales o estructura normativa.
- **MINOR:** nuevas reglas o capacidades compatibles.
- **PATCH:** aclaraciones, correcciones y mejoras que no cambian el significado normativo.

Cada proyecto declara la versión de AES que adopta. Una actualización no se aplica silenciosamente: se revisa y se registra en el proyecto. Los cambios propuestos se documentan como RFC en `docs/rfc/` antes de incorporarse.

Para regenerar `AES-CORE.md` tras editar `standard/`:

```bash
./scripts/build-core.sh
```

## Alcance

AES establece el ciclo de ingeniería, planificación por backlog con tracks proporcionales y compuerta de estabilización, estimación relativa con Fibonacci, diseño de tareas pequeñas, ATDD/TDD con pruebas protegidas y holdout, gobierno de agentes con controles en capas, verificación independiente, aceptación humana y mejora continua del harness. No prescribe lenguajes, frameworks, proveedores de modelos, herramientas de seguimiento ni una arquitectura de software universal.

## Fuentes principales

- Simon Willison — [Agentic Engineering Patterns](https://simonwillison.net/guides/agentic-engineering-patterns/)
- Kent Beck — [Augmented Coding: Beyond the Vibes](https://kentbeck.com/summaries/augmented-coding-beyond-the-vibes/)
- Alonso, Yovine y Braberman — TDAD (arXiv:2603.17973), resumido en [TDAD and the testing revolution](https://codex.danielvaughan.com/premium-pdfs/04-tdad-and-the-testing-revolution.pdf)
- Birgitta Böckeler — [Understanding Spec-Driven-Development: Kiro, spec-kit, and Tessl](https://www.martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)
- Anthropic — [Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)

La justificación completa de la versión 1.1.0 está en [`docs/rfc/RFC-001-aes-1.1.0.md`](docs/rfc/RFC-001-aes-1.1.0.md). La de 1.2.0, con la evidencia del experimento [aes-sandbox-gastos](https://github.com/KeylorBrenes/aes-sandbox-gastos), está en [`docs/rfc/RFC-002-aes-1.2.0.md`](docs/rfc/RFC-002-aes-1.2.0.md).
