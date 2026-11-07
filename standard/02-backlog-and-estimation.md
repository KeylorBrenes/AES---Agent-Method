# 02 — Backlog y estimación

## 1. Jerarquía

AES utiliza esta jerarquía lógica:

`Product Goal / Vision → Epic → User Story → Task/Subtask → Test/Evidence`

Los defectos (`Bug`), tareas técnicas (`Enabler`), tareas de mantenimiento (`Chore`), lotes de estabilización (§9.4) y actividades de investigación (`Spike`) pueden aparecer como tipos de elemento relacionados con el backlog. No deben disfrazarse de historias de usuario si no representan valor de usuario.

Los defectos, chores y hallazgos que se dejan para después son **elementos de primera clase** del backlog: tienen ID, criterio, track y, si son defectos, severidad. Una nota en un documento o en un comentario de PR no es un elemento del backlog y se pierde.

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
- el presupuesto se estima **por separado para código de producción y para pruebas**. El desvío que exige justificación es el de producción: un único número castiga probar bien (en el sandbox de AES, el 60 % de una tarea de 474 líneas eran pruebas unitarias);
- la tarea SHOULD tocar una única superficie de cambio coherente (04 §2).

## 7. Refinamiento continuo

El backlog es continuo. Solo las historias próximas necesitan cumplir completamente DoR. El resto puede permanecer como Epic, idea o historia preliminar. El refinamiento debe ocurrir antes de comprometer una historia para implementación y cuando aparece nueva información.

No se debe congelar un plan detallado de meses de trabajo si las historias posteriores dependen de descubrimientos aún no realizados.

## 8. Tracks proporcionales

AES no aplica el mismo proceso a todos los cambios. Una crítica conocida a las herramientas de spec-driven development es que convierten cambios pequeños en una cascada de documentos. AES evita ese coste clasificando cada elemento de trabajo en un **track** que fija los artefactos y gates mínimos.

| Track | Cuándo | Artefactos mínimos | Gate humano previo |
|---|---|---|---|
| **T0 — Trivial** | Errata, texto, configuración no funcional, actualización de parche sin cambio de API | Tarea + CI verde | Ninguno |
| **T1 — Bug / chore** | Comportamiento existente incorrecto, o cambio pequeño con un criterio verificable (configuración funcional, herramienta, script) | Elemento con severidad (si es defecto) y criterio + comprobación de reproducción **protegida** que falla (RED): prueba de aceptación o comando de verificación (05 §12) + tarea. Camino corto en 04 §10 | Aprobar que la comprobación describe el comportamiento correcto |
| **T2 — Historia** | Comportamiento nuevo de alcance conocido | Historia, criterios, contrato de interfaz (si hay frontera nueva), suite de aceptación con RED confirmado, tareas | Aprobar criterios y pruebas de aceptación |
| **T3 — Alto riesgo** | Autenticación, autorización, datos sensibles, pagos, migraciones, cambio arquitectónico o de contrato público | Todo T2 + ADR + pruebas holdout obligatorias + Spike si hay incertidumbre | Criterios, pruebas, ADR; revisión humana del código de riesgo después |

Reglas:

- El orquestador propone el track; el responsable humano puede cambiarlo.
- **Subir** de track durante el trabajo es automático en cuanto aparece un riesgo nuevo. **Bajar** de track requiere justificación registrada.
- Un T1 siempre empieza con una comprobación que reproduce el defecto (o la ausencia del cambio) y falla antes del arreglo. Si no existe ninguna comprobación que falle antes (por ejemplo, una configuración que ya funciona por casualidad en el entorno), el elemento lo declara como «sin RED», con el motivo, y el responsable humano lo aprueba de forma explícita.
- Los defectos encontrados durante la verificación o la prueba manual agéntica (05 §11) que no pertenecen a lo que añade la tarea se registran como T1, con severidad (§9).
- Los niveles de riesgo de 07 §2 se corresponden así: `Low` → T0/T1/T2 según el tipo; `Medium` → T2; `High`/`Critical` → T3.

## 9. Defectos: severidad y compuerta de estabilización

### 9.1 Severidad

La severidad mide el daño del defecto; la prioridad (§4), el orden en que se trabaja. Son independientes. Todo defecto registrado lleva una severidad:

| Severidad | Cuándo | Ejemplos |
|---|---|---|
| **Crítica** | Pérdida o corrupción de datos, fallo de seguridad, la aplicación no arranca, el flujo principal es inutilizable, o la CI de `dev` o de `main` está en rojo | Un gasto guardado se pierde; un usuario ve datos de otro; `main` no compila |
| **Alta** | Un criterio de aceptación ya aceptado deja de cumplirse, o un flujo importante falla sin alternativa razonable. Una **prueba inestable** en la suite que corre en la rama principal es Alta: puede poner en rojo a todos | Editar un gasto no guarda; una prueba de regresión falla 1 de cada 3 corridas |
| **Media** | Comportamiento incorrecto con alternativa, o en un flujo secundario; un mensaje o una respuesta de error que lleva al usuario a una conclusión equivocada | Un monto `abc` dice «obligatorio» en lugar de «inválido»; un cuerpo mal codificado responde `500` en lugar de `400` |
| **Menor** | Cosmético o de presentación, sin efecto en los datos ni en las decisiones del usuario | Un separador de miles distinto; dos paneles abiertos a la vez sin consecuencia |

El orquestador propone la severidad con la evidencia del hallazgo; el responsable humano la confirma o la cambia. Bajar la severidad de un defecto ya registrado es una decisión registrada (03 §8), con motivo.

### 9.2 Compuerta de estabilización

Una historia o enabler nuevo (T2/T3) **no puede pasar a `Ready`** mientras exista en el backlog algún defecto abierto de severidad **Crítica, Alta o Media**, ni mientras el número de defectos **Menores** abiertos supere el límite del perfil (por defecto, 5).

- Un defecto **Crítico** detiene además todo el trabajo en curso, incluida la historia activa: no se integra ningún cambio de código en `dev` ni en `main` salvo su corrección. Excepción: si el defecto es de la propia tarea en curso, se trata como ciclo `FAIL` de esa tarea (04 §9).
- Un defecto **Alto o Medio** encontrado durante una historia no la detiene: la historia termina, y la siguiente no empieza hasta corregirlo.
- Los defectos **Menores** pueden quedar abiertos dentro del límite. Cuando se supera, se corrigen en lote antes de seguir.
- Un defecto «abierto» es cualquiera que no está `Accepted` (corregido y aceptado) ni `Rejected` (no era un defecto). `Deferred` cuenta como abierto: posponer un defecto no lo corrige.
- Las únicas formas de abrir la compuerta son corregir los defectos o una excepción documentada (00 §4). Absorber un defecto dentro de la historia siguiente es una excepción, no un camino normal: mezcla la corrección de lo viejo con la construcción de lo nuevo.

La misma compuerta se evalúa al **liberar** (07 §8): un release no sale con defectos Críticos, Altos o Medios abiertos, ni con más Menores que el límite. Un defecto de algo ya liberado puede corregirse por hotfix o por `dev`, a elección del responsable humano (07 §9).

El perfil puede endurecer la compuerta (por ejemplo, un límite menor de defectos menores), nunca relajarla sin excepción documentada. La compuerta SHOULD implementarse en la CI (L3), leyendo el backlog desde la rama protegida; la implementación de referencia lo hace.

### 9.3 Qué es un defecto y qué no

- Un hallazgo sobre **lo que añade la tarea en curso** no es un defecto: es un ciclo `FAIL` de esa tarea, que se corrige antes de integrar (04 §9).
- Un hallazgo sobre comportamiento **ya aceptado o preexistente** es un defecto: se registra con ID, severidad, historia de origen, reproducción y criterio, aunque se encuentre durante otra historia.
- El responsable humano puede fijar en el perfil una **regla permanente** para clasificar los hallazgos tras un `PASS` del verificador (por ejemplo, «lo que añade la tarea se corrige; lo demás va al backlog»). El orquestador la aplica, registra cada clasificación como decisión y se la muestra al humano, que puede cambiarla antes de integrar.

### 9.4 Lote de estabilización

Los defectos que cierran la compuerta se corrigen juntos en un **lote de estabilización**: un elemento del backlog (por ejemplo, `ST-NNN`) que agrupa los defectos de una historia y los asociados a ella.

- Un lote se trabaja en **una sola sesión** del orquestador, sin mezclar funcionalidad nueva.
- Sigue el camino T1 (04 §10): un PR de especificación con los defectos, su severidad y su criterio; las comprobaciones de reproducción con RED; tareas agrupadas por superficie de cambio; verificación; cierre.
- Las comprobaciones de reproducción del lote pasan a la regresión al cerrarlo, como las de una historia.
- Un defecto que el lote no logra corregir sigue abierto y la compuerta sigue cerrada.
