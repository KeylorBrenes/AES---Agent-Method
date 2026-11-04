# RFC-002 — AES 1.2.0 (borrador vivo)

**Estado:** Borrador. Recoge la evidencia del experimento en [aes-sandbox-gastos](https://github.com/KeylorBrenes/aes-sandbox-gastos). Se cierra después de la tercera historia (US-002) y entonces se convierte en la propuesta de AES 1.2.0.
**Base:** AES 1.1.2
**Tipo de cambio esperado:** MINOR (reglas nuevas; ninguna incompatible con 1.1)

## Evidencia hasta ahora

| Historia | Orquestador | Costo | Ciclos FAIL | Intervenciones humanas | Notas |
|---|---|---|---|---|---|
| EN-001 (3 pts) | Opus 5.5 | $4.89 (89 % orquestador) | 0 | 5 | Mucha fricción de puesta en marcha; fusión con check en rojo (FL-003) |
| US-001 (5 pts) | Opus 5.5 | $5.13 (76 % orquestador) | 1 + 1 corrección de QA | 7 | `red-check` atrapó a QA; `labeled` confirmado; rodeo por delegación |
| US-002 | **Sonnet** (A/B) | — | — | — | Pendiente |

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
- *Sandbox:* `docs/ci/aes.yml` del ajuste 3 (probado en simulación; pendiente en una historia real).

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

## Cosas que **no** deben cambiar (confirmadas)

- La app de los agentes sin permiso de workflows (H9).
- RED que exige pruebas **ejecutadas** (`red-check.mjs`).
- Prueba manual del verificador como condición de PASS (FL-004 no se repitió).
- El orquestador se detiene en cada gate (H7).
