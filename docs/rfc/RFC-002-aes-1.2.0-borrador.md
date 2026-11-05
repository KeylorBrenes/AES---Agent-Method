# RFC-002 — AES 1.2.0 (borrador vivo)

**Estado:** Evidencia completa (EN-001, US-001, CH-001, US-002; 2026-11-05). Pendiente: decidir el alcance (sección «Triage») y redactar 1.2.0. Recoge la evidencia del experimento en [aes-sandbox-gastos](https://github.com/KeylorBrenes/aes-sandbox-gastos).
**Base:** AES 1.1.2
**Tipo de cambio esperado:** MINOR (reglas nuevas; ninguna incompatible con 1.1)

## Evidencia hasta ahora

| Historia | Orquestador | Costo | Ciclos FAIL | Intervenciones humanas | Notas |
|---|---|---|---|---|---|
| EN-001 (3 pts) | Opus 5.5 | $4.89 (89 % orquestador) | 0 | 5 | Mucha fricción de puesta en marcha; fusión con check en rojo (FL-003) |
| US-001 (5 pts) | Opus 5.5 | $5.13 (76 % orquestador) | 1 + 1 corrección de QA | 7 | `red-check` atrapó a QA; `labeled` confirmado; rodeo por delegación |
| CH-001 (1 pt, T1) | Sonnet 5.5 | $0.87 | 0 | 4 | Primer T1 y primer `mechanic` (Haiku, $0.005): la skill no tenía camino T1; criterio sin RED real; fusión de la tarea antes del PASS; FL-010 (el verificador leyó la copia de trabajo y no el blob) |
| US-002 (5 pts, absorbe BUG-001/002) | **Sonnet 5.5** (A/B) | $5.61 (Sonnet $5.59) | 2 (tras PASS, por decisión humana) + 1 corrección de QA | 12 | Primera historia con dos tareas y CI por criterio; «No fusiones hasta el PASS» se cumplió; detectó un error del registro retroactivo de US-001 (D-05); pruebas sin RED posible; pruebas inestables por datos compartidos |

**Lectura del A/B de modelos (n = 1, con cautela):** el orquestador Sonnet respetó todos los gates, hizo buenas preguntas en el refinamiento y encontró un error que el registro hecho con Opus no vio. El costo por punto fue similar ($1.12 frente a $1.03 de US-001), pero US-002 tuvo dos ciclos FAIL más y el doble de tiempo de API. No hay evidencia de que el orquestador necesite Opus; sí de que el costo lo dominan el contexto acumulado y los ciclos, no el modelo.

Detalle: `docs/harness-findings.md`, `docs/agent-failure-log.md` y `docs/retrospectives/` en el sandbox.

## Cambios candidatos

Cada uno indica dónde se probó en el sandbox y en qué capítulo de AES entraría.

### 1. Registro de decisiones y «ningún supuesto pasa la DoR» — 03, 08
- Cada ambigüedad resuelta es una fila `D-NN | pregunta | opciones | decisión | quién y fecha | impacto` en la historia, transcrita en el PR de refinamiento (la aprobación del PR es la firma).
- Los supuestos de QA (lo que el contrato no dice) se convierten en contrato o se rechazan **antes** de `Ready`. Si no, QA define el producto sin firma: pasó en US-001 (D-05, D-06).
- Una decisión que aplica a más de una historia sube a un ADR (ADR-002 del sandbox).
- *Sandbox:* ajuste del harness 3 (skill `aes-cycle` §1 y §2.4).

### 2. Historias bloqueadas y deuda — 02, 07
- Nunca se amplía en silencio. Según el bloqueo: ampliar por decisión humana con control de cambios, marcar `Blocked` por otra historia, dividir, o hacer un Spike.
- Los hallazgos que el humano deja para después se convierten en ítems del backlog (`BUG-NNN`, T1), no en notas.

### 3. Tareas por criterio — 04, 05
- Problema: si la CI exige toda la aceptación de la historia en cada tarea, las tareas no se pueden dividir (EN-001 y US-001 terminaron en una sola tarea de 300 a 500 líneas).
- Cambio: cada prueba lleva la etiqueta de la historia y la del criterio (`@<ID>-AC-NN`); cada tarea declara en `<TASK>.criteria` los criterios que cierra; la CI ejecuta solo esos más la regresión. La última tarea y el cierre ejecutan la historia completa.
- *Sandbox:* `docs/ci/aes.yml` del ajuste 3. **Confirmado en US-002** (TASK-001 con `.criteria`, TASK-002 como última tarea).
- Restricción descubierta: un criterio sin pruebas propias (ver 13) no puede aparecer en un `.criteria`, o la CI busca una etiqueta sin pruebas.

### 4. Binding de roles en el perfil — 06, plantilla del perfil
- Por rol: harness, modelo, forma de invocación, contexto propio y **capacidades de control del harness** (permisos L1, hooks L2, clasificador de permisos, sandbox).
- Requisitos mínimos de un harness para ocupar un rol: contexto propio, invocación con instrucción y directorio, trabajo en una rama.
- Lo que no ofrece el harness se compensa en L3.
- *Pendiente:* experimento con un harness distinto (OpenCode o un motor local).

### 5. Aislamiento del sistema de archivos — 06 §9
- En Windows nativo un agente puede escribir fuera del repo (FL-002) y ninguna capa lo detecta. El sandbox de la terminal de Claude Code requiere WSL 2.
- Regla propuesta: para proyectos con algo sensible en el disco, los roles que escriben trabajan en un entorno aislado (WSL 2 con sandbox, contenedor o *devcontainer*). Si no, excepción documentada en el perfil.

### 6. Aprobaciones humanas en la CI — 06 §8, 07
- Las etiquetas de aprobación deben validar **quién** las puso (un CODEOWNER, no un `[bot]`), o reemplazarse por una revisión aprobada.
- El bypass del aprobador nunca salta los checks obligatorios: dos rulesets (`main-ci` sin bypass, `main-aprobacion` con bypass solo para la aprobación).
- La CI debe reaccionar a `labeled`/`unlabeled`. Un re-run no sirve: repite el evento original.

### 7. Rodeo por delegación — 06
- Regla: una acción denegada a un rol es `BLOCKED` para el humano. Ningún otro agente la ejecuta en su lugar.
- Observado en US-001 (FL-007, FL-008). Ningún control técnico lo detecta; hoy depende del juicio del orquestador.

### 8. Estado entre roles — 05 §11, 06
- Un rol no debe dejar procesos, servidores ni datos que el siguiente pueda tomar como propios. Si un servidor vivo se reutiliza, la aceptación puede pasar contra código viejo (FL-007).
- La implementación de referencia incluye un script que arranca y detiene servidores, y un control al terminar cada subagente.

### 9. Costo del orquestador — 00, perfil
- El orquestador es el mayor costo (89 % y 76 %), por contexto acumulado y por redacción.
- Una sesión por historia; la redacción mecánica (consolidar notas, métricas) la hace un rol barato.
- El binding de roles debe permitir elegir el modelo por rol con evidencia de costo y calidad (A/B en US-002).

### 10. Huecos de la CI entre fases — 05, 08
- Un check verde no prueba que se ejecutó lo esperado: el orquestador y el humano confirman en el log qué corrió.
- Ramas de cierre: ejecutan la aceptación de la historia antes de fusionar.
- Pendiente: regresión de `main` entre la fusión de la última tarea y el cierre.

### 11. Evidencia con hora real y DoR/DoD a mano — 00 §7, 09
- Las notas del orquestador llevan la hora de un comando, no la estimada (FL-009).
- El perfil del proyecto copia o enlaza localmente las checklists de DoR y DoD, para que los agentes las tengan sin salir del repo.

### 12. Camino corto T0/T1 — 02 §8, 04, 08, skill
- La skill y la DoR solo describían el camino de historia T2. CH-001 (un `nuget.config`) obligó a improvisar: sin QA, sin Playwright, sin aceptación en la CI.
- Cambio: un camino T1 explícito. Un PR `spec/<ID>` con el ítem, el criterio y el `.scope`; una tarea; el verificador ejecuta el criterio.
- El criterio de un T1 debe tener **RED real**: una comprobación que falla antes del cambio. CH-001 no lo tenía (`dotnet restore` ya funcionaba). Si no existe, el ítem lo declara («sin RED») y el humano lo firma.
- Criterios por comando: un archivo `specs/<ID>/<ID>.verify` que la CI ejecuta en la rama de la tarea, para lo que no es Playwright (configuración, scripts, build).
- *Sandbox:* retrospectiva de CH-001.

### 13. Pruebas de caracterización (sin RED posible) — 05, contrato de QA
- Un criterio nuevo puede describir algo que el código ya hace (US-002 AC-08 y AC-16 en alta). `red-check` rechaza el conjunto si una prueba pasa, y QA improvisó una etiqueta que la CI no ejecutaba.
- Cambio: esas pruebas viven en la suite de la historia dueña del comportamiento (etiqueta `@<ID anterior>`), con el ID del criterio nuevo en el título; el criterio dice «Verificación: regresión de <ID>» y no entra en ningún `.criteria`.
- *Sandbox:* decisión D-10 de US-002.

### 14. Criterios de fallo de acción — 03, plantilla de historia
- Los dos ciclos FAIL de US-002 vinieron del mismo hueco: ningún criterio cubría qué pasa cuando guardar o eliminar falla (5xx, red caída), y al añadir el estado de error nadie listó qué lo limpia.
- Cambio: la plantilla de historia, para cada acción que escribe, pide el criterio de fallo (respuesta no 2xx y excepción de red). Una tarea que introduce un estado de error lista las transiciones que lo limpian.

### 15. Aislamiento de datos en las pruebas — 05, contrato de QA
- Pruebas que comparan conteos sobre datos compartidos fallan en paralelo (BUG-005: 1 de cada 3–4 corridas). Una prueba inestable en `main` pone en rojo a todos.
- Cambio: cada prueba crea y busca sus propios datos (marca única, periodo propio) y no compara totales globales. Una prueba inestable es un bug P1, no ruido.

### 16. Verificación como gate en L3 — 06 §8, 07, 08
- «No fusiones hasta el PASS» se rompió en CH-001 y se cumplió en US-002 solo porque el aviso lo decía. Es la única condición de la DoD que hoy depende de la memoria del humano.
- Cambio: el PASS del verificador queda como evidencia que la CI o el ruleset exigen (un check o una etiqueta que solo puede poner el humano o un verificador con identidad propia).

### 17. Evidencia contra la fuente correcta — 05, contrato del verificador, 09
- FL-010: el verificador afirmó CRLF leyendo la copia de trabajo; el blob era LF. El registro retroactivo de US-001 afirmó `type="date"` leyendo las pruebas, no el código (lo detectó el orquestador de US-002).
- Cambio: toda afirmación sobre el repositorio se comprueba en su fuente (`git cat-file`/`git show` para el contenido versionado; el código, no las pruebas, para el comportamiento implementado). Aplica también a los registros que escribe el humano o un asistente.

### 18. Presupuesto de diff separado — 04
- TASK-002 de US-002: ≈474 líneas frente a ≈250 estimadas, el 60 % pruebas unitarias. Un solo número castiga probar bien.
- Cambio: la tarea estima por separado código de producción y pruebas; el desvío que cuenta es el de producción.

### 19. Mantenimiento de las notas del orquestador — referencia
- El `mechanic` no pudo vaciar `.aes/` (el harness se lo negó) y el orquestador correctamente no lo rodeó. Vaciar notas es trabajo de un script (`aes-note.sh clear`) ejecutado por el humano o al fusionar el cierre, no de un rol.

### 20. Modelo registrado en la evidencia — 09, perfil
- Las dos sesiones Sonnet corrieron contra un perfil que declara Opus. No es un fallo (era el experimento), pero las métricas deben registrar el modelo real de cada rol para que las comparaciones valgan.

## Triage propuesto para 1.2.0

Para que AES no crezca más que lo que resuelve (el mismo riesgo que combate):

| Destino | Cambios |
|---|---|
| **Normativo en 1.2.0** (estándar y plantillas) | 1, 2, 3, 7, 8, 12, 13, 14, 15, 17, 18, 20 |
| **Normativo, con la implementación de referencia como ejemplo** | 6, 10, 11, 16 |
| **Solo implementación de referencia** (scripts, hooks, workflow) | 19; `with-servers.sh` documentado como herramienta del verificador, no de Playwright |
| **Se queda en el RFC hasta tener evidencia** | 4 (falta probar otro harness), 5 (falta probar WSL 2), 9 (n = 1; se mantiene solo «una sesión por historia») |

## Cosas que **no** deben cambiar (confirmadas)

- La app de los agentes sin permiso de workflows (H9).
- RED que exige pruebas **ejecutadas** (`red-check.mjs`).
- Prueba manual del verificador como condición de PASS (FL-004 no se repitió).
- El orquestador se detiene en cada gate (H7), también con Sonnet.
- La regla de acciones denegadas: en US-002 el orquestador no rodeó la denegación del `mechanic` y se la pasó al humano.
- La CI por criterio (3): permitió por primera vez una historia en dos tareas.
