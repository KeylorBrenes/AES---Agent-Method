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

## 4. Integración

Cada cambio debe integrarse mediante el mecanismo del proyecto (pull request, merge request o equivalente). Se debe revisar:

- alcance del diff;
- conflictos y compatibilidad;
- pruebas y CI;
- migraciones y rollback cuando aplique;
- configuración y secretos;
- documentación y observabilidad necesarias.

No se deben integrar cambios solo porque un agente terminó su tarea.

## 5. Liberación

La liberación sigue el perfil del proyecto y debe considerar, cuando aplique:

- versión y notas de cambio;
- migraciones y plan de recuperación;
- configuración por entorno;
- monitoreo y alertas;
- estrategia de rollback o mitigación;
- aprobación humana para cambios de riesgo alto.

La aceptación de una Historia de Usuario no implica automáticamente autorización para desplegar a producción.
