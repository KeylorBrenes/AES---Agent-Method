# Project Profile — [Nombre del proyecto]

- **AES version:** 1.2.0
- **Product owner / aprobador humano:** [rol/persona]
- **Repositorio / ramas:** [URL o convención]
- **Copia local de DoR/DoD:** [p. ej. `docs/aes/08-definition-of-ready-and-done.md`, de AES 1.2.0]

## Roles: harness y modelo
El modelo real de cada ejecución se registra en las métricas (09 §6); si difiere de esta tabla, se anota.

| Rol | Harness | Modelo | Invocación | Identidad con la que publica |
|---|---|---|---|---|
| Orquestador | | | | |
| QA | | | | |
| Programador | | | | |
| Mecánico (opcional) | | | | |
| Verificador | | | | |

## Producto y contexto
- Objetivo:
- Usuarios:
- Restricciones:
- Entornos:

## Stack
- Lenguaje y versión:
- Framework y versión:
- Base de datos:
- Infraestructura/despliegue:
- Integraciones:

## Arquitectura y convenciones
- Directorios/módulos importantes:
- Patrones existentes que deben respetarse:
- Contratos y APIs:
- ADRs:
- Reglas de compatibilidad:

## Backlog
- Herramienta / ubicación:
- Prefijos de ID: historias `US-`, enablers `EN-`, defectos `BUG-`, chores `CH-`, lotes `ST-`, spikes `SP-`
- Escala de prioridad:
- Escala de Story Points: Fibonacci 1, 2, 3, 5, 8, 13
- Estados:
- Criterios propios para clasificar tracks T0–T3 (si difieren de 02 §8):

## Defectos y compuerta de estabilización (02 §9)
- Escala de severidad: Crítica / Alta / Media / Menor (ajustes propios, si los hay):
- Límite de defectos Menores abiertos (por defecto 5):
- Dónde se implementa la compuerta (CI, L3):
- Regla permanente para hallazgos tras un PASS del verificador (02 §9.3), p. ej. «lo que añade la tarea se corrige antes de integrar; lo demás va al backlog con severidad»:
- Corridas sin fallo exigidas para dar por estable una prueba corregida (05 §6):

## Calidad y pruebas
- Unit tests (comando):
- Integration tests (comando):
- E2E / aceptación (comando, con filtro por historia):
- Lint / formato:
- Tipos / análisis estático:
- Seguridad / dependencias:
- Umbrales justificados:
- Generación del test map (herramienta o método):
- Proporción de pruebas holdout:
- Presupuesto de diff orientativo por tarea (producción / pruebas):
- Herramienta de prueba manual agéntica (Playwright, curl, etc.):
- Herramienta que arranca y detiene servidores (06 §10) y puertos del proyecto:
- Herramienta que comprueba el RED (05 §2.2):
- Comandos de verificación por elemento (05 §12): ubicación y convención:
- Política de auditoría de dependencias (p. ej. `npm audit`, `dotnet list package --vulnerable`):

## Controles en capas (06 §9)
| Control | L1 — Harness | L2 — Hooks | L3 — Fuera del agente |
|---|---|---|---|
| Suite de aceptación protegida | | | |
| Pruebas holdout inaccesibles | | | |
| Superficie de cambio | | | |
| Configuración de agentes/CI protegida | | | |
| No terminar con pruebas rojas | | | |
| Detector de trampas | | | |
| RED confirmado por herramienta | | | |
| CI por criterio y por fase | | | |
| Compuerta de estabilización | | | |
| Aprobaciones en la CI validan quién (etiquetas) | | | |
| PASS del verificador antes de integrar | | | |
| Sin servidores ni procesos entre roles | | | |
| Acciones denegadas no se delegan | | | |
| Escrituras fuera del repositorio (aislamiento) | | | |

## Permisos y operación de agentes
- Rutas editables por programador:
- Rutas protegidas:
- Ubicación de las pruebas holdout:
- Operaciones que requieren aprobación:
- MCP/CLI expuestos:
- Skills instaladas y su origen:
- Gestión de secretos:
- Estrategia de ramas/worktrees:
- Umbral del circuit breaker (≤ 3):
- Notas del orquestador durante el ciclo (ubicación y script):

## Riesgo y liberación
- Clasificación de riesgo:
- Controles High/Critical (T3):
- Migraciones/rollback:
- Aprobación de despliegue:

## Mejora del harness
- Ubicación del registro de fallos: `docs/agent-failure-log.md`
- Ubicación del registro de hallazgos y métricas: `docs/harness-findings.md`
- Frecuencia de retrospectiva compuesta:

## Excepciones AES
| Regla | Motivo | Riesgo | Mitigación | Aprobador | Revisión/expiración |
|---|---|---|---|---|---|
