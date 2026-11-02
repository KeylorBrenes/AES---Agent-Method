#!/usr/bin/env bash
# AES 1.1.0 — Hook PreToolUse (capa L2).
# Bloquea escrituras del agente a rutas protegidas. Código de salida 2 = bloquear
# la herramienta y devolver stderr al modelo.
# Usar en sesiones con rol programador/verificador. La sesión de QA usa otra configuración.
# Requiere jq.
input=$(cat)
f=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<< "$input")
[[ -z "$f" ]] && exit 0

# Normalizar a ruta relativa al proyecto cuando sea posible.
root="${CLAUDE_PROJECT_DIR:-$PWD}"
rel="${f#"$root"/}"

case "$rel" in
  tests/acceptance/*|specs/*|ci/*|.github/*|.claude/*|.opencode/*|AGENTS.md|CLAUDE.md|opencode.json|*/AGENTS.md|*/CLAUDE.md)
    echo "AES: '$rel' es una ruta protegida para este rol. Si necesitas cambiarla, detente y reporta BLOCKED con el motivo." >&2
    exit 2 ;;
esac
exit 0
