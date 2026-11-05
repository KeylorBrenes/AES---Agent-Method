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
8. **Seguridad por permisos.** Las restricciones importantes se aplican técnicamente mediante Git, sistema operativo, contenedores, permisos, CI y protección de ramas; no solo mediante prompts. Un control solo cuenta como técnico si el agente no puede desactivarlo ni esquivarlo desde su propio entorno (ver 06 §9, modelo de capas L1/L2/L3).
9. **Simplicidad deliberada.** Se reutiliza lo existente y se evita añadir abstracciones, dependencias, capas o funcionalidades sin necesidad demostrable.
10. **Trazabilidad proporcional al riesgo.** Los cambios importantes deben poder rastrearse desde el requisito hasta la evidencia. No se exige burocracia para cambios triviales.
11. **Transparencia de incertidumbre.** Los agentes deben distinguir hechos comprobados, supuestos, riesgos y aspectos no verificados.
12. **Aprobación humana en decisiones reservadas.** Los agentes pueden recomendar; no pueden apropiarse de decisiones de producto, cambios materiales de alcance, riesgos críticos o aceptación humana.
13. **La prueba de aceptación es la especificación ejecutable.** La prosa explica la intención; la suite de aceptación protegida la hace exigible. Cuando una especificación en prosa y una prueba de aceptación aprobada discrepan, la discrepancia es un defecto de especificación que se resuelve por control de cambios. Ningún agente decide unilateralmente cuál de las dos prevalece.
14. **Evidencia ejecutada, no narrada.** Solo cuenta como evidencia la salida capturada por la CI o por una herramienta que ejecuta y registra el comando. El resumen escrito por un agente es contexto, no evidencia.
15. **Proceso proporcional.** El tamaño del proceso depende del track del cambio (02 §8). Un cambio trivial no recorre el ciclo de una historia de alto riesgo, y un cambio de alto riesgo no se trata como trivial.
16. **Mejora continua del harness.** Los fallos de los agentes se registran y se convierten en controles (09). El mismo error no debe depender de que alguien lo recuerde.
17. **Estabilidad antes que avance.** No se construye funcionalidad nueva sobre defectos conocidos. Los defectos se clasifican por severidad y se corrigen antes de empezar la siguiente historia, salvo los menores (02 §9). Corregir un defecto viejo mientras se construye algo nuevo mezcla dos cambios y produce defectos nuevos.
18. **Cada decisión tiene firma.** Toda ambigüedad que afecta el producto se resuelve con una decisión registrada: quién, cuándo, qué opciones había y qué cambió (03 §8). Lo que nadie decidió explícitamente no es una decisión, aunque una prueba o un agente ya lo haya fijado.

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
- **Mecánico (opcional):** ejecuta cambios mecánicos y acotados (configuración no funcional, renombres, formato, consolidación de notas), sin lógica nueva. Permite asignar ese trabajo a un modelo más barato.
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

Toda afirmación sobre el repositorio o el producto se comprueba **en su fuente**, no en un reflejo de ella:

- el contenido versionado, en lo que está versionado (`git show`, `git cat-file`), no en la copia de trabajo, que puede diferir (por ejemplo, en los fines de línea);
- el comportamiento implementado, en el código o ejecutándolo, no en las pruebas que lo describen ni en el reporte de quien lo implementó;
- lo que se ejecutó en la CI, en el log del run, no en el color del check.

La regla aplica a los agentes y también a los registros que escribe el humano o un asistente: un registro escrito de memoria es un supuesto hasta que se compruebe.

## 8. Revisión humana proporcional

AES no pretende que el responsable humano lea cada línea de código, pero tampoco permite que nadie revise nada. La revisión humana se desplaza **del código a los contratos**: si el humano no va a leer el código, DEBE leer y aprobar las pruebas de aceptación, porque son lo único en lo que el proceso confía sin intermediarios.

| Momento | Qué revisa el humano | T0 | T1 | T2 | T3 |
|---|---|---|---|---|---|
| Antes | Criterios de aceptación y exclusiones | — | ✓ | ✓ | ✓ |
| Antes | Pruebas de aceptación (escenarios y aserciones clave) | — | ✓ | ✓ | ✓ |
| Antes | Contrato de interfaz / ADR | — | — | si cambia | ✓ |
| Antes | Decisiones registradas y supuestos de QA resueltos (03 §8) | — | ✓ | ✓ | ✓ |
| Después, antes de integrar | Informe de verificación y evidencias (salidas, capturas) | — | ✓ | ✓ | ✓ |
| Después | Severidad de los defectos encontrados (02 §9) | si hay | si hay | si hay | si hay |
| Después | Alertas del guardián de CI (superficie, trampas) | si hay | si hay | si hay | ✓ |
| Después | Código | lectura rápida del diff | opcional | solo zonas señaladas | **zonas de riesgo, obligatorio** |
| Después | Demostración o prueba funcional propia | — | — | ✓ | ✓ |

En T3 no existe una forma responsable de omitir la revisión humana del código sensible (autenticación, autorización, datos, pagos, migraciones). El perfil del proyecto puede endurecer esta tabla, nunca relajarla sin excepción documentada.
