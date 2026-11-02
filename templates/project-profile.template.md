# Project Profile — [Nombre del proyecto]

- **AES version:** 1.1.0
- **Product owner / aprobador humano:** [rol/persona]
- **Orquestador/harness:** [herramienta/modelo]
- **Programador:** [herramienta/modelo]
- **QA:** [herramienta/modelo]
- **Verificador:** [herramienta/modelo]
- **Repositorio / ramas:** [URL o convención]

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
- Herramienta:
- Escala de prioridad:
- Escala de Story Points: Fibonacci 1, 2, 3, 5, 8, 13
- Estados:
- Criterios propios para clasificar tracks T0–T3 (si difieren de 02 §8):

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
- Presupuesto de diff orientativo por tarea:
- Herramienta de prueba manual agéntica (Playwright, curl, etc.):

## Controles en capas (06 §9)
| Control | L1 — Harness | L2 — Hooks | L3 — Fuera del agente |
|---|---|---|---|
| Suite de aceptación protegida | | | |
| Pruebas holdout inaccesibles | | | |
| Superficie de cambio | | | |
| Configuración de agentes/CI protegida | | | |
| No terminar con pruebas rojas | | | |
| Detector de trampas | | | |

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

## Riesgo y liberación
- Clasificación de riesgo:
- Controles High/Critical (T3):
- Migraciones/rollback:
- Aprobación de despliegue:

## Mejora del harness
- Ubicación del registro de fallos: `docs/agent-failure-log.md`
- Frecuencia de retrospectiva compuesta:

## Excepciones AES
| Regla | Motivo | Riesgo | Mitigación | Aprobador | Revisión/expiración |
|---|---|---|---|---|---|
