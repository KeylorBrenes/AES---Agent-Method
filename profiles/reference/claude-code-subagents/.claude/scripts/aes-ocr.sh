#!/usr/bin/env bash
# shellcheck disable=SC2016  # the single-quoted strings are JavaScript and Markdown, not shell
# AES — Open Code Review (OCR) at a fixed version, in delegation mode (standard/05 §7.1).
#
# OCR does the deterministic part of a code review: which files of the diff are reviewed (and why
# the others are not) and which checklist applies to each one (its language rules plus the
# project's, in .opencodereview/rule.json). In delegation mode it calls no model and opens no
# network connection: the role that calls it does the review with its own model.
#
# Usage:
#   aes-ocr.sh rules <scope-file>   the checklist for the files of a task's surface (programmer,
#                                   before writing code). Globs with no file yet use a sample path
#                                   with their extension, so a new file still gets its language's rules
#   aes-ocr.sh plan [<base>]        the review plan of the diff <base>...HEAD (verifier): reviewable
#                                   files, the checklist of each group, the test files OCR leaves out
#                                   (the verifier reviews them with its own checklist) and the rest of
#                                   the excluded files with their reason. <base>: aes-base.sh
#   aes-ocr.sh install              installs the fixed version in the main checkout's .aes/tools/
#   aes-ocr.sh version              the installed version
#   aes-ocr.sh -- <ocr args…>       any other ocr command, with the same environment
#
# Configuration (.claude/aes.env): AES_OCR (1 = on, 0 = off) and AES_OCR_VERSION.
# Always with OCR_NO_UPDATE=1 (the npm launcher updates itself by default, 06 §6.2) and without
# OpenTelemetry variables (OCR's telemetry is off unless an endpoint is set).
set -euo pipefail

main_root() { dirname "$(git rev-parse --path-format=absolute --git-common-dir)"; }
root=$(main_root)
# shellcheck disable=SC1091
[[ -f "$root/.claude/aes.env" ]] && source "$root/.claude/aes.env"
: "${AES_OCR:=1}"
: "${AES_OCR_VERSION:=1.14.4}"
pkg="@alibaba-group/open-code-review"
tools="$root/.aes/tools/ocr-$AES_OCR_VERSION"
launcher="$tools/node_modules/$pkg/bin/ocr.js"

export OCR_NO_UPDATE=1
unset OTEL_EXPORTER_OTLP_ENDPOINT OTEL_EXPORTER_OTLP_TRACES_ENDPOINT OTEL_EXPORTER_OTLP_METRICS_ENDPOINT || true

install() {
  [[ -f "$launcher" ]] && return 0
  command -v npm >/dev/null || { echo "AES ocr: npm is missing from the PATH." >&2; return 1; }
  mkdir -p "$tools"
  echo "AES ocr: installing $pkg@$AES_OCR_VERSION in $tools (once)…" >&2
  npm install --prefix "$tools" --no-fund --no-audit --loglevel=error "$pkg@$AES_OCR_VERSION" >&2
  [[ -f "$launcher" ]] || { echo "AES ocr: the installation left no launcher in $launcher." >&2; return 1; }
}
ocr() { install && node "$launcher" "$@"; }

off() {
  echo "AES ocr: off in this project (AES_OCR=0). Review with your contract's checklist only." >&2
  exit 0
}

cmd="${1:-}"; shift || true
case "$cmd" in
  install) install; echo "$launcher" ;;
  version) ocr version | head -n1 ;;
  --) ocr "$@" ;;
  rules)
    [[ "$AES_OCR" == 1 ]] || off
    scope="${1:?Usage: aes-ocr.sh rules <scope-file>}"
    [[ -f "$scope" ]] || { echo "AES ocr: $scope does not exist." >&2; exit 2; }
    # Each scope line: a literal path, the tracked files its glob matches or, for a glob with no file
    # yet, a sample path with its extension (OCR resolves rules by path, so it still gets them).
    mapfile -t resolved < <(git ls-files --cached --others --exclude-standard | node -e '
      const fs = require("fs");
      const files = fs.readFileSync(0, "utf8").split("\n").filter(Boolean);
      const lines = fs.readFileSync(process.argv[1], "utf8").split(/\r?\n/).map(l => l.replace(/#.*/, "").trim()).filter(Boolean);
      const toRe = g => new RegExp("^" + g.replace(/[.+^${}()|\\]/g, "\\$&").replace(/\*\*\//g, "\u0001").replace(/\*\*/g, "\u0002")
        .replace(/\*/g, "[^/]*").replace(/\?/g, "[^/]").replace(/\u0001/g, "(.*/)?").replace(/\u0002/g, ".*") + "$");
      for (const l of lines) {
        if (!/[*?[]/.test(l)) { console.log("P " + l); continue; }
        const re = toRe(l), hits = files.filter(f => re.test(f));
        if (hits.length) { hits.forEach(f => console.log("P " + f)); continue; }
        const ext = (l.match(/\*\.([A-Za-z0-9]+)$/) || [])[1];
        const dir = l.replace(/\/?[^/]*[*?[].*$/, "");
        console.log(ext ? "P " + (dir ? dir + "/" : "") + "new." + ext : "M " + l);
      }
    ' "$scope")
    paths=(); missing=()
    for r in "${resolved[@]}"; do
      case "$r" in "P "*) paths+=("${r#P }") ;; "M "*) missing+=("${r#M }") ;; esac
    done
    (( ${#paths[@]} > 0 )) || { echo "AES ocr: no files in $scope to resolve rules for." >&2; exit 0; }
    printf '# Review checklist for the surface of %s (OCR %s, delegation mode)\n\n' "$scope" "$AES_OCR_VERSION"
    printf 'Write the code so it meets these rules: the verifier reviews your diff with the same ones.\n\n'
    ocr delegate rule "${paths[@]}"
    if (( ${#missing[@]} > 0 )); then
      printf '\n# Without rules (no file yet and no extension in the glob)\n'
      printf -- '- `%s`\n' "${missing[@]}"
    fi
    ;;
  plan)
    [[ "$AES_OCR" == 1 ]] || off
    base="${1:-$(bash "$(dirname "$0")/aes-base.sh")}"
    tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
    ocr delegate preview --from "$base" --to HEAD --format json > "$tmp"
    mapfile -t reviewable < <(node -e '
      const j = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
      for (const f of j.reviewable_files || []) if (f.status !== "deleted") console.log(f.path);
    ' "$tmp")
    node -e '
      const j = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
      const ex = j.excluded_files || [];
      const tests = ex.filter(f => f.exclude_reason === "default_path" && /(^|\/)(tests?|__tests__|spec)\/|[._-](test|tests|spec)\.|_test\.|test_/i.test(f.path));
      const other = ex.filter(f => !tests.includes(f));
      console.log(`# Review plan: ${j.from}...${j.to} (merge base ${String(j.merge_base).slice(0, 12)})\n`);
      console.log(`Files in the diff: ${j.total_files}. OCR reviewable: ${j.reviewable_count}. Test files: ${tests.length}. Other excluded: ${other.length}.\n`);
      console.log("## 1. Review each one with its checklist (section 3) and record it as reviewed or skipped with a reason");
      for (const f of j.reviewable_files || []) console.log(`- [ ] \`${f.path}\` [${f.status}] +${f.insertions}/-${f.deletions}`);
      console.log("\n## 2. Test files: OCR leaves them out; review them with your checklist (weakened, disabled or tautological tests)");
      for (const f of tests) console.log(`- [ ] \`${f.path}\` [${f.status}] +${f.insertions}/-${f.deletions}`);
      if (!tests.length) console.log("- (none)");
      console.log("\n## Excluded, with the reason (not reviewed as code)");
      for (const f of other) console.log(`- \`${f.path}\`: ${f.exclude_reason}`);
      if (!other.length) console.log("- (none)");
      console.log("\nReport coverage as: total, reviewed, skipped (each with its reason) and the rate, over sections 1 and 2.\n");
      console.log("## 3. Checklist per group of files");
    ' "$tmp"
    if (( ${#reviewable[@]} > 0 )); then ocr delegate rule --from "$base" --to HEAD "${reviewable[@]}"; else echo "(no reviewable files)"; fi
    ;;
  *) sed -n '2,24p' "$0" >&2; exit 2 ;;
esac
