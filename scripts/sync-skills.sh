#!/usr/bin/env bash
# Copies the core skills (skills/) into the Claude Code reference implementation.
# Usage: ./scripts/sync-skills.sh          (copies)
#        ./scripts/sync-skills.sh --check  (fails if the copies differ)
set -euo pipefail
cd "$(dirname "$0")/.."
dest=profiles/reference/claude-code-subagents/.claude/skills
status=0
for dir in skills/*/; do
  name=$(basename "$dir")
  if [[ "${1:-}" == "--check" ]]; then
    if ! diff -rq "$dir" "$dest/$name" >/dev/null 2>&1; then
      echo "The copy of $name in $dest is out of date. Run ./scripts/sync-skills.sh" >&2
      status=1
    fi
  else
    rm -rf "${dest:?}/$name"; cp -r "$dir" "$dest/$name"
  fi
done
[[ "${1:-}" == "--check" && $status -eq 0 ]] && echo "Skills in sync."
exit $status
