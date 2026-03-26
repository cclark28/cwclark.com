#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# gdrive-pull.sh
# Pull new assets from Google Drive → local repo, then optimise.
#
# LOCKED to folder: 14AaVS3se9Nakyl4XN-S9oe-HaQDDFRHG
# This script ONLY reads from that specific Drive folder.
# It will NOT access any other Drive location.
#
# Runs hourly via LaunchAgent (com.cwclark.gdrive-pull)
# Also run manually: ./_scripts/gdrive-pull.sh
# ─────────────────────────────────────────────────────────────────

REMOTE_NAME="cwclark-gdrive"
GDRIVE_FOLDER_ID="14AaVS3se9Nakyl4XN-S9oe-HaQDDFRHG"
REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/cwclark.com")"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
LOG="$REPO_ROOT/tasks/sync.log"
MONTH=$(date +%Y-%m)
NEW_COUNT=0

mkdir -p "$REPO_ROOT/tasks"
mkdir -p "$REPO_ROOT/assets/images/uploads/$MONTH"

echo "[$TIMESTAMP] gdrive-pull: starting (folder: $GDRIVE_FOLDER_ID)..." >> "$LOG"

# ── Verify remote is configured ──────────────────────────────────
if ! rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
  echo "[$TIMESTAMP] gdrive-pull: remote not configured. Run gdrive-setup.sh first." >> "$LOG"
  echo "  ✗ Google Drive not configured. Run ./_scripts/gdrive-setup.sh"
  exit 0
fi

# ── Safety check: confirm remote is scoped to the correct folder ─
CONFIGURED_ROOT=$(rclone config show "$REMOTE_NAME" 2>/dev/null | grep root_folder_id | awk '{print $3}')
if [ -n "$CONFIGURED_ROOT" ] && [ "$CONFIGURED_ROOT" != "$GDRIVE_FOLDER_ID" ]; then
  echo "[$TIMESTAMP] gdrive-pull: ERROR — remote root_folder_id '$CONFIGURED_ROOT' != expected '$GDRIVE_FOLDER_ID'" >> "$LOG"
  echo "  ✗ Drive remote is pointing to the wrong folder."
  echo "    Expected: $GDRIVE_FOLDER_ID"
  echo "    Got:      $CONFIGURED_ROOT"
  echo "    Re-run ./_scripts/gdrive-setup.sh to fix."
  exit 1
fi

# Common rclone flags scoped to the locked folder
RCLONE_FLAGS=(
  "--drive-root-folder-id=$GDRIVE_FOLDER_ID"
  "--log-file=$LOG"
  "--log-level=INFO"
)

# ── Pull: uploads → local ─────────────────────────────────────────
echo "  ← Pulling uploads..."
BEFORE=$(find "$REPO_ROOT/assets/images/uploads" -type f ! -name '.opt-manifest' | wc -l | tr -d ' ')

rclone sync "${REMOTE_NAME}:assets/images/uploads" \
  "$REPO_ROOT/assets/images/uploads" \
  "${RCLONE_FLAGS[@]}" 2>/dev/null

AFTER=$(find "$REPO_ROOT/assets/images/uploads" -type f ! -name '.opt-manifest' | wc -l | tr -d ' ')
NEW_COUNT=$((AFTER - BEFORE))

# ── Pull: fonts → local ───────────────────────────────────────────
echo "  ← Pulling fonts..."
rclone sync "${REMOTE_NAME}:assets/fonts" \
  "$REPO_ROOT/assets/fonts" \
  "${RCLONE_FLAGS[@]}" 2>/dev/null

# ── Pull: graphics → local ────────────────────────────────────────
echo "  ← Pulling graphics..."
rclone sync "${REMOTE_NAME}:assets/graphics" \
  "$REPO_ROOT/assets/graphics" \
  "${RCLONE_FLAGS[@]}" 2>/dev/null

# ── Pull: content → local (blog, location overrides, etc.) ───────
echo "  ← Pulling content..."
rclone sync "${REMOTE_NAME}:content" \
  "$REPO_ROOT/content" \
  --exclude "location/**" \
  "${RCLONE_FLAGS[@]}" 2>/dev/null

echo "[$TIMESTAMP] gdrive-pull: pulled +${NEW_COUNT} new files." >> "$LOG"

# ── Optimise images (runs every time; skips already-done files) ───
echo ""
echo "  ▶ Running image optimiser..."
bash "$REPO_ROOT/_scripts/optimize-images.sh"

# ── Auto-commit if anything changed ──────────────────────────────
cd "$REPO_ROOT" || exit 1
if ! git diff --quiet || [ -n "$(git ls-files --others --exclude-standard assets/ content/)" ]; then
  git add assets/ content/ 2>/dev/null
  git commit -m "sync: pull + optimise from Drive [$TIMESTAMP]" 2>/dev/null
  echo "  ✓ Changes committed to git."
fi

echo ""
if [ "$NEW_COUNT" -gt 0 ]; then
  echo "  ✓ Pulled $NEW_COUNT new file(s) from Google Drive"
  osascript -e "display notification \"$NEW_COUNT new file(s) synced and optimised\" with title \"cwclark.com\"" 2>/dev/null
else
  echo "  ✓ No new files from Google Drive"
fi
echo ""
