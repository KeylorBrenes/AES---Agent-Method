#!/usr/bin/env bash
# AES — Hook PreToolUse (capa L2).
# Bloquea escrituras del agente a rutas protegidas. Código de salida 2 = bloquear
# la herramienta y devolver stderr al modelo.
# Usar en sesiones con rol programador/verificador. La sesión de QA usa otra configuración.
# Para restringir por rol dentro de una misma sesión (subagentes), usa el campo agent_type
# de la entrada del hook; ver el ejemplo validado en el sandbox de AES.
# Requiere jq. Funciona con rutas POSIX y de Windows (H:\..., h:/..., /h/...).
input=$(cat)
f=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<< "$input")
[[ -z "$f" ]] && exit 0

norm() {
  local p="${1//\\//}"
  # Git Bash puede expresar H:/x como /h/x: unificar.
  if [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then p="${BASH_REMATCH[1]}:/${BASH_REMATCH[2]}"; fi
  printf '%s' "${p#./}"
}

file=$(norm "$f")
root=$(norm "$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}")")

# Ruta relativa al repo. En Windows la unidad no distingue mayúsculas (H: = h:).
if [[ "$file" =~ ^([a-zA-Z]:)?/ ]]; then
  lf=$(tr '[:upper:]' '[:lower:]' <<< "$file"); lr=$(tr '[:upper:]' '[:lower:]' <<< "$root")
  [[ "$lf" == "$lr"/* ]] || exit 0          # fuera del repositorio
  rel="${file:${#root}+1}"
else
  rel="$file"
fi

case "$rel" in
  tests/acceptance/*|specs/*|ci/*|.github/*|.claude/*|.opencode/*|AGENTS.md|CLAUDE.md|opencode.json|*/AGENTS.md|*/CLAUDE.md)
    echo "AES: '$rel' es una ruta protegida para este rol. Si necesitas cambiarla, detente y reporta BLOCKED con el motivo." >&2
    exit 2 ;;
esac
exit 0
