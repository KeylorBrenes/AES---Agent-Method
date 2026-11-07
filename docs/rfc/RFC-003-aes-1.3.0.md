# RFC-003 — AES 1.3.0

**Estado:** En curso. Se van incorporando los cambios que propone el responsable humano; el sandbox queda pausado hasta publicarla.
**Base:** AES 1.2.0
**Tipo de cambio esperado:** MINOR. El modelo de ramas cambia el flujo de los proyectos existentes: migrarlos exige crear `dev` y ajustar la CI (ver «Migración»).

## 1. Ramas `main` y `dev`, release, hotfix y back-merge — 00, 02, 05, 07, 08

**Problema.** Con una sola rama, todo lo que se integra queda como producto. Una épica de varias historias, o una funcionalidad que hay que usar una semana antes de confiar en ella, no tiene dónde vivir sin estar en `main`. Y un arreglo de algo ya liberado se hace sobre lo que está en construcción, así que puede arrastrar a `main` código a medias.

**Decisiones del responsable humano (2026-11-06):**

| Pregunta | Decisión | Motivo |
|---|---|---|
| ¿`dev` por defecto o siempre? | **Siempre**, también en proyectos pequeños | Una sola regla es más simple. `dev` no cambia el trabajo de los agentes; *trunk* con *feature flags* añade contexto, decisiones y código condicional |
| ¿Qué severidades pueden ir por hotfix? | **Todas**; el responsable decide la ruta de cada defecto | Limitarlo a Crítica y Alta impediría arreglar ya un defecto Medio que importa por otra razón |
| ¿El release exige un periodo mínimo de uso? | **No** | La evidencia es la aprobación humana del PR de release, después de usar `dev` lo que el responsable considere. Un plazo fijo es una aproximación y una opción más que configurar |

**Cambio.**
- `main` (lo liberado) y `dev` (lo integrado), ambas protegidas con la misma CI. Ramas de trabajo cortas desde `dev`; ninguna rama permanente de features ni de bugs (la «rama de bugs» propuesta se resuelve con ramas `hotfix` cortas desde `main`, que no se desfasan).
- Release `dev → main`: notas, compuerta de estabilización, comprobación de que `main` está contenido en `dev`, regresión completa, **merge commit**. Estado `Released`.
- Hotfix: ramas de trabajo de un `BUG-NNN` que nacen de `main` y vuelven a `main`.
- Back-merge `main → dev` con merge commit después de cada integración en `main`. La comprobación del release convierte el olvido en un fallo de la CI en lugar de en un defecto reintroducido.
- *Squash* solo en las ramas de trabajo: con *squash* en el release, los commits de `main` no existirían en `dev` y la comprobación fallaría siempre.

## 2. Checkout propio por rol (worktrees) — 06 §10

**Problema.** En el sandbox, el orquestador cambiaba de rama en el único checkout y los roles compartían archivos sin versionar y servidores (FL-007).

**Cambio.** El orquestador se queda en `dev`. Cada rol trabaja en su propio checkout de la rama de trabajo. En la referencia: `isolation: worktree` en los subagentes, más un hook `WorktreeCreate` que abre el worktree en la rama real (la que indica el orquestador con `aes-wt.sh delegate`) y copia la identidad de la app, que está fuera de git. Sin indicación, el hook falla y el subagente no arranca.

**Pendiente de comprobar en el sandbox:** que Claude Code use el hook `WorktreeCreate` también para los subagentes, el formato exacto de su evento y el `cwd` que recibe `SubagentStop` desde un worktree. Si algo no coincide, la referencia falla cerrada: el subagente no arranca, o el hook de rol lo bloquea por no estar en una rama de tarea.

## Migración de un proyecto en 1.2.0

1. `git push origin main:dev` y hacer `dev` la rama por defecto.
2. Aplicar los rulesets a `dev` y `main`; en `main`, solo merge commit.
3. Copiar el workflow, `ci/` y `.claude/` de la referencia 1.3.0; añadir `.claude/worktrees/` a `.gitignore`.
4. Los elementos ya cerrados quedan como `Released` (ya están en `main`).
