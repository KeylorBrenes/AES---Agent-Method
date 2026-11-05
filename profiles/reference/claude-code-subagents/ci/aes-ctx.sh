#!/usr/bin/env bash
# AES 1.2.0 — Contexto de la CI: qué tipo de rama es y qué debe ejecutarse (standard/05 §12).
#
# La lógica vive aquí y no en el workflow para poder probarla en local. El workflow ejecuta
# la copia de la rama protegida (base), igual que el guardián.
#
# Variables de entrada:
#   EVENT        pull_request | push
#   HEAD_BRANCH  rama del PR (vacía en push)
#   BASE         ref protegida con la que se compara (p. ej. origin/main); en push, HEAD
#
# Imprime líneas clave=valor (para $GITHUB_OUTPUT):
#   kind     task | qa | spec | close | other | main
#   item     ID del elemento (US-002, BUG-004, ST-001...) o vacío
#   task     ID de la tarea (solo kind=task)
#   wanted   etiquetas de Playwright del elemento en curso, sin @, separadas por |
#   active   elementos cerrados en regresión (specs/active-stories.txt de la base), separados por |
#   verify_green  comandos de verificación que deben PASAR (rutas en la base), separados por espacio
#   verify_red    comandos de verificación nuevos de esta rama que deben FALLAR (rutas en la rama)
set -euo pipefail

EVENT="${EVENT:-push}"
HEAD_BRANCH="${HEAD_BRANCH:-}"
BASE="${BASE:-HEAD}"

kind=main; item=""; task=""
if [[ "$EVENT" == "pull_request" ]]; then
  case "$HEAD_BRANCH" in
    task/*/*)     kind=task; item=$(cut -d/ -f2 <<< "$HEAD_BRANCH"); task=$(cut -d/ -f3 <<< "$HEAD_BRANCH") ;;
    qa/*)         kind=qa;   item=${HEAD_BRANCH#qa/} ;;
    spec/*-close) kind=close; item=${HEAD_BRANCH#spec/}; item=${item%-close} ;;
    spec/*)       kind=spec; item=${HEAD_BRANCH#spec/} ;;
    *)            kind=other ;;
  esac
fi

clean_list() { sed 's/#.*//' | tr -d ' \r' | { grep -v '^$' || true; }; }

# Elementos cerrados (regresión): siempre la versión de la base.
active=$( { git show "$BASE:specs/active-stories.txt" 2>/dev/null || true; } | clean_list | paste -sd'|')

# Criterios de la tarea, leídos de la base (igual que la superficie). Sin archivo: elemento completo.
wanted=""; criteria=""
if [[ -n "$item" && ( "$kind" == "task" || "$kind" == "close" ) ]]; then
  wanted="$item"
  if [[ "$kind" == "task" ]]; then
    criteria=$( { git show "$BASE:specs/$item/$task.criteria" 2>/dev/null || true; } | clean_list | { grep -E '^(AC-[0-9]+|BUG-[0-9]+)$' || true; })
    if [[ -n "$criteria" ]]; then
      # AC-NN → <item>-AC-NN ; BUG-NNN → BUG-NNN (la etiqueta propia del defecto)
      wanted=$(sed -E "s/^(AC-[0-9]+)$/$item-\1/" <<< "$criteria" | paste -sd'|')
    fi
  fi
fi

# Comandos de verificación (specs/<ID>/*.verify).
list_verify() {  # list_verify <ref> <item>
  git ls-tree -r --name-only "$1" -- "specs/$2/" 2>/dev/null | { grep -E '\.verify$' || true; }
}
verify_green=""; verify_red=""
# Regresión: los de todos los elementos cerrados (en tareas, cierre y main).
if [[ "$kind" != "qa" && "$kind" != "spec" ]]; then
  while IFS= read -r a; do
    [[ -z "$a" ]] && continue
    verify_green+=" $(list_verify "$BASE" "$a" | paste -sd' ')"
  done <<< "$(tr '|' '\n' <<< "$active")"
fi
# El elemento en curso.
if [[ -n "$item" ]]; then
  case "$kind" in
    task)
      if [[ -n "$criteria" ]]; then
        while IFS= read -r c; do
          [[ "$c" =~ ^BUG- ]] || continue
          git cat-file -e "$BASE:specs/$item/$c.verify" 2>/dev/null && verify_green+=" specs/$item/$c.verify"
        done <<< "$criteria"
        git cat-file -e "$BASE:specs/$item/$item.verify" 2>/dev/null && verify_green+=" specs/$item/$item.verify"
      else
        verify_green+=" $(list_verify "$BASE" "$item" | paste -sd' ')"
      fi
      ;;
    close)
      verify_green+=" $(list_verify "$BASE" "$item" | paste -sd' ')"
      ;;
    qa|spec)
      # RED: solo los comandos que esta rama añade o cambia.
      verify_red=$(git diff --name-only --diff-filter=AM "$BASE"...HEAD -- "specs/$item/" 2>/dev/null \
        | { grep -E '\.verify$' || true; } | paste -sd' ')
      ;;
  esac
fi
verify_green=$(tr ' ' '\n' <<< "$verify_green" | { grep -v '^$' || true; } | sort -u | paste -sd' ')

echo "kind=$kind"
echo "item=$item"
echo "task=$task"
echo "wanted=$wanted"
echo "active=$active"
echo "verify_green=$verify_green"
echo "verify_red=$verify_red"
