#!/usr/bin/env bash
# Sets up a GitHub repository with AES, end to end, with a single command.
#
# Usage:
#   ./scripts/setup-repo.sh <owner/repo> [options]
#
# Options:
#   --create private|public   creates the repository if it does not exist
#   --lang en|es              project language (AES_LANG): the language of the project's artifacts (en by default)
#   --opencode <prov/model>   QA, programmer and mechanic in OpenCode with that model (06 §12); the
#                             verifier stays in Claude. By default, AES_OPENCODE_MODEL from app.env;
#                             --opencode claude leaves them all in Claude
#   --personal                no GitHub App: the agents publish with your gh session and the rules
#                             require a PR and green CI, without approval (merging is your approval)
#   --dir <folder>            local checkout; if it exists and is not a git repo, it is initialized there (by default
#                             <repo>, next to the AES repo if you run it from inside it; if not, in the current folder)
#   --config <file>           the account's configuration (~/.config/aes/app.env by default)
#   --dry-run                 shows what it would do, without changing anything (reads are done)
#
# What it does (each step checks first and is skipped if it is already done; it can be repeated safely):
#   1. checks git, gh (with repo and workflow permissions), jq and the account's configuration;
#   2. creates the repository (with --create) and clones it;
#   3. installs AES with install-aes.sh (and the third-party skills in AES_VENDOR), sets the project
#      language and which roles run in OpenCode;
#   4. fills in CODEOWNERS and .claude/settings.local.json (the latter does NOT go to git);
#   5. initial commit on main (only if main does not exist on GitHub yet) and creates dev;
#   6. dev as the default branch; merge commit and squash allowed, rebase not;
#   7. rulesets: ci-branches (main and dev), approval-dev and approval-main (repositories set up before
#      2.0.0 keep their Spanish names: ramas-ci, aprobacion-dev, aprobacion-main);
#   8. aes:* labels and the AES_APPROVERS variable;
#   9. gives the agents' GitHub App access and checks its token.
#
# The only manual part is, once per account, creating the GitHub App (or using --personal); aes-new creates
# ~/.config/aes/app.env (see scripts/aes-app.env.example and the reference implementation's README).
set -euo pipefail

aes_root=$(cd "$(dirname "$0")/.." && pwd)
repo=""; create=""; dir=""; dry=0; oc_model=""; personal=0; lang=""
config="${XDG_CONFIG_HOME:-$HOME/.config}/aes/app.env"
[[ -f "$config" || ! -f "$HOME/.aes/app.env" ]] || config="$HOME/.aes/app.env"   # 1.3.0's location
while [[ $# -gt 0 ]]; do
  case "$1" in
    --create)  create=${2:?--create needs private or public}; shift ;;
    --lang)    lang=${2:?--lang needs en or es}; shift ;;
    --dir)     dir=${2:?--dir needs a folder}; shift ;;
    --opencode) oc_model=${2:?--opencode needs provider/model or claude}; shift ;;
    --config)  config=${2:?--config needs a file}; shift ;;
    --personal) personal=1 ;;
    --dry-run) dry=1 ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *)  repo=$1 ;;
  esac
  shift
done
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "Usage: $0 <owner/repo> [--create private|public] [--lang en|es] [--dir <folder>] [--dry-run]" >&2; exit 2; }
[[ -z "$create" || "$create" == private || "$create" == public ]] || { echo "--create: private or public" >&2; exit 2; }
[[ -z "$lang" || "$lang" == en || "$lang" == es ]] || { echo "--lang: en or es" >&2; exit 2; }
name=${repo#*/}
if [[ -z "$dir" ]]; then
  # Never inside the AES repo: if it is run from there, the project goes next to it.
  case "$PWD/" in "$aes_root"/*) dir="$(dirname "$aes_root")/$name" ;; *) dir="$PWD/$name" ;; esac
fi

ok()   { printf '  ✓ %s\n' "$*"; }
step() { printf '\n%s\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }
die()  { printf '  ✗ %s\n' "$*" >&2; exit 1; }
run()  { if [[ $dry -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else "$@"; fi; }

# --- 1. Requirements ----------------------------------------------------------------------------
step "1. Requirements"
for c in git gh jq; do command -v "$c" >/dev/null || die "$c is missing from the PATH."; done
gh auth status >/dev/null 2>&1 || die "gh has no session: gh auth login"
scopes=$(gh api -i user 2>/dev/null | tr -d '\r' | sed -n 's/^[Xx]-[Oo][Aa]uth-[Ss]copes: *//p')
if [[ -n "$scopes" ]]; then
  for s in repo workflow; do
    grep -qw "$s" <<< "${scopes//,/ }" || die "Your gh session lacks the '$s' permission: gh auth refresh -s $s"
  done
fi
me=$(gh api user --jq .login)
ok "gh as $me"

[[ $personal -eq 1 || -f "$config" ]] || die "$config does not exist. Create it with aes-new or from scripts/aes-app.env.example, or use --personal."
# AES_VENDOR from the environment (even if empty) overrides app.env's: that is how aes-new passes it.
vendor_from_env=${AES_VENDOR+set}; vendor_env=${AES_VENDOR:-}
# shellcheck source=/dev/null
[[ -f "$config" ]] && source "$config"
[[ -n "$vendor_from_env" ]] && AES_VENDOR=$vendor_env
approvers=${AES_APPROVERS:-$me}
owner_login=${approvers%%,*}
if [[ $personal -eq 0 ]]; then
  for v in AES_APP_ID AES_APP_INSTALLATION_ID AES_APP_PRIVATE_KEY AES_BOT_SLUG; do
    [[ -n "${!v:-}" ]] || die "$v is missing in $config."
  done
  [[ -f "${AES_APP_PRIVATE_KEY/#\~/$HOME}" ]] || warn "I cannot find the key at $AES_APP_PRIVATE_KEY (from this shell). If the path is a Windows one and you are on another system, ignore this."
  if [[ -z "${AES_BOT_ID:-}" ]]; then
    AES_BOT_ID=$(gh api "users/${AES_BOT_SLUG}%5Bbot%5D" --jq .id 2>/dev/null || true)
    [[ -n "$AES_BOT_ID" ]] || die "I cannot find the user ${AES_BOT_SLUG}[bot]; check AES_BOT_SLUG or define AES_BOT_ID."
  fi
fi
oc_model=${oc_model:-${AES_OPENCODE_MODEL:-claude}}
if [[ "$oc_model" != claude ]]; then
  command -v opencode >/dev/null || die "You asked for roles in OpenCode ($oc_model), but opencode is not on the PATH."
  [[ "$oc_model" == */* ]] || die "--opencode expects provider/model (e.g. deepseek/deepseek-flash) or claude."
fi
if [[ $personal -eq 1 ]]; then ok "personal mode: the agents publish as $me; approvers $approvers"
else ok "account configuration: app $AES_APP_ID, bot ${AES_BOT_SLUG}[bot] ($AES_BOT_ID), approvers $approvers"; fi

# --- 2. Repository and checkout ------------------------------------------------------------------
step "2. Repository"
if gh repo view "$repo" --json name >/dev/null 2>&1; then
  ok "$repo exists"
elif [[ -n "$create" ]]; then
  run gh repo create "$repo" "--$create" --description "Project managed with AES"
  ok "$repo created ($create)"
else
  die "$repo does not exist. Create it or use --create private|public."
fi
if [[ -d "$dir/.git" ]]; then
  url=$(git -C "$dir" config --get remote.origin.url || true)
  [[ "$url" == *"$repo"* || "$url" == *"$repo.git" ]] || die "$dir is already a repository, but its origin ($url) is not $repo."
  ok "checkout in $dir"
elif [[ -d "$dir" ]]; then
  # An existing folder (e.g. the one you created for the project, with aes-new inside): it is initialized there.
  run git -C "$dir" init -q
  run git -C "$dir" remote add origin "https://github.com/$repo.git"
  if git ls-remote --exit-code --heads "https://github.com/$repo.git" main >/dev/null 2>&1; then
    run git -C "$dir" fetch -q origin
    run git -C "$dir" checkout -q -B main origin/main || die "Could not bring main into $dir: there are files that clash with the repo's."
  else
    run git -C "$dir" checkout -q -B main
  fi
  ok "repository initialized in $dir"
else
  run gh repo clone "$repo" "$dir" -- -q
  ok "cloned in $dir"
fi
[[ $dry -eq 1 && ! -d "$dir/.git" ]] && { warn "dry-run: without a checkout the local steps cannot be simulated."; dir=""; }

# --- 3. AES --------------------------------------------------------------------------------------
step "3. AES"
vendor_args=()
IFS=';' read -r -a vendors <<< "${AES_VENDOR:-}"
for v in "${vendors[@]}"; do [[ -n "$v" ]] && vendor_args+=(--vendor "${v/#\~/$HOME}"); done
if [[ -n "$dir" ]]; then
  if [[ -f "$dir/docs/aes/VERSION" ]]; then
    ok "already installed: $(cat "$dir/docs/aes/VERSION") (to upgrade: install-aes.sh $dir --upgrade)"
  else
    run env AES_QUIET_NEXT=1 "$aes_root/scripts/install-aes.sh" "$dir" --lang "${lang:-en}" "${vendor_args[@]}"
    ok "installed (project language: ${lang:-en})"
  fi
fi

if [[ -n "$dir" && -f "$dir/.claude/aes.env" ]]; then
  if [[ "$oc_model" == claude ]]; then bind=claude; else bind="opencode:$oc_model"; fi
  for role in QA PROGRAMMER MECHANIC; do
    run sed -i.bak "s#^AES_BIND_${role}=.*#AES_BIND_${role}=\"${bind}\"#" "$dir/.claude/aes.env"
  done
  run rm -f "$dir/.claude/aes.env.bak"
  ok "QA, programmer and mechanic: $bind; verifier: claude"
  if [[ $personal -eq 1 ]]; then ident=personal; else ident=app; fi
  run sed -i.bak "s#^AES_IDENTITY=.*#AES_IDENTITY=\"${ident}\"#" "$dir/.claude/aes.env"; run rm -f "$dir/.claude/aes.env.bak"
  ok "agents' identity: $ident"
  if [[ "$oc_model" != claude && $dry -eq 0 ]]; then
    if (cd "$dir" && timeout 120 opencode run -m "$oc_model" "Answer only: OK" 2>/dev/null | grep -q OK); then
      ok "OpenCode answers with $oc_model"
    else
      warn "OpenCode did not answer with $oc_model. Check the connection, the key (/connect) or the balance before delegating."
    fi
  fi
fi

# --- 4. Account files ---------------------------------------------------------------------------
step "4. CODEOWNERS and local credentials"
if [[ -n "$dir" && -f "$dir/.github/CODEOWNERS" ]]; then
  # The placeholder is @your-user (@tu-usuario before 2.0.0).
  if grep -qE '^[^#].*@(your-user|tu-usuario)' "$dir/.github/CODEOWNERS"; then
    run sed -i.bak -E "/^#/!s/@(your-user|tu-usuario)/@$owner_login/g" "$dir/.github/CODEOWNERS"; run rm -f "$dir/.github/CODEOWNERS.bak"
    ok "CODEOWNERS → @$owner_login"
  else ok "CODEOWNERS already has an owner"; fi
fi
local_settings="$dir/.claude/settings.local.json"
if [[ $personal -eq 1 ]]; then
  ok "personal mode: no app credentials (the agents use your gh session)"
elif [[ -n "$dir" && ! -f "$local_settings" && -f "$dir/.claude/settings.local.example.json" ]]; then
  mail="${AES_BOT_ID}+${AES_BOT_SLUG}[bot]@users.noreply.github.com"
  if [[ $dry -eq 1 ]]; then printf '  [dry-run] write %s\n' "$local_settings"; else
    jq --arg id "$AES_APP_ID" --arg inst "$AES_APP_INSTALLATION_ID" --arg key "$AES_APP_PRIVATE_KEY" \
       --arg nm "${AES_BOT_SLUG}[bot]" --arg mail "$mail" \
       '.env.AES_APP_ID=$id | .env.AES_APP_INSTALLATION_ID=$inst | .env.AES_APP_PRIVATE_KEY=$key
        | .env.GIT_AUTHOR_NAME=$nm | .env.GIT_COMMITTER_NAME=$nm
        | .env.GIT_AUTHOR_EMAIL=$mail | .env.GIT_COMMITTER_EMAIL=$mail' \
       "$dir/.claude/settings.local.example.json" > "$local_settings"
  fi
  ok ".claude/settings.local.json (ignored by git)"
elif [[ -n "$dir" ]]; then ok ".claude/settings.local.json already exists"; fi
if [[ -n "$dir" && $dry -eq 0 ]] && ! git -C "$dir" check-ignore -q .claude/settings.local.json; then
  die ".claude/settings.local.json is not in .gitignore: stopping (it has the path of the app's key)."
fi

# --- 5. main and dev ----------------------------------------------------------------------------
step "5. Branches"
remote_has() { [[ -n "$dir" ]] && git -C "$dir" ls-remote --exit-code --heads origin "$1" >/dev/null 2>&1; }
if [[ -n "$dir" ]]; then
  if remote_has main; then
    ok "main exists on GitHub"
    [[ -z "$(git -C "$dir" status --porcelain)" ]] || warn "there are uncommitted changes in $dir (the installation): push them through a PR into dev, main is or will be protected."
  else
    ver=$(cat "$dir/docs/aes/VERSION" 2>/dev/null || echo AES)
    run git -C "$dir" checkout -q -B main
    run git -C "$dir" add -A
    # If an earlier run already made the commit (and the push failed), there is nothing to commit.
    if [[ $dry -eq 1 ]] || ! git -C "$dir" diff --cached --quiet || ! git -C "$dir" rev-parse -q --verify HEAD >/dev/null; then
      run git -C "$dir" commit -q -m "chore: install ${ver%% (*}"
    fi
    run git -C "$dir" push -q -u origin main
    ok "initial commit on main"
  fi
  if remote_has dev; then ok "dev exists"; else run git -C "$dir" push -q origin main:dev; ok "dev created from main"; fi
fi

# --- 6. Repository settings ---------------------------------------------------------------------
step "6. Repository settings"
run gh api -X PATCH "repos/$repo" -f default_branch=dev -F allow_squash_merge=true -F allow_merge_commit=true \
  -F allow_rebase_merge=false -F delete_branch_on_merge=true --silent
ok "dev by default; merge commit and squash yes, rebase no; merged branches are deleted"

# --- 7. Rulesets ---------------------------------------------------------------------------------
step "7. Rulesets"
admin_bypass='[{"actor_id":5,"actor_type":"RepositoryRole","bypass_mode":"pull_request"}]'
# The rulesets' names before 2.0.0: an existing one is updated (and renamed), never duplicated.
legacy_name() { case "$1" in ci-branches) echo ramas-ci ;; approval-dev) echo aprobacion-dev ;; approval-main) echo aprobacion-main ;; esac; }
ruleset() { # $1 name, $2 branches (JSON), $3 bypass (JSON), $4 rules (JSON)
  local body id old
  old=$(legacy_name "$1")
  body=$(jq -n --arg n "$1" --argjson inc "$2" --argjson by "$3" --argjson rules "$4" \
    '{name:$n, target:"branch", enforcement:"active", bypass_actors:$by,
      conditions:{ref_name:{include:$inc, exclude:[]}}, rules:$rules}')
  id=$(gh api "repos/$repo/rulesets" --jq ".[] | select(.name==\"$1\" or .name==\"$old\") | .id" 2>/dev/null | head -n1 || true)
  if [[ $dry -eq 1 ]]; then printf '  [dry-run] %s ruleset %s\n' "$([[ -n "$id" ]] && echo update || echo create)" "$1"; return 0; fi
  if [[ -n "$id" ]]; then gh api -X PUT "repos/$repo/rulesets/$id" --input - --silent <<< "$body"
  else gh api -X POST "repos/$repo/rulesets" --input - --silent <<< "$body"; fi
}
# With the app: 1 approval from CODEOWNERS (you approve the bot's PRs). In personal mode, the PRs are yours
# and GitHub does not allow approving your own: a PR is required, without approval; merging is your approval.
if [[ $personal -eq 1 ]]; then approvals=0; codeowners=false; else approvals=1; codeowners=true; fi
pr_rule() { # $1 allowed methods (JSON) or empty
  jq -n --argjson m "${1:-null}" --argjson n "$approvals" --argjson co "$codeowners" '[{type:"pull_request", parameters:({
      required_approving_review_count:$n, require_code_owner_review:$co,
      dismiss_stale_reviews_on_push:true, require_last_push_approval:false,
      required_review_thread_resolution:false} + (if $m then {allowed_merge_methods:$m} else {} end))}]'
}
ci_rules='[{"type":"deletion"},{"type":"non_fast_forward"},
  {"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":true,
   "required_status_checks":[{"context":"aes"}]}}]'
if ! ruleset ci-branches '["refs/heads/main","refs/heads/dev"]' '[]' "$ci_rules"; then
  warn "GitHub did not accept the rulesets: in private repos they need GitHub Pro or Team."
  warn "CI will run anyway, but nothing will prevent merging with CI red. Make the repo public or upgrade the plan, and run again."
  no_rulesets=1
else
  ok "ci-branches: no deletion, no force push, aes check required and up to date (no exceptions)"
fi
if [[ -n "${no_rulesets:-}" ]]; then :
elif ! ruleset approval-dev '["refs/heads/dev"]' "$admin_bypass" "$(pr_rule '["squash","merge"]')" 2>/dev/null \
   || ! ruleset approval-main '["refs/heads/main"]' "$admin_bypass" "$(pr_rule '["merge"]')" 2>/dev/null; then
  warn "GitHub did not accept limiting the merge methods per ruleset; they are created without that limit."
  warn "On main ALWAYS merge with a merge commit (releases and hotfixes)."
  ruleset approval-dev '["refs/heads/dev"]' "$admin_bypass" "$(pr_rule)"
  ruleset approval-main '["refs/heads/main"]' "$admin_bypass" "$(pr_rule)"
fi
if [[ -z "${no_rulesets:-}" && $personal -eq 1 ]]; then ok "approval-dev and approval-main: PR required (no approval: merging is your approval)"
elif [[ -z "${no_rulesets:-}" ]]; then ok "approval-dev and approval-main: PR with 1 approval from CODEOWNERS, stale approvals are dismissed; you can merge your own PRs"; fi

# --- 8. Labels and variables --------------------------------------------------------------------
step "8. Labels and variables"
run gh label create aes:deps-approved    -R "$repo" --color B60205 --description "The human approves new dependencies" --force
run gh label create aes:markers-approved -R "$repo" --color D93F0B --description "The human approves guard markers" --force
run gh label create aes:budget-approved  -R "$repo" --color FBCA04 --description "The human approves going over a task's production budget" --force
run gh label create aes:verified         -R "$repo" --color 0E8A16 --description "Only with AES_REQUIRE_VERIFIED=1: the verifier gave PASS (the human puts it on)" --force
ok "aes:* labels"
run gh variable set AES_APPROVERS -R "$repo" --body "$approvers"
ok "AES_APPROVERS=$approvers"

# --- 9. GitHub App -------------------------------------------------------------------------------
step "9. The agents' access"
repo_id=$(gh api "repos/$repo" --jq .id 2>/dev/null || true)
if [[ $personal -eq 1 ]]; then
  ok "personal mode: the agents publish with your gh session (bash .claude/scripts/agent-gh.sh uses it)"
  repo_id=""; dir_check=0
else dir_check=1; fi
if [[ -n "$repo_id" ]]; then
  if run gh api -X PUT "user/installations/$AES_APP_INSTALLATION_ID/repositories/$repo_id" --silent 2>/dev/null; then
    ok "the app has access to $repo"
  else
    warn "Could not give the app access from here. Do it at https://github.com/settings/installations/$AES_APP_INSTALLATION_ID (Repository access → $repo)."
  fi
fi
if [[ -n "$dir" && $dry -eq 0 && $dir_check -eq 1 ]]; then
  if tok=$(cd "$dir" && bash .claude/scripts/gh-app-token.sh 2>/dev/null) && [[ "$tok" == ghs_* ]]; then
    if GH_TOKEN=$tok gh api "repos/$repo" --silent 2>/dev/null; then ok "the app's token is valid and has access to the repo"
    else warn "the app's token is valid, but it does not see $repo yet (check the previous step)"; fi
    perms=$(cd "$dir" && bash .claude/scripts/gh-app-token.sh --permissions 2>/dev/null || echo '{}')
    for p in contents pull_requests; do
      [[ "$(jq -r --arg p "$p" '.[$p] // "none"' <<< "$perms")" == write ]] \
        || warn "the app does not have $p = write: adjust it in the app (Permissions) and accept the change in the installation"
    done
    [[ "$(jq -r '.workflows // "none"' <<< "$perms")" == none ]] \
      || warn "the app has the Workflows permission: AES leaves it at No access so that the agents cannot change the CI that judges them. You apply workflow changes with .claude/scripts/aes-workflow.sh"
  else
    warn "could not get the app's token: (cd $dir && bash .claude/scripts/gh-app-token.sh)"
  fi
fi

step "Done."
cat <<EOF
Next:
  - Adapt the seeds once there is a stack (aes.env, ci/validate.sh, the workflow's STACK section): EN-001 does it.
  - Open Claude Code in $dir with the most capable model (/model opus) and ask to start the project:
    the orchestrator will use the aes-inception skill.
  - Cost of the roles in OpenCode: bash .claude/scripts/aes-oc.sh report
EOF
