# US-[NNN] — [Título orientado al resultado]

[También sirve para Enablers (EN-NNN). Para defectos, chores y lotes de estabilización usa `defect.md` y `stabilization-batch.md`.]

- **Epic:** EPIC-[NNN]
- **Track:** T2 / T3
- **Estado:** Draft / Ready / In Progress / In Review / Blocked / Ready for Acceptance / Accepted / Rejected / Deferred
- **Prioridad:** P0 / P1 / P2 / P3
- **Story Points:** 1 / 2 / 3 / 5 / 8 / 13
- **Riesgo:** Low / Medium / High / Critical
- **Aprobador de producto:**

## Historia
Como [actor], quiero [capacidad], para [beneficio].

## Contexto y reglas

## Alcance incluido

## Fuera de alcance
[Obligatorio y no vacío en T2/T3.]

## Criterios de aceptación
| ID | Dado | Cuando | Entonces | Verificación / prueba |
|---|---|---|---|---|
| AC-01 | | | | Aceptación `@US-[NNN]-AC-01` |
| AC-02 | | | | Regresión de US-[MMM] (caracterización: el comportamiento ya existe, 05 §2.4) |

[Cada acción que escribe (guardar, editar, eliminar, enviar) tiene un criterio de fallo: qué ve el usuario si la respuesta no es exitosa y si la red falla, y qué lo limpia (03 §3).]

## Casos negativos y límites relevantes

## Contrato de interfaz
[Punto de entrada observable contra el que se escriben las pruebas de aceptación. Omitir solo si la historia no toca ninguna frontera observable.]

| Tipo | Definición |
|---|---|
| API / CLI / UI / librería | [p. ej. `GET /api/notifications` → 200 `{items:[{id, title, read, createdAt}]}`; 401 sin sesión] |

## Dependencias y contratos

## ADRs aplicables

## Decisiones
[Cada ambigüedad resuelta y cada supuesto de QA convertido en contrato (03 §8). Entra en el mismo PR que la usa. Ningún supuesto queda abierto al pasar a `Ready`.]

| ID | Pregunta | Opciones | Decisión | Quién y fecha | Impacto |
|---|---|---|---|---|---|
| D-01 | | | | | AC nuevo/modificado, contrato, ADR o «ninguno» |

## Supuestos e incertidumbres
[Solo los que no afectan el producto (03 §5). Los que sí, van a «Decisiones».]

## Estrategia de pruebas
- Aceptación visible:
- Aceptación holdout (obligatoria en T3):
- RED confirmado (fecha/commit/artefacto):
- Unitarias:
- Integración:
- E2E/regresión:
- Prueba manual agéntica:
- Seguridad/no funcionales:

## Tareas
[Divididas por criterios, no por capas. La última tarea no lleva lista de criterios: ejecuta la historia completa.]

| ID | Resultado | Superficie | Criterios que deja en verde | Dependencias | Estado |
|---|---|---|---|---|---|

## Evidencia y revisión
- CI y guardián:
- Informe QA:
- Informe verificador:
- Revisión humana de código (T3):
- Aceptación humana:
- Defectos registrados en el cierre (ID, severidad):

## Historial de cambios
| Fecha | Cambio | Motivo | Aprobador |
|---|---|---|---|
