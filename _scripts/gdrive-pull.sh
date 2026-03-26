#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# gdrive-pull.sh
# Pull new assets from Google Drive → local repo
# Runs hourly via LaunchAgent (replaces the old sync-photos.sh)
# Also pulls content updates (blog posts, location overrides, etc.)
# ─────────────────────────────────────────────────────────────────

REMOTE_NAME="cwclark-gdrive"
REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/cwclark.com")"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
LOG="$REPO_ROOT/tasks/sync.log"
MONTH=$(date +%Y-%m)
NEW_COUNT=0

mkdir -p "$REPO_ROOT/tasks"
mkdir -p "$REPO_ROOT/assets/images/uploads/$MONTH"

echo "[$TIMESTAMP] gdrive-pull: starting..." >> "$LOG"

# ── Verify remote ────────────────────────────────────────────────
if ! rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
  echo "[$TIMESTAMP] gdrive-pull: remote not configured." >> "$LOG"
  exit 0
fi

# ── Pull: Drive/assets/images/uploads → local ────────────────────
echo "  ← Pulling uploads..."
BEFORE=$(find "$REPO_ROOT/assets/images/uploads" -type f | wc -l | tr -d ' ')

rclone sync "${REMOTE_NAME}:assets/images/uploads" \
  "$REPO_ROOT/assets/images/uploads" \
  --log-file="$LOG" --log-level INFO 2>/dev/null

AFTER=$(find "$REPO_ROOT/assets/images/uploads" -type f | wc -l | tr -d ' ')
NEW_COUNT=$((AFTER - BEFORE))

# ── Pull: Drive/assets/fonts → local ─────────────────────────────
echo "  ← Pulling fonts..."
rclone sync "${REMOTE_NAME}:assets/fonts" \
  "$REPO_ROOT/assets/fonts" \
  --log-file="$LOG" --log-level INFO 2>/dev/null

# ── Pull: Drive/assets/graphics → local ──────────────────────────
echo "  ← Pulling graphics..."
rclone sync "${REMOTE_NAME}:assets/graphics" \
  "$REPO_ROOT/assets/graphics" \
  --log-file="$LOG" --log-level INFO 2>/dev/null

# ── Pull: Drive/content → local (blog posts, overrides, etc.) ────
echo "  ← Pulling content..."
rclone sync "${REMOTE_NAME}:content" \
  "$REPO_ROOT/content" \
  --exclude "location/**" \
  --log-file="$LOG" --log-level INFO 2>/dev/null

echo "[$TIMESTAMP] gdrive-pull: complete. +${NEW_COUNT} new files." >> "$LOG"

# ── Auto-commit if anything changed ──────────────────────────────
cd "$REPO_ROOT" || exit 1
if ! git diff --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  git add assets/ content/ 2>/dev/null
  git commit -m "sync: pull from Google Drive [$TIMESTAMP]" 2>/dev/null
  echo "  ✓ Changes committed to git."
fi

echo ""
if [ "$NEW_COUNT" -gt 0 ]; then
  echo "  ✓ Pulled $NEW_COUNT new file(s) from Google Drive"
  osascript -e "display notification \"$NEW_COUNT new file(s) synced from Google Drive\" with title \"cwclark.com\"" 2>/dev/null
else
  echo "  ✓ No new files from Google Drive"
fi
echo ""
