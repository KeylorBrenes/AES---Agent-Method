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
| Escribir/leer pruebas holdout | Coordina, no lee | No | Sí, flujo autorizado | **No** (ni lectura) | Ejecuta |
| Publicar superficie de cambio de una tarea | Sí, en rama protegida | Consulta | No | No | No |
| Modificar CI/protecciones | No sin autorización | No | No | No | No |
| Modificar `AGENTS.md`, hooks, skills, permisos | Propone; requiere aprobación humana | No | No | No | No |
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

El verificador MUST volver a ejecutar las validaciones en lugar de aceptar las del programador, ejecutar las pruebas holdout cuando existan y realizar la prueba manual agéntica que corresponda al track (05 §11). Además vigila las señales de desvío que Kent Beck describe en *Augmented Coding: Beyond the Vibes*:

1. bucles: código repetitivo o innecesario, o el agente atascado repitiendo intentos;
2. funcionalidad no pedida, aunque parezca el siguiente paso razonable;
3. cualquier indicio de trampa, como desactivar, borrar o debilitar pruebas.

Cualquiera de las tres es motivo suficiente para `FAIL`.

## 5. Contexto mínimo suficiente

El orquestador debe entregar información relevante, no todo el historial del chat o el repositorio indiscriminadamente. El paquete suele incluir: tarea, historia, criterios relacionados, arquitectura/ADRs pertinentes, contratos y convenciones, rutas relevantes y comandos de validación.

Los agentes deben indicar qué información falta. No deben rellenar vacíos inventando APIs, estructuras o reglas.

El contexto entregado SHOULD ser **estructural** (comandos exactos, rutas, superficie de cambio, pruebas afectadas, contratos) y no **procedimental genérico** (04 §2).

### 5.1 Instrucciones persistentes (`AGENTS.md`, `CLAUDE.md` y equivalentes)

- MUST NOT contener instrucciones de proceso genéricas («usa TDD», «escribe código limpio», «ejecuta las pruebas relevantes»). No añaden información y consumen contexto.
- SHOULD ser breves y contener: comandos de build/prueba/lint, rutas prohibidas, restricciones arquitectónicas, convenciones que un linter no detecta y fallos observados del agente.
- SHOULD empezarse tarde y crecer **una entrada por cada error real** que valga la pena registrar (09).
- En repositorios grandes SHOULD apuntar a los archivos relevantes en lugar de copiar su contenido.
- Están en rutas protegidas: el programador no puede modificarlas.

## 6. Herramientas, MCP, skills y hooks

- **Harness:** ejecuta el ciclo del agente y controla contexto/herramientas.
- **MCP:** expone herramientas o recursos externos.
- **Skills:** instrucciones/procedimientos reutilizables para un agente.
- **Hooks:** automatizan acciones ante eventos definidos.
- **CLI/API:** permiten delegar a otro proceso o servicio.

El perfil del proyecto define implementaciones concretas. Una skill no concede permisos. Un MCP no debe exponer más privilegios de los necesarios. Los hooks no sustituyen CI ni revisión.

Skills:

- SHOULD construirse **después** de evaluar al agente en tareas representativas y observar dónde falla, no por anticipado (09).
- MUST instalarse solo desde fuentes confiables. Las de terceros se auditan antes de usarlas: archivos incluidos, scripts, dependencias y cualquier instrucción que conecte con redes externas no confiables.

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

## 9. Modelo de controles en capas

Un permiso del harness no equivale a un control que el agente no puede esquivar. Ejemplo: en OpenCode, el permiso `edit` cubre las herramientas de edición, escritura y parche, pero una terminal permisiva puede escribir el mismo archivo con `sed` o una redirección.

Un control solo se considera **técnico** (principio 8) si el agente **no puede desactivarlo ni esquivarlo desde su propio entorno de ejecución**. AES distingue tres capas:

| Capa | Dónde vive | Qué hace | ¿Puede esquivarla el agente? |
|---|---|---|---|
| **L1 — Harness** | Permisos del harness (por ejemplo `opencode.json`, permisos de Claude Code) | Niega edición de rutas, limita comandos. | Parcialmente (terminal, configuración editable). Es **fricción**, no garantía. |
| **L2 — Hooks** | Hooks del harness (`PreToolUse`, `Stop`, plugins) | Bloquea escrituras a rutas protegidas; impide terminar con pruebas rojas. | Solo si puede editar la configuración de hooks, que debe estar protegida en L1 y L3. |
| **L3 — Fuera del agente** | CI desde ref confiable, protección de rama, CODEOWNERS, montajes de solo lectura, repositorios separados | Ejecuta la suite protegida desde la rama principal; verifica integridad, superficie y marcadores de trampa. | **No.** Es la única capa que cuenta como gate. |

Reglas:

- Los controles fundamentales (protección de la suite de aceptación, independencia de verificación, rutas protegidas, superficie de cambio) MUST existir en L3.
- La configuración del harness, los hooks, la CI y las instrucciones persistentes MUST estar en rutas que el programador no puede editar (L1) y cuya modificación hace fallar la CI (L3).
- El programador SHOULD trabajar en un worktree o contenedor donde la suite holdout no existe y la suite visible está montada en solo lectura.
- MUST NOT presentarse L1 o L2 como suficientes para un control fundamental.

`profiles/reference/` contiene una implementación de referencia de las tres capas.
