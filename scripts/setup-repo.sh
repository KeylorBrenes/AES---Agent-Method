#!/usr/bin/env bash
# Pone en marcha un repositorio de GitHub con AES, de punta a punta, con un solo comando.
#
# Uso:
#   ./scripts/setup-repo.sh <dueño/repo> [opciones]
#
# Opciones:
#   --create private|public   crea el repositorio si no existe
#   --opencode <prov/modelo>  QA, programador y mecánico en OpenCode con ese modelo (06 §12); el
#                             verificador sigue en Claude. Por defecto, AES_OPENCODE_MODEL de app.env;
#                             --opencode claude los deja todos en Claude
#   --personal                sin GitHub App: los agentes publican con tu sesión de gh y las reglas
#                             exigen PR y CI en verde, sin aprobación (integrar es tu aprobación)
#   --dir <carpeta>           checkout local; si existe y no es un repo git, se inicializa ahí (por defecto <repo>, al lado del repo de AES si lo
#                             ejecutas desde dentro de él; si no, en la carpeta actual)
#   --config <archivo>        configuración de la cuenta (por defecto ~/.config/aes/app.env)
#   --dry-run                 muestra lo que haría, sin cambiar nada (las lecturas sí se hacen)
#
# Qué hace (cada paso comprueba antes y se salta si ya está hecho; se puede repetir sin miedo):
#   1. comprueba git, gh (con permisos repo y workflow), jq y la configuración de la cuenta;
#   2. crea el repositorio (con --create) y lo clona;
#   3. instala AES con install-aes.sh (y las skills de terceros de AES_VENDOR) y fija qué roles
#      corren en OpenCode;
#   4. rellena CODEOWNERS y .claude/settings.local.json (este último NO va a git);
#   5. commit inicial en main (solo si main todavía no existe en GitHub) y crea dev;
#   6. dev como rama por defecto; merge commit y squash permitidos, rebase no;
#   7. rulesets: ramas-ci (main y dev), aprobacion-dev y aprobacion-main;
#   8. etiquetas aes:* y la variable AES_APPROVERS;
#   9. da acceso a la GitHub App de los agentes y comprueba su token.
#
# Lo único manual es, una vez por cuenta, crear la GitHub App (o usar --personal); aes-new crea ~/.config/aes/app.env.
# (ver scripts/aes-app.env.example y el README de la implementación de referencia).
set -euo pipefail

aes_root=$(cd "$(dirname "$0")/.." && pwd)
repo=""; create=""; dir=""; dry=0; oc_model=""; personal=0
config="${XDG_CONFIG_HOME:-$HOME/.config}/aes/app.env"
[[ -f "$config" || ! -f "$HOME/.aes/app.env" ]] || config="$HOME/.aes/app.env"   # ubicación de 1.3.0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --create)  create=${2:?--create necesita private o public}; shift ;;
    --dir)     dir=${2:?--dir necesita una carpeta}; shift ;;
    --opencode) oc_model=${2:?--opencode necesita proveedor/modelo o claude}; shift ;;
    --config)  config=${2:?--config necesita un archivo}; shift ;;
    --personal) personal=1 ;;
    --dry-run) dry=1 ;;
    -h|--help) sed -n '2,26p' "$0"; exit 0 ;;
    -*) echo "Opción desconocida: $1" >&2; exit 2 ;;
    *)  repo=$1 ;;
  esac
  shift
done
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "Uso: $0 <dueño/repo> [--create private|public] [--dir <carpeta>] [--dry-run]" >&2; exit 2; }
[[ -z "$create" || "$create" == private || "$create" == public ]] || { echo "--create: private o public" >&2; exit 2; }
name=${repo#*/}
if [[ -z "$dir" ]]; then
  # Nunca dentro del repo de AES: si se ejecuta desde ahí, el proyecto va al lado.
  case "$PWD/" in "$aes_root"/*) dir="$(dirname "$aes_root")/$name" ;; *) dir="$PWD/$name" ;; esac
fi

ok()   { printf '  ✓ %s\n' "$*"; }
step() { printf '\n%s\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }
die()  { printf '  ✗ %s\n' "$*" >&2; exit 1; }
run()  { if [[ $dry -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else "$@"; fi; }

# --- 1. Requisitos -------------------------------------------------------------------------------
step "1. Requisitos"
for c in git gh jq; do command -v "$c" >/dev/null || die "Falta $c en el PATH."; done
gh auth status >/dev/null 2>&1 || die "gh no tiene sesión: gh auth login"
scopes=$(gh api -i user 2>/dev/null | tr -d '\r' | sed -n 's/^[Xx]-[Oo][Aa]uth-[Ss]copes: *//p')
if [[ -n "$scopes" ]]; then
  for s in repo workflow; do
    grep -qw "$s" <<< "${scopes//,/ }" || die "Tu sesión de gh no tiene el permiso '$s': gh auth refresh -s $s"
  done
fi
me=$(gh api user --jq .login)
ok "gh como $me"

[[ $personal -eq 1 || -f "$config" ]] || die "No existe $config. Créalo con aes-new o a partir de scripts/aes-app.env.example, o usa --personal."
# AES_VENDOR del entorno (aunque sea vacío) manda sobre el de app.env: así lo pasa aes-new.
vendor_from_env=${AES_VENDOR+set}; vendor_env=${AES_VENDOR:-}
# shellcheck source=/dev/null
[[ -f "$config" ]] && source "$config"
[[ -n "$vendor_from_env" ]] && AES_VENDOR=$vendor_env
approvers=${AES_APPROVERS:-$me}
owner_login=${approvers%%,*}
if [[ $personal -eq 0 ]]; then
  for v in AES_APP_ID AES_APP_INSTALLATION_ID AES_APP_PRIVATE_KEY AES_BOT_SLUG; do
    [[ -n "${!v:-}" ]] || die "Falta $v en $config."
  done
  [[ -f "${AES_APP_PRIVATE_KEY/#\~/$HOME}" ]] || warn "No encuentro la llave en $AES_APP_PRIVATE_KEY (desde este shell). Si la ruta es de Windows y estás en otro sistema, ignóralo."
  if [[ -z "${AES_BOT_ID:-}" ]]; then
    AES_BOT_ID=$(gh api "users/${AES_BOT_SLUG}%5Bbot%5D" --jq .id 2>/dev/null || true)
    [[ -n "$AES_BOT_ID" ]] || die "No encuentro el usuario ${AES_BOT_SLUG}[bot]; revisa AES_BOT_SLUG o define AES_BOT_ID."
  fi
fi
oc_model=${oc_model:-${AES_OPENCODE_MODEL:-claude}}
if [[ "$oc_model" != claude ]]; then
  command -v opencode >/dev/null || die "Pediste roles en OpenCode ($oc_model), pero opencode no está en el PATH."
  [[ "$oc_model" == */* ]] || die "--opencode espera proveedor/modelo (p. ej. opencode/deepseek-v4.1-flash-free) o claude."
fi
if [[ $personal -eq 1 ]]; then ok "modo personal: los agentes publican como $me; aprobadores $approvers"
else ok "configuración de la cuenta: app $AES_APP_ID, bot ${AES_BOT_SLUG}[bot] ($AES_BOT_ID), aprobadores $approvers"; fi

# --- 2. Repositorio y checkout -------------------------------------------------------------------
step "2. Repositorio"
if gh repo view "$repo" --json name >/dev/null 2>&1; then
  ok "$repo existe"
elif [[ -n "$create" ]]; then
  run gh repo create "$repo" "--$create" --description "Proyecto gestionado con AES"
  ok "$repo creado ($create)"
else
  die "$repo no existe. Créalo o usa --create private|public."
fi
if [[ -d "$dir/.git" ]]; then
  url=$(git -C "$dir" config --get remote.origin.url || true)
  [[ "$url" == *"$repo"* || "$url" == *"$repo.git" ]] || die "$dir ya es un repositorio, pero su origin ($url) no es $repo."
  ok "checkout en $dir"
elif [[ -d "$dir" ]]; then
  # Carpeta existente (p. ej. la que creaste para el proyecto, con aes-new dentro): se inicializa ahí.
  run git -C "$dir" init -q
  run git -C "$dir" remote add origin "https://github.com/$repo.git"
  if git ls-remote --exit-code --heads "https://github.com/$repo.git" main >/dev/null 2>&1; then
    run git -C "$dir" fetch -q origin
    run git -C "$dir" checkout -q -B main origin/main || die "No pude traer main a $dir: hay archivos que chocan con los del repo."
  else
    run git -C "$dir" checkout -q -B main
  fi
  ok "repositorio inicializado en $dir"
else
  run gh repo clone "$repo" "$dir" -- -q
  ok "clonado en $dir"
fi
[[ $dry -eq 1 && ! -d "$dir/.git" ]] && { warn "dry-run: sin checkout no se pueden simular los pasos locales."; dir=""; }

# --- 3. AES --------------------------------------------------------------------------------------
step "3. AES"
vendor_args=()
IFS=';' read -r -a vendors <<< "${AES_VENDOR:-}"
for v in "${vendors[@]}"; do [[ -n "$v" ]] && vendor_args+=(--vendor "${v/#\~/$HOME}"); done
if [[ -n "$dir" ]]; then
  if [[ -f "$dir/docs/aes/VERSION" ]]; then
    ok "ya instalado: $(cat "$dir/docs/aes/VERSION") (para actualizar: install-aes.sh $dir --upgrade)"
  else
    run env AES_QUIET_NEXT=1 "$aes_root/scripts/install-aes.sh" "$dir" "${vendor_args[@]}"
    ok "instalado"
  fi
fi

if [[ -n "$dir" && -f "$dir/.claude/aes.env" ]]; then
  if [[ "$oc_model" == claude ]]; then bind=claude; else bind="opencode:$oc_model"; fi
  for role in QA PROGRAMMER MECHANIC; do
    run sed -i.bak "s#^AES_BIND_${role}=.*#AES_BIND_${role}=\"${bind}\"#" "$dir/.claude/aes.env"
  done
  run rm -f "$dir/.claude/aes.env.bak"
  ok "QA, programador y mecánico: $bind; verificador: claude"
  if [[ $personal -eq 1 ]]; then ident=personal; else ident=app; fi
  run sed -i.bak "s#^AES_IDENTITY=.*#AES_IDENTITY=\"${ident}\"#" "$dir/.claude/aes.env"; run rm -f "$dir/.claude/aes.env.bak"
  ok "identidad de los agentes: $ident"
  if [[ "$oc_model" != claude && $dry -eq 0 ]]; then
    if (cd "$dir" && timeout 120 opencode run -m "$oc_model" "Responde solo: OK" 2>/dev/null | grep -q OK); then
      ok "OpenCode responde con $oc_model"
    else
      warn "OpenCode no respondió con $oc_model. Revisa la conexión, la clave (/connect) o el saldo antes de delegar."
    fi
  fi
fi

# --- 4. Archivos de la cuenta --------------------------------------------------------------------
step "4. CODEOWNERS y credenciales locales"
if [[ -n "$dir" && -f "$dir/.github/CODEOWNERS" ]]; then
  if grep -q '^[^#].*@tu-usuario' "$dir/.github/CODEOWNERS"; then
    run sed -i.bak "/^#/!s/@tu-usuario/@$owner_login/g" "$dir/.github/CODEOWNERS"; run rm -f "$dir/.github/CODEOWNERS.bak"
    ok "CODEOWNERS → @$owner_login"
  else ok "CODEOWNERS ya tiene dueño"; fi
fi
local_settings="$dir/.claude/settings.local.json"
if [[ $personal -eq 1 ]]; then
  ok "modo personal: sin credenciales de app (los agentes usan tu sesión de gh)"
elif [[ -n "$dir" && ! -f "$local_settings" && -f "$dir/.claude/settings.local.example.json" ]]; then
  mail="${AES_BOT_ID}+${AES_BOT_SLUG}[bot]@users.noreply.github.com"
  if [[ $dry -eq 1 ]]; then printf '  [dry-run] escribir %s\n' "$local_settings"; else
    jq --arg id "$AES_APP_ID" --arg inst "$AES_APP_INSTALLATION_ID" --arg key "$AES_APP_PRIVATE_KEY" \
       --arg nm "${AES_BOT_SLUG}[bot]" --arg mail "$mail" \
       '.env.AES_APP_ID=$id | .env.AES_APP_INSTALLATION_ID=$inst | .env.AES_APP_PRIVATE_KEY=$key
        | .env.GIT_AUTHOR_NAME=$nm | .env.GIT_COMMITTER_NAME=$nm
        | .env.GIT_AUTHOR_EMAIL=$mail | .env.GIT_COMMITTER_EMAIL=$mail' \
       "$dir/.claude/settings.local.example.json" > "$local_settings"
  fi
  ok ".claude/settings.local.json (ignorado por git)"
elif [[ -n "$dir" ]]; then ok ".claude/settings.local.json ya existe"; fi
if [[ -n "$dir" && $dry -eq 0 ]] && ! git -C "$dir" check-ignore -q .claude/settings.local.json; then
  die ".claude/settings.local.json no está en .gitignore: no sigo (tiene la ruta de la llave de la app)."
fi

# --- 5. main y dev -------------------------------------------------------------------------------
step "5. Ramas"
remote_has() { [[ -n "$dir" ]] && git -C "$dir" ls-remote --exit-code --heads origin "$1" >/dev/null 2>&1; }
if [[ -n "$dir" ]]; then
  if remote_has main; then
    ok "main existe en GitHub"
    [[ -z "$(git -C "$dir" status --porcelain)" ]] || warn "hay cambios sin commit en $dir (la instalación): súbelos por PR a dev, main ya está protegida o lo estará."
  else
    ver=$(cat "$dir/docs/aes/VERSION" 2>/dev/null || echo AES)
    run git -C "$dir" checkout -q -B main
    run git -C "$dir" add -A
    # Si una ejecución anterior ya hizo el commit (y falló el push), no hay nada que commitear.
    if [[ $dry -eq 1 ]] || ! git -C "$dir" diff --cached --quiet || ! git -C "$dir" rev-parse -q --verify HEAD >/dev/null; then
      run git -C "$dir" commit -q -m "chore: instalar ${ver%% (*}"
    fi
    run git -C "$dir" push -q -u origin main
    ok "commit inicial en main"
  fi
  if remote_has dev; then ok "dev existe"; else run git -C "$dir" push -q origin main:dev; ok "dev creada desde main"; fi
fi

# --- 6. Ajustes del repositorio ------------------------------------------------------------------
step "6. Ajustes del repositorio"
run gh api -X PATCH "repos/$repo" -f default_branch=dev -F allow_squash_merge=true -F allow_merge_commit=true \
  -F allow_rebase_merge=false -F delete_branch_on_merge=true --silent
ok "dev por defecto; merge commit y squash sí, rebase no; se borran las ramas integradas"

# --- 7. Rulesets ---------------------------------------------------------------------------------
step "7. Rulesets"
admin_bypass='[{"actor_id":5,"actor_type":"RepositoryRole","bypass_mode":"pull_request"}]'
ruleset() { # $1 nombre, $2 ramas (JSON), $3 bypass (JSON), $4 reglas (JSON)
  local body id
  body=$(jq -n --arg n "$1" --argjson inc "$2" --argjson by "$3" --argjson rules "$4" \
    '{name:$n, target:"branch", enforcement:"active", bypass_actors:$by,
      conditions:{ref_name:{include:$inc, exclude:[]}}, rules:$rules}')
  id=$(gh api "repos/$repo/rulesets" --jq ".[] | select(.name==\"$1\") | .id" 2>/dev/null || true)
  if [[ $dry -eq 1 ]]; then printf '  [dry-run] %s ruleset %s\n' "$([[ -n "$id" ]] && echo actualizar || echo crear)" "$1"; return 0; fi
  if [[ -n "$id" ]]; then gh api -X PUT "repos/$repo/rulesets/$id" --input - --silent <<< "$body"
  else gh api -X POST "repos/$repo/rulesets" --input - --silent <<< "$body"; fi
}
# Con app: 1 aprobación de CODEOWNERS (tú apruebas los PR del bot). En modo personal, los PR son tuyos
# y GitHub no deja aprobar los propios: PR obligatorio, sin aprobación; integrar es tu aprobación.
if [[ $personal -eq 1 ]]; then approvals=0; codeowners=false; else approvals=1; codeowners=true; fi
pr_rule() { # $1 métodos permitidos (JSON) o vacío
  jq -n --argjson m "${1:-null}" --argjson n "$approvals" --argjson co "$codeowners" '[{type:"pull_request", parameters:({
      required_approving_review_count:$n, require_code_owner_review:$co,
      dismiss_stale_reviews_on_push:true, require_last_push_approval:false,
      required_review_thread_resolution:false} + (if $m then {allowed_merge_methods:$m} else {} end))}]'
}
ci_rules='[{"type":"deletion"},{"type":"non_fast_forward"},
  {"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":true,
   "required_status_checks":[{"context":"aes"}]}}]'
if ! ruleset ramas-ci '["refs/heads/main","refs/heads/dev"]' '[]' "$ci_rules"; then
  warn "GitHub no aceptó los rulesets: en repos privados necesitan GitHub Pro o Team."
  warn "La CI correrá igual, pero nada impedirá integrar con la CI en rojo. Haz público el repo o mejora el plan, y vuelve a ejecutar."
  no_rulesets=1
else
  ok "ramas-ci: sin borrar, sin force push, check aes obligatorio y al día (sin excepciones)"
fi
if [[ -n "${no_rulesets:-}" ]]; then :
elif ! ruleset aprobacion-dev '["refs/heads/dev"]' "$admin_bypass" "$(pr_rule '["squash","merge"]')" 2>/dev/null \
   || ! ruleset aprobacion-main '["refs/heads/main"]' "$admin_bypass" "$(pr_rule '["merge"]')" 2>/dev/null; then
  warn "GitHub no aceptó limitar los métodos de integración por ruleset; se crean sin ese límite."
  warn "En main integra SIEMPRE con merge commit (releases y hotfixes)."
  ruleset aprobacion-dev '["refs/heads/dev"]' "$admin_bypass" "$(pr_rule)"
  ruleset aprobacion-main '["refs/heads/main"]' "$admin_bypass" "$(pr_rule)"
fi
if [[ -z "${no_rulesets:-}" && $personal -eq 1 ]]; then ok "aprobacion-dev y aprobacion-main: PR obligatorio (sin aprobación: integrar es tu aprobación)"
elif [[ -z "${no_rulesets:-}" ]]; then ok "aprobacion-dev y aprobacion-main: PR con 1 aprobación de CODEOWNERS, aprobaciones viejas se descartan; tú puedes integrar tus PR"; fi

# --- 8. Etiquetas y variables --------------------------------------------------------------------
step "8. Etiquetas y variables"
run gh label create aes:deps-approved    -R "$repo" --color B60205 --description "El humano aprueba dependencias nuevas" --force
run gh label create aes:markers-approved -R "$repo" --color D93F0B --description "El humano aprueba marcadores del guardián" --force
run gh label create aes:verified         -R "$repo" --color 0E8A16 --description "El verificador dio PASS (la pone el humano)" --force
ok "etiquetas aes:*"
run gh variable set AES_APPROVERS -R "$repo" --body "$approvers"
ok "AES_APPROVERS=$approvers"

# --- 9. GitHub App -------------------------------------------------------------------------------
step "9. Acceso de los agentes"
repo_id=$(gh api "repos/$repo" --jq .id 2>/dev/null || true)
if [[ $personal -eq 1 ]]; then
  ok "modo personal: los agentes publican con tu sesión de gh (bash .claude/scripts/agent-gh.sh la usa)"
  repo_id=""; dir_check=0
else dir_check=1; fi
if [[ -n "$repo_id" ]]; then
  if run gh api -X PUT "user/installations/$AES_APP_INSTALLATION_ID/repositories/$repo_id" --silent 2>/dev/null; then
    ok "la app tiene acceso a $repo"
  else
    warn "No pude dar acceso a la app desde aquí. Hazlo en https://github.com/settings/installations/$AES_APP_INSTALLATION_ID (Repository access → $repo)."
  fi
fi
if [[ -n "$dir" && $dry -eq 0 && $dir_check -eq 1 ]]; then
  if tok=$(cd "$dir" && bash .claude/scripts/gh-app-token.sh 2>/dev/null) && [[ "$tok" == ghs_* ]]; then
    if GH_TOKEN=$tok gh api "repos/$repo" --silent 2>/dev/null; then ok "token de la app válido y con acceso al repo"
    else warn "el token de la app es válido, pero todavía no ve $repo (revisa el paso anterior)"; fi
  else
    warn "no se pudo obtener el token de la app: (cd $dir && bash .claude/scripts/gh-app-token.sh)"
  fi
fi

step "Listo."
cat <<EOF
Siguiente:
  - Adapta las semillas cuando haya stack (aes.env, ci/validate.sh, sección STACK del workflow): lo hace EN-001.
  - Abre Claude Code en $dir con el modelo más capaz (/model opus) y pide empezar el proyecto:
    el orquestador usará la skill aes-inception.
  - Costo de los roles en OpenCode: bash .claude/scripts/aes-oc.sh report
EOF
