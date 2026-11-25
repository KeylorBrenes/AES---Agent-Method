#!/usr/bin/env bash
# aes-new — turns the folder you run it in into a project with AES, ready to start.
#
#   mkdir to-do && cd to-do
#   curl -fsSL https://raw.githubusercontent.com/KeylorBrenes/AES---Agent-Method/main/scripts/aes-new.sh -o aes-new.sh
#   bash aes-new.sh
#
# It works on macOS, Linux and Windows (Git Bash). It asks what it needs, with default values:
#   1. does the project go in this folder?, the repository's name (the folder's), public or private,
#      and the project language (the one the agents write stories, plans and reports in);
#   2. which identity the agents publish with: the agents' GitHub App or your own gh session;
#   3. where QA, programmer and mechanic work: Claude Code or OpenCode (and with which model);
#   4. third-party skills (archify, impeccable).
# Then it downloads AES to a temporary folder, creates the repository on GitHub, installs AES, makes the
# initial commit, creates main and dev, applies the rules and configures the roles. At the end it offers
# to start: it opens Claude Code right there, with Opus, and the orchestrator starts the inception (it asks
# you for the idea).
#
# Outside the project it only stores your account's configuration (the GitHub App's data and your
# default answers) in ~/.config/aes/. The script moves itself to .aes/aes-new.sh (ignored by git)
# so you can run it again if something failed halfway.
#
# Optional variables: AES_REF (the AES version: tag or branch), AES_REPO_URL.
set -euo pipefail

# Default AES version. "latest" = the latest published tag.
AES_DEFAULT_REF="latest"
AES_REPO_URL=${AES_REPO_URL:-https://github.com/KeylorBrenes/AES---Agent-Method.git}
AES_WEB=https://github.com/KeylorBrenes/AES---Agent-Method
README_APP="$AES_WEB/blob/main/profiles/reference/claude-code-subagents/README.md#2-the-agents-github-app"
conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/aes"
app_env="$conf_dir/app.env"
[[ -f "$app_env" || ! -f "$HOME/.aes/app.env" ]] || app_env="$HOME/.aes/app.env"   # 1.3.0's location
defaults="$conf_dir/defaults.env"
# shellcheck source=/dev/null
[[ -f "$defaults" ]] && source "$defaults"
self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")

# --- Helpers (bash 3.2: no ${x,,}, mapfile or associative arrays) --------------------------------
if [[ -t 1 ]]; then b=$'\033[1m'; n=$'\033[0m'; else b=""; n=""; fi
step() { printf '\n%s%s%s\n' "$b" "$*" "$n"; }
ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }
die()  { printf '  ✗ %s\n' "$*" >&2; exit 1; }
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
ask() { # $1 question, $2 default value → $REPLY
  if [[ -n "${2:-}" ]]; then read -r -p "  $1 [$2]: " REPLY || true; REPLY=${REPLY:-$2}
  else read -r -p "  $1: " REPLY || true; fi
}
# A path as the person types or pastes it: without quotes (Windows "Copy as path" adds them),
# with ~ expanded and, in Git Bash, in C:/… form (bash, node and openssl understand it).
norm_path() {
  local p=$1
  p="${p#"${p%%[![:space:]]*}"}"; p="${p%"${p##*[![:space:]]}"}"
  p=${p#\"}; p=${p%\"}; p=${p#\'}; p=${p%\'}
  # shellcheck disable=SC2088  # compares the "~" text the person typed
  case "$p" in "~"|"~/"*) p="$HOME${p#\~}" ;; esac
  if command -v cygpath >/dev/null 2>&1; then p=$(cygpath -m "$p"); else p=${p//\\//}; fi
  printf '%s' "$p"
}
ask_req() { while :; do ask "$@"; [[ -n "$REPLY" ]] && return 0; warn "A value is needed."; done; }
yes_no() { # $1 question, $2 y|n default
  while :; do
    ask "$1 (y/n)" "${2:-y}"
    case "$(lower "$REPLY")" in y|yes|s|si|sí) return 0 ;; n|no) return 1 ;; esac
  done
}
choose() { # $1 question, $2 default option, rest: options → number in $REPLY
  local q=$1 def=$2 i=1 o; shift 2
  printf '  %s\n' "$q"
  for o in "$@"; do printf '    %d) %s\n' "$i" "$o"; i=$((i + 1)); done
  while :; do ask "Option" "$def"; [[ "$REPLY" =~ ^[0-9]+$ ]] && (( REPLY >= 1 && REPLY <= $# )) && return 0; done
}
save_default() {
  mkdir -p "$conf_dir"; touch "$defaults"
  grep -v "^$1=" "$defaults" > "$defaults.tmp" || true
  printf '%s=%q\n' "$1" "$2" >> "$defaults.tmp"; mv "$defaults.tmp" "$defaults"
}
tmp=$(mktemp -d 2>/dev/null || mktemp -d -t aes)
trap 'rm -rf "$tmp"' EXIT

printf '%saes-new%s — a new project with AES. Enter accepts the value in brackets; Ctrl+C cancels without changing anything.\n' "$b" "$n"

# --- 1. Tools and GitHub session ----------------------------------------------------------------
step "1. Tools"
missing=""
for c in git gh jq node; do command -v "$c" >/dev/null || missing="$missing $c"; done
if [[ -n "$missing" ]]; then
  warn "Missing:$missing"
  echo "    macOS:   brew install git gh jq node"
  echo "    Windows: winget install --id Git.Git -e; winget install --id GitHub.cli -e; winget install --id jqlang.jq -e; winget install --id OpenJS.NodeJS.LTS -e"
  echo "    Linux:   sudo dnf install git gh jq nodejs  (or apt; gh: https://github.com/cli/cli/blob/trunk/docs/install_linux.md)"
  die "Install them, open a new terminal and run again: bash aes-new.sh"
fi
ok "git, gh, jq and node"
if command -v claude >/dev/null; then ok "Claude Code"; else warn "I cannot find Claude Code (claude): you will need it to start (https://claude.com/claude-code)."; fi
if ! gh auth status >/dev/null 2>&1; then
  warn "gh has no session."
  yes_no "Sign in now (gh auth login)?" y || die "Without a gh session I cannot create the repository."
  gh auth login
fi
scopes=$(gh api -i user 2>/dev/null | tr -d '\r' | sed -n 's/^[Xx]-[Oo][Aa]uth-[Ss]copes: *//p')
if [[ -n "$scopes" ]] && ! printf '%s' "$scopes" | tr ',' ' ' | grep -qw workflow; then
  warn "Your gh session lacks the 'workflow' permission (needed to push the CI)."
  yes_no "Add it now (gh auth refresh -s workflow)?" y || die "Without 'workflow' the CI cannot be pushed."
  gh auth refresh -s workflow
fi
me=$(gh api user --jq .login)
ok "GitHub as $me"

# --- 2. Folder and repository -------------------------------------------------------------------
step "2. Project"
here=$(pwd)
if yes_no "Does the project go in this folder? ($here)" y; then dir=$here
else
  ask_req "Project folder (created if it does not exist)"; dir=$(norm_path "$REPLY")
  mkdir -p "$dir"; dir=$(cd "$dir" && pwd)
fi
if [[ ! -d "$dir/.git" ]]; then
  others=""
  for f in "$dir"/* "$dir"/.[!.]*; do
    [[ -e "$f" ]] || continue
    case "$(basename "$f")" in "$(basename "$self")"|.aes) ;; *) others="$others$(basename "$f")"$'\n' ;; esac
  done
  if [[ -n "$others" ]]; then
    warn "The folder already has files; they will go into the initial commit:"
    printf '%s' "$others" | head -n 8 | sed 's/^/      /'
    yes_no "Continue?" n || exit 0
  fi
fi
folder=$(basename "$dir" | tr ' ' '-' | tr -cd 'A-Za-z0-9._-')
while :; do
  ask "Repository name" "$folder"; name=$REPLY
  [[ "$name" =~ ^[A-Za-z0-9_.-]+$ ]] && break; warn "Only letters, digits, '.', '-' and '_'."
done
ask "Owner on GitHub (user or organization)" "$me"; owner=$REPLY
create=""
if gh repo view "$owner/$name" --json name >/dev/null 2>&1; then
  ok "$owner/$name already exists on GitHub: it is used as it is."
else
  choose "Visibility" 1 \
    "public: full branch rules and unlimited GitHub Actions" \
    "private: only you see the code (branch rules need GitHub Pro or Team)"
  if [[ $REPLY == 1 ]]; then create=public; else
    create=private
    plan=""; [[ "$owner" == "$me" ]] && plan=$(gh api user --jq '.plan.name // empty' 2>/dev/null || true)
    if [[ "$(lower "$plan")" == free ]]; then
      warn "Your account is GitHub Free: a private repo has no branch rules (nothing prevents merging"
      warn "with CI red) and Actions has 2,000 minutes a month."
      yes_no "Continue with private?" n || { create=public; ok "It will be public."; }
    fi
  fi
fi
choose "Project language (what the agents write stories, plans, reports and the backlog in):" "${AES_LANG_CHOICE:-1}" \
  "English" \
  "Español"
if [[ $REPLY == 2 ]]; then lang=es; else lang=en; fi

# --- 3. The agents' identity ---------------------------------------------------------------------
step "3. Which identity the agents publish with"
app_ok() {
  [[ -f "$app_env" ]] || return 1
  # shellcheck source=/dev/null
  (source "$app_env"; [[ -n "${AES_APP_ID:-}" && -n "${AES_APP_INSTALLATION_ID:-}" && -n "${AES_APP_PRIVATE_KEY:-}" && -n "${AES_BOT_SLUG:-}" ]])
}
personal=0
if app_ok; then
  # shellcheck source=/dev/null
  bot=$(source "$app_env"; printf '%s[bot]' "$AES_BOT_SLUG")
  choose "You have the app $bot configured." "${AES_IDENTITY_CHOICE:-1}" \
    "with the app: you approve its PRs (recommended)" \
    "personal: with your gh session; PR and CI required, merging is your approval"
  [[ $REPLY == 2 ]] && personal=1
else
  choose "There is no agents' GitHub App configured." 1 \
    "I already created it: here is its data" \
    "I want to create it first (show me how and exit)" \
    "continue without an app: personal mode (PR and CI required, merging is your approval)"
  case "$REPLY" in
    2) echo; echo "  Create it with this section (once per account, a few minutes):"; echo "    $README_APP"
       echo "  Then run again: bash aes-new.sh"; exit 0 ;;
    3) personal=1 ;;
    1)
      echo "  The app's data (Settings → Developer settings → GitHub Apps → your app):"
      ask_req "App ID (General page)"; app_id=$REPLY
      ask_req "Installation ID (final number of github.com/settings/installations/<id>)"; inst=$REPLY
      ask_req "Slug (github.com/apps/<slug>)"; slug=$REPLY
      while :; do
        ask_req "Path of the .pem key (outside any repository; you can paste it as it is)" "$conf_dir/aes-agent.pem"; key=$(norm_path "$REPLY")
        [[ -f "$key" ]] && break; warn "$key does not exist."
      done
      ask "Approvers (comma-separated logins)" "$me"; approvers=$REPLY
      mkdir -p "$conf_dir"; app_env="$conf_dir/app.env"
      ( umask 077
        printf '%s\n' "# aes-new: the agents' GitHub App data (only the key's path, never the key)." \
          "AES_APP_ID=$app_id" "AES_APP_INSTALLATION_ID=$inst" "AES_APP_PRIVATE_KEY=$key" \
          "AES_BOT_SLUG=$slug" "AES_APPROVERS=$approvers" > "$app_env" )
      ok "saved in $app_env" ;;
  esac
fi

# --- 4. Where the roles work --------------------------------------------------------------------
step "4. Where the roles work"
echo "  The orchestrator is Claude Code with the most capable model; the verifier, always Claude."
choose "QA, programmer and mechanic:" "${AES_HARNESS_CHOICE:-1}" \
  "Claude Code (subagents)" \
  "OpenCode (another provider, cheaper)" \
  "Codex (not available in AES yet)"
harness=$REPLY; oc_model=claude
case "$harness" in
  2)
    command -v opencode >/dev/null || die "I cannot find opencode. Install it (https://opencode.ai) and run again."
    choose "Model:" "${AES_MODEL_CHOICE:-1}" \
      "deepseek/deepseek-flash (paid DeepSeek V4.1 Flash, recommended: a platform.deepseek.com key with /connect in OpenCode)" \
      "opencode/deepseek-v4.1-flash-free (free, only for trying out: the plan cuts long sessions off at its usage limit)" \
      "other (provider/model)"
    model_choice=$REPLY
    case "$REPLY" in
      1) oc_model=deepseek/deepseek-flash ;;
      2) oc_model=opencode/deepseek-v4.1-flash-free ;;
      3) while :; do ask_req "provider/model" "${AES_OPENCODE_MODEL:-}"; [[ "$REPLY" == */* ]] && break; done; oc_model=$REPLY ;;
    esac ;;
  3) die "Codex is not integrated in AES yet. Run again and choose Claude Code or OpenCode." ;;
esac

# --- 5. Third-party skills -----------------------------------------------------------------------
step "5. Third-party skills (optional; installed at their latest published version, which stays fixed)"
want_archify=n; want_imp=n
if yes_no "archify: architecture diagrams at inception" "${AES_WANT_ARCHIFY:-y}"; then want_archify=y; fi
if yes_no "impeccable: interface design (if the project has a UI)" "${AES_WANT_IMPECCABLE:-y}"; then want_imp=y; fi

# --- 6. Summary ----------------------------------------------------------------------------------
ref=${AES_REF:-$AES_DEFAULT_REF}
if [[ "$ref" == latest ]]; then
  ref=$(git ls-remote --tags --refs "$AES_REPO_URL" 'v*' 2>/dev/null | sed 's#.*refs/tags/##' | sort -V | tail -n1)
  [[ -n "$ref" ]] || die "I cannot find published AES versions at $AES_REPO_URL."
fi
vis=""; [[ -n "$create" ]] && { if [[ $create == public ]]; then vis=" (created, public)"; else vis=" (created, private)"; fi; }
skills_txt=""; [[ $want_archify == y ]] && skills_txt="archify "; [[ $want_imp == y ]] && skills_txt="${skills_txt}impeccable"
step "6. Summary"
echo "  Folder:      $dir"
echo "  Repository:  $owner/$name$vis"
echo "  Language:    $lang"
if [[ $personal -eq 1 ]]; then echo "  Identity:    personal ($me)"; else echo "  Identity:    GitHub App"; fi
if [[ $oc_model == claude ]]; then echo "  Roles:       Claude Code"
else echo "  Roles:       QA, programmer and mechanic in OpenCode ($oc_model); verifier in Claude"; fi
echo "  Skills:      ${skills_txt:-none}"
echo "  AES:         $ref"
yes_no "Create the project?" y || { echo "  Cancelled. Nothing was changed."; exit 0; }

save_default AES_HARNESS_CHOICE "$harness"
[[ -n "${model_choice:-}" ]] && save_default AES_MODEL_CHOICE "$model_choice"
[[ $oc_model != claude ]] && save_default AES_OPENCODE_MODEL "$oc_model"
save_default AES_IDENTITY_CHOICE "$((personal + 1))"
save_default AES_WANT_ARCHIFY "$want_archify"
save_default AES_WANT_IMPECCABLE "$want_imp"
save_default AES_LANG_CHOICE "$([[ $lang == es ]] && echo 2 || echo 1)"

# --- 7. Downloads (temporary) -------------------------------------------------------------------
step "7. Downloads"
git -c core.autocrlf=false clone -q --depth 1 --branch "$ref" "$AES_REPO_URL" "$tmp/aes" 2>/dev/null \
  || die "Could not download AES $ref from $AES_REPO_URL."
grep -q -- '--personal' "$tmp/aes/scripts/setup-repo.sh" || die "AES $ref is older than 1.4.0: aes-new needs 1.4.0 or later (AES_REF)."
lang_arg=(--lang "$lang")
if ! grep -q -- '--lang' "$tmp/aes/scripts/setup-repo.sh"; then
  lang_arg=(); [[ $lang == es ]] || warn "AES $ref is older than 2.0.0: it has no project language and writes in Spanish."
fi
ok "AES $ref"
vendors=""
skill() { # $1 name, $2 repo → adds the skill's folder to $vendors
  local nm=$1 url=$2 dst="$tmp/skills/$1" tags tag folder
  tags=$(git ls-remote --tags --refs "$url" 2>/dev/null | sed 's#.*refs/tags/##' || true)
  tag=$(printf '%s\n' "$tags" | grep -E '^v?[0-9]+\.[0-9]+' | sort -V | tail -n1 || true)
  [[ -n "$tag" ]] || tag=$(printf '%s\n' "$tags" | grep -E '[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1 || true)
  if [[ -n "$tag" ]]; then git -c core.autocrlf=false clone -q --depth 1 --branch "$tag" "$url" "$dst" 2>/dev/null
  else git -c core.autocrlf=false clone -q --depth 1 "$url" "$dst" 2>/dev/null; fi || { warn "Could not download $nm; continuing without it."; return 0; }
  # The skill's folder: the copy for Claude Code if it brings one, if not the one of the SKILL.md with its name.
  if [[ -f "$dst/.claude/skills/$nm/SKILL.md" ]]; then folder="$dst/.claude/skills/$nm"
  else
    folder=$(find "$dst" -name SKILL.md -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null \
      | while IFS= read -r f; do head -n 15 "$f" | grep -qE "^name: *[\"']?${nm}[\"']? *\$" \
          && printf '%s %s\n' "${#f}" "$(dirname "$f")"; done | sort -n | head -n1 | cut -d' ' -f2-) || true
  fi
  [[ -n "$folder" ]] || { warn "I cannot find $nm's SKILL.md; continuing without it."; return 0; }
  vendors="${vendors:+$vendors;}$folder"
  ok "$nm ${tag:-(main branch)}"
}
if [[ $want_archify == y ]]; then skill archify https://github.com/tt-a1i/archify.git; fi
if [[ $want_imp == y ]]; then skill impeccable https://github.com/pbakaus/impeccable.git; fi

# --- 8. Create the project -----------------------------------------------------------------------
# The script moves itself to .aes/ (which AES ignores in git) before the initial commit.
if [[ "$(dirname "$self")" == "$dir" ]]; then
  mkdir -p "$dir/.aes"; mv "$self" "$dir/.aes/aes-new.sh"; self="$dir/.aes/aes-new.sh"
fi
args=("$owner/$name" --dir "$dir" --opencode "$oc_model" ${lang_arg[@]+"${lang_arg[@]}"})
[[ -n "$create" ]] && args+=(--create "$create")
[[ $personal -eq 1 ]] && args+=(--personal)
[[ -f "$app_env" ]] && args+=(--config "$app_env")
AES_VENDOR="$vendors" bash "$tmp/aes/scripts/setup-repo.sh" "${args[@]}"

# --- 9. Start -----------------------------------------------------------------------------------
step "Project ready in $dir"
echo "  To repeat a step: bash .aes/aes-new.sh (it skips what is already done)."
if [[ $lang == es ]]; then start_prompt="Empecemos el proyecto. Todavía no hay planeamiento: usa la skill aes-inception y pregúntame por la idea."
else start_prompt="Let's start the project. There is no planning yet: use the aes-inception skill and ask me about the idea."; fi
if command -v claude >/dev/null && yes_no "Start now? (opens Claude Code here, with Opus, and starts the inception)" y; then
  cd "$dir"
  trap - EXIT; rm -rf "$tmp"
  exec claude --model opus "$start_prompt"
fi
echo "  Whenever you want: cd \"$dir\" && claude --model opus"
echo "  And tell it: \"$start_prompt\""
