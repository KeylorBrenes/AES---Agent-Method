# 10 — Principios de diseño y patrones

## 1. Objetivo

Que el código, sea pequeño o grande, se pueda entender, probar, depurar y hacer crecer sin reescribirlo, **sin** añadir estructura que nadie necesita todavía.

Decirle a un modelo «aplica SOLID» o «escribe código limpio» no le da información que no tuviera: añade ruido. Este capítulo convierte esos principios en reglas con un síntoma comprobable y una frontera explícita de cuándo no aplican, y asigna a alguien con criterio la decisión de qué patrón usar en cada caso.

## 2. Dos niveles

Un principio es de **nivel 1 (siempre obligatorio)** si cumple las tres condiciones:

1. **Aplicarlo hoy no cuesta casi nada:** no añade tipos, capas ni indirección; es una forma de escribir lo que se iba a escribir de todos modos.
2. **Aplicarlo después cuesta cada vez más:** introducirlo en código existente crece con el tamaño de ese código.
3. **Es local:** no obliga a diseñar otros módulos alrededor.

Lo que no cumple las tres es de **nivel 2 (condicional)**: se aplica solo cuando hay una **razón presente**, es decir, variantes reales en el código, historias del backlog que la piden o un ADR. «Por si acaso» no es una razón presente.

Los dos niveles se refuerzan: los principios del nivel 1 son los que hacen que añadir un patrón del nivel 2 más adelante sea un cambio local y no un refactor de todo el código. Por eso el nivel 2 puede esperar sin que esperar salga caro.

## 3. Nivel 1: principios siempre obligatorios

Aplican a todo código del proyecto, en cualquier lenguaje, también en scripts. Un incumplimiento es un hallazgo del verificador (de la tarea → ciclo `FAIL`). Las excepciones son excepciones documentadas (00 §4).

| Principio | Qué exige | Síntoma de incumplimiento |
|---|---|---|
| **Responsabilidad única** | Cada función y cada módulo hace una sola cosa. En un script: leer la entrada, procesar y escribir la salida son funciones distintas | Una unidad que cambia por dos motivos; un nombre con «y» o vago (`procesar`, `manejar`, `utils`) |
| **Lógica separada de la entrada/salida** | Las reglas del negocio reciben datos y devuelven datos; no leen archivos, no llaman a la red ni a la base de datos | Una regla que no se puede probar sin levantar la base de datos, el servidor o el sistema de archivos |
| **Dependencias recibidas, no creadas** | Lo que una pieza necesita lo recibe por parámetro o constructor; no lo crea por dentro ni lo toma de un global. No exige crear interfaces | Una regla de negocio que instancia un cliente HTTP, una conexión o un reloj, o que lee un global |
| **Acceso a datos agrupado por funcionalidad** | Las consultas y escrituras de una funcionalidad viven juntas, en un solo lugar | La misma consulta, o una casi igual, repartida en varios archivos |
| **Contratos explícitos en las fronteras** | Lo que se expone (API, CLI, eventos) tiene tipos propios, distintos de los internos | Cambiar una columna o un tipo interno cambia la respuesta pública |
| **Errores explícitos** | Se falla pronto, con un mensaje que dice qué y dónde; ningún error se silencia | `catch` vacío; devolver `null`, `-1` o una cadena vacía para indicar un error |
| **Sustitución (Liskov)** | Si se usa herencia, una subclase funciona donde se espera su base. La opción por defecto es la composición | Una subclase que lanza «no soportado», ignora o debilita un método de su base |
| **Interfaces pequeñas** | Cuando se crea una interfaz (por una razón del nivel 2), contiene solo lo que usan sus clientes. No es una razón para crear interfaces | Una implementación con métodos vacíos o que lanzan «no implementado» |
| **Visibilidad mínima** | Todo es privado salvo lo que otra pieza necesita usar | Miembros públicos que solo se usan dentro de su propio módulo |
| **Configuración fuera del código** | Direcciones, rutas, credenciales y valores que cambian por entorno salen del entorno o de la configuración | Un valor de un entorno concreto escrito en el código |
| **Validar en la frontera y convertir** («parse, don't validate») | Lo que entra (petición, archivo, argumento) se valida una vez, en la frontera, y se convierte a un tipo que ya no puede ser inválido; el interior trabaja con ese tipo | La misma validación repetida dentro del sistema; funciones internas que vuelven a comprobar si un valor es nulo, vacío o tiene el formato correcto |
| **Comprobaciones estrictas del compilador** | El modo estricto del lenguaje está activado (por ejemplo, `strict` en TypeScript, *nullable reference types* y advertencias como errores en C#, `set -euo pipefail` en bash) | Valores que pueden ser nulos sin que el tipo lo diga; advertencias del compilador ignoradas |

Lo que un linter del stack pueda detectar (complejidad y largo máximos por función, `catch` vacíos, variables globales, ShellCheck en scripts) SHOULD ir a la CI (L3): así deja de depender de que alguien lo recuerde. El perfil lista qué reglas del nivel 1 cubre su CI.

## 4. Nivel 2: principios y patrones condicionales

| Principio o patrón | Cuándo sí | Cuándo no |
|---|---|---|
| **Abierto/cerrado** | La variación ya existe: hay dos o más variantes reales, o están en el backlog | Para «facilitar extensiones futuras» que nadie pidió |
| **DRY (no repetirse)** | A la **tercera** repetición del mismo conocimiento, no del mismo texto | Dos fragmentos que se parecen pero cambian por motivos distintos: unificarlos crea la abstracción equivocada |
| **Interfaz o abstracción** | Hay dos implementaciones, o las pruebas necesitan sustituir la dependencia y el lenguaje no permite hacerlo sin una interfaz | Una sola implementación sin otra a la vista |
| **Repository** | Varias fuentes de datos para el mismo agregado, consultas complejas que se repiten entre funcionalidades, o un ADR que lo pide | Encima de un ORM que ya es un repositorio, con una sola fuente y consultas simples |
| **Strategy** | Varias formas de hacer lo mismo elegidas en tiempo de ejecución, ya presentes o en el backlog | Una sola forma, o dos que no cambian |
| **Observer / eventos** | Varios consumidores independientes de un mismo hecho, o desacoplar módulos que de otro modo se llamarían en cadena | Un solo consumidor conocido: una llamada directa es más clara y más fácil de depurar |
| **Factory** | La creación tiene lógica real (elegir tipo, validar, ensamblar varias piezas) | Un `new` con parámetros |
| **Mediator, CQRS, bus de comandos** | Un ADR que lo justifica por escala, auditoría o separación de modelos de lectura y escritura | Un CRUD |
| **Genéricos y plugins** | Tres casos concretos que comparten la forma | El primer caso |
| **Tipos propios para conceptos del dominio** (*value objects*: un monto, un correo, un periodo) | El concepto tiene reglas propias (rango, formato, redondeo) que hoy se comprueban en más de un lugar, o un error de unidades ya costó un defecto | Un valor sin reglas, que solo se transporta |
| **Estados imposibles irrepresentables** (uniones discriminadas, máquinas de estado tipadas) | Un objeto con campos que solo tienen sentido en ciertos estados, y combinaciones inválidas que ya aparecieron | Dos o tres estados simples que un enumerado expresa bien |

La tabla no es exhaustiva. Todo patrón del nivel 2 se decide con la misma pregunta: **¿qué razón presente lo justifica, y qué costaría añadirlo más adelante si se respeta el nivel 1?** Si la respuesta a la segunda es «poco», se espera.

## 5. Nota de diseño

El **orquestador** decide el nivel 2 y actúa como diseñador senior del equipo. Por eso MUST correr en el modelo más capaz disponible (06 §11): elegir un patrón, y sobre todo decidir no usarlo, es razonamiento, no redacción.

**Cuándo:**
- en cada historia o enabler T2/T3, al dividir en tareas y antes de `Ready`: una nota de diseño por tarea;
- a demanda: si el programador tiene una duda de diseño a mitad de una tarea, termina con `BLOCKED` y la pregunta; el orquestador responde con una nota nueva o una enmienda.

**Con qué decide:** con hechos, no con el relato de otro agente (00 §7):
- la historia, sus criterios y el contrato de interfaz;
- los ADR y el **catálogo de diseño** del proyecto (§6);
- un **resumen estructural** generado por una herramienta: los archivos y las firmas públicas, sin el código de las implementaciones; o, si el proyecto lo usa, un grafo de código generado por análisis sintáctico, del que solo cuentan como hechos las relaciones extraídas del código, no las inferidas;
- la pregunta del programador, si la hay.

**Qué produce** (plantilla `templates/design-note.md`):
- qué piezas crear o cambiar, dónde y con qué responsabilidad cada una;
- qué patrón del nivel 2 se usa, con su razón presente;
- **qué no se hace**, de forma explícita («no se crea interfaz para X: hay una sola implementación»), con el mismo peso que lo que sí;
- cómo se aplica el nivel 1 donde no es obvio (por ejemplo, dónde termina la lógica y empieza la entrada/salida).

La nota va en la especificación de la tarea y la aprueba el responsable humano con el resto del PR de pruebas y tareas. Una decisión que vale para más de una historia sube a un ADR (01 §4).

## 6. Catálogo de diseño del proyecto

Cada proyecto mantiene `docs/design-catalog.md` (plantilla `templates/design-catalog.md`): qué patrones del nivel 2 usa, dónde, por qué y qué se decidió no usar. Es la memoria de diseño del proyecto: sin él, cada nota de diseño vuelve a decidir lo mismo, o decide distinto.

El orquestador lo actualiza en el cierre de cada elemento con lo que las notas de diseño introdujeron.

## 7. Verificación

- La nota de diseño es parte del contrato de la tarea: el verificador revisa el diff contra ella igual que contra la superficie de cambio. Un patrón que la nota no autoriza o una pieza con otra responsabilidad que la asignada es un hallazgo.
- El verificador revisa el diff contra los síntomas del nivel 1 (§3).
- Lo que detecta un linter en la CI no hace falta revisarlo a mano; lo que no, sí.
