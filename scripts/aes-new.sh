#!/usr/bin/env bash
# aes-new — convierte la carpeta donde lo ejecutas en un proyecto con AES, listo para empezar.
#
#   mkdir to-do && cd to-do
#   curl -fsSL https://raw.githubusercontent.com/KeylorBrenes/AES---Agent-Method/main/scripts/aes-new.sh -o aes-new.sh
#   bash aes-new.sh
#
# Funciona en macOS, Linux y Windows (Git Bash). Pregunta lo necesario, con valores por defecto:
#   1. ¿el proyecto va en esta carpeta?, nombre del repositorio (el de la carpeta), público o privado;
#   2. con qué identidad publican los agentes: la GitHub App de los agentes o tu propia sesión de gh;
#   3. dónde trabajan QA, programador y mecánico: Claude Code u OpenCode (y con qué modelo);
#   4. skills de terceros (archify, impeccable).
# Después baja AES a una carpeta temporal, crea el repositorio en GitHub, instala AES, hace el commit
# inicial, crea main y dev, aplica las reglas y configura los roles. Al final ofrece empezar: abre
# Claude Code ahí mismo, con Opus, y el orquestador arranca la incepción (te pregunta por la idea).
#
# Fuera del proyecto solo guarda la configuración de tu cuenta (datos de la GitHub App y tus
# respuestas por defecto) en ~/.config/aes/. El script se mueve a .aes/aes-new.sh (ignorado por git)
# para que puedas volver a ejecutarlo si algo falló a medias.
#
# Variables opcionales: AES_REF (versión de AES: etiqueta o rama), AES_REPO_URL.
set -euo pipefail

# Versión de AES por defecto. "latest" = la última etiqueta publicada.
AES_DEFAULT_REF="release/1.4.0"
AES_REPO_URL=${AES_REPO_URL:-https://github.com/KeylorBrenes/AES---Agent-Method.git}
AES_WEB=https://github.com/KeylorBrenes/AES---Agent-Method
README_APP="$AES_WEB/blob/main/profiles/reference/claude-code-subagents/README.md#2-github-app-de-los-agentes"
conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/aes"
app_env="$conf_dir/app.env"
[[ -f "$app_env" || ! -f "$HOME/.aes/app.env" ]] || app_env="$HOME/.aes/app.env"   # ubicación de 1.3.0
defaults="$conf_dir/defaults.env"
# shellcheck source=/dev/null
[[ -f "$defaults" ]] && source "$defaults"
self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")

# --- Ayudantes (bash 3.2: nada de ${x,,}, mapfile ni arrays asociativos) ------------------------
if [[ -t 1 ]]; then b=$'\033[1m'; n=$'\033[0m'; else b=""; n=""; fi
step() { printf '\n%s%s%s\n' "$b" "$*" "$n"; }
ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }
die()  { printf '  ✗ %s\n' "$*" >&2; exit 1; }
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
ask() { # $1 pregunta, $2 valor por defecto → $REPLY
  if [[ -n "${2:-}" ]]; then read -r -p "  $1 [$2]: " REPLY || true; REPLY=${REPLY:-$2}
  else read -r -p "  $1: " REPLY || true; fi
}
ask_req() { while :; do ask "$@"; [[ -n "$REPLY" ]] && return 0; warn "Hace falta un valor."; done; }
yes_no() { # $1 pregunta, $2 s|n por defecto
  while :; do
    ask "$1 (s/n)" "${2:-s}"
    case "$(lower "$REPLY")" in s|si|sí|y|yes) return 0 ;; n|no) return 1 ;; esac
  done
}
choose() { # $1 pregunta, $2 opción por defecto, resto: opciones → número en $REPLY
  local q=$1 def=$2 i=1 o; shift 2
  printf '  %s\n' "$q"
  for o in "$@"; do printf '    %d) %s\n' "$i" "$o"; i=$((i + 1)); done
  while :; do ask "Opción" "$def"; [[ "$REPLY" =~ ^[0-9]+$ ]] && (( REPLY >= 1 && REPLY <= $# )) && return 0; done
}
save_default() {
  mkdir -p "$conf_dir"; touch "$defaults"
  grep -v "^$1=" "$defaults" > "$defaults.tmp" || true
  printf '%s=%q\n' "$1" "$2" >> "$defaults.tmp"; mv "$defaults.tmp" "$defaults"
}
tmp=$(mktemp -d 2>/dev/null || mktemp -d -t aes)
trap 'rm -rf "$tmp"' EXIT

printf '%saes-new%s — proyecto nuevo con AES. Enter acepta el valor entre corchetes; Ctrl+C cancela sin cambiar nada.\n' "$b" "$n"

# --- 1. Herramientas y sesión de GitHub ----------------------------------------------------------
step "1. Herramientas"
missing=""
for c in git gh jq node; do command -v "$c" >/dev/null || missing="$missing $c"; done
if [[ -n "$missing" ]]; then
  warn "Faltan:$missing"
  echo "    macOS:   brew install git gh jq node"
  echo "    Windows: winget install --id Git.Git -e; winget install --id GitHub.cli -e; winget install --id jqlang.jq -e; winget install --id OpenJS.NodeJS.LTS -e"
  echo "    Linux:   sudo dnf install git gh jq nodejs  (o apt; gh: https://github.com/cli/cli/blob/trunk/docs/install_linux.md)"
  die "Instálalas, abre una terminal nueva y vuelve a ejecutar: bash aes-new.sh"
fi
ok "git, gh, jq y node"
if command -v claude >/dev/null; then ok "Claude Code"; else warn "No encuentro Claude Code (claude): lo necesitarás para empezar (https://claude.com/claude-code)."; fi
if ! gh auth status >/dev/null 2>&1; then
  warn "gh no tiene sesión."
  yes_no "¿Inicio sesión ahora (gh auth login)?" s || die "Sin sesión de gh no puedo crear el repositorio."
  gh auth login
fi
scopes=$(gh api -i user 2>/dev/null | tr -d '\r' | sed -n 's/^[Xx]-[Oo][Aa]uth-[Ss]copes: *//p')
if [[ -n "$scopes" ]] && ! printf '%s' "$scopes" | tr ',' ' ' | grep -qw workflow; then
  warn "Tu sesión de gh no tiene el permiso 'workflow' (hace falta para subir la CI)."
  yes_no "¿Lo añado ahora (gh auth refresh -s workflow)?" s || die "Sin 'workflow' no se puede subir la CI."
  gh auth refresh -s workflow
fi
me=$(gh api user --jq .login)
ok "GitHub como $me"

# --- 2. Carpeta y repositorio --------------------------------------------------------------------
step "2. Proyecto"
here=$(pwd)
if yes_no "¿El proyecto va en esta carpeta? ($here)" s; then dir=$here
else
  ask_req "Carpeta del proyecto (se crea si no existe)"; dir=${REPLY/#\~/$HOME}
  mkdir -p "$dir"; dir=$(cd "$dir" && pwd)
fi
if [[ ! -d "$dir/.git" ]]; then
  others=""
  for f in "$dir"/* "$dir"/.[!.]*; do
    [[ -e "$f" ]] || continue
    case "$(basename "$f")" in "$(basename "$self")"|.aes) ;; *) others="$others$(basename "$f")"$'\n' ;; esac
  done
  if [[ -n "$others" ]]; then
    warn "La carpeta ya tiene archivos; entrarán en el commit inicial:"
    printf '%s' "$others" | head -n 8 | sed 's/^/      /'
    yes_no "¿Sigo?" n || exit 0
  fi
fi
folder=$(basename "$dir" | tr ' ' '-' | tr -cd 'A-Za-z0-9._-')
while :; do
  ask "Nombre del repositorio" "$folder"; name=$REPLY
  [[ "$name" =~ ^[A-Za-z0-9_.-]+$ ]] && break; warn "Solo letras, números, '.', '-' y '_'."
done
ask "Dueño en GitHub (usuario u organización)" "$me"; owner=$REPLY
create=""
if gh repo view "$owner/$name" --json name >/dev/null 2>&1; then
  ok "$owner/$name ya existe en GitHub: se usa tal cual."
else
  choose "Visibilidad" 1 \
    "pública: reglas de rama completas y GitHub Actions sin límite" \
    "privada: el código solo lo ves tú (las reglas de rama necesitan GitHub Pro o Team)"
  if [[ $REPLY == 1 ]]; then create=public; else
    create=private
    plan=""; [[ "$owner" == "$me" ]] && plan=$(gh api user --jq '.plan.name // empty' 2>/dev/null || true)
    if [[ "$(lower "$plan")" == free ]]; then
      warn "Tu cuenta es GitHub Free: en un repo privado no hay reglas de rama (nada impide integrar"
      warn "con la CI en rojo) y Actions tiene 2.000 minutos al mes."
      yes_no "¿Sigo con privado?" n || { create=public; ok "Será público."; }
    fi
  fi
fi

# --- 3. Identidad de los agentes -----------------------------------------------------------------
step "3. Con qué identidad publican los agentes"
app_ok() {
  [[ -f "$app_env" ]] || return 1
  # shellcheck source=/dev/null
  (source "$app_env"; [[ -n "${AES_APP_ID:-}" && -n "${AES_APP_INSTALLATION_ID:-}" && -n "${AES_APP_PRIVATE_KEY:-}" && -n "${AES_BOT_SLUG:-}" ]])
}
personal=0
if app_ok; then
  # shellcheck source=/dev/null
  bot=$(source "$app_env"; printf '%s[bot]' "$AES_BOT_SLUG")
  choose "Tienes configurada la app $bot." "${AES_IDENTITY_CHOICE:-1}" \
    "con la app: sus PR los apruebas tú (recomendado)" \
    "personal: con tu sesión de gh; PR y CI obligatorios, integrar es tu aprobación"
  [[ $REPLY == 2 ]] && personal=1
else
  choose "No hay una GitHub App de agentes configurada." 1 \
    "ya la creé: te doy sus datos" \
    "quiero crearla primero (te muestro cómo y salgo)" \
    "seguir sin app: modo personal (PR y CI obligatorios, integrar es tu aprobación)"
  case "$REPLY" in
    2) echo; echo "  Créala con esta sección (una vez por cuenta, unos minutos):"; echo "    $README_APP"
       echo "  Después vuelve a ejecutar: bash aes-new.sh"; exit 0 ;;
    3) personal=1 ;;
    1)
      echo "  Datos de la app (Settings → Developer settings → GitHub Apps → tu app):"
      ask_req "App ID (página General)"; app_id=$REPLY
      ask_req "Installation ID (número final de github.com/settings/installations/<id>)"; inst=$REPLY
      ask_req "Slug (github.com/apps/<slug>)"; slug=$REPLY
      while :; do
        ask_req "Ruta de la llave .pem (fuera de cualquier repositorio)" "$conf_dir/aes-agent.pem"; key=${REPLY/#\~/$HOME}
        [[ -f "$key" ]] && break; warn "No existe $key."
      done
      ask "Aprobadores (logins separados por coma)" "$me"; approvers=$REPLY
      mkdir -p "$conf_dir"; app_env="$conf_dir/app.env"
      ( umask 077
        printf '%s\n' "# aes-new: datos de la GitHub App de los agentes (solo la ruta de la llave, nunca la llave)." \
          "AES_APP_ID=$app_id" "AES_APP_INSTALLATION_ID=$inst" "AES_APP_PRIVATE_KEY=$key" \
          "AES_BOT_SLUG=$slug" "AES_APPROVERS=$approvers" > "$app_env" )
      ok "guardado en $app_env" ;;
  esac
fi

# --- 4. Dónde trabajan los roles -----------------------------------------------------------------
step "4. Dónde trabajan los roles"
echo "  El orquestador es Claude Code con el modelo más capaz; el verificador, siempre Claude."
choose "QA, programador y mecánico:" "${AES_HARNESS_CHOICE:-1}" \
  "Claude Code (subagentes)" \
  "OpenCode (otro proveedor, más barato)" \
  "Codex (todavía no disponible en AES)"
harness=$REPLY; oc_model=claude
case "$harness" in
  2)
    command -v opencode >/dev/null || die "No encuentro opencode. Instálalo (https://opencode.ai) y vuelve a ejecutar."
    choose "Modelo:" "${AES_MODEL_CHOICE:-1}" \
      "opencode/deepseek-v4.1-flash-free (gratis por tiempo limitado, sin retención declarada)" \
      "deepseek/deepseek-flash (de pago: clave de platform.deepseek.com con /connect en OpenCode)" \
      "otro (proveedor/modelo)"
    model_choice=$REPLY
    case "$REPLY" in
      1) oc_model=opencode/deepseek-v4.1-flash-free ;;
      2) oc_model=deepseek/deepseek-flash ;;
      3) while :; do ask_req "proveedor/modelo" "${AES_OPENCODE_MODEL:-}"; [[ "$REPLY" == */* ]] && break; done; oc_model=$REPLY ;;
    esac ;;
  3) die "Codex todavía no está integrado en AES. Vuelve a ejecutar y elige Claude Code u OpenCode." ;;
esac

# --- 5. Skills de terceros -----------------------------------------------------------------------
step "5. Skills de terceros (opcionales; se instalan en su última versión publicada, que queda fija)"
want_archify=n; want_imp=n
if yes_no "archify: diagramas de arquitectura en la incepción" "${AES_WANT_ARCHIFY:-s}"; then want_archify=s; fi
if yes_no "impeccable: diseño de interfaz (si el proyecto tiene UI)" "${AES_WANT_IMPECCABLE:-s}"; then want_imp=s; fi

# --- 6. Resumen ----------------------------------------------------------------------------------
ref=${AES_REF:-$AES_DEFAULT_REF}
if [[ "$ref" == latest ]]; then
  ref=$(git ls-remote --tags --refs "$AES_REPO_URL" 'v*' 2>/dev/null | sed 's#.*refs/tags/##' | sort -V | tail -n1)
  [[ -n "$ref" ]] || die "No encuentro versiones publicadas de AES en $AES_REPO_URL."
fi
vis=""; [[ -n "$create" ]] && { if [[ $create == public ]]; then vis=" (se crea, pública)"; else vis=" (se crea, privada)"; fi; }
skills_txt=""; [[ $want_archify == s ]] && skills_txt="archify "; [[ $want_imp == s ]] && skills_txt="${skills_txt}impeccable"
step "6. Resumen"
echo "  Carpeta:     $dir"
echo "  Repositorio: $owner/$name$vis"
if [[ $personal -eq 1 ]]; then echo "  Identidad:   personal ($me)"; else echo "  Identidad:   GitHub App"; fi
if [[ $oc_model == claude ]]; then echo "  Roles:       Claude Code"
else echo "  Roles:       QA, programador y mecánico en OpenCode ($oc_model); verificador en Claude"; fi
echo "  Skills:      ${skills_txt:-ninguna}"
echo "  AES:         $ref"
yes_no "¿Creo el proyecto?" s || { echo "  Cancelado. No se cambió nada."; exit 0; }

save_default AES_HARNESS_CHOICE "$harness"
[[ -n "${model_choice:-}" ]] && save_default AES_MODEL_CHOICE "$model_choice"
[[ $oc_model != claude ]] && save_default AES_OPENCODE_MODEL "$oc_model"
save_default AES_IDENTITY_CHOICE "$((personal + 1))"
save_default AES_WANT_ARCHIFY "$want_archify"
save_default AES_WANT_IMPECCABLE "$want_imp"

# --- 7. Descargas (temporales) -------------------------------------------------------------------
step "7. Descargas"
git clone -q --depth 1 --branch "$ref" "$AES_REPO_URL" "$tmp/aes" 2>/dev/null \
  || die "No pude bajar AES $ref de $AES_REPO_URL."
grep -q -- '--personal' "$tmp/aes/scripts/setup-repo.sh" || die "AES $ref es anterior a 1.4.0: aes-new necesita 1.4.0 o posterior (AES_REF)."
ok "AES $ref"
vendors=""
skill() { # $1 nombre, $2 repo → añade a $vendors la carpeta de la skill
  local nm=$1 url=$2 dst="$tmp/skills/$1" tags tag folder
  tags=$(git ls-remote --tags --refs "$url" 2>/dev/null | sed 's#.*refs/tags/##' || true)
  tag=$(printf '%s\n' "$tags" | grep -E '^v?[0-9]+\.[0-9]+' | sort -V | tail -n1 || true)
  [[ -n "$tag" ]] || tag=$(printf '%s\n' "$tags" | grep -E '[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1 || true)
  if [[ -n "$tag" ]]; then git clone -q --depth 1 --branch "$tag" "$url" "$dst" 2>/dev/null
  else git clone -q --depth 1 "$url" "$dst" 2>/dev/null; fi || { warn "No pude bajar $nm; sigo sin ella."; return 0; }
  # La carpeta de la skill: la copia para Claude Code si la trae, si no la del SKILL.md con su nombre.
  if [[ -f "$dst/.claude/skills/$nm/SKILL.md" ]]; then folder="$dst/.claude/skills/$nm"
  else
    folder=$(find "$dst" -name SKILL.md -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null \
      | while IFS= read -r f; do head -n 15 "$f" | grep -qE "^name: *[\"']?${nm}[\"']? *\$" \
          && printf '%s %s\n' "${#f}" "$(dirname "$f")"; done | sort -n | head -n1 | cut -d' ' -f2-) || true
  fi
  [[ -n "$folder" ]] || { warn "No encuentro el SKILL.md de $nm; sigo sin ella."; return 0; }
  vendors="${vendors:+$vendors;}$folder"
  ok "$nm ${tag:-(rama principal)}"
}
if [[ $want_archify == s ]]; then skill archify https://github.com/tt-a1i/archify.git; fi
if [[ $want_imp == s ]]; then skill impeccable https://github.com/pbakaus/impeccable.git; fi

# --- 8. Crear el proyecto ------------------------------------------------------------------------
# El script se aparta a .aes/ (que AES ignora en git) antes del commit inicial.
if [[ "$(dirname "$self")" == "$dir" ]]; then
  mkdir -p "$dir/.aes"; mv "$self" "$dir/.aes/aes-new.sh"; self="$dir/.aes/aes-new.sh"
fi
args=("$owner/$name" --dir "$dir" --opencode "$oc_model")
[[ -n "$create" ]] && args+=(--create "$create")
[[ $personal -eq 1 ]] && args+=(--personal)
[[ -f "$app_env" ]] && args+=(--config "$app_env")
AES_VENDOR="$vendors" bash "$tmp/aes/scripts/setup-repo.sh" "${args[@]}"

# --- 9. Empezar ----------------------------------------------------------------------------------
step "Proyecto listo en $dir"
echo "  Para repetir algún paso: bash .aes/aes-new.sh (se salta lo que ya está hecho)."
start_prompt="Empecemos el proyecto. Todavía no hay planeamiento: usa la skill aes-inception y pregúntame por la idea."
if command -v claude >/dev/null && yes_no "¿Empiezo ahora? (abre Claude Code aquí, con Opus, y arranca la incepción)" s; then
  cd "$dir"
  trap - EXIT; rm -rf "$tmp"
  exec claude --model opus "$start_prompt"
fi
echo "  Cuando quieras: cd \"$dir\" && claude --model opus"
echo "  Y dile: \"$start_prompt\""
