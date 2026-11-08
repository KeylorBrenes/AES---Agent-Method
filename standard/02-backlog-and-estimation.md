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

Una Historia de Usuario representa una necesidad/comportamiento con valor identificable para un usuario o actor. Su **título** MUST tener este formato:

> Como [tipo de usuario], quiero [capacidad], para [beneficio].

> Como usuario, quiero registrar un pago pendiente, para no olvidarme de él.

Otros elementos tienen su propio formato, porque no tienen un usuario que los pida:

| Tipo | Formato del título | Ejemplo |
|---|---|---|
| Enabler | Para [historia u objetivo], necesitamos [capacidad técnica] | Para que las historias de pagos se puedan probar de punta a punta, necesitamos la app arrancando con base de datos, API y web |
| Defecto | [Comportamiento incorrecto, en una frase] | Un monto «abc» dice «obligatorio» en lugar de «inválido» |
| Chore | [Cambio de mantenimiento] para [motivo] | Fijar las fuentes de paquetes para que la restauración no dependa de la máquina |

Cada historia incluye criterios de aceptación verificables y límites de alcance, y declara con `Requiere:` los elementos que deben estar terminados antes (por ejemplo, `Requiere: US-001`).

### 3.1 Historias atómicas

Una historia MUST ser **atómica**: una sola capacidad del usuario que se puede demostrar por sí sola, y que no contiene otra capacidad que también se podría demostrar sola. No se mide por verbos: «crear tareas y verlas en mi lista» es una capacidad, porque crear sin ver no se puede comprobar; «registrarme y crear tareas» son dos.

- Un «y» que une dos objetivos del usuario en el «quiero» es la señal de que hay que dividirla.
- Las épicas y las funcionalidades grandes existen, pero solo como agrupación: se implementan como historias atómicas, nunca de una sola vez.
- Motivo: una historia atómica se puede verificar, auditar, medir y depurar. Una historia que implica muchas funcionalidades a la vez es más difícil de depurar, hace que el agente pierda el control del contexto y alucine, y retrasa el momento de comprobar que lo construido sirve.

Una historia puede ser atómica para el usuario y aun así grande por dentro. Dos señales objetivas obligan a dividirla:

1. **Al estimar:** 8 puntos o más (§5).
2. **Al diseñar:** si el orquestador no consigue dividirla en **3 tareas como máximo**, cada una dentro del presupuesto de diff de producción y dejando criterios en verde (04 §3). No se hacen tareas más grandes: se divide la historia (§10).

### 3.2 Cortes verticales

Cada historia es un **corte vertical completo**: la parte mínima de cada capa (datos, servidor, interfaz) para que la capacidad funcione de verdad y se pueda usar. No se construye una capa entera antes que la siguiente: «toda la base de datos, después todo el servidor, después toda la interfaz» tarda semanas en mostrar que algo no servía, y un corte vertical lo muestra el mismo día.

- El esquema de datos crece historia a historia: cada historia trae la migración que necesita, y nada más.
- El primer elemento del proyecto es un **esqueleto que camina** (*walking skeleton*): un enabler que deja la aplicación arrancando de punta a punta con un caso trivial (por ejemplo, una página que muestra el estado de la API, que a su vez lee la base de datos), con la CI ya en verde. Las historias siguientes engrosan ese esqueleto.
- Dentro de una historia vale lo mismo: primero el camino más delgado de punta a punta, después las reglas y los casos límite.

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
- **8:** demasiado grande para una historia atómica: MUST dividirse antes de refinarse (§3.1, §10).
- **13:** demasiado grande o incierto para planificar con confianza: se divide o se investiga con un Spike.

Una historia de 8 o más no pasa a refinamiento: se divide en historias con valor verificable, o se crea un Spike cuando la incertidumbre impide dividirla de forma responsable.

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

## 7. Refinamiento continuo: planificación en dos niveles

La planificación tiene dos niveles, y el detalle llega tarde a propósito:

1. **Al inicio del proyecto** (ligero, en la incepción, 01 §2): visión del producto, stack, y un **backlog completo pero superficial**: todas las historias que se conocen para llegar a la app completa, cada una con su título en formato, una línea de valor, `Requiere:`, una estimación aproximada y el release al que apunta. Nada de criterios detallados, diseño ni tareas.
2. **Cuando le toca a cada historia** (detallado): criterios, decisiones, fuera de alcance, plan técnico y tareas. Solo entonces, porque es cuando se sabe lo que las historias anteriores enseñaron.

El backlog inicial va a cambiar: reordenar, dividir, fusionar o descartar historias es parte del proceso, no un fallo de la planificación. Solo las historias próximas necesitan cumplir completamente la DoR.

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

## 10. Cómo dividir una historia

Formas de dividir una historia grande, de la más habitual a la menos. Cada parte resultante sigue siendo atómica, vertical y con valor propio.

| Forma | Cuándo | Ejemplo |
|---|---|---|
| **Camino feliz primero, reglas después** | La historia tiene validaciones, errores y casos límite | «Registrarme con email y contraseña y entrar con la sesión iniciada» primero; «ver un aviso si el email ya existe» después |
| **Por variación de datos o de reglas** | La misma capacidad aplica a varios tipos, monedas, canales o roles | Un tipo de pago ahora, los demás después |
| **Por pasos del flujo** | El usuario completa etapas por separado | «Agregar un pago» y «marcar un pago como hecho» |
| **Por operación** | Crear, ver, editar y eliminar pueden demostrarse por separado | «Registrar un gasto» y «editar un gasto» |
| **Lo no funcional después** | Rendimiento, caché, paginación, exportación | «Ver mis pagos» primero; «ver mis pagos paginados» cuando sean muchos |
| **Spike** | Lo grande es la incertidumbre, no el trabajo | Averiguar cómo autenticar contra un proveedor antes de planificar el inicio de sesión |
| **Enabler** | Una pieza técnica es inevitable y la necesitan varias historias | La infraestructura de autenticación, con un criterio verificable propio (un comando o un caso mínimo de punta a punta), nunca «toda la base de datos» |

Una historia dividida conserva su orden con `Requiere:`. Si ninguna forma la deja en 3 tareas o menos, el problema suele ser de diseño o de incertidumbre: se pregunta al responsable humano o se abre un Spike.

## 11. El backlog como archivo y sus vistas

El backlog vive en **un archivo del repositorio** (por ejemplo, `docs/backlog.md`), que es la única fuente de verdad. No depende de ningún servicio, viaja con el código y pasa por PR, así que cada cambio lleva la firma del responsable humano. La CI lo lee (la compuerta de estabilización, 02 §9) y los agentes lo leen sin herramientas externas.

El formato MUST ser una tabla con estas columnas, en cualquier orden:

| Columna | Contenido |
|---|---|
| `ID` | `US-NNN`, `EN-NNN`, `BUG-NNN`, `CH-NNN`, `ST-NNN`, `SP-NNN`, `REL-NNN` |
| `Tipo` | Historia, Enabler, Defecto, Chore, Lote, Spike, Release |
| `Título` | En el formato de su tipo (§3) |
| `Requiere` | IDs separados por coma, o `—` |
| `Puntos` | Fibonacci (§5), o `—` |
| `Prioridad` | Escala del perfil (§4) |
| `Severidad` | Solo defectos (§9.1); el resto, `—` |
| `Estado` | 00 §6 |

Dos columnas son opcionales y SHOULD usarse desde la incepción: `Epic`, la acción del usuario a la que pertenece la historia (§2), y `Release` (por ejemplo, `REL-001`), el release al que apunta (§12). Con ellas, el backlog es también el mapa de historias: Epics en una dimensión, releases en la otra.

Para el responsable humano, una tabla en un archivo no es la mejor forma de ver dónde va el proyecto. Las **vistas** (un tablero) se generan desde el archivo, en una sola dirección:

- la implementación de referencia genera un tablero HTML autocontenido, sin ningún servicio;
- adaptadores opcionales publican el mismo backlog en GitHub Projects, Trello, GitLab u otro tablero. Cambiar de herramienta es cambiar de adaptador, no de metodología;
- lo que se mueve en una vista no vuelve solo al archivo: se le pide al orquestador y entra por PR.

## 12. Releases como horizonte de planificación

AES planifica por **releases**, no por sprints. Un release es un conjunto de historias que, juntas, dan un resultado que el usuario puede usar, y se libera cuando está completo y la compuerta de estabilización lo permite (§9.2, 07 §8). No hay una duración fija: con agentes, el ritmo lo marcan la aprobación humana y la CI, no el calendario.

- **La incepción define los releases** (01 §2): el primero es lo mínimo que ya sirve; los siguientes, lo que se sabe que viene después. Cada uno tiene un objetivo de una frase y una lista de historias.
- **Solo el release en curso está comprometido.** Los siguientes son una previsión: se reordenan con lo que enseñe el primero.
- **Mover una historia de release** es un cambio del backlog y entra por PR. Si el release en curso crece, lo normal es mover historias al siguiente, no esperar.
- Los puntos aceptados por release (§5) sirven para prever los siguientes. No son una meta ni se comparan entre proyectos.

