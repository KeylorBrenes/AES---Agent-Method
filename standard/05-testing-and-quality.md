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

Los cambios en pruebas protegidas requieren un cambio aprobado del requisito o una corrección de prueba demostrada, revisión independiente y aprobación de un responsable autorizado. La CI debería obtener la suite protegida desde una rama/commit confiable o aplicar un control equivalente (CODEOWNERS, protección de rama, permisos de filesystem, contenedor o repositorio separado).

No basta con confiar en el prompt del programador.

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
