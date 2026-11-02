# 06 — Gobierno de agentes y permisos

## 1. Objetivo

Separar responsabilidades, limitar el contexto y restringir las acciones de cada agente para reducir desviaciones, conflictos, filtraciones y autoaprobación.

## 2. Roles base

### Responsable humano del producto

- aprueba visión, prioridades y criterios de producto;
- resuelve ambigüedades materiales;
- aprueba cambios materiales de alcance, arquitectura transversal, seguridad y decisiones irreversibles;
- acepta el producto/funcionalidad según el perfil del proyecto.

### Orquestador

- mantiene el estado del backlog y del ciclo;
- asigna agentes y les entrega contexto mínimo suficiente;
- verifica que la tarea cumple DoR;
- controla dependencias, límites y gates;
- agrega evidencias y comunica bloqueos;
- no altera requisitos para acomodar una implementación.

### Arquitecto

- inspecciona arquitectura actual;
- identifica impactos, alternativas y riesgos;
- propone cambios y ADRs;
- no impone cambios materiales sin aprobación.

### QA / Diseñador de pruebas

- deriva escenarios desde criterios aprobados;
- crea y mantiene la suite protegida en un espacio/flujo autorizado;
- comprueba trazabilidad y casos negativos;
- no implementa la funcionalidad que está definiendo como aceptación.

### Programador

- implementa tareas asignadas;
- añade pruebas técnicas permitidas;
- no modifica contratos de aceptación ni aprueba su trabajo;
- reporta supuestos, desviaciones y bloqueos.

### Verificador

- inspecciona la especificación, el diff y las evidencias;
- ejecuta o revisa pruebas según permisos;
- busca incumplimientos, regresiones, riesgos y sobreingeniería;
- es de solo lectura respecto al código bajo revisión;
- no cambia el alcance ni corrige silenciosamente el trabajo.

## 3. Matriz base de permisos

La aplicación exacta se define en el perfil, pero la intención no debe cambiar:

| Recurso/acción | Orquestador | Arquitecto | QA | Programador | Verificador |
|---|---|---|---|---|---|
| Leer repositorio | Sí | Sí | Sí | Sí | Sí |
| Proponer requisitos | Sí | Consulta | Consulta | No | No |
| Aprobar alcance de producto | No, recomienda | No | No | No | No |
| Proponer ADR | Sí | Sí | No | Puede sugerir | Puede señalar |
| Aprobar ADR reservado | No | No | No | No | No |
| Escribir pruebas de aceptación protegidas | No, coordina | No | Sí, flujo autorizado | No | No |
| Modificar código de producción | Según necesidad/configuración | No por defecto | No | Sí, dentro de tarea | No |
| Modificar pruebas unitarias/integración | No por defecto | No | Puede revisar | Sí, dentro de tarea | No |
| Modificar CI/protecciones | No sin autorización | No | No | No | No |
| Ejecutar pruebas | Sí | Sí | Sí | Sí | Sí |
| Aprobar su propio trabajo | No | No | No | No | No |
| Emitir informe de verificación | No sustituye | Puede aportar | Puede aportar | No | Sí |

## 4. Aislamiento del verificador

El verificador debe iniciar una ejecución separada y recibir directamente:

- petición original relevante;
- Historia de Usuario aprobada y criterios de aceptación;
- ADRs/contratos aplicables;
- diff real y commit/branch inspeccionados;
- resultados originales de CI y pruebas;
- instrucciones de verificación.

No debe recibir como fuente de verdad el razonamiento privado, la autoevaluación ni el resumen promocional del programador. Puede leer el código y los artefactos necesarios para comprobar el resultado.

La independencia depende principalmente de la separación de permisos, contexto y evidencia. Usar otro proveedor/modelo puede aportar diversidad, pero no sustituye esos controles.

## 5. Contexto mínimo suficiente

El orquestador debe entregar información relevante, no todo el historial del chat o el repositorio indiscriminadamente. El paquete suele incluir: tarea, historia, criterios relacionados, arquitectura/ADRs pertinentes, contratos y convenciones, rutas relevantes y comandos de validación.

Los agentes deben indicar qué información falta. No deben rellenar vacíos inventando APIs, estructuras o reglas.

## 6. Herramientas, MCP, skills y hooks

- **Harness:** ejecuta el ciclo del agente y controla contexto/herramientas.
- **MCP:** expone herramientas o recursos externos.
- **Skills:** instrucciones/procedimientos reutilizables para un agente.
- **Hooks:** automatizan acciones ante eventos definidos.
- **CLI/API:** permiten delegar a otro proceso o servicio.

El perfil del proyecto define implementaciones concretas. Una skill no concede permisos. Un MCP no debe exponer más privilegios de los necesarios. Los hooks no sustituyen CI ni revisión.

## 7. Secretos y entornos

Los agentes no deben imprimir, copiar a reportes ni incluir en commits secretos, credenciales, tokens, datos personales reales o archivos de entorno. Los entornos de prueba deben usar datos sintéticos o anonimizados cuando sea posible. Los agentes reciben credenciales solo si su tarea las necesita y con privilegio mínimo.

## 8. Aprobaciones humanas obligatorias

Requieren aprobación humana previa:

- cambio material de visión, alcance o comportamiento de producto;
- decisión arquitectónica transversal o difícil de revertir;
- cambio en autenticación, autorización, seguridad o manejo de datos sensibles;
- migración destructiva o acción irreversible sobre datos;
- coste externo significativo o nuevo servicio de pago;
- cambio de políticas de permisos, CI o suite protegida;
- excepción a un control fundamental;
- aceptación final de una funcionalidad/producto cuando el perfil lo requiera.

Los detalles rutinarios, locales y reversibles pueden delegarse si respetan la arquitectura y las convenciones.
