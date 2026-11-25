#!/usr/bin/env bash
# Installs or upgrades AES in a project, from this copy of AES (a fixed version).
#
# Usage:
#   ./scripts/install-aes.sh <project>                      new installation
#   ./scripts/install-aes.sh <project> --upgrade            upgrade to this version
#   ./scripts/install-aes.sh <project> --check              does what is installed match this version?
#   ... --vendor <skill-folder>  (repeatable)               copies a third-party skill and records its version
#   ... --profile <name>                                     reference implementation (by default
#                                                            claude-code-subagents)
#   ... --lang en|es                                         project language (AES_LANG in .claude/aes.env).
#                                                            Default: en on install; on upgrade, the one the
#                                                            project has, or else the backlog's language
#
# What it copies (06 §6.2: everything at a fixed version, inside the repository, reviewed by PR):
#   - AES files: hooks, scripts, core skills, CI scripts, docs/aes/ (DoR/DoD,
#     AES-CORE.md, templates, license, VERSION). Overwritten on upgrade: not edited in the project.
#   - Seed files: subagents, settings.json, aes.env, workflow, CODEOWNERS, validate.sh,
#     CLAUDE.md. The project adapts them. They are only copied if they do not exist; on upgrade, if the
#     project adapted one and AES changed it, the new one is left beside it as <file>.aes-new for you to
#     compare by hand (docs/aes/seeds.sha256 keeps the checksum of the seeds delivered).
#   - Third-party skills (--vendor): copied to the skills folder and recorded in
#     docs/aes/skills.lock (version, origin and checksum), without downloading anything.
#
# The installer does not commit or touch GitHub's configuration: when it finishes, it lists what is left.
set -euo pipefail

aes_root=$(cd "$(dirname "$0")/.." && pwd)
target=""; mode=install; profile=claude-code-subagents; vendors=(); lang=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --upgrade) mode=upgrade ;;
    --check)   mode=check ;;
    --vendor)  vendors+=("${2:?--vendor needs a folder}"); shift ;;
    --profile) profile=${2:?--profile needs a name}; shift ;;
    --lang)    lang=${2:?--lang needs en or es}; shift
               [[ $lang == en || $lang == es ]] || { echo "--lang: en or es" >&2; exit 2; } ;;
    -h|--help) sed -n '2,26p' "$0"; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *)  target=$1 ;;
  esac
  shift
done
[[ -n "$target" ]] || { echo "Usage: $0 <project> [--upgrade|--check] [--lang en|es] [--vendor <folder>]..." >&2; exit 2; }
[[ -d "$target" ]] || { echo "The project folder does not exist: $target" >&2; exit 2; }
target=$(cd "$target" && pwd)
ref="$aes_root/profiles/reference/$profile"
[[ -d "$ref" ]] || { echo "The reference implementation does not exist: $ref" >&2; exit 2; }

# "**Version:**" (or "**Versión:**" in READMEs before 2.0.0).
version=$(sed -nE 's/^\*\*Versi(o|ó)n:\*\* *([0-9.]+).*/\2/p' "$aes_root/README.md" | head -n1)
commit=$(git -C "$aes_root" rev-parse --short HEAD 2>/dev/null || echo "no-git")
if [[ -n "$(git -C "$aes_root" status --porcelain 2>/dev/null)" ]]; then commit="$commit-modified"; fi
stamp="AES $version ($commit, profile $profile)"

# The copies of the core skills in the reference must be up to date.
"$aes_root/scripts/sync-skills.sh" --check >/dev/null

# --- What belongs to AES and what is a seed ----------------------------------------------------
owned=()   # pairs "source|relative destination"
seeds=()
add_tree() { # $1 list, $2 source folder, $3 relative destination
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
# AES's license (MIT for the code, CC BY 4.0 for the rest): it travels with the copies.
for f in LICENSE LICENSE-MIT.txt LICENSE-CC-BY-4.0.txt; do owned+=("$aes_root/$f|docs/aes/$f"); done
add_tree owned "$aes_root/templates" docs/aes/templates

add_tree seeds "$ref/.claude/agents" .claude/agents
for f in .claude/settings.json .claude/aes.env .github/workflows/aes.yml .github/CODEOWNERS ci/validate.sh CLAUDE.md opencode.json; do
  seeds+=("$ref/$f|$f")
done

# Equal except for line endings: on Windows, a clone with core.autocrlf leaves CRLF in the working copy.
same() { [[ -f "$2" ]] && cmp -s <(tr -d '\r' < "$1") <(tr -d '\r' < "$2"); }
# sha256sum does not exist on macOS; shasum does.
sha256() { if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }

# --- Check ---------------------------------------------------------------------------------------
if [[ $mode == check ]]; then
  echo "Installed: $(cat "$target/docs/aes/VERSION" 2>/dev/null || echo 'no docs/aes/VERSION')"
  echo "This copy: $stamp"
  diff=0
  for p in "${owned[@]}"; do
    src=${p%%|*}; rel=${p#*|}
    same "$src" "$target/$rel" || { echo "  different or missing: $rel"; diff=1; }
  done
  for p in "${seeds[@]}"; do
    rel=${p#*|}
    [[ -f "$target/$rel" ]] || { echo "  seed missing: $rel"; diff=1; }
    [[ -f "$target/$rel.aes-new" ]] && echo "  pending review: $rel.aes-new"
  done
  [[ $diff -eq 0 ]] && echo "The AES files match this version."
  exit $diff
fi

if [[ $mode == install && -f "$target/docs/aes/VERSION" ]]; then
  echo "The project already has AES ($(cat "$target/docs/aes/VERSION")). Use --upgrade." >&2
  exit 1
fi
git -C "$target" rev-parse --git-dir >/dev/null 2>&1 || echo "Warning: $target is not a git repository."

# The project language it had before this run (an unadapted aes.env seed may be replaced below).
prev_lang=$(sed -nE 's/^AES_LANG="?([a-z]+)"?.*/\1/p' "$target/.claude/aes.env" 2>/dev/null | head -n1 || true)

# --- Copy ----------------------------------------------------------------------------------------
copied=0; unchanged=0; new_seeds=(); updated_seeds=(); pending=()
put() { mkdir -p "$(dirname "$2")"; cp "$1" "$2"; }
for p in "${owned[@]}"; do
  src=${p%%|*}; dst="$target/${p#*|}"
  if same "$src" "$dst"; then unchanged=$((unchanged + 1)); else put "$src" "$dst"; copied=$((copied + 1)); fi
done
# docs/aes/seeds.sha256: the checksum of each seed as AES delivered it the last time. That way, on
# upgrade, it only warns if AES's seed changed, not if the project adapted its own.
seedsums="$target/docs/aes/seeds.sha256"; touch "$seedsums"; newsums=""
for p in "${seeds[@]}"; do
  src=${p%%|*}; rel=${p#*|}; dst="$target/$rel"
  sum=$(tr -d '\r' < "$src" | sha256 | cut -c1-64)
  # Checksum of the same seed with CRLF: the one 1.4.0 recorded if AES was downloaded on Windows with autocrlf.
  sum_crlf=$(tr -d '\r' < "$src" | sed 's/$/\r/' | sha256 | cut -c1-64)
  # Checksum of the project's copy: if it matches the seed delivered, the project did not adapt it.
  cur=""; [[ -f "$dst" ]] && cur=$(tr -d '\r' < "$dst" | sha256 | cut -c1-64)
  cur_crlf=""; [[ -f "$dst" ]] && cur_crlf=$(tr -d '\r' < "$dst" | sed 's/$/\r/' | sha256 | cut -c1-64)
  if [[ ! -f "$dst" ]]; then put "$src" "$dst"; new_seeds+=("$rel")
  elif ! same "$src" "$dst" && { grep -qxF "$cur $rel" "$seedsums" || grep -qxF "$cur_crlf $rel" "$seedsums"; }; then
    put "$src" "$dst"; updated_seeds+=("$rel")   # not adapted: updated without asking
  elif ! same "$src" "$dst" && ! grep -qxF "$sum $rel" "$seedsums" && ! grep -qxF "$sum_crlf $rel" "$seedsums"; then
    put "$src" "$dst.aes-new"; pending+=("$rel.aes-new")
  fi
  newsums+="$sum $rel"$'\n'
done
printf '%s' "$newsums" > "$seedsums"
chmod +x "$target"/.claude/hooks/*.sh "$target"/.claude/scripts/*.sh "$target"/ci/*.sh 2>/dev/null || true

# Project language (00 §3): AES_LANG in .claude/aes.env. On install, --lang (or en). On upgrade,
# a project without AES_LANG (installed before 2.0.0) gets --lang or, failing that, its backlog's
# language, so its roles keep writing in the language they always have.
envf="$target/.claude/aes.env"
if [[ -f "$envf" ]]; then
  if [[ -z "$lang" ]]; then
    lang=$prev_lang
    if [[ -z "$lang" ]]; then
      lang=en
      [[ -f "$target/docs/backlog.md" ]] && grep -qiE '^\|.*\b(T[ií]tulo|Estado)\b' "$target/docs/backlog.md" && lang=es
    fi
  fi
  have=$(sed -nE 's/^AES_LANG="?([a-z]+)"?.*/\1/p' "$envf" | head -n1)
  if [[ -z "$have" ]]; then
    printf '\n# Project language (00 §3): the language agents write the project'"'"'s artifacts in. en | es\nAES_LANG="%s"\n' "$lang" >> "$envf"
    echo "  .claude/aes.env: AES_LANG=\"$lang\" added."
  elif [[ "$lang" != "$have" ]]; then
    sed -i.bak -E "s/^AES_LANG=.*/AES_LANG=\"$lang\"/" "$envf" && rm -f "$envf.bak"
    [[ $mode == upgrade ]] && echo "  .claude/aes.env: AES_LANG=\"$lang\" (was $have)."
  fi
fi

# Regression and .gitignore (02 §11, the reference's README).
mkdir -p "$target/specs"
[[ -f "$target/specs/active-stories.txt" ]] || : > "$target/specs/active-stories.txt"
touch "$target/.gitignore"
for line in .aes/ .claude/settings.local.json .claude/worktrees/; do
  grep -qxF "$line" "$target/.gitignore" || printf '%s\n' "$line" >> "$target/.gitignore"
done

# Backlog board up to date after each pull (local git hook; not versioned). Without node, skipped.
if git -C "$target" rev-parse --git-dir >/dev/null 2>&1 && command -v node >/dev/null; then
  (cd "$target" && node .claude/scripts/aes-board.mjs --install-hook >/dev/null 2>&1) \
    || echo "  Warning: could not install the board hook (node .claude/scripts/aes-board.mjs --install-hook)." >&2
fi

# Scripts with LF on any system: bash does not accept CRLF, and Windows with core.autocrlf would add it.
touch "$target/.gitattributes"
for line in '*.sh text eol=lf' '*.mjs text eol=lf'; do
  grep -qxF "$line" "$target/.gitattributes" || printf '%s\n' "$line" >> "$target/.gitattributes"
done

# --- Third-party skills --------------------------------------------------------------------------
lock="$target/docs/aes/skills.lock"
hash_tree() { (cd "$1" && find . -type f ! -path './.git/*' ! -path './node_modules/*' | LC_ALL=C sort | while IFS= read -r f; do sha256 "$f"; done) | sha256 | cut -c1-16; }
for v in "${vendors[@]}"; do
  [[ -f "$v/SKILL.md" ]] || { echo "No SKILL.md in $v: it is not a skill." >&2; exit 1; }
  v=$(cd "$v" && pwd); name=$(basename "$v")
  [[ "$name" == aes-* ]] && { echo "$name: the aes-* names belong to the AES core." >&2; exit 1; }
  ver=$(sed -n '1,/^---$/{s/^version: *"\{0,1\}\([^"]*\)"\{0,1\} *$/\1/p}' "$v/SKILL.md" | head -n1)
  [[ -z "$ver" && -f "$v/package.json" ]] && ver=$(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$v/package.json" | head -n1)
  [[ -z "$ver" ]] && ver=$(git -C "$v" describe --tags --always 2>/dev/null || true)
  [[ -z "$ver" ]] && ver="no-version"
  dst="$target/.claude/skills/$name"
  rm -rf "$dst"; mkdir -p "$dst"
  (cd "$v" && tar --exclude=.git --exclude=node_modules -cf - .) | (cd "$dst" && tar -xf -)
  # License and notices: if the skill's folder does not bring them, they are copied from its repository's root
  # (Apache-2.0, for example, requires keeping LICENSE and NOTICE when redistributing).
  if ! compgen -G "$dst/LICENSE*" >/dev/null; then
    vroot=$(git -C "$v" rev-parse --show-toplevel 2>/dev/null || true)
    if [[ -n "$vroot" ]]; then
      for f in "$vroot"/LICENSE* "$vroot"/NOTICE*; do [[ -f "$f" ]] && cp "$f" "$dst/"; done
    fi
    compgen -G "$dst/LICENSE*" >/dev/null || echo "Warning: $name brings no license; review it before versioning it." >&2
  fi
  # 06 §6.2 adjustments per known skill: no telemetry, no update notices, no hook of its own.
  case "$name" in
    impeccable)
      cfg="$target/.impeccable/config.json"
      if [[ ! -f "$cfg" ]]; then
        mkdir -p "$target/.impeccable"
        printf '%s\n' '{' '  "telemetry": false,' '  "updateCheck": false,' '  "hook": { "enabled": false }' '}' > "$cfg"
        echo "  .impeccable/config.json: telemetry, update notice and hook turned off."
      else
        echo "  Check .impeccable/config.json: telemetry false, updateCheck false, hook.enabled false (06 §6.2)."
      fi
      for line in .impeccable/config.local.json .impeccable/questions/ .impeccable/mocks/ .impeccable/live/; do
        grep -qxF "$line" "$target/.gitignore" || printf '%s\n' "$line" >> "$target/.gitignore"
      done ;;
  esac
  touch "$lock"
  grep -v "^$name " "$lock" > "$lock.tmp" || true; mv "$lock.tmp" "$lock"
  printf '%s %s sha256:%s %s\n' "$name" "$ver" "$(hash_tree "$dst")" "$(date -u +%Y-%m-%d)" >> "$lock"
  echo "Third-party skill: $name $ver → .claude/skills/$name (recorded in docs/aes/skills.lock)"
done
if [[ -f "$lock" ]] && ! head -n1 "$lock" | grep -q '^#'; then
  { echo "# name version checksum date — third-party skills installed with install-aes.sh (06 §6.2)"; cat "$lock"; } > "$lock.tmp" && mv "$lock.tmp" "$lock"
fi

echo "$stamp" > "$target/docs/aes/VERSION"

# --- Summary -------------------------------------------------------------------------------------
echo
echo "$stamp → $target"
echo "  AES files: $copied copied, $unchanged unchanged"
[[ ${#new_seeds[@]} -gt 0 ]] && printf '  new seed (adapt it): %s\n' "${new_seeds[@]}"
[[ ${#updated_seeds[@]} -gt 0 ]] && printf '  seed updated (the project had not adapted it): %s\n' "${updated_seeds[@]}"
[[ ${#pending[@]} -gt 0 ]] && printf '  REVIEW by hand and delete afterwards: %s\n' "${pending[@]}"
if [[ $mode == install && -z "${AES_QUIET_NEXT:-}" ]]; then
  cat <<EOF

Left to do (the reference's README, "Getting started"):
  - Adapt the seeds: CODEOWNERS (@your-user), .claude/aes.env, ci/validate.sh and the
    workflow's STACK section. If there is no stack yet, leave it: EN-001 does it.
  - Initial commit on main, create dev (git push origin main:dev) and make it the default branch.
  - The agents' GitHub App and .claude/settings.local.json.
  - Rulesets, aes:* labels and the repository's AES_* variables.
  - Then: an orchestrator session with the aes-inception skill.
EOF
fi
