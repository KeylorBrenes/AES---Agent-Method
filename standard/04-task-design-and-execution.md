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
- track (02 §8);
- **superficie de cambio**: globs de archivos que la tarea puede modificar;
- restricciones y permisos;
- **comandos de validación exactos** (no descripciones como «ejecuta las pruebas relevantes»);
- **pruebas de regresión afectadas** (test map), cuando puedan generarse o deducirse;
- **criterios que deja en verde**: los IDs de criterio (o de defecto) que esta tarea cumple. La CI de la tarea ejecuta solo esos más la regresión; la **última** tarea de la historia ejecuta la historia completa (05 §12);
- presupuesto de diff orientativo, separado en producción y pruebas (02 §6);
- si la tarea introduce un **estado** (de error, de carga, de edición), las transiciones que lo crean y las que lo limpian;
- condición de finalización.

La superficie de cambio no es una sugerencia: la CI compara el diff contra ella (05 §10). Un archivo modificado fuera de la superficie es un `FAIL` salvo aprobación registrada. La superficie se publica en la rama protegida **antes** de delegar la tarea, para que el programador no pueda ampliarla.

### Por qué comandos exactos y no instrucciones de proceso

El estudio TDAD (Alonso, Yovine y Braberman, arXiv:2603.17973; tesis de maestría, Universidad ORT Uruguay) midió que añadir instrucciones genéricas de TDD a la guía de un agente aumentó su tasa de regresiones de 6,08 % a 9,94 %, mientras que darle un mapa de qué pruebas afecta cada archivo la redujo a 1,82 %. El estudio se hizo con un modelo abierto (Qwen3-Coder 30B) y solo en Python, así que AES no adopta la cifra, sino el principio: **información estructural concreta en lugar de procedimientos genéricos**.

## 3. Tamaño y divisibilidad

Una tarea es suficientemente pequeña si un agente puede comprender su objetivo, implementarla, inspeccionar el diff y ejecutar su validación sin tener que aceptar varios resultados independientes como un bloque indivisible.

Las tareas se dividen **por criterios** (cortes verticales que dejan criterios en verde), no por capas técnicas. Una tarea «solo API» y otra «solo UI» no pueden quedar verdes por separado si la aceptación cruza ambas. Sin CI por criterio, toda historia termina en una sola tarea grande: en el sandbox de AES, las dos primeras historias acabaron en tareas únicas de 300 a 500 líneas.

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

1. **ejecutar primero la suite existente** y registrar el baseline (pruebas que ya fallaban antes de tocar nada), para no «arreglar» ni atribuirse fallos preexistentes;
2. inspeccionar el código relevante antes de cambiarlo;
3. describir brevemente el enfoque cuando el cambio no sea trivial;
4. implementar solo el alcance de la tarea, dentro de su superficie de cambio;
5. añadir o ajustar pruebas técnicas permitidas, siguiendo RED/GREEN/REFACTOR donde aplique (05 §3);
6. separar commits estructurales y conductuales (§8);
7. ejecutar los comandos de validación exactos de la tarea;
8. inspeccionar su propio diff para detectar archivos o cambios ajenos;
9. dejar el entorno como lo encontró: ningún servidor, proceso ni dato que el rol siguiente pueda tomar como propio (06 §10);
10. entregar un reporte con archivos modificados, pruebas ejecutadas, resultados, riesgos y decisiones/supuestos.

El programador NO DEBE:

- modificar criterios aprobados o pruebas de aceptación protegidas;
- alterar CI, permisos, políticas o configuraciones de agentes para facilitar su tarea;
- ocultar, saltar o silenciar pruebas fallidas;
- ampliar el alcance con refactorizaciones no relacionadas;
- añadir dependencias sin justificación y aprobación requerida;
- editar a mano código generado por herramientas (por ejemplo, migraciones): se regenera;
- borrar un marcador del guardián que no escribió (por ejemplo, un `#pragma` de código generado) para que el control deje de marcarlo: se reporta;
- afirmar que algo funciona sin evidencia de ejecución.

## 5. Dependencias y paralelismo

Las tareas pueden ejecutarse en paralelo solo si sus archivos, contratos y dependencias permiten trabajo independiente. El orquestador debe identificar conflictos de escritura y definir integración.

Se DEBERÍA usar ramas o worktrees separados para agentes concurrentes. No se permite que dos agentes escriban simultáneamente en los mismos archivos sin coordinación explícita.

## 6. Bloqueos

Si el agente descubre una dependencia, contradicción o cambio necesario fuera del alcance, debe detener esa parte, explicar el bloqueo y proponer opciones. No debe resolverlo ampliando unilateralmente la tarea.

Una **acción denegada** (por un permiso, un hook o un clasificador del harness) también es un bloqueo. El agente termina con `BLOCKED` e indica la acción exacta que necesita **del responsable humano**. No la intenta de otra forma ni le pide a otro agente que la haga: eso es un rodeo por delegación (06 §6.1).

## 7. Cierre de tarea

Una tarea puede pasar a revisión cuando:

- el resultado esperado está implementado;
- las pruebas aplicables se ejecutaron;
- el diff está limitado y revisado;
- no quedan cambios temporales o secretos;
- el reporte de ejecución está completo.

El cierre de una tarea no significa que la Historia de Usuario esté aceptada.

## 8. Commits estructurales y conductuales

Basado en *Tidy First* (Kent Beck).

- Cada commit MUST ser **estructural** (reorganiza código sin cambiar comportamiento; todas las pruebas verdes antes y después) **o conductual** (cambia comportamiento). Nunca ambos.
- Prefijos obligatorios: `struct:` para estructurales; `feat:`, `fix:` o `test:` para conductuales. El perfil puede mapearlos a Conventional Commits.
- Un cambio estructural fuera de la superficie de la tarea es fuera de alcance, aunque mejore el código. Se propone como tarea propia.

Efecto: un commit `struct:` se revisa comprobando que las pruebas siguen verdes; la atención humana y del verificador se concentra en los conductuales.

## 9. Circuit breaker e higiene de contexto

- Cada tarea MUST ejecutarse en una **sesión nueva**. No se reutiliza el contexto de una tarea anterior.
- Cuenta como ciclo `FAIL`: una CI roja por causa del cambio, un `FAIL` del verificador, o un hallazgo tras un `PASS` que el responsable humano manda corregir antes de integrar. No cuenta: una CI roja que solo espera una aprobación humana prevista (por ejemplo, la etiqueta de dependencias).
- Si una misma tarea acumula **3 ciclos `FAIL`** (CI o verificador), se detiene. No hay cuarto intento automático. El orquestador clasifica la causa y decide:
  - tarea mal especificada o demasiado grande → vuelve a refinamiento;
  - prueba de aceptación incorrecta → control de cambios con QA (05 §6);
  - problema de diseño → arquitecto o Spike;
  - limitación del modelo o del harness → reasignar o escalar al responsable humano.
- Si el agente repite el mismo enfoque fallido dos veces seguidas, el orquestador SHOULD reiniciar el contexto con un resumen escrito de lo aprendido en lugar de compactarlo: la compactación conserva los supuestos erróneos.
- El perfil puede reducir el umbral de 3 ciclos; aumentarlo requiere excepción documentada.

## 10. Camino corto para T0 y T1

T0 y T1 no recorren el ciclo de una historia, pero tampoco se improvisan. Pasos mínimos:

| Paso | T0 | T1 (defecto, chore o lote de estabilización) |
|---|---|---|
| Elemento en el backlog | Sí | Sí, con severidad si es defecto (02 §9) y con historia de origen |
| Especificación | La tarea | Un PR de especificación con el elemento, su criterio y la superficie. Aprobarlo es el gate humano |
| Comprobación de reproducción | — | Prueba de aceptación protegida o **comando de verificación** (05 §12), con RED confirmado; o «sin RED» declarado y aprobado (02 §8) |
| QA | No | Solo si la comprobación es una prueba de aceptación nueva |
| Tareas | Una | Las mínimas, agrupadas por superficie; cada una declara qué defectos deja en verde |
| CI | Guardián + validaciones | Guardián + validaciones + la comprobación del elemento + regresión |
| Verificador | No (salvo que el perfil lo exija) | Sí, ejecutando la comprobación él mismo |
| Cierre | Estado en el backlog | Estado, comprobación añadida a la regresión, hallazgos registrados |

Un T1 que, al trabajarse, resulta tocar comportamiento nuevo o un riesgo de T3 sube de track (02 §8).

## 11. Sesiones del orquestador

- El orquestador trabaja **una historia, enabler o lote por sesión**. Arrastrar el contexto de otro elemento encarece cada turno y mezcla decisiones; en el sandbox de AES, el contexto acumulado fue la mayor parte del costo de cada historia.
- La redacción mecánica (consolidar notas, tablas de métricas) SHOULD delegarse en un rol barato (el mecánico).
