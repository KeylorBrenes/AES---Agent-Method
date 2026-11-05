# 03 — Historias de Usuario y aceptación

## 1. Contenido mínimo de una historia

Cada Historia de Usuario refinada DEBE tener:

- identificador estable y título;
- usuario/actor y necesidad, o resultado técnico justificado;
- beneficio/objetivo;
- contexto y reglas relevantes;
- alcance incluido y exclusiones importantes;
- criterios de aceptación observables y verificables;
- prioridad, Story Points y track (02 §8);
- dependencias y riesgos relevantes;
- contrato de interfaz contra el que se escribirán las pruebas de aceptación, cuando la historia introduce o modifica una frontera observable (05 §2.1);
- estrategia de pruebas/aceptación;
- estado y responsable de decisión;
- registro de decisiones (§8).

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
- **fallo de cada acción que escribe** (guardar, editar, eliminar, enviar): qué ve el usuario si la respuesta no es exitosa y si la red falla, y qué transiciones limpian ese estado de error;
- estados límite y concurrencia;
- compatibilidad con comportamiento existente;
- accesibilidad, privacidad y seguridad.

No todos los escenarios aplican a todas las historias. QA debe explicar brevemente por qué un escenario de riesgo relevante se omite.

El fallo de una acción que escribe MUST tener criterio en toda historia con interfaz de usuario. En el sandbox de AES, los dos ciclos `FAIL` de una historia vinieron del mismo hueco: ningún criterio decía qué pasaba al fallar el guardado o el borrado, y al añadir el mensaje de error nadie listó qué lo limpiaba.

## 4. Fuera de alcance

Las exclusiones son obligatorias cuando existe riesgo razonable de expansión del alcance. Deben nombrar funcionalidades cercanas que el agente podría implementar «por conveniencia» pero que no están aprobadas.

En T2 y T3 la sección «Fuera de alcance» MUST NOT estar vacía. Implementar funcionalidad no pedida, aunque parezca el siguiente paso razonable, es una de las señales de desvío más frecuentes en agentes; nombrar explícitamente lo excluido es la forma más barata de prevenirla.

## 5. Ambigüedad y supuestos

Los agentes no deben inventar comportamiento del producto. Deben:

- pedir decisión humana ante ambigüedades que afectan comportamiento visible, datos, seguridad, costes, integraciones, cumplimiento o decisiones irreversibles;
- registrar como supuesto una decisión de bajo riesgo, reversible y coherente con patrones existentes;
- elegir la alternativa más simple y consistente cuando el detalle es local y no cambia el contrato del producto;
- informar el supuesto en el reporte de ejecución.

Los **supuestos de QA** merecen una regla propia. Al escribir las pruebas, QA tiene que fijar detalles que el contrato no dice (el tipo de control de un campo, un formato, qué pasa en un caso límite). Si esos supuestos llegan a la suite sin decisión, QA define el producto y nadie lo firmó. Por eso:

- QA MUST listar en el plan de pruebas todo lo que tuvo que suponer;
- cada supuesto se convierte en contrato (decisión registrada, §8) o se rechaza **antes** de que la historia pase a `Ready`;
- ningún supuesto abierto pasa la DoR.

No se debe interrumpir al usuario por decisiones internas triviales que el estándar ya delega al equipo técnico.

## 6. Trazabilidad

Cada criterio de aceptación debe relacionarse con uno o más escenarios/pruebas o con una justificación explícita de verificación manual. Cada tarea debe referenciar la historia y los criterios que contribuye a satisfacer.

La trazabilidad SHOULD ser comprobable por máquina:

- cada prueba de aceptación lleva el ID de su historia y el de su criterio (por ejemplo, las etiquetas `@US-002` y `@US-002-AC-03`, y `AC-03` al inicio del título);
- cada tarea declara los criterios que deja en verde (04 §2), de modo que la CI ejecute solo esos (05 §12);
- toda prueba se deriva de un criterio aprobado. Si QA ve un hueco, propone un criterio nuevo; no escribe una prueba sin criterio.

Un criterio que describe un comportamiento que el código **ya tiene** no puede demostrar RED. Su verificación es la **regresión** de la historia dueña de ese comportamiento (05 §2.4), y el criterio lo dice: «Verificación: regresión de US-001».

No se considera trazabilidad suficiente una lista de pruebas sin vínculo con los requisitos.

## 7. Cambios en la historia

Una vez que la historia está `Ready`, los cambios de alcance, comportamiento esperado o criterios de aceptación requieren control de cambios. Las correcciones editoriales que no cambian el significado pueden hacerse sin re-aprobación, dejando historial cuando la herramienta lo permita.

## 8. Registro de decisiones

Cada historia tiene una sección «Decisiones». Cada ambigüedad resuelta y cada supuesto convertido en contrato es una fila:

| ID | Pregunta | Opciones | Decisión | Quién y fecha | Impacto |
|---|---|---|---|---|---|
| D-01 | ¿Qué categoría queda seleccionada al cancelar una edición? | Vuelve a la inicial / queda la última | Vuelve a la inicial | Responsable humano, 2026-11-05 | AC-12 modificado |

Reglas:

- La decisión entra en la historia **en el mismo PR** que la usa (refinamiento o pruebas). Aprobar ese PR es la firma del responsable humano.
- En «Impacto» va qué cambió: un criterio nuevo o modificado, el contrato de interfaz, un ADR, o «ninguno».
- Una decisión que vale para más de una historia sube a un ADR (01 §4).
- Una decisión que resultó basarse en un hecho falso se corrige **en su fila**, con fecha y motivo; no se borra.
- Las decisiones que el orquestador toma aplicando una regla permanente del humano (02 §9.3) también se registran, con la regla citada.
