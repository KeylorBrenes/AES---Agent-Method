#!/usr/bin/env bash
# AES — A lock shared by every worktree of the project (standard/04 §5).
#
# Roles running in parallel each have their own worktree, but the machine has one set of ports: two
# acceptance runs or two manual tests at the same time would collide on them (the second one fails
# with "port taken", a false FAIL). The commands that start the project's servers run inside the
# "servers" lock: the model works in parallel and only those commands wait for their turn.
#
# Usage:
#   aes-lock.sh <name> -- <command> [args…]   waits for the lock, runs the command and releases it
#   aes-lock.sh status [<name>]               who holds it
#
# The lock is a folder in the main checkout's .aes/locks/ (atomic mkdir, portable to Git Bash and
# macOS). A lock whose process no longer exists, or older than AES_LOCK_STALE seconds, is released.
#   AES_LOCK_WAIT    maximum wait in seconds (1800 by default); then it fails with code 75
#   AES_LOCK_STALE   age at which a lock is considered abandoned (3600 by default)
set -uo pipefail

root=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
dir="$root/.aes/locks"

name="${1:-}"; shift || true
if [[ "$name" == status ]]; then
  for d in "$dir"/${1:-*}; do [[ -f "$d/owner" ]] && printf '%s: %s\n' "$(basename "$d")" "$(cat "$d/owner")"; done
  exit 0
fi
[[ -n "$name" && "${1:-}" == -- ]] || { echo "Usage: aes-lock.sh <name> -- <command> [args...]" >&2; exit 2; }
shift
[[ $# -gt 0 ]] || { echo "The command to run after -- is missing" >&2; exit 2; }

# Inside a lock already held by this process tree (with-servers.sh called from a locked run): no wait.
var="AES_LOCK_HELD_${name//[^A-Za-z0-9]/_}"
if [[ "${!var:-}" == 1 ]]; then "$@"; exit $?; fi

lock="$dir/$name"; mkdir -p "$dir"
wait_max=${AES_LOCK_WAIT:-1800}; stale=${AES_LOCK_STALE:-3600}
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')
start=$(date +%s); told=0
while ! mkdir "$lock" 2>/dev/null; do
  pid=$(sed -nE 's/^pid=([0-9]+).*/\1/p' "$lock/owner" 2>/dev/null)
  since=$(sed -nE 's/.* since=([0-9]+).*/\1/p' "$lock/owner" 2>/dev/null)
  now=$(date +%s)
  if { [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; } || { [[ -n "$since" ]] && (( now - since > stale )); }; then
    echo "AES lock: releasing an abandoned '$name' lock ($(cat "$lock/owner" 2>/dev/null))." >&2
    rm -rf "$lock"; continue
  fi
  if (( told == 0 )); then echo "AES lock: waiting for '$name', held by $(cat "$lock/owner" 2>/dev/null || echo '?')…" >&2; told=1; fi
  (( now - start < wait_max )) || { echo "AES lock: '$name' still held after ${wait_max}s." >&2; exit 75; }
  sleep 3
done
printf 'pid=%s branch=%s since=%s\n' "$$" "$branch" "$(date +%s)" > "$lock/owner"
trap 'rm -rf "$lock"' EXIT
trap 'exit 130' INT TERM

export "$var=1"
"$@"
