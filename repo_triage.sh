#!/usr/bin/env bash
set -euo pipefail

OUT="forensics/triage_report_$(date +%F_%H%M).txt"
mkdir -p forensics

echo "== Quiet Purgatory – Triage Report ==" | tee "$OUT"
echo "Timestamp: $(date)" | tee -a "$OUT"
echo "PWD: $(pwd)" | tee -a "$OUT"

echo -e "\n--- GIT BASICS ---" | tee -a "$OUT"
git rev-parse --is-inside-work-tree 2>&1 | tee -a "$OUT"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)" | tee -a "$OUT"
git status -s | tee -a "$OUT" || true

echo -e "\n--- FETCH REMOTE & SHOW DIVERGENCE ---" | tee -a "$OUT"
git fetch --all --prune 2>&1 | tee -a "$OUT" || true
echo -e "\nCommits you have not pushed (HEAD but not on origin/main):" | tee -a "$OUT"
git log --oneline origin/main..HEAD 2>/dev/null | tee -a "$OUT" || true
echo -e "\nCommits remote has that you don't (origin/main but not HEAD):" | tee -a "$OUT"
git log --oneline HEAD..origin/main 2>/dev/null | tee -a "$OUT" || true

echo -e "\n--- RECENT COMMITS (last 72h, with changed files) ---" | tee -a "$OUT"
git log --since='72 hours ago' --name-status --pretty=format:'%C(yellow)%h%Creset %C(bold)%s%Creset  %Cgreen(%cr)%Creset' | tee -a "$OUT" || true

echo -e "\n--- REFLOG (last 50) ---" | tee -a "$OUT"
git reflog -n 50 2>/dev/null | tee -a "$OUT" || true

echo -e "\n--- STASH LIST ---" | tee -a "$OUT"
git stash list 2>/dev/null | tee -a "$OUT" || true

echo -e "\n--- MODIFIED/UNTRACKED FILES ---" | tee -a "$OUT"
echo "Modified:" | tee -a "$OUT"; git ls-files -m | tee -a "$OUT" || true
echo "Untracked:" | tee -a "$OUT"; git ls-files --others --exclude-standard | tee -a "$OUT" || true

echo -e "\n--- FILES MOST RECENTLY TOUCHED (last 48h) ---" | tee -a "$OUT"
# Show file mtimes, most recent first
find . -type f -not -path './.git/*' -mtime -2 -print0 | xargs -0 stat -f "%m %N" 2>/dev/null | sort -rn | head -n 50 | awk '{ $1=""; sub(/^ /,""); print }' | tee -a "$OUT" || true

echo -e "\n--- GREP FOR LIKELY PHRASES (voice rant anchors) ---" | tee -a "$OUT"
PHRASES=(
  "voice rant" "last voice" "Even the devil may cry" "devil rejected me" "Lucifer rejected me"
  "death of a thousand cuts" "Quiet Purgatory" "107 days" "separation agreement"
  "nirvana in hell" "lubarna in hell" "True Colors" "suicide ward"
)
for p in "${PHRASES[@]}"; do
  echo -e "\n>>> Searching for: $p" | tee -a "$OUT"
  rg -n --hidden --glob '!.git' "$p" 2>/dev/null | tee -a "$OUT" || true
done

echo -e "\n--- AUDIO HUNT (common formats) ---" | tee -a "$OUT"
find . \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.wav' -o -iname '*.aac' \) -print0 | xargs -0 ls -lhtr 2>/dev/null | tee -a "$OUT" || true

echo -e "\n--- GIT ORPHANS (only helps if it was ever committed) ---" | tee -a "$OUT"
git fsck --lost-found 2>&1 | tee -a "$OUT" || true

echo -e "\n--- VS CODE BACKUPS (unsaved/dirty editors) ---" | tee -a "$OUT"
BACKUP_DIR="${HOME}/Library/Application Support/Code/Backups"
if [ -d "$BACKUP_DIR" ]; then
  echo "Backups directory: $BACKUP_DIR" | tee -a "$OUT"
  # Try to find anchor phrases inside VS Code backups
  for p in "${PHRASES[@]}"; do
    echo -e "\n>>> Searching VS Code Backups for: $p" | tee -a "$OUT"
    rg -n "$p" "$BACKUP_DIR" 2>/dev/null | tee -a "$OUT" || true
  done
else
  echo "VS Code Backups directory not found." | tee -a "$OUT"
fi

echo -e "\n--- TIMELINE TIP (manual) ---" | tee -a "$OUT"
echo "In VS Code: right-click the file > Open Timeline (checks local history even if not committed)." | tee -a "$OUT"

echo -e "\nDone. Report written to: $OUT" | tee -a "$OUT"
