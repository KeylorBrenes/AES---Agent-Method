#!/usr/bin/env bash
# aes-new — crea un proyecto nuevo con AES, de punta a punta, preguntando lo que haga falta.
#
# Es un solo archivo: no hace falta clonar el repo de AES. Descárgalo una vez y ejecútalo desde donde
# quieras (en Windows, con Git Bash):
#
#   mkdir -p ~/.aes && curl -fsSL \
#     https://raw.githubusercontent.com/KeylorBrenes/AES---Agent-Method/main/scripts/aes-new.sh \
#     -o ~/.aes/aes-new.sh
#   bash ~/.aes/aes-new.sh
#
# Qué hace:
#   1. comprueba las herramientas y la sesión de gh (y ofrece arreglarla);
#   2. comprueba la GitHub App de los agentes; si no existe, te manda a la sección del README y sale;
#      si existe pero falta ~/.aes/app.env, te pide los datos y lo crea;
#   3. baja la versión de AES que elijas a ~/.aes/versions/<versión> (no toca tu clon de AES);
#   4. pregunta nombre, dueño, visibilidad y carpeta del proyecto;
#   5. pregunta con qué harness trabajarán los roles (solo Claude Code, o Claude Code + OpenCode);
#   6. ofrece las skills de terceros (archify, impeccable) y las baja en una versión fija;
#   7. ejecuta setup-repo.sh de esa versión: repo, AES, ramas, rulesets, etiquetas, app y roles.
#
# Variables opcionales: AES_HOME (por defecto ~/.aes), AES_REPO_URL (repo de AES, por defecto el oficial).
set -euo pipefail

AES_HOME=${AES_HOME:-$HOME/.aes}
AES_REPO_URL=${AES_REPO_URL:-https://github.com/KeylorBrenes/AES---Agent-Method.git}
AES_WEB=https://github.com/KeylorBrenes/AES---Agent-Method
README_ONCE="$AES_WEB/blob/main/profiles/reference/claude-code-subagents/README.md#una-vez-por-cuenta"
README_APP="$AES_WEB/blob/main/profiles/reference/claude-code-subagents/README.md#2-github-app-de-los-agentes"
app_env="$AES_HOME/app.env"
defaults="$AES_HOME/defaults.env"
mkdir -p "$AES_HOME"
# shellcheck source=/dev/null
[[ -f "$defaults" ]] && source "$defaults"

# --- Ayudantes -----------------------------------------------------------------------------------
bold() { printf '\033[1m%s\033[0m\n' "$*"; }
step() { printf '\n'; bold "$*"; }
ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }
die()  { printf '  ✗ %s\n' "$*" >&2; exit 1; }
ask() { # $1 pregunta, $2 valor por defecto → respuesta en $REPLY
  local q=$1 def=${2:-}
  if [[ -n "$def" ]]; then read -r -p "  $q [$def]: " REPLY || true; REPLY=${REPLY:-$def}
  else read -r -p "  $q: " REPLY || true; fi
}
ask_req() { while :; do ask "$@"; [[ -n "$REPLY" ]] && return 0; warn "Hace falta un valor."; done; }
yes_no() { # $1 pregunta, $2 s|n por defecto
  local d=${2:-s}
  while :; do
    ask "$1 (s/n)" "$d"
    case "${REPLY,,}" in s|si|sí|y|yes) return 0 ;; n|no) return 1 ;; esac
  done
}
choose() { # $1 pregunta, $2 por defecto (número), resto: opciones → número en $REPLY
  local q=$1 def=$2 i=1; shift 2
  printf '  %s\n' "$q"
  for o in "$@"; do printf '    %d) %s\n' "$i" "$o"; i=$((i + 1)); done
  while :; do ask "Opción" "$def"; [[ "$REPLY" =~ ^[0-9]+$ && $REPLY -ge 1 && $REPLY -le $# ]] && return 0; done
}
save_default() { # guarda una preferencia para la próxima vez
  touch "$defaults"; grep -v "^$1=" "$defaults" > "$defaults.tmp" || true
  printf '%s=%q\n' "$1" "$2" >> "$defaults.tmp"; mv "$defaults.tmp" "$defaults"
}

bold "aes-new — proyecto nuevo con AES"
echo "  Responde con Enter para aceptar el valor entre corchetes. Ctrl+C cancela sin cambiar nada."

# --- 1. Herramientas -----------------------------------------------------------------------------
step "1. Herramientas"
missing=()
for c in git gh jq node; do command -v "$c" >/dev/null || missing+=("$c"); done
if [[ ${#missing[@]} -gt 0 ]]; then
  warn "Faltan: ${missing[*]}"
  echo "    Windows (PowerShell): winget install --id Git.Git -e; winget install --id GitHub.cli -e;"
  echo "                          winget install --id jqlang.jq -e; winget install --id OpenJS.NodeJS.LTS -e"
  echo "    Fedora: sudo dnf install git gh jq nodejs · Debian/Ubuntu: $README_ONCE"
  die "Instálalas, abre una terminal nueva y vuelve a ejecutar aes-new."
fi
ok "git, gh, jq y node"
if command -v claude >/dev/null; then ok "Claude Code"; else warn "No encuentro Claude Code (claude). Lo necesitarás para el orquestador."; fi

if ! gh auth status >/dev/null 2>&1; then
  warn "gh no tiene sesión."
  yes_no "¿Inicio sesión ahora (gh auth login)?" s || die "Sin sesión de gh no puedo seguir."
  gh auth login
fi
scopes=$(gh api -i user 2>/dev/null | tr -d '\r' | sed -n 's/^[Xx]-[Oo][Aa]uth-[Ss]copes: *//p')
if [[ -n "$scopes" ]] && ! grep -qw workflow <<< "${scopes//,/ }"; then
  warn "Tu sesión de gh no tiene el permiso 'workflow' (para subir la CI)."
  yes_no "¿Lo añado ahora (gh auth refresh -s workflow)?" s || die "Sin 'workflow' no se puede subir la CI."
  gh auth refresh -s workflow
fi
me=$(gh api user --jq .login)
ok "gh como $me"

# --- 2. GitHub App de los agentes ----------------------------------------------------------------
step "2. GitHub App de los agentes"
app_ok() {
  [[ -f "$app_env" ]] || return 1
  # shellcheck source=/dev/null
  (source "$app_env"; [[ -n "${AES_APP_ID:-}" && -n "${AES_APP_INSTALLATION_ID:-}" && -n "${AES_APP_PRIVATE_KEY:-}" && -n "${AES_BOT_SLUG:-}" ]])
}
if app_ok; then
  # shellcheck source=/dev/null
  source "$app_env"
  ok "$app_env: app $AES_APP_ID, ${AES_BOT_SLUG}[bot]"
else
  if ! yes_no "¿Ya creaste la GitHub App de los agentes y descargaste su llave (.pem)?" n; then
    echo
    echo "  Créala siguiendo esta sección (una vez por cuenta, unos minutos):"
    echo "    $README_APP"
    echo "  Después vuelve a ejecutar aes-new: te pedirá sus datos."
    exit 0
  fi
  echo "  Datos de la app (Settings → Developer settings → GitHub Apps → tu app):"
  ask_req "App ID (página General)"; app_id=$REPLY
  ask_req "Installation ID (número final de github.com/settings/installations/<id>)"; inst=$REPLY
  ask_req "Slug de la app (github.com/apps/<slug>)"; slug=$REPLY
  while :; do
    ask_req "Ruta de la llave .pem (con /)" "$AES_HOME/aes-agent.pem"; key=${REPLY/#\~/$HOME}
    [[ -f "$key" ]] && break; warn "No existe $key."
  done
  [[ "$key" == "$AES_HOME"/* || "$key" == "$HOME"/* ]] || warn "La llave está fuera de tu carpeta de usuario; revisa que no esté dentro de un repositorio."
  ask "Aprobadores (logins separados por coma)" "$me"; approvers=$REPLY
  umask 077
  {
    echo "# Creado por aes-new. Configuración de la cuenta para AES (no contiene la llave, solo su ruta)."
    echo "AES_APP_ID=$app_id"
    echo "AES_APP_INSTALLATION_ID=$inst"
    echo "AES_APP_PRIVATE_KEY=$key"
    echo "AES_BOT_SLUG=$slug"
    echo "AES_APPROVERS=$approvers"
  } > "$app_env"
  umask 022
  # shellcheck source=/dev/null
  source "$app_env"
  ok "$app_env creado"
fi

# --- 3. Versión de AES ---------------------------------------------------------------------------
step "3. Versión de AES"
latest=$(git ls-remote --tags --refs "$AES_REPO_URL" 'v*' 2>/dev/null | sed 's#.*refs/tags/##' | sort -V | tail -n1)
ask "Versión (etiqueta, o una rama como release/1.4.0)" "${AES_VERSION:-${latest:-main}}"; ref=$REPLY
aes="$AES_HOME/versions/${ref//\//-}"
if [[ -d "$aes/.git" ]]; then
  if git -C "$aes" show-ref --verify --quiet "refs/remotes/origin/$ref"; then
    git -C "$aes" fetch -q origin "$ref" && git -C "$aes" reset -q --hard "origin/$ref"
    ok "AES $ref actualizada en $aes"
  else ok "AES $ref ya está en $aes"; fi
else
  mkdir -p "$AES_HOME/versions"
  git clone -q --depth 1 --branch "$ref" "$AES_REPO_URL" "$aes" 2>/dev/null \
    || die "No pude bajar AES $ref de $AES_REPO_URL (¿existe esa etiqueta o rama?)."
  ok "AES $ref bajada a $aes"
fi
[[ -x "$aes/scripts/setup-repo.sh" || -f "$aes/scripts/setup-repo.sh" ]] || die "AES $ref no trae scripts/setup-repo.sh (hace falta 1.3.0 o posterior)."
oc_capable=0; grep -q -- '--opencode' "$aes/scripts/setup-repo.sh" && oc_capable=1

# --- 4. Proyecto ---------------------------------------------------------------------------------
step "4. Proyecto"
while :; do
  ask_req "Nombre del repositorio (p. ej. aes-todo)"; name=$REPLY
  [[ "$name" =~ ^[A-Za-z0-9_.-]+$ ]] && break; warn "Solo letras, números, '.', '-' y '_'."
done
ask "Dueño en GitHub (usuario u organización)" "$me"; owner=$REPLY
if gh repo view "$owner/$name" --json name >/dev/null 2>&1; then
  warn "$owner/$name ya existe: se usará tal cual (no se crea)."; create=""
else
  choose "Visibilidad" 1 "público (los rulesets funcionan con GitHub Free)" "privado (los rulesets necesitan GitHub Pro o Team)"
  if [[ $REPLY == 1 ]]; then create=public; else create=private; fi
fi
ask "Carpeta donde se crea el proyecto" "${AES_PROJECTS_DIR:-$HOME/proyectos}"; parent=${REPLY/#\~/$HOME}
mkdir -p "$parent"; parent=$(cd "$parent" && pwd)
dir="$parent/$name"
[[ -e "$dir" && ! -d "$dir/.git" ]] && die "$dir ya existe y no es un repositorio git."

# --- 5. Harness de los roles ---------------------------------------------------------------------
step "5. Dónde trabajan los roles"
echo "  El orquestador siempre es Claude Code (modelo más capaz). El verificador, siempre Claude."
choose "QA, programador y mecánico:" "${AES_HARNESS_CHOICE:-1}" \
  "Claude Code (subagentes)" \
  "OpenCode (otro proveedor, más barato)" \
  "Codex (todavía no disponible en AES)"
harness_choice=$REPLY
oc_model=claude
case "$harness_choice" in
  2)
    [[ $oc_capable -eq 1 ]] || die "AES $ref no soporta roles en OpenCode: elige 1.4.0 o posterior en el paso 3."
    command -v opencode >/dev/null || die "No encuentro opencode. Instálalo (https://opencode.ai) y vuelve a ejecutar aes-new."
    choose "Modelo para esos roles:" 1 \
      "opencode/deepseek-v4.1-flash-free (gratis por tiempo limitado, sin retención declarada)" \
      "deepseek/deepseek-flash (de pago: clave de platform.deepseek.com con /connect o DEEPSEEK_API_KEY)" \
      "otro (lo escribes: proveedor/modelo)"
    case "$REPLY" in
      1) oc_model=opencode/deepseek-v4.1-flash-free ;;
      2) oc_model=deepseek/deepseek-flash ;;
      3) while :; do ask_req "proveedor/modelo" "${AES_OPENCODE_MODEL:-}"; [[ "$REPLY" == */* ]] && break; done; oc_model=$REPLY ;;
    esac ;;
  3) die "Codex todavía no está integrado en AES. Elige Claude Code u OpenCode." ;;
esac

# --- 6. Skills de terceros -----------------------------------------------------------------------
step "6. Skills de terceros (opcionales)"
vendors=()
skill() { # $1 nombre, $2 repo
  local n=$1 url=$2 dst="$AES_HOME/skills/$1" tag tags folder
  if [[ ! -d "$dst/.git" ]]; then
    # Última etiqueta de versión: primero las de la forma v1.2.3; si no hay, las que llevan prefijo
    # (impeccable usa cli-v4.8.1).
    tags=$(git ls-remote --tags --refs "$url" 2>/dev/null | sed 's#.*refs/tags/##' || true)
    tag=$(grep -E '^v?[0-9]+\.[0-9]+' <<< "$tags" | sort -V | tail -n1 || true)
    [[ -n "$tag" ]] || tag=$(grep -E '[0-9]+\.[0-9]+\.[0-9]+$' <<< "$tags" | sort -V | tail -n1 || true)
    mkdir -p "$AES_HOME/skills"
    if [[ -n "$tag" ]]; then git clone -q --depth 1 --branch "$tag" "$url" "$dst" 2>/dev/null
    else git clone -q --depth 1 "$url" "$dst" 2>/dev/null; fi || { warn "No pude bajar $n."; return 0; }
    ok "$n ${tag:-(rama principal)} en $dst"
  else ok "$n ya está en $dst (versión fija: para actualizarla, bórrala y vuelve a ejecutar)"; fi
  # La carpeta de la skill es la del SKILL.md cuyo name coincide (la más corta): así no depende de cómo
  # organice su repositorio cada tercero (archify 3 la movió a archify/, impeccable usa .claude/skills/).
  # Si trae una copia para Claude Code (.claude/skills/<nombre>), esa.
  if [[ -f "$dst/.claude/skills/$n/SKILL.md" ]]; then vendors+=("$dst/.claude/skills/$n"); return 0; fi
  folder=$(find "$dst" -name SKILL.md -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null \
    | while IFS= read -r f; do head -n 15 "$f" | grep -qE "^name: *[\"']?${n}[\"']? *\$" \
        && printf '%s %s\n' "${#f}" "$(dirname "$f")"; done | sort -n | head -n1 | cut -d' ' -f2-) || true
  [[ -n "$folder" ]] || { warn "No encuentro el SKILL.md de $n en $dst; no se instala."; return 0; }
  vendors+=("$folder")
}
want_archify=n; want_imp=n
if yes_no "archify: diagramas de arquitectura en la incepción" "${AES_WANT_ARCHIFY:-s}"; then
  want_archify=s; skill archify https://github.com/tt-a1i/archify.git
fi
if yes_no "impeccable: diseño de interfaz (si el proyecto tiene UI)" "${AES_WANT_IMPECCABLE:-s}"; then
  want_imp=s; skill impeccable https://github.com/pbakaus/impeccable.git
fi

# --- 7. Resumen y ejecución ----------------------------------------------------------------------
step "7. Resumen"
echo "  Repositorio:  $owner/$name ${create:+(se crea, $create)}"
echo "  Carpeta:      $dir"
echo "  AES:          $ref"
if [[ $oc_model == claude ]]; then echo "  Roles:        todos en Claude Code"
else echo "  Roles:        QA, programador y mecánico en OpenCode ($oc_model); verificador en Claude"; fi
echo "  Skills:       ${vendors[*]:-ninguna}"
yes_no "¿Sigo?" s || { echo "  Cancelado. No se cambió nada."; exit 0; }

save_default AES_PROJECTS_DIR "$parent"
save_default AES_VERSION "$ref"
save_default AES_HARNESS_CHOICE "$harness_choice"
[[ $oc_model != claude ]] && save_default AES_OPENCODE_MODEL "$oc_model"
save_default AES_WANT_ARCHIFY "$want_archify"
save_default AES_WANT_IMPECCABLE "$want_imp"

args=("$owner/$name" --dir "$dir" --config "$app_env")
[[ -n "$create" ]] && args+=(--create "$create")
[[ $oc_capable -eq 1 ]] && args+=(--opencode "$oc_model")
vendor_list=$(IFS=';'; echo "${vendors[*]:-}")
AES_VENDOR="$vendor_list" bash "$aes/scripts/setup-repo.sh" "${args[@]}"

step "Proyecto listo"
echo "  cd \"$dir\" && claude"
echo "  En Claude Code: /model opus, y cuéntale la idea (\"Quiero empezar el proyecto: …\")."
