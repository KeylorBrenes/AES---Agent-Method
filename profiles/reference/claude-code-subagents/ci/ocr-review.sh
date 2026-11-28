#!/usr/bin/env bash
# AES — Second review of a task in CI with Open Code Review in native mode (standard/05 §7.1), layer L3.
#
# OCR reviews the task's diff with a model of its own (ideally from a family other than the
# programmer's and the verifier's), with the story and the task as context. It annotates the PR,
# keeps one comment with the summary up to date and fails only on a new critical finding, unless the
# human dismissed it with the aes:review-dismissed label. Everything else is classified by the
# orchestrator with 02 §9.3.
#
# Without a token it is skipped with a warning (a skipped step is not a control, 05 §7: the verifier's
# review in delegation mode still runs). A failure of the model or the provider is a warning too.
#
# Variables:
#   AES_BASE            protected ref (origin/dev)
#   ITEM, TASK          the task (specs/<ITEM>/<TASK>.md, read from the base, is the context)
#   OCR_LLM_URL, OCR_LLM_MODEL, OCR_LLM_TOKEN, OCR_LLM_PROTOCOL (openai | anthropic | openai-responses)
#   AES_OCR_EFFORT      low | medium | high (medium by default)
#   AES_OCR_VERSION     fixed version (by default, the one in the base's .claude/aes.env, or 1.14.4)
#   DISMISSED           1 if aes:review-dismissed is valid (label-approver.sh)
#   GH_TOKEN, REPO, PR  to keep the comment on the PR (optional)
set -uo pipefail

: "${AES_BASE:?AES_BASE is missing}"
if [[ -z "${OCR_LLM_TOKEN:-}" || -z "${OCR_LLM_MODEL:-}" ]]; then
  echo "::warning::Second review (OCR) skipped: there is no AES_OCR_TOKEN secret or AES_OCR_MODEL variable. Only the verifier reviews the diff."
  exit 0
fi

ver=${AES_OCR_VERSION:-$(git show "$AES_BASE:.claude/aes.env" 2>/dev/null | sed -nE 's/^AES_OCR_VERSION="?([0-9.]+)"?.*/\1/p' | head -n1)}
ver=${ver:-1.14.4}
work="${RUNNER_TEMP:-/tmp}/aes-ocr"; mkdir -p "$work"
export OCR_NO_UPDATE=1 OCR_LLM_PROTOCOL="${OCR_LLM_PROTOCOL:-openai}"
unset OTEL_EXPORTER_OTLP_ENDPOINT || true
npm install --prefix "$work/tool" --no-fund --no-audit --loglevel=error "@alibaba-group/open-code-review@$ver" >/dev/null \
  || { echo "::warning::Second review (OCR) skipped: @alibaba-group/open-code-review@$ver could not be installed."; exit 0; }
ocr=(node "$work/tool/node_modules/@alibaba-group/open-code-review/bin/ocr.js")

# Context: the story and the task's design note, as they are on the protected branch.
# OCR accepts up to 8000 characters of context: the task first (goal, out of scope, design note), then the
# story, cut at the limit.
bg="$work/background.md"; : > "$bg"
for f in "specs/$ITEM/$TASK.md" "specs/$ITEM/$ITEM.md"; do
  git show "$AES_BASE:$f" >> "$bg" 2>/dev/null && printf '\n\n' >> "$bg"
done
node -e '
  const fs = require("fs"), p = process.argv[1], max = 7800;
  const t = [...fs.readFileSync(p, "utf8")];
  if (t.length > max) fs.writeFileSync(p, t.slice(0, max).join("") + "\n\n[context cut at the limit]\n");
' "$bg"
bgargs=(); [[ -s "$bg" ]] && bgargs=(--background-file "$bg")

base=$(git merge-base "$AES_BASE" HEAD)
rc=0
"${ocr[@]}" review --from "$base" --to HEAD --format json --audience agent \
  --effort "${AES_OCR_EFFORT:-medium}" "${bgargs[@]}" --output "$work/review.json" || rc=$?
if [[ ! -s "$work/review.json" ]]; then
  echo "::warning::Second review (OCR) did not run (code $rc): check the provider, the model and the token. Only the verifier reviews the diff."
  exit 0
fi
status=$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).status || "")' "$work/review.json" 2>/dev/null)
if [[ "$status" == failed ]]; then
  echo "::warning::Second review (OCR) failed (code $rc): no file could be reviewed. Check the provider, the model and the token. Only the verifier reviews the diff."
  exit 0
fi
(( rc == 0 )) || echo "::warning::Second review (OCR) ended with code $rc (status $status): part of the diff may not have been reviewed."

dir=$(dirname "$0")
out=$(node "$dir/ocr-report.mjs" "$work/review.json" "$work/summary.md") || { echo "::warning::The OCR result could not be read."; exit 0; }
printf '%s\n' "$out"
[[ -n "${GITHUB_STEP_SUMMARY:-}" ]] && cat "$work/summary.md" >> "$GITHUB_STEP_SUMMARY"

# One comment per PR, updated on every run.
if [[ -n "${GH_TOKEN:-}" && -n "${REPO:-}" && -n "${PR:-}" ]]; then
  id=$(gh api "repos/$REPO/issues/$PR/comments" --paginate --jq '.[] | select(.body | startswith("<!-- aes-ocr-review -->")) | .id' 2>/dev/null | tail -n1)
  if [[ -n "$id" ]]; then gh api -X PATCH "repos/$REPO/issues/comments/$id" -F "body=@$work/summary.md" --silent || true
  else gh api "repos/$REPO/issues/$PR/comments" -F "body=@$work/summary.md" --silent || true; fi
fi

critical=$(sed -nE 's/^critical=([0-9]+).*/\1/p' <<< "$out" | tail -n1)
if (( ${critical:-0} > 0 )); then
  if [[ "${DISMISSED:-0}" == 1 ]]; then
    echo "::warning::$critical critical finding(s) dismissed by the human (aes:review-dismissed)."
  else
    echo "::error::Second review: $critical new critical finding(s). Fix them (a FAIL cycle) or, if it is a false positive, the human dismisses it with aes:review-dismissed (AES 05 §7.1)."
    exit 1
  fi
fi
exit 0
