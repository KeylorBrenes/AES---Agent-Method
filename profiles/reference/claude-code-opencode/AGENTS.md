# AGENTS.md — [Proyecto]

<!--
AES 1.1.0 (06 §5.1): breve, estructural, crece una entrada por error real.
Sin instrucciones genéricas tipo «usa TDD» o «escribe buen código».
Este archivo está en una ruta protegida: el programador no puede editarlo.
-->

## Comandos
- Instalar: `npm ci`
- Pruebas unitarias: `npm test -- <ruta>`
- Aceptación de una historia: `npm run test:acceptance -- --grep "US-NNN"`
- Lint y tipos: `npm run lint && npm run typecheck`

## Rutas
- No editables por el programador: `tests/acceptance/`, `specs/`, `ci/`, `.github/`, `.claude/`, `opencode.json`, este archivo.
- Tu superficie de cambio está en `specs/US-NNN/TASK-NNN.scope`. Lo que no esté ahí, no se toca.

## Restricciones de arquitectura
- [p. ej. la capa de UI no importa directamente de `db/`]

## Convenciones que el linter no detecta
- [p. ej. los errores de dominio se lanzan como `DomainError`, nunca `Error` genérico]

## Fallos observados (de docs/agent-failure-log.md)
<!-- Añadir una línea por patrón confirmado, con su ID FL-NNN. -->
