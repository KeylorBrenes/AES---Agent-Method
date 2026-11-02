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

AES adopta Story Points relativos usando la secuencia Fibonacci:

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

Las tareas no necesitan Story Points obligatoriamente. Deben ser pequeñas, observables y verificables. Su tamaño se determina por la claridad del resultado, superficie de cambio, dependencias y facilidad de prueba, no por una duración ficticiamente precisa.

Una tarea SHOULD:

- producir un resultado principal identificable;
- tener un alcance y límites concretos;
- poder implementarse y depurarse sin coordinar muchos cambios independientes;
- tener una forma clara de validación;
- evitar mezclar responsabilidades diferentes;
- ser suficientemente pequeña para entender qué falló si su prueba falla.

Una tarea MUST dividirse si contiene varios resultados independientes, combina responsabilidades no relacionadas, abarca demasiados componentes sin razón, tiene dependencias ocultas o no puede verificarse de forma focalizada.

No se fija un límite universal en horas. Si una tarea parece grande, se divide por resultado verificable, no arbitrariamente en fragmentos que no tienen sentido por sí solos.

Heurísticas específicas para tareas ejecutadas por agentes (el perfil las ajusta):

- la tarea SHOULD poder completarse en **una sola sesión con contexto nuevo**, sin compactación;
- el diff resultante SHOULD ser revisable de una vez; el perfil fija un **presupuesto de diff orientativo** (por ejemplo, 300–400 líneas cambiadas). Superarlo no es un fallo automático, pero obliga a justificar por qué no se dividió;
- la tarea SHOULD tocar una única superficie de cambio coherente (04 §2).

## 7. Refinamiento continuo

El backlog es continuo. Solo las historias próximas necesitan cumplir completamente DoR. El resto puede permanecer como Epic, idea o historia preliminar. El refinamiento debe ocurrir antes de comprometer una historia para implementación y cuando aparece nueva información.

No se debe congelar un plan detallado de meses de trabajo si las historias posteriores dependen de descubrimientos aún no realizados.

## 8. Tracks proporcionales

AES no aplica el mismo proceso a todos los cambios. Una crítica conocida a las herramientas de spec-driven development es que convierten cambios pequeños en una cascada de documentos. AES evita ese coste clasificando cada elemento de trabajo en un **track** que fija los artefactos y gates mínimos.

| Track | Cuándo | Artefactos mínimos | Gate humano previo |
|---|---|---|---|
| **T0 — Trivial** | Errata, texto, configuración no funcional, actualización de parche sin cambio de API | Tarea + CI verde | Ninguno |
| **T1 — Bug** | Comportamiento existente incorrecto | Prueba de reproducción **protegida** que falla (RED) + tarea | Aprobar que la prueba describe el comportamiento correcto |
| **T2 — Historia** | Comportamiento nuevo de alcance conocido | Historia, criterios, contrato de interfaz (si hay frontera nueva), suite de aceptación con RED confirmado, tareas | Aprobar criterios y pruebas de aceptación |
| **T3 — Alto riesgo** | Autenticación, autorización, datos sensibles, pagos, migraciones, cambio arquitectónico o de contrato público | Todo T2 + ADR + pruebas holdout obligatorias + Spike si hay incertidumbre | Criterios, pruebas, ADR; revisión humana del código de riesgo después |

Reglas:

- El orquestador propone el track; el responsable humano puede cambiarlo.
- **Subir** de track durante el trabajo es automático en cuanto aparece un riesgo nuevo. **Bajar** de track requiere justificación registrada.
- Un T1 siempre empieza con una prueba que reproduce el defecto y falla antes del arreglo.
- Los defectos encontrados durante la verificación o la prueba manual agéntica (05 §11) se registran como T1.
- Los niveles de riesgo de 07 §2 se corresponden así: `Low` → T0/T1/T2 según el tipo; `Medium` → T2; `High`/`Critical` → T3.
