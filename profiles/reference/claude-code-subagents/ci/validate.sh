#!/usr/bin/env bash
# AES — The project's validations the programmer and the mechanic must pass before finishing
# (run by .claude/hooks/subagent-gate.sh). Stack-specific: a .NET + React example.
# Keep here the same commands as the workflow's STACK section.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if compgen -G "*.slnx" >/dev/null || compgen -G "*.sln" >/dev/null; then
  dotnet build -warnaserror -nologo -v q
  dotnet test --no-build -nologo -v q
fi

if [[ -f web/package.json ]]; then
  npm --prefix web run lint --silent
  npm --prefix web test --silent
  npm --prefix web run build --silent
fi
