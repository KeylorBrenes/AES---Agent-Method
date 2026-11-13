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

## Inicio rápido

1. Instalar AES en el proyecto desde una versión fija (tag `vX.Y.Z`): `./scripts/install-aes.sh <proyecto>` copia la implementación de referencia de Claude Code + GitHub (`profiles/reference/claude-code-subagents/`), las skills del núcleo, la DoR/DoD y las plantillas, y anota la versión en `docs/aes/VERSION`. Con `--vendor <carpeta>` copia además una skill de terceros en su versión (por ejemplo, archify); con `--upgrade` actualiza, y con `--check` comprueba. Si el programador es OpenCode, toma de `claude-code-opencode/` la parte de OpenCode.
2. En GitHub, con la implementación de referencia: una vez por cuenta (herramientas para Windows o Linux, sesión de `gh` y GitHub App de los agentes, paso a paso en [su README](profiles/reference/claude-code-subagents/README.md#una-vez-por-cuenta)), crear la GitHub App de los agentes y `~/.aes/app.env`; después, cada proyecto nuevo se pone en marcha con `./scripts/setup-repo.sh <dueño/repo> --create private`, que crea el repositorio, instala AES (paso 1), crea `main` y `dev`, aplica rulesets, etiquetas y variables, y da acceso a la app (README de la referencia, «Puesta en marcha»).
3. **Incepción** (01 §2): el orquestador entrevista al responsable del producto por temas, con preguntas concretas, y produce el brief, el backlog completo pero superficial con Epics y releases, la arquitectura inicial, el ADR del stack y EN-001, en un PR que el humano aprueba (skill `aes-inception`).
4. Implementar EN-001, el esqueleto que camina.
5. Ir release a release. Refinar solo las Historias de Usuario próximas.
6. Mantener `project-profile.md` al día con lo que se decide en cada historia.
7. Para cada historia: aprobar criterios, definir el contrato de interfaz, aprobar las pruebas de aceptación con RED confirmado.
8. Dividir en tareas pequeñas con superficie de cambio y ejecutar el ciclo.
9. No cerrar la historia hasta cumplir la Definition of Done, registrar la aceptación y ejecutar la retrospectiva compuesta.
10. Antes de la historia siguiente, corregir en un lote de estabilización los defectos Críticos, Altos y Medios.

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
