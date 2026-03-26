#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# gdrive-push.sh
# Push local assets, content, and site backup → Google Drive
# Schedule: runs after every save.sh commit, or on demand
# ─────────────────────────────────────────────────────────────────

REMOTE_NAME="cwclark-gdrive"
REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/cwclark.com")"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
LOG="$REPO_ROOT/tasks/sync.log"

mkdir -p "$REPO_ROOT/tasks"

echo "[$TIMESTAMP] gdrive-push: starting..." >> "$LOG"

# ── Verify remote ────────────────────────────────────────────────
if ! rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
  echo "[$TIMESTAMP] gdrive-push: remote '${REMOTE_NAME}' not found. Run gdrive-setup.sh first." >> "$LOG"
  echo "  ✗ Google Drive not configured. Run ./_scripts/gdrive-setup.sh"
  exit 1
fi

# ── Push: assets/images/uploads → Drive ──────────────────────────
echo "  → Pushing uploads..."
rclone sync "$REPO_ROOT/assets/images/uploads" \
  "${REMOTE_NAME}:assets/images/uploads" \
  --progress \
  --log-file="$LOG" \
  --log-level INFO \
  2>/dev/null

# ── Push: assets/fonts → Drive ───────────────────────────────────
echo "  → Pushing fonts..."
rclone sync "$REPO_ROOT/assets/fonts" \
  "${REMOTE_NAME}:assets/fonts" \
  --log-file="$LOG" --log-level INFO 2>/dev/null

# ── Push: assets/graphics → Drive ────────────────────────────────
echo "  → Pushing graphics..."
rclone sync "$REPO_ROOT/assets/graphics" \
  "${REMOTE_NAME}:assets/graphics" \
  --log-file="$LOG" --log-level INFO 2>/dev/null

# ── Push: content → Drive ────────────────────────────────────────
echo "  → Pushing content..."
rclone sync "$REPO_ROOT/content" \
  "${REMOTE_NAME}:content" \
  --log-file="$LOG" --log-level INFO 2>/dev/null

# ── Push: site backup (zip) → Drive ──────────────────────────────
echo "  → Creating site backup..."
BACKUP_DATE=$(date "+%Y-%m-%d")
BACKUP_FILE="/tmp/cwclark-backup-${BACKUP_DATE}.zip"

zip -r "$BACKUP_FILE" "$REPO_ROOT" \
  --exclude "$REPO_ROOT/.git/*" \
  --exclude "$REPO_ROOT/tasks/sync.log" \
  --exclude "$REPO_ROOT/node_modules/*" \
  -q

rclone copyto "$BACKUP_FILE" \
  "${REMOTE_NAME}:backups/cwclark-backup-${BACKUP_DATE}.zip" \
  --log-file="$LOG" --log-level INFO 2>/dev/null

rm -f "$BACKUP_FILE"
echo "  → Backup uploaded: cwclark-backup-${BACKUP_DATE}.zip"

echo "[$TIMESTAMP] gdrive-push: complete." >> "$LOG"
echo ""
echo "  ✓ Pushed to Google Drive:"
echo "    assets/images/uploads"
echo "    assets/fonts"
echo "    assets/graphics"
echo "    content/"
echo "    backups/cwclark-backup-${BACKUP_DATE}.zip"
echo ""
