# 08 — Definition of Ready y Definition of Done

## 1. Definition of Ready (DoR) — Historia de Usuario

Una historia puede pasar a `Ready` cuando:

- [ ] objetivo, actor y beneficio/resultante están claros;
- [ ] alcance y exclusiones relevantes están definidos;
- [ ] criterios de aceptación son observables y verificables;
- [ ] ambigüedades materiales están resueltas;
- [ ] dependencias y riesgos relevantes están identificados;
- [ ] prioridad y Story Points están asignados;
- [ ] existe estrategia de aceptación y pruebas;
- [ ] decisiones arquitectónicas necesarias están aprobadas;
- [ ] puede dividirse en tareas pequeñas sin inventar requisitos.

Si una casilla no aplica, se puede marcar `N/A` con justificación. No se debe forzar una historia a `Ready` por presión de planificación.

## 2. Definition of Ready — Tarea

Una tarea puede pasar a ejecución cuando:

- [ ] pertenece a una historia/elemento aprobado;
- [ ] tiene un resultado principal concreto;
- [ ] alcance, exclusiones y restricciones están claros;
- [ ] dependencias/contratos se conocen;
- [ ] permisos del agente están definidos;
- [ ] método de validación y condición de finalización están definidos;
- [ ] el contexto necesario está disponible.

## 3. Definition of Done — Tarea

Una tarea está técnicamente terminada cuando:

- [ ] cumple el resultado especificado;
- [ ] el cambio está dentro del alcance;
- [ ] las pruebas pertinentes se añadieron/actualizaron y ejecutaron;
- [ ] lint, tipos y análisis requeridos pasan;
- [ ] se inspeccionó el diff y no hay cambios ajenos;
- [ ] no se introdujeron secretos, artefactos temporales ni dependencias no aprobadas;
- [ ] se entregó el reporte con evidencia y bloqueos conocidos.

La tarea pasa a revisión; el programador no la marca como aceptada.

## 4. Definition of Done — Historia de Usuario

Una historia puede pasar a `Ready for Acceptance` cuando:

- [ ] todas sus tareas están técnicamente terminadas;
- [ ] todos los criterios de aceptación tienen evidencia PASS o una excepción formal aprobada;
- [ ] pruebas unitarias, integración, contrato, E2E y regresión requeridas pasan;
- [ ] controles estáticos y de seguridad aplicables pasan;
- [ ] el verificador independiente emite `PASS`;
- [ ] no quedan defectos críticos ni bloqueantes conocidos;
- [ ] documentación/ADRs afectados están actualizados;
- [ ] el comportamiento existente relevante no sufrió regresiones;
- [ ] el resultado puede probarse en un entorno apropiado.

Después de eso:

- funcionalidades visibles o relevantes para el usuario pasan por aceptación humana según el perfil;
- el responsable humano emite `Accepted` o `Rejected`;
- solo entonces la historia se considera aceptada.

Un resultado `BLOCKED`, `NOT RUN` o una prueba omitida sin justificación no equivale a `PASS`.

## 5. Definition of Done del proyecto

El proyecto puede declararse listo para una liberación cuando se cumplen sus gates de release, seguridad, migración, documentación, recuperación y aprobación definidos en el perfil. No basta con que todas las historias estén en estado `Accepted` si aún existen riesgos de liberación sin resolver.
