# 00 — Gobierno y principios de AES Core

## 1. Propósito

AES define un proceso reproducible para producir software correcto, mantenible y verificable mediante personas y agentes de IA. El objetivo no es maximizar documentos ni velocidad de generación de código: es entregar comportamiento útil, dentro del alcance aprobado, con evidencia suficiente de calidad.

## 2. Principios obligatorios

1. **Valor antes que actividad.** El trabajo se organiza alrededor de resultados para usuarios o necesidades técnicas justificadas, no alrededor de cantidad de código o documentos.
2. **Planificación progresiva.** La visión y los límites arquitectónicos se establecen temprano; el detalle de implementación se agrega cuando el trabajo se aproxima y existe información suficiente.
3. **Una fuente de verdad.** Los requisitos aprobados, criterios de aceptación y decisiones vigentes deben tener una ubicación identificable. Los mensajes del chat no sustituyen los artefactos del proyecto.
4. **Alcance explícito.** Cada Historia de Usuario define lo incluido y, cuando sea relevante, lo excluido. Los agentes NO DEBEN ampliar el alcance por iniciativa propia.
5. **Tareas pequeñas y verificables.** Una tarea debe producir un resultado concreto, tener límites claros y poder comprobarse sin tener que aceptar una gran cantidad de trabajo no relacionado.
6. **Pruebas desde el requisito.** Los criterios de aceptación se definen antes de implementar. Las pruebas técnicas acompañan el desarrollo.
7. **Independencia de verificación.** El agente que implementa no puede aprobar su propio trabajo. La verificación se basa en artefactos y evidencias, no en el informe del implementador.
8. **Seguridad por permisos.** Las restricciones importantes se aplican técnicamente mediante Git, sistema operativo, contenedores, permisos, CI y protección de ramas; no solo mediante prompts.
9. **Simplicidad deliberada.** Se reutiliza lo existente y se evita añadir abstracciones, dependencias, capas o funcionalidades sin necesidad demostrable.
10. **Trazabilidad proporcional al riesgo.** Los cambios importantes deben poder rastrearse desde el requisito hasta la evidencia. No se exige burocracia para cambios triviales.
11. **Transparencia de incertidumbre.** Los agentes deben distinguir hechos comprobados, supuestos, riesgos y aspectos no verificados.
12. **Aprobación humana en decisiones reservadas.** Los agentes pueden recomendar; no pueden apropiarse de decisiones de producto, cambios materiales de alcance, riesgos críticos o aceptación humana.

## 3. Adaptabilidad

AES Core es común entre proyectos. Cada proyecto puede adaptar:

- lenguaje, framework, base de datos y proveedores;
- estructura de carpetas y herramientas de seguimiento;
- comandos de build, lint, análisis y pruebas;
- umbrales de cobertura y controles específicos del stack;
- modelos, harnesses, MCP, skills y herramientas disponibles.

El proyecto NO DEBE debilitar controles de seguridad, independencia de verificación, protección de pruebas de aceptación, trazabilidad de cambios relevantes ni aprobación de decisiones reservadas sin una excepción documentada.

## 4. Excepciones

Una excepción a una regla SHOULD/MUST debe registrar:

- regla afectada;
- motivo y contexto;
- riesgos introducidos;
- mitigación o control compensatorio;
- responsable que la aprobó;
- fecha o condición de expiración, si aplica.

Una excepción no debe presentarse como cumplimiento normal del estándar. Las excepciones a controles fundamentales MUST ser aprobadas por el responsable humano del proyecto.

## 5. Roles y autoridad

Los nombres pueden cambiar según las herramientas, pero las responsabilidades deben mantenerse:

- **Responsable del producto / humano:** define objetivos y prioridades; aprueba cambios materiales de alcance, decisiones reservadas y aceptación del producto.
- **Orquestador:** coordina el proceso, prepara contexto, delega trabajo, mantiene estados y hace cumplir gates. No inventa requisitos ni se autoaprueba.
- **Arquitecto:** analiza estructura y consecuencias técnicas; propone decisiones y ADRs.
- **Diseñador de pruebas / QA:** transforma criterios aprobados en escenarios y pruebas de aceptación; protege su integridad.
- **Programador:** implementa tareas delimitadas y sus pruebas técnicas permitidas.
- **Verificador independiente:** comprueba el resultado contra requisitos y evidencia; no modifica el código bajo revisión.
- **CI y herramientas deterministas:** ejecutan controles repetibles. Sus resultados se conservan como evidencia.

Una persona o modelo puede asumir más de un rol en un proyecto pequeño, pero las funciones de implementación y aprobación/verificación deben permanecer separadas. Si se reutiliza el mismo modelo, la ejecución de verificación debe ser nueva, con contexto separado y permisos de solo lectura.

## 6. Estados de trabajo

Los proyectos DEBERÍAN usar, como mínimo, estados equivalentes a:

- `Draft`: todavía se está definiendo.
- `Ready`: cumple Definition of Ready.
- `In Progress`: implementación activa.
- `In Review`: esperando revisión o verificación.
- `Blocked`: depende de una decisión, recurso o corrección.
- `Ready for Acceptance`: gates técnicos superados; falta aceptación humana cuando aplique.
- `Accepted`: aceptado por la autoridad correspondiente.
- `Rejected`: no aceptado; requiere corrección o replanteamiento.
- `Deferred`: se pospone con motivo.

No se debe usar `Done` como sinónimo de «el agente terminó de escribir código».

## 7. Evidencia y afirmaciones

Un agente MUST NOT afirmar que una prueba pasó si no la ejecutó y no dispone del resultado. Si una prueba no se pudo ejecutar, se reporta como `NOT RUN` o `BLOCKED`, con el motivo. Los resultados deben incluir el comando o procedimiento, entorno relevante y salida resumida cuando sea posible.
