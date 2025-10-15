# overwrite the script with a clean copy
cat > ~/Documents/Quiet_Purgatory_Project/safe_sync.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Find the repo root (prefer git; fall back to Documents path)
REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/Documents/Quiet_Purgatory_Project")"
cd "$REPO_DIR" || { echo "Repo not found at: $REPO_DIR"; exit 1; }

# Basic facts
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
REMOTE_URL="$(git remote get-url origin 2>/dev/null || echo "")"
TRACK_REF="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")"

# Logging
LOG_DIR="$REPO_DIR/.repo_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/sync_$(date +%F_%H%M%S).log"

echo "📁 Repo: $REPO_DIR" | tee -a "$LOG_FILE"
echo "🔀 Branch: $BRANCH  |  Remote: ${REMOTE_URL:-<none>}  |  Track: ${TRACK_REF:-<none>}" | tee -a "$LOG_FILE"

# Rescue branch (so you can always roll back)
RESCUE="rescue/pre-sync-$(date +%F_%H%M%S)"
git branch -f "$RESCUE" >/dev/null 2>&1 || true
echo "🛟 Rescue branch: $RESCUE" | tee -a "$LOG_FILE"

# Save unstaged work if any
if ! git diff --quiet || ! git diff --cached --quiet; then
  git add -A
  git commit -m "auto: save work $(date -u +%F_%T)Z" | tee -a "$LOG_FILE"
fi

# Update from remote safely
git fetch --all --prune | tee -a "$LOG_FILE"
git pull --rebase --autostash origin "$BRANCH" | tee -a "$LOG_FILE"

# Stage & commit any changes (new files, etc.)
git add -A
if ! git diff --cached --quiet; then
  git commit -m "auto: sync $(date -u +%F_%T)Z" | tee -a "$LOG_FILE"
fi

# Push
git push -u origin "$BRANCH" | tee -a "$LOG_FILE"

echo "✅ Done. Log → $LOG_FILE"
SH

# make it executable and normalize line endings
chmod +x ~/Documents/Quiet_Purgatory_Project/safe_sync.sh
LC_ALL=C sed -i '' $'s/\r$//' ~/Documents/Quiet_Purgatory_Project/safe_sync.sh 2>/dev/null || true