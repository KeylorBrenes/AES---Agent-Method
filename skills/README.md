# Skills del núcleo de AES

Skills propias de AES, escritas para sus gates, contratos y roles (`standard/06` §6.2), en el formato abierto de [Agent Skills](https://agentskills.io) (`SKILL.md` con `name` y `description`). No son obligatorias: un proyecto puede usar otras equivalentes si cumplen las reglas de 06 §6.2.

| Skill | Tipo | Rol | Cuándo |
|---|---|---|---|
| [`aes-debugging`](aes-debugging/SKILL.md) | Técnica | Programador, mecánico; orquestador al clasificar | Ante cualquier fallo antes de arreglar: ciclo FAIL, defecto, prueba inestable |
| [`aes-security-review`](aes-security-review/SKILL.md) | Herramienta | Programador; orquestador al clasificar | Antes de entregar una tarea sensible, ante un hallazgo de SAST en la CI |
| [`aes-design-note`](aes-design-note/SKILL.md) | Técnica | Orquestador | Al dividir una historia en tareas; ante una pregunta de diseño |

El flujo del ciclo no está aquí: es la skill del orquestador de cada implementación de referencia (por ejemplo, `profiles/reference/claude-code-subagents/.claude/skills/aes-cycle/`), porque depende del harness.

## Uso en un proyecto

Copia las carpetas a la ubicación de skills de tu harness (en Claude Code, `.claude/skills/`), en una versión fija de AES, y regístralas en el perfil del proyecto (origen, versión, quién las revisó, qué roles las usan). No las enlaces a una rama que cambie: una skill que cambia sola cambia las instrucciones de los agentes sin aprobación.

## Atribución

`aes-debugging` toma como referencia `systematic-debugging` de [obra/superpowers](https://github.com/obra/superpowers) (licencia MIT).
