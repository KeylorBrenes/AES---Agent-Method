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

La liberación sigue el perfil del proyecto y debe considerar, cuando aplique:

- versión y notas de cambio;
- migraciones y plan de recuperación;
- configuración por entorno;
- monitoreo y alertas;
- estrategia de rollback o mitigación;
- aprobación humana para cambios de riesgo alto.

La aceptación de una Historia de Usuario no implica automáticamente autorización para desplegar a producción.

## 6. Defectos

Los defectos se registran con severidad y se gestionan con la compuerta de estabilización (02 §9): un defecto Crítico detiene todo; uno Alto o Medio impide empezar la historia siguiente; los Menores se acumulan solo hasta el límite del perfil. Los defectos se corrigen en lotes de estabilización, en su propia sesión, sin mezclarse con funcionalidad nueva.
