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

### 2.1 Contrato de interfaz antes de las pruebas

QA no puede escribir pruebas útiles antes de que exista el código si no sabe por dónde entrar al sistema. Cuando la historia introduce o modifica una frontera observable, el orden es:

1. criterios de aceptación aprobados;
2. **contrato de interfaz** propuesto por el arquitecto/orquestador, en el plan técnico de la historia (03 §1.2): el punto de entrada observable que usarán las pruebas. Por defecto, la frontera externa del sistema:
   - HTTP/API: método, ruta, payload, códigos y forma de la respuesta;
   - CLI: comando, argumentos, salida y código de salida;
   - UI: flujo y selectores estables acordados (por ejemplo, `data-testid`);
   - librería: firmas públicas mínimas;
3. pruebas de aceptación escritas por QA contra ese contrato.

Las pruebas de aceptación MUST ejercitar comportamiento a través del contrato de interfaz, no detalles internos. Si el programador necesita cambiar el contrato, la tarea pasa a `BLOCKED` y se resuelve por control de cambios; el programador no adapta las pruebas. Si el contrato no puede definirse por incertidumbre real, primero se ejecuta un Spike cuyo resultado es precisamente el contrato.

### 2.2 RED confirmado

Una prueba que ya pasa antes del cambio no verifica el código nuevo: puede no estar ejercitando el comportamiento en absoluto. El paso rojo demuestra que la prueba es capaz de detectar la funcionalidad ausente.

Antes de que una historia pase a `Ready`, QA MUST ejecutar la suite de aceptación contra la rama base y registrar que **cada prueba nueva falla por la razón esperada** (por ejemplo, «404 en `/notifications`», no «error de importación» ni «timeout»). Una prueba nueva que pasa en verde contra la base se considera defectuosa hasta que se justifique. Este registro (`acceptance-baseline` en el plan de pruebas o artefacto de CI) forma parte de la DoR de la historia.

RED confirmado exige, además:

- que **todas** las pruebas nuevas se hayan **ejecutado**. Un error de compilación, de configuración o de arranque no es RED: no demuestra que ninguna aserción falle. Tampoco lo es una prueba que no llegó a correr (por ejemplo, por un modo serie que detiene la suite al primer fallo) ni una prueba omitida;
- que la comprobación la haga una **herramienta**, la misma en el entorno de QA y en la CI, sobre el reporte de la ejecución. «Las corrí por separado» no es evidencia: en el sandbox de AES, QA reportó un RED con dos pruebas sin ejecutar y la herramienta lo detectó;
- una única excepción, el **RED de arranque**: cuando la base todavía no tiene código de aplicación (el primer enabler), se acepta que ninguna prueba se ejecute porque no hay nada que arrancar. La herramienta solo la admite si la base no tiene código.

### 2.3 Pruebas visibles y holdout

La suite de aceptación SHOULD dividirse (MUST en T3) en:

- **visibles**: el programador puede leerlas y ejecutarlas; le dan el bucle de retroalimentación;
- **holdout**: variantes de los mismos criterios con datos y casos distintos, almacenadas donde el entorno del programador no tiene acceso (repositorio separado, rama sin permisos o directorio no montado). Solo las ejecutan la CI y el verificador.

Cuando una prueba holdout falla, el programador recibe el ID del criterio y el comportamiento observado, **no el código de la prueba**. Objetivo: detectar implementaciones ajustadas a los datos visibles (valores codificados, ramas especiales para el caso de prueba) sin quitar el feedback. Proporción orientativa: 20–30 % de los escenarios; el perfil la ajusta.

### 2.4 Pruebas de caracterización

A veces un criterio nuevo describe algo que el código **ya hace** (por ejemplo, el mismo mensaje de error en el formulario de alta que la historia nueva exige en el de edición). Su prueba pasa contra la base, así que no puede demostrar RED, y la regla de §2.2 la rechazaría junto con todo el conjunto.

Esas pruebas son de **caracterización**: documentan un comportamiento existente. Reglas:

- viven en la suite de la historia **dueña** de ese comportamiento (con su etiqueta, por ejemplo `@US-001`), y llevan en el título el ID del criterio nuevo para la trazabilidad;
- corren en la regresión desde que se integran;
- el criterio nuevo declara «Verificación: regresión de <ID>» y **no** aparece en el archivo de criterios de ninguna tarea (§12), porque no tiene pruebas propias que ejecutar;
- QA las marca como tales en el plan, y el responsable humano las aprueba con el resto.

No se inventan etiquetas que la CI no ejecuta: una prueba que nunca corre no verifica nada.

### 2.5 Aislamiento de datos

Las pruebas de aceptación corren en paralelo y comparten datos (la misma base, el mismo periodo, la misma lista). Cada prueba MUST:

- crear sus propios datos y buscarlos por algo que solo ella usa (una marca única en un texto, un periodo propio);
- no comparar totales o conteos globales que otras pruebas pueden cambiar mientras corre;
- no depender del orden de ejecución ni de lo que dejó otra prueba.

Una prueba que falla a veces no es ruido: es un defecto de severidad Alta (02 §9) si corre en la regresión de la rama principal, porque puede ponerla en rojo para todos.

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

Los cambios en pruebas protegidas requieren un cambio aprobado del requisito o una corrección de prueba demostrada, revisión independiente y aprobación de un responsable autorizado.

La CI MUST ejecutar la suite protegida obtenida desde la rama protegida (o verificar su integridad contra un manifiesto almacenado en ella), nunca la versión presente en la rama del agente. Este es un control de capa L3 (06 §9). CODEOWNERS, protección de rama, montajes de solo lectura y repositorios separados lo complementan.

No basta con confiar en el prompt del programador, ni tampoco en los permisos de su harness: un permiso que niega editar un archivo no impide escribirlo mediante la terminal.

## 6. Verificación de pruebas

Si una prueba falla, el equipo debe clasificar la causa antes de cambiar código o prueba:

- defecto de implementación;
- defecto en la prueba;
- requisito contradictorio o incompleto;
- entorno/configuración;
- dependencia externa.

El agente no debe borrar, deshabilitar, reducir aserciones ni cambiar datos esperados para ocultar un fallo. La corrección de una prueba es legítima solo si se demuestra que la prueba contradice el requisito aprobado o es técnicamente incorrecta.

Una prueba **inestable** (falla sin cambio de código) es técnicamente incorrecta. Se registra como defecto (02 §9), la corrige QA por el flujo autorizado de pruebas protegidas, y su comprobación no es un RED sino evidencia de estabilidad: el número de corridas que fallaban antes y una serie de corridas sin fallo después (el perfil fija cuántas; por ejemplo, 10). Su corrección no cambia lo que la prueba exige.

## 7. Calidad estática y seguridad

El perfil de proyecto debe declarar herramientas y umbrales aplicables: formato, lint, tipos, análisis estático, dependencias, secretos, vulnerabilidades y migraciones. Los umbrales deben ser razonados para el proyecto; AES no impone un porcentaje universal de cobertura.

Los cambios que afectan autenticación, autorización, datos personales, pagos, secretos, límites de confianza o migraciones requieren revisión reforzada y pruebas negativas pertinentes.

El **análisis estático de seguridad** (SAST, con reglas mapeadas a OWASP y CWE) SHOULD ejecutarse en la CI de cada tarea sobre lo que la tarea cambia:

- un hallazgo **nuevo** de severidad alta en el diff falla la tarea: es un hallazgo de la tarea (ciclo `FAIL`);
- un hallazgo nuevo de severidad menor y los hallazgos **preexistentes** no bloquean la tarea: el orquestador los registra como defectos con severidad (02 §9), y la compuerta de estabilización hace el resto;
- un falso positivo se suprime en la configuración de la herramienta, con motivo, y como cualquier marcador del guardián exige aprobación humana (05 §10).

La comprobación de dependencias con vulnerabilidades conocidas sigue la política del perfil.

Si el proyecto tiene interfaz, un **detector determinista de interfaz** (contraste, legibilidad, desbordes, accesibilidad básica, desviaciones del sistema visual del proyecto) SHOULD ejecutarse en la CI de cada tarea sobre los archivos de interfaz que cambia. Mientras el proyecto no haya decidido qué reglas bloquean, sus hallazgos se anotan en el PR y el orquestador los registra como defectos; después, las reglas que el perfil declare bloqueantes fallan la tarea, igual que el SAST. Las revisiones de diseño de un agente (crítica, puntuaciones de estilo) son hallazgos, no evidencia (00 §7).

## 8. Cobertura y mutation testing

La cobertura es una señal, no prueba de calidad. No se debe optimizar el porcentaje a costa de aserciones significativas.

Mutation testing SHOULD aplicarse a lógica crítica, autorización, cálculos sensibles y áreas donde sea importante saber si las pruebas detectan defectos. Su uso puede ser selectivo por coste.

## 9. Evidencia

Los resultados se registran con comando, estado (`PASS`, `FAIL`, `NOT RUN`, `BLOCKED`), entorno o versión relevante y resumen. No se aceptan pruebas reportadas como ejecutadas sin salida o evidencia verificable.

La evidencia válida es la salida capturada por la CI o por una herramienta que ejecuta el comando y registra su salida real (por ejemplo, el patrón `exec` de Showboat descrito por Simon Willison). Registrar la salida real, en lugar de lo que el agente esperaba que ocurriera, desincentiva fingir resultados. El texto redactado por un agente sobre lo que ejecutó no es evidencia.

Un check verde no prueba que se ejecutó lo esperado. La CI MUST imprimir qué ejecutó (tipo de rama, elemento, criterios o etiquetas, número de pruebas), y el orquestador y el humano lo confirman en el log antes de dar el gate por superado. En el sandbox de AES, un cierre salió en verde sin ejecutar ni una prueba de su historia.

Las afirmaciones sobre el repositorio se comprueban en su fuente (00 §7).

## 10. Guardián de CI: superficie de cambio y detector de trampas

La CI MUST incluir un guardián que, como mínimo:

1. **rechaza modificaciones a rutas protegidas** (suite de aceptación, especificaciones, CI, configuración de agentes, hooks, `AGENTS.md`/`CLAUDE.md`);
2. **compara el diff con la superficie de cambio** de la tarea, leída desde la rama protegida;
3. **rechaza cambios en manifiestos y lockfiles** de dependencias sin aprobación;
4. **detecta archivos de prueba eliminados**;
5. **busca marcadores de trampa en las líneas añadidas**:

| Señal | Ejemplos |
|---|---|
| Pruebas omitidas | `.skip(`, `xit(`, `xdescribe(`, `@Disabled`, `@Ignore`, `#[ignore]`, `pytest.mark.skip`, `[Fact(Skip=` |
| Analizadores silenciados | `eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `# type: ignore`, `#pragma warning disable`, `noqa` |
| Errores tragados | `catch {}` o `catch (e) {}` vacíos, `except: pass` |

Una coincidencia no siempre es trampa, pero siempre requiere justificación en el reporte de la tarea y una aprobación explícita de alguien distinto del programador. El perfil añade los patrones propios de su stack.

Dos precisiones aprendidas en la práctica:

- **Dependencias** incluye las fuentes de paquetes y las herramientas locales, no solo los manifiestos: cambiar de dónde salen los paquetes es tan sensible como cambiar un paquete (por ejemplo, `nuget.config`, `.npmrc`, `pip.conf`, `global.json`, manifiestos de herramientas).
- **El código generado** por herramientas (por ejemplo, migraciones) contiene marcadores que nadie escribió a mano. Si el guardián lo excluye de la búsqueda, la exclusión MUST ser estrecha: una ubicación conocida **y** el encabezado de generación, de modo que un encabezado puesto a mano en otro archivo no esconda un marcador. Los archivos excluidos se listan en la salida para el verificador.

La cobertura de los archivos tocados SHOULD compararse con el baseline; una caída se trata igual que un marcador de trampa.

## 11. Prueba manual agéntica

Que todas las pruebas pasen no garantiza que el programa arranque o que un elemento de la interfaz sea visible. Para T2 y T3 con interfaz de usuario o API, el verificador MUST arrancar la aplicación y ejercitar los flujos de los criterios con la herramienta adecuada:

- APIs: servidor de desarrollo y peticiones reales (`curl` o equivalente);
- interfaces web: automatización de navegador (por ejemplo, Playwright) con capturas;
- CLI y librerías: ejecución real, con scripts temporales fuera del repositorio.

Las salidas y capturas se adjuntan al informe de verificación. Un defecto encontrado así se clasifica (02 §9.3): si es de lo que añade la tarea, es un ciclo `FAIL`; si no, se registra como T1 con severidad y se corrige con RED/GREEN, de modo que quede una comprobación automatizada permanente.

Reglas adicionales:

- **Sin prueba manual no hay `PASS`.** Si el track la exige y el verificador no pudo hacerla, el resultado es `BLOCKED`, no `PASS`: las pruebas automatizadas, aunque pasen, no la sustituyen. En el sandbox de AES, un verificador la omitió porque «la aceptación ya usa servidores reales».
- La prueba manual usa **datos distintos** de los de las pruebas automatizadas.
- Los servidores se arrancan y se detienen con una herramienta que **siempre** detiene lo que arrancó y solo eso, sobre datos temporales propios, y que falla si el puerto ya está ocupado en lugar de reutilizar un servidor ajeno (06 §10).

## 12. Qué ejecuta la CI en cada fase

La CI decide qué pruebas ejecutar según el tipo de rama y la rama destino (`dev` o `main`, 07 §7). El perfil fija los nombres de rama; la intención es esta:

| Fase | Qué ejecuta |
|---|---|
| Especificación de un T1 con comando de verificación | El comando, que **debe fallar** (RED), salvo «sin RED» aprobado |
| Pruebas de aceptación de un elemento (`qa/<ID>`) | Las pruebas del elemento, que **deben ejecutarse y fallar** (RED, §2.2) |
| Tarea | Guardián + validaciones + los criterios que declara la tarea (o el elemento completo, si es la última) + regresión |
| Cierre del elemento | El elemento completo, que **debe ejecutarse y pasar**, + regresión |
| `dev` y `main` | Regresión de todos los elementos cerrados en esa rama |
| Release (`dev` → `main`) | Regresión completa + compuerta de estabilización + `main` contenido en `dev` (07 §8) |
| Back-merge (`main` → `dev`) | Regresión completa de `dev` |

Reglas:

- El archivo de criterios de cada tarea se lee de la **rama protegida**, igual que la superficie de cambio.
- La regresión incluye las pruebas de aceptación **y** los comandos de verificación de todos los elementos cerrados.
- Un **comando de verificación** es un criterio que no se comprueba con una prueba de aceptación (configuración, herramientas, scripts, build). Es un script versionado en la ruta protegida del elemento, que termina con código 0 si el criterio se cumple. Se trata como una prueba protegida: lo escribe quien escribe las pruebas, lo aprueba el humano y la CI lo ejecuta desde la rama protegida.
- Entre la integración de la última tarea de un elemento y la de su cierre no se integra nada más en esa rama (`dev`, o `main` en un hotfix): durante ese intervalo la regresión todavía no incluye el elemento.
- La lista de elementos en regresión es un archivo versionado. Viaja con los releases y los back-merges, así que la regresión de `main` cubre lo liberado y la de `dev`, todo lo integrado.
