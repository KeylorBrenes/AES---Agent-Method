# 01 — Inicio del proyecto y arquitectura

## 1. Objetivo

Establecer una comprensión compartida del producto y una arquitectura suficiente para guiar los incrementos sin diseñar prematuramente todos sus detalles.

## 2. Incepción: de la idea al backlog

Antes de escribir código, el responsable del producto y el orquestador **conversan en lenguaje natural** hasta que la idea es lo bastante clara para planificar. La incepción produce la visión, el backlog completo pero superficial, la arquitectura inicial y el stack. No produce criterios detallados, diseño de tareas ni código: eso llega cuando le toca a cada historia (02 §7).

La conduce el orquestador, en el modelo más capaz disponible (06 §11): de esta conversación salen el corte de las historias y las decisiones de arquitectura, que todo lo demás hereda.

### 2.1 La entrevista

El orquestador pregunta **por temas, en bloques cortos de preguntas concretas**:

| Tema | Qué tiene que quedar claro |
|---|---|
| Problema y usuarios | Quién usa el producto, qué hace hoy sin él y qué le duele |
| Lo que el usuario hace | Las acciones principales, de principio a fin (serán los Epics del mapa de historias) |
| Datos y reglas | Qué se guarda, qué reglas lo limitan, qué pasa en los casos raros |
| Restricciones | Privacidad, acceso, dispositivos, idioma, plazos, presupuesto, integraciones |
| Stack y operación | Preferencias o restricciones tecnológicas, dónde corre, quién lo mantiene |
| Primer release | Qué es lo mínimo que ya sirve, y qué puede esperar |
| Interfaz (si la hay) | Tono de los textos, accesibilidad, marca y recursos que ya existen, restricciones visuales que no se discuten |

Reglas de las preguntas:

- **Un bloque es un tema**, con 2 a 5 preguntas. No se mezclan temas, y no se manda la entrevista entera de una vez.
- **Cada pregunta es concreta y se responde en una o dos frases.** Cuando hay opciones razonables, el orquestador las propone con su recomendación, y el responsable elige o corrige. «¿Qué más necesitas?» o «¿Cómo te imaginas la app?» no son preguntas de AES: obligan al responsable a hacer el trabajo del orquestador.
- **Se pregunta por comportamiento, no por tecnología**, salvo en el bloque de stack. «¿Una tarea puede tener fecha límite?», no «¿Guardamos un `DateOnly` nullable?».
- **Cada bloque parte de las respuestas anteriores.** Antes del siguiente, el orquestador resume en tres o cuatro líneas lo que entendió, para que el responsable corrija a tiempo.
- **Lo que el responsable no sabe no se inventa:** queda «por definir» en el brief (supuesto o incertidumbre, con cómo se resolverá), o se convierte en un Spike (§7).

### 2.2 Cuándo parar

La entrevista termina cuando:

1. cada acción principal del usuario tiene historias con título en formato (02 §3), una línea de valor, `Requiere:` y una estimación aproximada;
2. el primer release está delimitado: qué historias entran y qué resultado observable da;
3. hay datos suficientes para elegir el stack y describir la arquitectura del esqueleto que camina;
4. lo que falta está nombrado como «por definir» o como Spike, con quién y cuándo lo resolverá.

No se sigue preguntando para completar el detalle de historias lejanas. Ese detalle se pregunta en el refinamiento de cada historia, cuando lo que enseñaron las anteriores ya está a la vista.

### 2.3 Lo que produce

1. **Project Brief:** problema, usuarios, objetivos, alcance, fuera de alcance, restricciones, supuestos e incertidumbres, riesgos, y los releases previstos.
2. **Backlog inicial, completo pero superficial** (02 §7, §11): todas las historias que se conocen para llegar al producto, agrupadas por Epic y asignadas a un release. Las historias pasan el control de atomicidad (02 §3.1) desde el principio: dividir en la incepción es barato, dividir a media implementación no.
3. **Architecture Overview** (§3) del esqueleto y las primeras historias, con un diagrama de componentes. El texto es la fuente; el diagrama es una vista y se regenera desde él.
4. **ADR del stack** (§4): opciones consideradas y por qué se elige una.
5. **Project Profile:** stack, entorno, comandos, convenciones, controles de calidad, agentes, permisos, skills y herramientas.
6. **Quality Strategy:** niveles de prueba, CI y controles aplicables.
7. **Dirección visual** (si hay interfaz): el sistema visual del producto (colores, tipografía, componentes, tono), elegido por el responsable humano entre opciones concretas, como el stack. El agente propone y el humano elige; el agente no la decide a partir de lo que le contestaron. EN-001 monta la interfaz ya con ella.
8. **EN-001, el esqueleto que camina** (02 §3.2), primero en el backlog: la aplicación arrancando de punta a punta, con la CI en verde, sobre la que crecen las historias.
9. **Copia local de las reglas que los agentes consultan:** como mínimo, las checklists de DoR y DoD (08) dentro del repositorio (por ejemplo, `docs/aes/`), con la versión de AES de la que salen. Un agente que solo tiene la referencia «AES 08» revisa la DoR de memoria.

### 2.4 Aprobación y revisión

Todo lo anterior entra en **un PR de incepción**, que aprueba el responsable humano. Hasta entonces, nada de lo producido es un compromiso; después, cambiarlo es normal y entra por PR como cualquier otro cambio del backlog.

Cuando aparece una idea nueva que no cabe en el backlog (un Epic nuevo, un cambio de usuario o de alcance), el orquestador hace una **mini-incepción**: solo los bloques afectados, con las mismas reglas, y un PR que actualiza el brief, el backlog y, si hace falta, la arquitectura. Una historia nueva dentro de un Epic existente no necesita mini-incepción: se añade al backlog.

### 2.5 Proyecto existente

Si se trabaja sobre un proyecto existente, primero se inspecciona el repositorio y el comportamiento actual, y la entrevista empieza por lo que el código no dice (para qué es, quién lo usa, qué falta). No se asume que la documentación está actualizada ni que la arquitectura deseada coincide con la implementada.

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
- decisiones de escalabilidad, seguridad o despliegue;
- **convenciones que aplican a más de una historia**: cómo se valida, cómo se muestran los errores, qué control de UI se usa para cada tipo de dato, formato de fechas y montos. Si una convención se decide dentro de una historia y vale para las siguientes, sube a un ADR; si no, la siguiente historia vuelve a preguntarla, o la fija sin firma el primer agente que escribe una prueba.

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
