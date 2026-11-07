#!/usr/bin/env bash
# Copia las skills del núcleo (skills/) a la implementación de referencia de Claude Code.
# Uso: ./scripts/sync-skills.sh          (copia)
#      ./scripts/sync-skills.sh --check  (falla si las copias no coinciden)
set -euo pipefail
cd "$(dirname "$0")/.."
dest=profiles/reference/claude-code-subagents/.claude/skills
status=0
for dir in skills/*/; do
  name=$(basename "$dir")
  if [[ "${1:-}" == "--check" ]]; then
    if ! diff -rq "$dir" "$dest/$name" >/dev/null 2>&1; then
      echo "La copia de $name en $dest no está al día. Ejecuta ./scripts/sync-skills.sh" >&2
      status=1
    fi
  else
    rm -rf "${dest:?}/$name"; cp -r "$dir" "$dest/$name"
  fi
done
[[ "${1:-}" == "--check" && $status -eq 0 ]] && echo "Skills sincronizadas."
exit $status
