#!/usr/bin/env bash
# Instala o actualiza AES en un proyecto, desde esta copia de AES (una versión fija).
#
# Uso:
#   ./scripts/install-aes.sh <proyecto>                     instalación nueva
#   ./scripts/install-aes.sh <proyecto> --upgrade           actualización a esta versión
#   ./scripts/install-aes.sh <proyecto> --check             ¿coincide lo instalado con esta versión?
#   ... --vendor <carpeta-de-skill>  (repetible)            copia una skill de terceros y anota su versión
#   ... --profile <nombre>                                   implementación de referencia (por defecto
#                                                            claude-code-subagents)
#
# Qué copia (06 §6.2: todo en una versión fija, dentro del repositorio, revisado por PR):
#   - Archivos de AES: hooks, scripts, skills del núcleo, scripts de la CI, docs/aes/ (DoR/DoD,
#     AES-CORE.md, plantillas, VERSION). Se sobrescriben al actualizar: no se editan en el proyecto.
#   - Archivos semilla: subagentes, settings.json, aes.env, workflow, CODEOWNERS, validate.sh,
#     CLAUDE.md. El proyecto los adapta. Solo se copian si no existen; al actualizar, si la versión
#     de AES cambió, se deja al lado como <archivo>.aes-new para que lo compares a mano
#     (docs/aes/seeds.sha256 guarda la huella de las semillas entregadas).
#   - Skills de terceros (--vendor): se copian a la carpeta de skills y se anotan en
#     docs/aes/skills.lock (versión, origen y huella), sin descargar nada.
#
# El instalador no hace commits ni toca la configuración de GitHub: al terminar, lista lo que falta.
set -euo pipefail

aes_root=$(cd "$(dirname "$0")/.." && pwd)
target=""; mode=install; profile=claude-code-subagents; vendors=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --upgrade) mode=upgrade ;;
    --check)   mode=check ;;
    --vendor)  vendors+=("${2:?--vendor necesita una carpeta}"); shift ;;
    --profile) profile=${2:?--profile necesita un nombre}; shift ;;
    -h|--help) sed -n '2,23p' "$0"; exit 0 ;;
    -*) echo "Opción desconocida: $1" >&2; exit 2 ;;
    *)  target=$1 ;;
  esac
  shift
done
[[ -n "$target" ]] || { echo "Uso: $0 <proyecto> [--upgrade|--check] [--vendor <carpeta>]..." >&2; exit 2; }
[[ -d "$target" ]] || { echo "No existe la carpeta del proyecto: $target" >&2; exit 2; }
target=$(cd "$target" && pwd)
ref="$aes_root/profiles/reference/$profile"
[[ -d "$ref" ]] || { echo "No existe la implementación de referencia: $ref" >&2; exit 2; }

version=$(sed -n 's/^\*\*Versión:\*\* *\([0-9.]*\).*/\1/p' "$aes_root/README.md" | head -n1)
commit=$(git -C "$aes_root" rev-parse --short HEAD 2>/dev/null || echo "sin-git")
if [[ -n "$(git -C "$aes_root" status --porcelain 2>/dev/null)" ]]; then commit="$commit-modificado"; fi
stamp="AES $version ($commit, perfil $profile)"

# Las copias de las skills del núcleo en la referencia tienen que estar al día.
"$aes_root/scripts/sync-skills.sh" --check >/dev/null

# --- Qué es de AES y qué es semilla ------------------------------------------------------------
owned=()   # pares "origen|destino relativo"
seeds=()
add_tree() { # $1 lista, $2 carpeta origen, $3 destino relativo
  local list=$1 src=$2 dst=$3 f
  while IFS= read -r f; do
    eval "$list+=(\"\$src/\$f|\$dst/\$f\")"
  done < <(cd "$src" && find . -type f ! -name '.DS_Store' | sed 's#^\./##' | LC_ALL=C sort)
}
add_tree owned "$ref/.claude/hooks"   .claude/hooks
add_tree owned "$ref/.claude/scripts" .claude/scripts
add_tree owned "$ref/.opencode/plugin" .opencode/plugin
for d in "$ref"/.claude/skills/*/; do
  n=$(basename "$d"); add_tree owned "$d" ".claude/skills/$n"
done
owned+=("$ref/.claude/settings.local.example.json|.claude/settings.local.example.json")
for f in aes-ctx.sh aes-guard.sh defect-gate.sh label-approver.sh red-check.mjs run-verify.sh; do
  owned+=("$ref/ci/$f|ci/$f")
done
owned+=("$aes_root/standard/08-definition-of-ready-and-done.md|docs/aes/08-definition-of-ready-and-done.md")
owned+=("$aes_root/AES-CORE.md|docs/aes/AES-CORE.md")
add_tree owned "$aes_root/templates" docs/aes/templates

add_tree seeds "$ref/.claude/agents" .claude/agents
for f in .claude/settings.json .claude/aes.env .github/workflows/aes.yml .github/CODEOWNERS ci/validate.sh CLAUDE.md opencode.json; do
  seeds+=("$ref/$f|$f")
done

# Iguales salvo fines de línea: en Windows, un clon con core.autocrlf deja CRLF en la copia de trabajo.
same() { [[ -f "$2" ]] && cmp -s <(tr -d '\r' < "$1") <(tr -d '\r' < "$2"); }
# sha256sum no existe en macOS; shasum sí.
sha256() { if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }

# --- Comprobación --------------------------------------------------------------------------------
if [[ $mode == check ]]; then
  echo "Instalado: $(cat "$target/docs/aes/VERSION" 2>/dev/null || echo 'sin docs/aes/VERSION')"
  echo "Esta copia: $stamp"
  diff=0
  for p in "${owned[@]}"; do
    src=${p%%|*}; rel=${p#*|}
    same "$src" "$target/$rel" || { echo "  distinto o ausente: $rel"; diff=1; }
  done
  for p in "${seeds[@]}"; do
    rel=${p#*|}
    [[ -f "$target/$rel" ]] || { echo "  semilla ausente: $rel"; diff=1; }
    [[ -f "$target/$rel.aes-new" ]] && echo "  pendiente de revisar: $rel.aes-new"
  done
  [[ $diff -eq 0 ]] && echo "Los archivos de AES coinciden con esta versión."
  exit $diff
fi

if [[ $mode == install && -f "$target/docs/aes/VERSION" ]]; then
  echo "El proyecto ya tiene AES ($(cat "$target/docs/aes/VERSION")). Usa --upgrade." >&2
  exit 1
fi
git -C "$target" rev-parse --git-dir >/dev/null 2>&1 || echo "Aviso: $target no es un repositorio git."

# --- Copia ---------------------------------------------------------------------------------------
copied=0; unchanged=0; new_seeds=(); updated_seeds=(); pending=()
put() { mkdir -p "$(dirname "$2")"; cp "$1" "$2"; }
for p in "${owned[@]}"; do
  src=${p%%|*}; dst="$target/${p#*|}"
  if same "$src" "$dst"; then unchanged=$((unchanged + 1)); else put "$src" "$dst"; copied=$((copied + 1)); fi
done
# docs/aes/seeds.sha256: huella de cada semilla tal como la entregó AES la última vez. Así, al
# actualizar, solo se avisa si cambió la semilla de AES, no si el proyecto adaptó la suya.
seedsums="$target/docs/aes/seeds.sha256"; touch "$seedsums"; newsums=""
for p in "${seeds[@]}"; do
  src=${p%%|*}; rel=${p#*|}; dst="$target/$rel"
  sum=$(tr -d '\r' < "$src" | sha256 | cut -c1-64)
  # Huella de la misma semilla con CRLF: la que registraba 1.4.0 si AES se bajó en Windows con autocrlf.
  sum_crlf=$(tr -d '\r' < "$src" | sed 's/$/\r/' | sha256 | cut -c1-64)
  # Huella de la copia del proyecto: si coincide con la semilla entregada, el proyecto no la adaptó.
  cur=""; [[ -f "$dst" ]] && cur=$(tr -d '\r' < "$dst" | sha256 | cut -c1-64)
  cur_crlf=""; [[ -f "$dst" ]] && cur_crlf=$(tr -d '\r' < "$dst" | sed 's/$/\r/' | sha256 | cut -c1-64)
  if [[ ! -f "$dst" ]]; then put "$src" "$dst"; new_seeds+=("$rel")
  elif ! same "$src" "$dst" && { grep -qxF "$cur $rel" "$seedsums" || grep -qxF "$cur_crlf $rel" "$seedsums"; }; then
    put "$src" "$dst"; updated_seeds+=("$rel")   # sin adaptar: se actualiza sin preguntar
  elif ! same "$src" "$dst" && ! grep -qxF "$sum $rel" "$seedsums" && ! grep -qxF "$sum_crlf $rel" "$seedsums"; then
    put "$src" "$dst.aes-new"; pending+=("$rel.aes-new")
  fi
  newsums+="$sum $rel"$'\n'
done
printf '%s' "$newsums" > "$seedsums"
chmod +x "$target"/.claude/hooks/*.sh "$target"/.claude/scripts/*.sh "$target"/ci/*.sh 2>/dev/null || true

# Regresión y .gitignore (02 §11, README de la referencia).
mkdir -p "$target/specs"
[[ -f "$target/specs/active-stories.txt" ]] || : > "$target/specs/active-stories.txt"
touch "$target/.gitignore"
for line in .aes/ .claude/settings.local.json .claude/worktrees/; do
  grep -qxF "$line" "$target/.gitignore" || printf '%s\n' "$line" >> "$target/.gitignore"
done

# Tablero del backlog al día tras cada pull (hook local de git; no se versiona). Sin node, se omite.
if git -C "$target" rev-parse --git-dir >/dev/null 2>&1 && command -v node >/dev/null; then
  (cd "$target" && node .claude/scripts/aes-board.mjs --install-hook >/dev/null 2>&1) \
    || echo "  Aviso: no pude instalar el hook del tablero (node .claude/scripts/aes-board.mjs --install-hook)." >&2
fi

# Scripts con LF en cualquier sistema: bash no acepta CRLF, y Windows con core.autocrlf lo pondría.
touch "$target/.gitattributes"
for line in '*.sh text eol=lf' '*.mjs text eol=lf'; do
  grep -qxF "$line" "$target/.gitattributes" || printf '%s\n' "$line" >> "$target/.gitattributes"
done

# --- Skills de terceros --------------------------------------------------------------------------
lock="$target/docs/aes/skills.lock"
hash_tree() { (cd "$1" && find . -type f ! -path './.git/*' ! -path './node_modules/*' | LC_ALL=C sort | while IFS= read -r f; do sha256 "$f"; done) | sha256 | cut -c1-16; }
for v in "${vendors[@]}"; do
  [[ -f "$v/SKILL.md" ]] || { echo "Sin SKILL.md en $v: no es una skill." >&2; exit 1; }
  v=$(cd "$v" && pwd); name=$(basename "$v")
  [[ "$name" == aes-* ]] && { echo "$name: los nombres aes-* son del núcleo de AES." >&2; exit 1; }
  ver=$(sed -n '1,/^---$/{s/^version: *"\{0,1\}\([^"]*\)"\{0,1\} *$/\1/p}' "$v/SKILL.md" | head -n1)
  [[ -z "$ver" && -f "$v/package.json" ]] && ver=$(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$v/package.json" | head -n1)
  [[ -z "$ver" ]] && ver=$(git -C "$v" describe --tags --always 2>/dev/null || true)
  [[ -z "$ver" ]] && ver="sin-version"
  dst="$target/.claude/skills/$name"
  rm -rf "$dst"; mkdir -p "$dst"
  (cd "$v" && tar --exclude=.git --exclude=node_modules -cf - .) | (cd "$dst" && tar -xf -)
  # Licencia y avisos: si la carpeta de la skill no los trae, se copian de la raíz de su repositorio
  # (Apache-2.0, por ejemplo, exige conservar LICENSE y NOTICE al redistribuir).
  if ! compgen -G "$dst/LICENSE*" >/dev/null; then
    vroot=$(git -C "$v" rev-parse --show-toplevel 2>/dev/null || true)
    if [[ -n "$vroot" ]]; then
      for f in "$vroot"/LICENSE* "$vroot"/NOTICE*; do [[ -f "$f" ]] && cp "$f" "$dst/"; done
    fi
    compgen -G "$dst/LICENSE*" >/dev/null || echo "Aviso: $name no trae licencia; revísala antes de versionarla." >&2
  fi
  # Ajustes de 06 §6.2 por skill conocida: sin telemetría, sin avisos de actualización, sin hook propio.
  case "$name" in
    impeccable)
      cfg="$target/.impeccable/config.json"
      if [[ ! -f "$cfg" ]]; then
        mkdir -p "$target/.impeccable"
        printf '%s\n' '{' '  "telemetry": false,' '  "updateCheck": false,' '  "hook": { "enabled": false }' '}' > "$cfg"
        echo "  .impeccable/config.json: telemetría, aviso de actualizaciones y hook desactivados."
      else
        echo "  Revisa .impeccable/config.json: telemetry false, updateCheck false, hook.enabled false (06 §6.2)."
      fi
      for line in .impeccable/config.local.json .impeccable/questions/ .impeccable/mocks/ .impeccable/live/; do
        grep -qxF "$line" "$target/.gitignore" || printf '%s\n' "$line" >> "$target/.gitignore"
      done ;;
  esac
  touch "$lock"
  grep -v "^$name " "$lock" > "$lock.tmp" || true; mv "$lock.tmp" "$lock"
  printf '%s %s sha256:%s %s\n' "$name" "$ver" "$(hash_tree "$dst")" "$(date -u +%Y-%m-%d)" >> "$lock"
  echo "Skill de terceros: $name $ver → .claude/skills/$name (anotada en docs/aes/skills.lock)"
done
if [[ -f "$lock" ]] && ! head -n1 "$lock" | grep -q '^#'; then
  { echo "# nombre versión huella fecha — skills de terceros instaladas con install-aes.sh (06 §6.2)"; cat "$lock"; } > "$lock.tmp" && mv "$lock.tmp" "$lock"
fi

echo "$stamp" > "$target/docs/aes/VERSION"

# --- Resumen -------------------------------------------------------------------------------------
echo
echo "$stamp → $target"
echo "  archivos de AES: $copied copiados, $unchanged sin cambios"
[[ ${#new_seeds[@]} -gt 0 ]] && printf '  semilla nueva (adáptala): %s\n' "${new_seeds[@]}"
[[ ${#updated_seeds[@]} -gt 0 ]] && printf '  semilla actualizada (el proyecto no la había adaptado): %s\n' "${updated_seeds[@]}"
[[ ${#pending[@]} -gt 0 ]] && printf '  REVISA a mano y borra después: %s\n' "${pending[@]}"
if [[ $mode == install && -z "${AES_QUIET_NEXT:-}" ]]; then
  cat <<EOF

Falta (README de la referencia, «Puesta en marcha»):
  - Adaptar las semillas: CODEOWNERS (@tu-usuario), .claude/aes.env, ci/validate.sh y la
    sección STACK del workflow. Si todavía no hay stack, déjalo: lo hace EN-001.
  - Commit inicial en main, crear dev (git push origin main:dev) y hacerla la rama por defecto.
  - GitHub App de los agentes y .claude/settings.local.json.
  - Rulesets, etiquetas aes:* y variables AES_* del repositorio.
  - Después: una sesión del orquestador con la skill aes-inception.
EOF
fi
