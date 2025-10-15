#!/usr/bin/env bash
set -euo pipefail

# Make sure we're at the repo root
cd "$(git rev-parse --show-toplevel)"

# Quick sanity: show branch
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "NO_BRANCH")"

# Stage and commit whatever changed; exit quietly if nothing to commit
git add -A
git commit -m "auto: save on file change" >/dev/null 2>&1 || exit 0

# Ensure upstream is set once (idempotent)
git branch --set-upstream-to=origin/${BRANCH} ${BRANCH} >/dev/null 2>&1 || true

# Stay current, then push our new commit
git pull --rebase --autostash origin "${BRANCH}" || true
git push origin HEAD:"${BRANCH}" || true
