# Agentic Engineering Standard — AES Core 1.0.0

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

---

# 01 — Inicio del proyecto y arquitectura

## 1. Objetivo

Establecer una comprensión compartida del producto y una arquitectura suficiente para guiar los incrementos sin diseñar prematuramente todos sus detalles.

## 2. Inicio del proyecto

Antes de implementar funcionalidades, el orquestador DEBE ayudar a crear o localizar:

1. **Project Brief:** problema, usuarios, objetivos, alcance inicial, restricciones y criterios generales de éxito.
2. **Project Profile:** stack, entorno, comandos, convenciones, controles de calidad, agentes y permisos.
3. **Architecture Overview:** contexto, componentes principales, límites, datos e integraciones conocidas.
4. **Backlog inicial:** Epics y riesgos/incertidumbres conocidos; no es necesario detallar todas las historias futuras.
5. **Quality Strategy:** niveles de prueba, CI y controles aplicables.

Si se trabaja sobre un proyecto existente, primero se inspecciona el repositorio y el comportamiento actual. No se asume que la documentación está actualizada ni que la arquitectura deseada coincide con la implementada.

## 3. Contenido mínimo de arquitectura

El documento de arquitectura DEBERÍA cubrir, en proporción al proyecto:

- propósito, límites del sistema y actores externos;
- componentes/módulos y responsabilidades;
- dependencias y dirección de dependencias;
- stack tecnológico y versiones relevantes;
- persistencia, entidades principales y propiedad de los datos;
- autenticación, autorización y límites de confianza;
- integraciones y contratos externos;
- despliegue, configuración y observabilidad, si aplican;
- restricciones no funcionales relevantes: rendimiento, disponibilidad, privacidad, accesibilidad, mantenibilidad y seguridad.

No se exige definir clases, funciones, tablas o endpoints que todavía no se necesitan. El diseño detallado de una historia se realiza durante su refinamiento.

## 4. Decisiones de arquitectura (ADR)

Se DEBERÍA crear un ADR para decisiones con impacto material, difícil reversión o efecto transversal, por ejemplo:

- selección o sustitución de tecnología fundamental;
- límites entre módulos o servicios;
- estrategia de persistencia o migración de datos;
- autenticación/autorización;
- contratos de integración importantes;
- decisiones de escalabilidad, seguridad o despliegue.

Un ADR debe resumir contexto, decisión, alternativas consideradas, consecuencias, riesgos, estado y fecha. No se crean ADRs para elecciones locales triviales.

Los ADRs aceptados se consideran historial de decisiones. Si una decisión cambia, se crea un ADR que la sustituye; no se reescribe el pasado para ocultar el cambio.

## 5. Evolución arquitectónica

La arquitectura es evolutiva. Antes de implementar una historia, el arquitecto/orquestador DEBE identificar si el cambio:

- cabe dentro de los límites existentes;
- cambia un contrato o dependencia;
- introduce una tecnología o dependencia nueva;
- afecta seguridad, datos, rendimiento o despliegue;
- requiere una decisión humana.

Los cambios locales y reversibles pueden documentarse en la tarea o en el historial del cambio. Los cambios transversales requieren ADR y aprobación según el perfil del proyecto.

## 6. Regla contra la sobreingeniería

Un agente NO DEBE crear una abstracción, capa, servicio, microservicio, sistema genérico, framework interno, mecanismo de configuración o dependencia «por si acaso».

Antes de proponerlo, debe demostrar:

1. qué requisito actual lo necesita;
2. por qué la solución existente no basta;
3. qué alternativas más simples se consideraron;
4. qué coste de mantenimiento introduce.

La opción por defecto es la solución más simple que satisface los requisitos aprobados y mantiene los límites arquitectónicos.

## 7. Investigación y spikes

Cuando existe incertidumbre técnica material, se puede crear un `Spike` de investigación. Un Spike tiene pregunta, límite de tiempo/esfuerzo establecido por el proyecto, método de evaluación y resultado esperado (decisión, prototipo desechable o evidencia). No se debe convertir automáticamente un Spike en implementación de producción.

---

# 02 — Backlog y estimación

## 1. Jerarquía

AES utiliza esta jerarquía lógica:

`Product Goal / Vision → Epic → User Story → Task/Subtask → Test/Evidence`

Los defectos (`Bug`), tareas técnicas (`Enabler`) y actividades de investigación (`Spike`) pueden aparecer como tipos de elemento relacionados con el backlog. No deben disfrazarse de historias de usuario si no representan valor de usuario.

## 2. Product Goal y Epics

- El **Product Goal** expresa el resultado general buscado.
- Un **Epic** agrupa una capacidad amplia que debe descomponerse en historias entregables.
- Un Epic puede tener hipótesis, riesgos, métricas y dependencias, pero no necesita tareas detalladas desde el inicio.

## 3. Historias de Usuario

Una Historia de Usuario representa una necesidad/comportamiento con valor identificable para un usuario o actor. Formato recomendado:

> Como [tipo de usuario], quiero [capacidad], para [beneficio].

El formato no es obligatorio para trabajo puramente técnico; en ese caso se declara el resultado técnico y su justificación. Cada historia debe incluir criterios de aceptación verificables y límites de alcance.

## 4. Priorización

La prioridad y la estimación son dimensiones distintas. Cada proyecto DEBERÍA declarar una escala sencilla, por ejemplo `P0` crítica, `P1` alta, `P2` normal y `P3` baja. La prioridad representa orden/valor, no esfuerzo.

La priorización considera valor, urgencia, riesgo, dependencias y coste de demora cuando sean relevantes. Los agentes pueden recomendar prioridades, pero el responsable del producto aprueba cambios significativos.

## 5. Estimación de Historias de Usuario

AES 1.0.0 adopta Story Points relativos usando la secuencia Fibonacci:

`1, 2, 3, 5, 8, 13`

Los puntos expresan una combinación relativa de esfuerzo, complejidad e incertidumbre comparada con otras historias del mismo proyecto. NO representan horas, días, productividad individual ni una promesa de fecha.

Guía orientativa:

- **1:** cambio muy pequeño, conocido y de bajo riesgo.
- **2:** pequeño, con pocas dependencias y comportamiento claro.
- **3:** complejidad moderada, alcance conocido.
- **5:** varias partes o escenarios, pero entendidos.
- **8:** trabajo amplio o con incertidumbre/dependencias importantes; revisar si conviene dividir.
- **13:** demasiado grande o incierto para planificar con confianza; normalmente debe dividirse o investigarse antes.

Si una historia supera 13, no se asigna un número mayor: se divide en historias con valor verificable o se crea un Spike cuando la incertidumbre impide dividirla de forma responsable.

La estimación debe basarse en el alcance aprobado y en referencias históricas del proyecto. No se debe usar para comparar personas, modelos o equipos.

## 6. Tamaño de tareas

Las tareas no necesitan Story Points obligatoriamente en AES 1.0.0. Deben ser pequeñas, observables y verificables. Su tamaño se determina por la claridad del resultado, superficie de cambio, dependencias y facilidad de prueba, no por una duración ficticiamente precisa.

Una tarea SHOULD:

- producir un resultado principal identificable;
- tener un alcance y límites concretos;
- poder implementarse y depurarse sin coordinar muchos cambios independientes;
- tener una forma clara de validación;
- evitar mezclar responsabilidades diferentes;
- ser suficientemente pequeña para entender qué falló si su prueba falla.

Una tarea MUST dividirse si contiene varios resultados independientes, combina responsabilidades no relacionadas, abarca demasiados componentes sin razón, tiene dependencias ocultas o no puede verificarse de forma focalizada.

No se fija un límite universal en horas. Si una tarea parece grande, se divide por resultado verificable, no arbitrariamente en fragmentos que no tienen sentido por sí solos.

## 7. Refinamiento continuo

El backlog es continuo. Solo las historias próximas necesitan cumplir completamente DoR. El resto puede permanecer como Epic, idea o historia preliminar. El refinamiento debe ocurrir antes de comprometer una historia para implementación y cuando aparece nueva información.

No se debe congelar un plan detallado de meses de trabajo si las historias posteriores dependen de descubrimientos aún no realizados.

---

# 03 — Historias de Usuario y aceptación

## 1. Contenido mínimo de una historia

Cada Historia de Usuario refinada DEBE tener:

- identificador estable y título;
- usuario/actor y necesidad, o resultado técnico justificado;
- beneficio/objetivo;
- contexto y reglas relevantes;
- alcance incluido y exclusiones importantes;
- criterios de aceptación observables y verificables;
- prioridad y Story Points;
- dependencias y riesgos relevantes;
- estrategia de pruebas/aceptación;
- estado y responsable de decisión.

No se deben rellenar campos con texto vacío. Un elemento puede permanecer en `Draft` hasta que exista información suficiente.

## 2. Criterios de aceptación

Los criterios deben expresar resultados observables, no detalles internos innecesarios. Deben ser:

- claros y no contradictorios;
- comprobables mediante una acción, resultado o inspección;
- vinculados al objetivo y al alcance;
- específicos sobre permisos, errores y límites cuando sean relevantes;
- independientes de una implementación concreta salvo que exista una restricción técnica aprobada.

Se puede usar Given/When/Then, ejemplos tabulares, casos de prueba o lenguaje natural estructurado. AES no obliga a una sintaxis BDD determinada.

## 3. Casos negativos y límites

Cuando aplique, los criterios DEBERÍAN contemplar:

- entradas inválidas o incompletas;
- ausencia de datos;
- duplicados y conflictos;
- usuarios sin permisos;
- errores de servicios externos;
- estados límite y concurrencia;
- compatibilidad con comportamiento existente;
- accesibilidad, privacidad y seguridad.

No todos los escenarios aplican a todas las historias. QA debe explicar brevemente por qué un escenario de riesgo relevante se omite.

## 4. Fuera de alcance

Las exclusiones son obligatorias cuando existe riesgo razonable de expansión del alcance. Deben nombrar funcionalidades cercanas que el agente podría implementar «por conveniencia» pero que no están aprobadas.

## 5. Ambigüedad y supuestos

Los agentes no deben inventar comportamiento del producto. Deben:

- pedir decisión humana ante ambigüedades que afectan comportamiento visible, datos, seguridad, costes, integraciones, cumplimiento o decisiones irreversibles;
- registrar como supuesto una decisión de bajo riesgo, reversible y coherente con patrones existentes;
- elegir la alternativa más simple y consistente cuando el detalle es local y no cambia el contrato del producto;
- informar el supuesto en el reporte de ejecución.

No se debe interrumpir al usuario por decisiones internas triviales que el estándar ya delega al equipo técnico.

## 6. Trazabilidad

Cada criterio de aceptación debe relacionarse con uno o más escenarios/pruebas o con una justificación explícita de verificación manual. Cada tarea debe referenciar la historia y los criterios que contribuye a satisfacer.

No se considera trazabilidad suficiente una lista de pruebas sin vínculo con los requisitos.

## 7. Cambios en la historia

Una vez que la historia está `Ready`, los cambios de alcance, comportamiento esperado o criterios de aceptación requieren control de cambios. Las correcciones editoriales que no cambian el significado pueden hacerse sin re-aprobación, dejando historial cuando la herramienta lo permita.

---

# 04 — Diseño y ejecución de tareas

## 1. Objetivo de una tarea

Una tarea transforma una parte de una Historia de Usuario o un enabler aprobado en un cambio concreto y comprobable. No es una instrucción abierta como «termina el módulo» o «mejora el código».

## 2. Campos obligatorios

Cada tarea lista para ejecución DEBE especificar:

- ID y título orientado al resultado;
- Historia de Usuario/Enabler relacionado;
- objetivo y resultado esperado;
- alcance incluido y exclusiones relevantes;
- dependencias y contratos que debe respetar;
- zonas/archivos potencialmente afectados, si se conocen;
- restricciones y permisos;
- método de validación;
- condición de finalización.

Los archivos sugeridos son orientación, no permiso para modificar cualquier parte del repositorio.

## 3. Tamaño y divisibilidad

Una tarea es suficientemente pequeña si un agente puede comprender su objetivo, implementarla, inspeccionar el diff y ejecutar su validación sin tener que aceptar varios resultados independientes como un bloque indivisible.

Señales para dividir:

- más de un resultado observable sin dependencia necesaria;
- lógica, interfaz, migración y despliegue agrupados solo por conveniencia;
- múltiples módulos o contratos modificados sin una razón común;
- numerosas condiciones de aceptación que pueden fallar de forma independiente;
- alta incertidumbre técnica;
- imposibilidad de describir una prueba focalizada.

No dividir hasta producir tareas artificiales sin valor o dependientes de detalles especulativos. Mantener cohesión técnica y una secuencia ejecutable.

## 4. Contrato de ejecución

El programador recibe un paquete de contexto acotado: historia aprobada, tarea, criterios relacionados, arquitectura/ADRs pertinentes, contratos de APIs/datos y convenciones del proyecto.

El programador DEBE:

1. inspeccionar el código relevante antes de cambiarlo;
2. describir brevemente el enfoque cuando el cambio no sea trivial;
3. implementar solo el alcance de la tarea;
4. añadir o ajustar pruebas técnicas permitidas;
5. ejecutar las validaciones pertinentes;
6. inspeccionar su propio diff para detectar archivos o cambios ajenos;
7. entregar un reporte con archivos modificados, pruebas ejecutadas, resultados, riesgos y decisiones/supuestos.

El programador NO DEBE:

- modificar criterios aprobados o pruebas de aceptación protegidas;
- alterar CI, permisos, políticas o configuraciones de agentes para facilitar su tarea;
- ocultar, saltar o silenciar pruebas fallidas;
- ampliar el alcance con refactorizaciones no relacionadas;
- añadir dependencias sin justificación y aprobación requerida;
- afirmar que algo funciona sin evidencia de ejecución.

## 5. Dependencias y paralelismo

Las tareas pueden ejecutarse en paralelo solo si sus archivos, contratos y dependencias permiten trabajo independiente. El orquestador debe identificar conflictos de escritura y definir integración.

Se DEBERÍA usar ramas o worktrees separados para agentes concurrentes. No se permite que dos agentes escriban simultáneamente en los mismos archivos sin coordinación explícita.

## 6. Bloqueos

Si el agente descubre una dependencia, contradicción o cambio necesario fuera del alcance, debe detener esa parte, explicar el bloqueo y proponer opciones. No debe resolverlo ampliando unilateralmente la tarea.

## 7. Cierre de tarea

Una tarea puede pasar a revisión cuando:

- el resultado esperado está implementado;
- las pruebas aplicables se ejecutaron;
- el diff está limitado y revisado;
- no quedan cambios temporales o secretos;
- el reporte de ejecución está completo.

El cierre de una tarea no significa que la Historia de Usuario esté aceptada.

---

# 05 — Pruebas y calidad

## 1. Estrategia

AES combina ATDD (Acceptance Test-Driven Development) y TDD (Test-Driven Development), junto con pruebas de integración, extremo a extremo y controles estáticos. La selección depende del riesgo y del tipo de cambio.

## 2. ATDD: antes de implementar la historia

Para cada Historia de Usuario, QA o un rol independiente DEBE:

1. leer la petición y la historia aprobada;
2. derivar escenarios de aceptación desde los criterios;
3. identificar casos positivos, negativos y límites relevantes;
4. mapear cada criterio a una prueba o método de comprobación;
5. revisar que los escenarios prueben comportamiento, no una implementación supuesta;
6. proteger la versión aprobada de las pruebas.

Los escenarios de aceptación deben estar disponibles antes de declarar que la implementación está completa. Cuando sea viable, las pruebas automatizadas se escriben antes de la implementación.

## 3. TDD: durante la implementación

Para lógica nueva o modificada donde sea práctico, el programador SHOULD seguir:

1. **Red:** crear una prueba focalizada que falle por la razón esperada.
2. **Green:** implementar el cambio mínimo para pasarla.
3. **Refactor:** mejorar estructura sin cambiar el comportamiento y manteniendo todas las pruebas verdes.

No se exige TDD mecánico para cambios donde no aporta una prueba útil (por ejemplo, ciertos cambios visuales, documentación o configuración). En esos casos se documenta el método alternativo de verificación.

## 4. Capas de prueba

El perfil del proyecto define herramientas y comandos. En general:

- **Unitarias:** lógica aislada y casos de borde.
- **Integración:** persistencia, servicios, colas, APIs y límites entre componentes.
- **Contrato:** compatibilidad entre consumidores y proveedores.
- **E2E:** flujos de usuario que cruzan capas relevantes.
- **Aceptación:** criterios de la Historia de Usuario.
- **Regresión:** comportamiento existente que podría verse afectado.
- **No funcionales:** seguridad, rendimiento, accesibilidad, resiliencia u otras cualidades según riesgo.

No todas las historias requieren todas las capas. La omisión de una capa relevante debe justificarse.

## 5. Protección de pruebas de aceptación

Las pruebas que expresan criterios de aceptación aprobados constituyen un contrato independiente y DEBEN protegerse técnicamente.

El agente programador:

- puede crear y modificar pruebas unitarias/de integración propias del cambio, dentro del alcance;
- NO puede modificar o borrar la suite de aceptación protegida para conseguir un resultado verde;
- no puede cambiar workflows o configuración de CI que ejecutan esas pruebas.

Los cambios en pruebas protegidas requieren un cambio aprobado del requisito o una corrección de prueba demostrada, revisión independiente y aprobación de un responsable autorizado. La CI debería obtener la suite protegida desde una rama/commit confiable o aplicar un control equivalente (CODEOWNERS, protección de rama, permisos de filesystem, contenedor o repositorio separado).

No basta con confiar en el prompt del programador.

## 6. Verificación de pruebas

Si una prueba falla, el equipo debe clasificar la causa antes de cambiar código o prueba:

- defecto de implementación;
- defecto en la prueba;
- requisito contradictorio o incompleto;
- entorno/configuración;
- dependencia externa.

El agente no debe borrar, deshabilitar, reducir aserciones ni cambiar datos esperados para ocultar un fallo. La corrección de una prueba es legítima solo si se demuestra que la prueba contradice el requisito aprobado o es técnicamente incorrecta.

## 7. Calidad estática y seguridad

El perfil de proyecto debe declarar herramientas y umbrales aplicables: formato, lint, tipos, análisis estático, dependencias, secretos, vulnerabilidades y migraciones. Los umbrales deben ser razonados para el proyecto; AES no impone un porcentaje universal de cobertura.

Los cambios que afectan autenticación, autorización, datos personales, pagos, secretos, límites de confianza o migraciones requieren revisión reforzada y pruebas negativas pertinentes.

## 8. Cobertura y mutation testing

La cobertura es una señal, no prueba de calidad. No se debe optimizar el porcentaje a costa de aserciones significativas.

Mutation testing SHOULD aplicarse a lógica crítica, autorización, cálculos sensibles y áreas donde sea importante saber si las pruebas detectan defectos. Su uso puede ser selectivo por coste.

## 9. Evidencia

Los resultados se registran con comando, estado (`PASS`, `FAIL`, `NOT RUN`, `BLOCKED`), entorno o versión relevante y resumen. No se aceptan pruebas reportadas como ejecutadas sin salida o evidencia verificable.

---

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

---

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

El perfil puede usar niveles `Low`, `Medium`, `High` y `Critical`, con controles definidos. Los elementos High/Critical requieren revisión reforzada y aprobación humana según el tipo de riesgo.

## 3. Bloqueos y fallos

Cuando una validación falla, el orquestador detiene el avance del gate afectado, clasifica el fallo y asigna una corrección delimitada. No se continúa marcando como terminado el trabajo dependiente.

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

---

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
