# Skills del núcleo de AES

Skills propias de AES, escritas para sus gates, contratos y roles (`standard/06` §6.2), en el formato abierto de [Agent Skills](https://agentskills.io) (`SKILL.md` con `name` y `description`). No son obligatorias: un proyecto puede usar otras equivalentes si cumplen las reglas de 06 §6.2.

| Skill | Tipo | Rol | Cuándo |
|---|---|---|---|
| [`aes-debugging`](aes-debugging/SKILL.md) | Técnica | Programador, mecánico; orquestador al clasificar | Ante cualquier fallo antes de arreglar: ciclo FAIL, defecto, prueba inestable |
| [`aes-security-review`](aes-security-review/SKILL.md) | Herramienta | Programador; orquestador al clasificar | Antes de entregar una tarea sensible, ante un hallazgo de SAST en la CI |
| [`aes-inception`](aes-inception/SKILL.md) | Técnica | Orquestador | Al empezar un proyecto (no hay backlog) o ante una idea que no cabe en el backlog (mini-incepción) |
| [`aes-design-note`](aes-design-note/SKILL.md) | Técnica | Orquestador | Al dividir una historia en tareas; ante una pregunta de diseño |

El flujo del ciclo no está aquí: es la skill del orquestador de cada implementación de referencia (por ejemplo, `profiles/reference/claude-code-subagents/.claude/skills/aes-cycle/`), porque depende del harness.

## Uso en un proyecto

El instalador las copia con todo lo demás, en la versión fija de AES de la que lo ejecutas:

```bash
./scripts/install-aes.sh /ruta/al/proyecto
```

Después, regístralas en el perfil del proyecto (origen, versión, quién las revisó, qué roles las usan). No las enlaces a una rama que cambie: una skill que cambia sola cambia las instrucciones de los agentes sin aprobación.

## Skills de terceros recomendadas

No son parte de AES y no viajan en este repositorio. Si el proyecto las usa, el instalador las copia desde una carpeta local en la versión que tengas (`--vendor <carpeta>`) y anota su versión en `docs/aes/skills.lock`.

| Skill | Tipo | Licencia | Para qué en AES | Ajuste obligatorio |
|---|---|---|---|---|
| [archify](https://github.com/tt-a1i/archify) | Herramienta | MIT | Diagramas HTML validados desde JSON (arquitectura, flujo, secuencia, flujo de datos, ciclo de vida): el diagrama de componentes de la incepción, notas de diseño con flujo, ciclos de vida de una entidad | Desactivar su aviso de actualizaciones (`ARCHIFY_UPDATE_CHECK_DISABLED=1`, 06 §6.2). Se versiona el JSON; el HTML se genera en `.aes/` |

## Atribución

`aes-debugging` toma como referencia `systematic-debugging` de [obra/superpowers](https://github.com/obra/superpowers) (licencia MIT).
