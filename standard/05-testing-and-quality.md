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
2. **contrato de interfaz** propuesto por el arquitecto/orquestador: el punto de entrada observable que usarán las pruebas. Por defecto, la frontera externa del sistema:
   - HTTP/API: método, ruta, payload, códigos y forma de la respuesta;
   - CLI: comando, argumentos, salida y código de salida;
   - UI: flujo y selectores estables acordados (por ejemplo, `data-testid`);
   - librería: firmas públicas mínimas;
3. pruebas de aceptación escritas por QA contra ese contrato.

Las pruebas de aceptación MUST ejercitar comportamiento a través del contrato de interfaz, no detalles internos. Si el programador necesita cambiar el contrato, la tarea pasa a `BLOCKED` y se resuelve por control de cambios; el programador no adapta las pruebas. Si el contrato no puede definirse por incertidumbre real, primero se ejecuta un Spike cuyo resultado es precisamente el contrato.

### 2.2 RED confirmado

Una prueba que ya pasa antes del cambio no verifica el código nuevo: puede no estar ejercitando el comportamiento en absoluto. El paso rojo demuestra que la prueba es capaz de detectar la funcionalidad ausente.

Antes de que una historia pase a `Ready`, QA MUST ejecutar la suite de aceptación contra la rama base y registrar que **cada prueba nueva falla por la razón esperada** (por ejemplo, «404 en `/notifications`», no «error de importación» ni «timeout»). Una prueba nueva que pasa en verde contra la base se considera defectuosa hasta que se justifique. Este registro (`acceptance-baseline` en el plan de pruebas o artefacto de CI) forma parte de la DoR de la historia.

### 2.3 Pruebas visibles y holdout

La suite de aceptación SHOULD dividirse (MUST en T3) en:

- **visibles**: el programador puede leerlas y ejecutarlas; le dan el bucle de retroalimentación;
- **holdout**: variantes de los mismos criterios con datos y casos distintos, almacenadas donde el entorno del programador no tiene acceso (repositorio separado, rama sin permisos o directorio no montado). Solo las ejecutan la CI y el verificador.

Cuando una prueba holdout falla, el programador recibe el ID del criterio y el comportamiento observado, **no el código de la prueba**. Objetivo: detectar implementaciones ajustadas a los datos visibles (valores codificados, ramas especiales para el caso de prueba) sin quitar el feedback. Proporción orientativa: 20–30 % de los escenarios; el perfil la ajusta.

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

## 7. Calidad estática y seguridad

El perfil de proyecto debe declarar herramientas y umbrales aplicables: formato, lint, tipos, análisis estático, dependencias, secretos, vulnerabilidades y migraciones. Los umbrales deben ser razonados para el proyecto; AES no impone un porcentaje universal de cobertura.

Los cambios que afectan autenticación, autorización, datos personales, pagos, secretos, límites de confianza o migraciones requieren revisión reforzada y pruebas negativas pertinentes.

## 8. Cobertura y mutation testing

La cobertura es una señal, no prueba de calidad. No se debe optimizar el porcentaje a costa de aserciones significativas.

Mutation testing SHOULD aplicarse a lógica crítica, autorización, cálculos sensibles y áreas donde sea importante saber si las pruebas detectan defectos. Su uso puede ser selectivo por coste.

## 9. Evidencia

Los resultados se registran con comando, estado (`PASS`, `FAIL`, `NOT RUN`, `BLOCKED`), entorno o versión relevante y resumen. No se aceptan pruebas reportadas como ejecutadas sin salida o evidencia verificable.

La evidencia válida es la salida capturada por la CI o por una herramienta que ejecuta el comando y registra su salida real (por ejemplo, el patrón `exec` de Showboat descrito por Simon Willison). Registrar la salida real, en lugar de lo que el agente esperaba que ocurriera, desincentiva fingir resultados. El texto redactado por un agente sobre lo que ejecutó no es evidencia.

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

La cobertura de los archivos tocados SHOULD compararse con el baseline; una caída se trata igual que un marcador de trampa.

## 11. Prueba manual agéntica

Que todas las pruebas pasen no garantiza que el programa arranque o que un elemento de la interfaz sea visible. Para T2 y T3 con interfaz de usuario o API, el verificador MUST arrancar la aplicación y ejercitar los flujos de los criterios con la herramienta adecuada:

- APIs: servidor de desarrollo y peticiones reales (`curl` o equivalente);
- interfaces web: automatización de navegador (por ejemplo, Playwright) con capturas;
- CLI y librerías: ejecución real, con scripts temporales fuera del repositorio.

Las salidas y capturas se adjuntan al informe de verificación. Un defecto encontrado así se registra como T1 y se corrige con RED/GREEN, de modo que quede una prueba automatizada permanente.
L � n e a   d e   p r u e b a .  
 