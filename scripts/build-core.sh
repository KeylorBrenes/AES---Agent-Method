#!/usr/bin/env bash
# Genera AES-CORE.md concatenando los capítulos de standard/ en orden.
# Uso: ./scripts/build-core.sh          (escribe AES-CORE.md)
#      ./scripts/build-core.sh --check  (falla si AES-CORE.md no está al día)
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(sed -nE 's/^\*\*Versi(o|ó)n:\*\* *([0-9.]+).*/\2/p' README.md | head -n1)
[[ -n "$version" ]] || { echo "No se encontró la versión en README.md" >&2; exit 1; }

tmp=$(mktemp)
{
  printf '# Agentic Engineering Standard — AES Core %s\n\n' "$version"
  printf '<!-- Archivo generado por scripts/build-core.sh a partir de standard/. No editar a mano. -->\n\n'
  first=1
  for f in standard/[0-9][0-9]-*.md; do
    if [[ $first -eq 0 ]]; then printf '\n---\n\n'; fi
    first=0
    cat "$f"
  done
} > "$tmp"

if [[ "${1:-}" == "--check" ]]; then
  if ! diff -q "$tmp" AES-CORE.md >/dev/null 2>&1; then
    echo "AES-CORE.md no está al día. Ejecuta ./scripts/build-core.sh" >&2
    rm -f "$tmp"; exit 1
  fi
  rm -f "$tmp"; echo "AES-CORE.md al día."
else
  mv "$tmp" AES-CORE.md
  echo "AES-CORE.md generado (AES $version)."
fi
