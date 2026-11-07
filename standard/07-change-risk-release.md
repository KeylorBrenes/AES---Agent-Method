# 07 — Cambios, riesgos y liberación

## 1. Control de cambios

Una nueva información puede justificar cambiar una historia o decisión. El cambio se registra; no se reescribe el objetivo silenciosamente.

Un cambio de alcance o criterios después de `Ready` requiere:

1. describir qué cambió y por qué;
2. identificar impactos en arquitectura, tareas, pruebas, estimación y dependencias;
3. actualizar los artefactos afectados;
4. obtener la aprobación correspondiente;
5. volver a ejecutar DoR para la parte afectada.

Correcciones editoriales sin cambio semántico no requieren un ciclo completo.

## 2. Riesgo

Cada historia debe identificar riesgos relevantes. Como mínimo, evaluar si toca:

- autenticación, autorización o límites de confianza;
- datos personales, financieros o sensibles;
- pagos, facturación o proveedores externos;
- migraciones, borrado o integridad de datos;
- APIs o contratos utilizados por otros sistemas;
- concurrencia, rendimiento o disponibilidad;
- despliegue, recuperación o continuidad.

El perfil puede usar niveles `Low`, `Medium`, `High` y `Critical`, con controles definidos. Los elementos High/Critical requieren revisión reforzada y aprobación humana según el tipo de riesgo, y se tratan como track T3 (02 §8): pruebas holdout obligatorias y revisión humana del código de las zonas de riesgo.

## 3. Bloqueos y fallos

Cuando una validación falla, el orquestador detiene el avance del gate afectado, clasifica el fallo y asigna una corrección delimitada. No se continúa marcando como terminado el trabajo dependiente. Los fallos repetidos sobre la misma tarea activan el circuit breaker (04 §9).

Un bloqueo debe incluir: qué falta, por qué bloquea, evidencia disponible, opciones y quién puede resolverlo.

Cuando una historia se bloquea porque necesita algo que no está en su alcance (otra historia, una decisión, una pieza técnica), el alcance **nunca se amplía en silencio**. El responsable humano elige entre:

1. **ampliar** la historia por control de cambios (§1), si lo que falta es pequeño y del mismo resultado;
2. marcarla `Blocked` por el elemento que falta, que pasa delante en el backlog;
3. **dividirla**, entregando ahora la parte que no depende de lo que falta;
4. abrir un **Spike** (01 §7), si lo que falta es conocimiento.

La elección es una decisión registrada en la historia (03 §8).

## 4. Integración

Cada cambio debe integrarse mediante el mecanismo del proyecto (pull request, merge request o equivalente). Se debe revisar:

- alcance del diff;
- conflictos y compatibilidad;
- pruebas y CI;
- migraciones y rollback cuando aplique;
- configuración y secretos;
- documentación y observabilidad necesarias.

No se deben integrar cambios solo porque un agente terminó su tarea.

Una tarea no se integra sin el `PASS` del verificador, aunque la CI esté en verde (06 §8). Antes de añadir commits a la rama de un PR, se comprueba que el PR sigue abierto: publicar en una rama ya integrada y borrada la recrea con trabajo que nadie revisará.

## 5. Liberación

La liberación sigue el perfil del proyecto y el proceso de release (§8), y debe considerar, cuando aplique:

- versión y notas de cambio;
- migraciones y plan de recuperación;
- configuración por entorno;
- monitoreo y alertas;
- estrategia de rollback o mitigación;
- aprobación humana para cambios de riesgo alto.

La aceptación de una Historia de Usuario no implica automáticamente autorización para desplegar a producción.

## 6. Defectos

Los defectos se registran con severidad y se gestionan con la compuerta de estabilización (02 §9): un defecto Crítico detiene todo; uno Alto o Medio impide empezar la historia siguiente; los Menores se acumulan solo hasta el límite del perfil. Los defectos se corrigen en lotes de estabilización, en su propia sesión, sin mezclarse con funcionalidad nueva.

## 7. Ramas: `main` y `dev`

Todo proyecto AES MUST tener dos ramas permanentes y protegidas:

| Rama | Contiene | Recibe |
|---|---|---|
| `main` | Lo liberado: estable, verificado y aceptado como producto | Solo releases desde `dev` (§8) y hotfixes (§9) |
| `dev` | Lo integrado: historias aceptadas, lotes y tareas terminadas, aún sin liberar | Las ramas de trabajo de cada elemento (especificación, pruebas, tareas, cierre) y los back-merges desde `main` (§9) |

Reglas:

- La regla es la misma en proyectos pequeños y grandes. No hay variante «solo `main`» ni *feature flags* como sustituto: un flag es código condicional que un agente puede escribir mal, y revisar que algo queda apagado obliga a leer el código. El aislamiento lo da git.
- `dev` MUST estar siempre en verde, con la misma CI y la misma protección que `main`. Es la base de todo el trabajo nuevo.
- Las ramas de trabajo son **cortas**: nacen de `dev` (o de `main`, si son de un hotfix) y desaparecen al integrarse. No hay ramas permanentes de features ni de bugs: una rama larga se desfasa y vuelve a traer los conflictos que se querían evitar.
- Una épica de muchas historias se construye en `dev` y sale a `main` cuando el responsable humano la libera. `main` nunca recibe una funcionalidad a medias.
- La compuerta de estabilización (02 §9) se evalúa sobre `dev` para empezar historias, y sobre el candidato a release para liberar.

## 8. Release (`dev` → `main`)

Un release es un PR de `dev` a `main`. Es un gate humano propio, distinto de la aceptación de cada historia: aceptar una historia dice que cumple sus criterios; liberar dice que el conjunto se puede usar como producto.

Antes de abrirlo:

- se preparan las notas del release (plantilla `templates/release.md`): qué elementos salen, qué defectos conocidos quedan y cómo se vuelve atrás;
- la compuerta de estabilización está abierta sobre `dev`;
- `main` está contenido en `dev` (§9): todo hotfix previo ya volvió a `dev`.

El PR de release:

- ejecuta la regresión completa de `dev`;
- MUST fallar si `main` tiene commits que `dev` no tiene (en git: `main` no es ancestro de `dev`). Así un hotfix que no volvió a `dev` no puede perderse ni reintroducir el defecto;
- se integra con **merge commit**, no con *squash*. Con *squash*, los commits de `main` dejan de existir en `dev`, la comprobación anterior falla siempre y cada release trae conflictos. El *squash* se reserva para las ramas de trabajo;
- lo aprueba e integra el responsable humano. No hay un periodo mínimo de uso: el responsable usa `dev` todo lo que considere necesario, y su aprobación del PR es la evidencia de que lo hizo.

Después de integrarlo:

- los elementos incluidos pasan a `Released`;
- se hace un back-merge de `main` a `dev` (§9), porque el commit del release solo existe en `main`;
- la versión se marca según el perfil (por ejemplo, con un tag).

## 9. Hotfix y back-merge

Un **hotfix** corrige un defecto de algo que ya está en `main`, sin pasar por lo que está en construcción en `dev`.

- El responsable humano decide la ruta de cada defecto de algo liberado, sea cual sea su severidad: **hotfix** (sale ya, desde `main`) o **`dev`** (sale con el próximo release). La decisión se registra en el defecto (03 §8). El orquestador propone; lo habitual es hotfix para lo Crítico o Alto, pero no es una regla.
- Un hotfix es un elemento T1 (04 §10) cuyas ramas de trabajo nacen de `main` y se integran en `main`. Solo defectos (`BUG-NNN`) pueden ir por esta ruta: ninguna funcionalidad entra a `main` sin pasar por `dev`.
- Su comprobación de reproducción entra a la regresión de `main` al cerrarlo, como la de cualquier elemento.

El **back-merge** lleva `main` a `dev`. MUST hacerse justo después de cada integración en `main` (hotfix o release):

- es un PR de `main` a `dev`, integrado con **merge commit**, para que `dev` tenga exactamente los mismos commits. No se usa *cherry-pick* ni un segundo PR con el mismo arreglo: crean commits distintos con el mismo cambio y conflictos en el release siguiente;
- si hay conflictos, se resuelven en ese PR, con la regresión de `dev` como evidencia;
- la comprobación de reproducción del hotfix llega a `dev` con el back-merge: si `dev` no tuviera el arreglo, su propia CI se pondría roja.
