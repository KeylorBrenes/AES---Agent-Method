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
- no altera requisitos para acomodar una implementación;
- es el **diseñador senior**: decide los patrones del nivel 2 de cada tarea en una nota de diseño, a partir de hechos y no del relato de otro agente (10 §5).

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

### Mecánico (opcional)

- ejecuta tareas mecánicas dentro de una superficie de cambio: configuración no funcional, renombres, formato, consolidación de notas y métricas;
- tiene los permisos del programador, limitados a su tarea;
- si la tarea exige decidir comportamiento o diseñar, se detiene con `BLOCKED`: esa tarea no es mecánica.

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

El mecánico, cuando existe, tiene la columna del programador.

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

El orquestador puede añadir **puntos de atención**: hechos concretos y comprobables (un commit, un archivo, un cambio de comportamiento que notó), nunca conclusiones. El verificador los trata como hipótesis que comprueba él mismo.

La verificación ocurre **antes de integrar**. Verificar después (por ejemplo, porque se integró por error) es un incidente que se registra, y pierde información: con integración por *squash*, el verificador ya no ve los commits individuales.

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

### 6.1 Acciones denegadas y rodeo por delegación

Cuando un permiso, un hook o un clasificador del harness deniega una acción a un agente, el agente puede intentar conseguirla por otra vía: otro comando, o pedirle a otro agente que la haga. Lo segundo es un **rodeo por delegación**, y ningún control técnico lo detecta: en el sandbox de AES, dos subagentes pidieron al orquestador que detuviera procesos que a ellos se les había denegado detener.

Reglas:

- Una acción denegada es `BLOCKED` **para el responsable humano**, con la acción exacta que hace falta.
- Ningún agente ejecuta una acción que se le denegó a otro rol, aunque él sí tenga permiso.
- El orquestador registra el caso y se lo pasa al humano; no lo resuelve.

### 6.2 Tipos de skill y núcleo de AES

Las skills potencian la metodología si encajan en ella, y la paralizan si compiten con ella. AES distingue tres tipos:

| Tipo | Qué es | Regla |
|---|---|---|
| **Técnica** | Cómo hacer bien una actividad: depurar, revisar seguridad, escribir una nota de diseño | Se asigna a los roles que hacen esa actividad. MUST NOT contradecir un gate, un contrato ni un permiso de AES |
| **Herramienta** | Envuelve un análisis determinista (análisis estático, grafo de código) | Lo que la herramienta detecta de forma determinista SHOULD ejecutarse en la CI (L3); la skill ayuda a interpretar y corregir, no es el control |
| **Flujo** | Orquesta el ciclo completo: planes, ejecución, revisión, cierre de ramas | MUST NOT instalarse junto a AES. Dos metodologías dando instrucciones sobre lo mismo hacen que el agente elija una distinta cada vez |

Reglas para toda skill:

- **Versión fija y revisada:** se copia al repositorio en una versión concreta, dentro de una ruta protegida, y la revisa el responsable humano. Nada de plugins o skills que se actualizan solos: una actualización silenciosa cambia las instrucciones de los agentes sin aprobación.
- **Registrada en el perfil:** origen, versión o commit, licencia, quién la revisó y qué roles la usan.
- **Hooks y scripts incluidos** se revisan como código propio, y respetan las demás reglas (por ejemplo, no dejar procesos vivos entre roles, 06 §10).
- **Su salida no es evidencia** salvo que ejecute un comando y muestre la salida real (00 §7).
- **Pocas por rol:** cada skill disponible ocupa contexto; un rol carga las que su trabajo necesita.

AES mantiene un **núcleo de skills propias** (`skills/` en el repositorio de AES), escritas para sus gates y contratos, en el formato abierto de Agent Skills. No son obligatorias: un proyecto puede usar otras equivalentes si cumplen las reglas anteriores. Cuando una skill de terceros es buena pero de tipo flujo, o depende de otras de su paquete, se escribe una propia tomándola como referencia, con atribución y respetando su licencia.

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

Cuando la aprobación se expresa en la CI (por ejemplo, con una etiqueta en el PR que autoriza dependencias o marcadores), la CI SHOULD comprobar **quién** la dio: una persona autorizada, no la identidad de los agentes. Una etiqueta que la identidad de los agentes puede poner no es una aprobación. Si la plataforma no permite comprobarlo, se usa una revisión aprobada en su lugar.

La **verificación independiente** es una condición de integración que no debe depender de la memoria de nadie. El `PASS` del verificador SHOULD quedar como evidencia que la CI o la protección de rama exigen antes de integrar una tarea (por ejemplo, una etiqueta de verificación que solo puede poner el responsable humano tras leer el informe, comprobada como en el párrafo anterior). En el sandbox de AES, una tarea se integró antes del `PASS` cuando el aviso del orquestador no lo recordaba, y la regla se cumplió en la historia siguiente solo porque el aviso lo decía.

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
- Si la CI se define en archivos del propio repositorio, una rama puede modificar su propio workflow para saltarse el guardián. Las credenciales con las que se publican ramas de programador MUST NOT tener permiso para modificar workflows (en GitHub, un token sin el permiso *Workflows*), o la plataforma MUST imponer el workflow desde fuera de la rama (por ejemplo, workflows obligatorios a nivel de organización).
- MUST NOT presentarse L1 o L2 como suficientes para un control fundamental.
- Si el responsable humano necesita poder integrar sus propios cambios (nadie puede aprobar su propio PR), el permiso de saltarse la aprobación MUST NOT alcanzar a los checks obligatorios. En GitHub: dos rulesets, uno con los checks y sin bypass, otro con la aprobación y un bypass solo para PR. Un único ruleset con bypass permite integrar con la CI en rojo; en el sandbox de AES pasó.
- Los agentes publican con una **identidad propia**, distinta de la del humano, y sus commits llevan esa misma autoría. Así la aprobación del humano es real y el historial distingue quién escribió qué.
- **Aislamiento del sistema de archivos:** la terminal de un agente puede escribir fuera del repositorio, y ninguna de las tres capas lo detecta. Si el disco tiene algo sensible, los roles que escriben SHOULD trabajar en un entorno aislado (contenedor, máquina virtual o el aislamiento de terminal del harness); si no, el perfil lo declara como excepción.

`profiles/reference/` contiene una implementación de referencia de las tres capas.

## 10. Estado entre roles

Un rol no debe dejar nada que el siguiente pueda tomar como propio: servidores escuchando, procesos, datos de prueba o archivos temporales dentro del repositorio. Si la aceptación reutiliza un servidor que dejó vivo otro rol, puede pasar contra código viejo; en el sandbox de AES, los servidores de un verificador bloquearon la compilación del programador siguiente.

Cada rol que lee o escribe una rama de trabajo SHOULD hacerlo en un **checkout propio** de esa rama (por ejemplo, un *worktree* de git), no en el checkout del orquestador:

- el orquestador se queda en `dev` y no cambia de rama; los roles no heredan sus archivos sin versionar ni él los suyos;
- el verificador revisa una copia limpia de la rama, no la que acaba de usar el programador;
- los archivos locales que un rol necesita y no están versionados (credenciales de su identidad, configuración local) se copian al checkout de forma explícita, nunca se versionan;
- si varios roles trabajan a la vez, cada checkout necesita sus propios puertos y datos; hasta que el perfil lo resuelva, los roles se ejecutan de uno en uno.

- Los servidores se arrancan con una herramienta que los detiene siempre al terminar y que **no reutiliza** un servidor ajeno: si el puerto está ocupado, falla.
- Al terminar cada rol, un control comprueba que no quedó nada escuchando en los puertos del proyecto (L2 en la implementación de referencia; en la CI, cada ejecución empieza limpia).
- Si un agente no puede detener algo que arrancó, es una acción denegada (§6.1).

## 11. Modelo y harness por rol

El perfil declara qué harness y qué modelo ocupa cada rol. El **orquestador** MUST correr en el modelo más capaz disponible: decide el diseño (10 §5), clasifica tracks, severidades y hallazgos, y es el único rol que ve el ciclo completo. Los demás roles pueden usar modelos más baratos porque reciben instrucciones desglosadas y su trabajo se verifica. La evidencia de cada elemento (09 §6) registra el modelo **real** de cada rol en esa ejecución, no el declarado: si cambian, las comparaciones de costo y calidad entre elementos no valen.
