# 01 — Inicio del proyecto y arquitectura

## 1. Objetivo

Establecer una comprensión compartida del producto y una arquitectura suficiente para guiar los incrementos sin diseñar prematuramente todos sus detalles.

## 2. Inicio del proyecto

Antes de implementar funcionalidades, el orquestador DEBE ayudar a crear o localizar:

1. **Project Brief:** problema, usuarios, objetivos, alcance inicial, restricciones y criterios generales de éxito.
2. **Project Profile:** stack, entorno, comandos, convenciones, controles de calidad, agentes y permisos.
3. **Architecture Overview:** contexto, componentes principales, límites, datos e integraciones conocidas.
4. **Backlog inicial, completo pero superficial** (02 §7): todas las historias que se conocen para llegar al producto, cada una con su título en formato, una línea de valor, `Requiere:` y una estimación aproximada; Epics y riesgos conocidos. Sin criterios detallados, diseño ni tareas: eso llega cuando le toca a cada historia.
5. **Quality Strategy:** niveles de prueba, CI y controles aplicables.
6. **Copia local de las reglas que los agentes consultan:** como mínimo, las checklists de DoR y DoD (08) dentro del repositorio (por ejemplo, `docs/aes/`), con la versión de AES de la que salen. Un agente que solo tiene la referencia «AES 08» revisa la DoR de memoria.

El primer elemento que se implementa es el **esqueleto que camina** (02 §3.2): un enabler que deja la aplicación arrancando de punta a punta, con la CI en verde, sobre el que crecen las historias. La arquitectura inicial describe lo suficiente para ese esqueleto y para las primeras historias; el resto se decide cuando haga falta.

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
