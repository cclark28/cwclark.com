#!/bin/bash
# Hourly Google Drive photo sync
# Watches ~/Library/CloudStorage/GoogleDrive-.../My Drive/cwclark-uploads/
# Copies new images into assets/images/uploads/YYYY-MM/
# Logs to content/updates/photos.json

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/cwclark.com")"
PHOTOS_LOG="$REPO_ROOT/content/updates/photos.json"
UPLOAD_DEST="$REPO_ROOT/assets/images/uploads"
SYNC_LOG="$REPO_ROOT/tasks/sync.log"
TODAY=$(date +%Y-%m-%d)
MONTH=$(date +%Y-%m)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")

# ── Find Google Drive sync folder ─────────────────────────────────────────────
GDRIVE_BASE="$HOME/Library/CloudStorage"
GDRIVE_FOLDER=""

if [ -d "$GDRIVE_BASE" ]; then
  # Find the GoogleDrive-* folder (works for any Google account)
  GDRIVE_FOLDER=$(find "$GDRIVE_BASE" -maxdepth 2 -type d -name "cwclark-uploads" 2>/dev/null | head -1)
fi

if [ -z "$GDRIVE_FOLDER" ]; then
  echo "[$TIMESTAMP] Google Drive folder 'cwclark-uploads' not found. Is Google Drive for Desktop installed and synced?" >> "$SYNC_LOG"
  exit 0
fi

# ── Find new image files ───────────────────────────────────────────────────────
DEST_MONTH="$UPLOAD_DEST/$MONTH"
mkdir -p "$DEST_MONTH"

NEW_COUNT=0
NEW_FILES=()

while IFS= read -r -d '' FILE; do
  FILENAME=$(basename "$FILE")
  DEST_FILE="$DEST_MONTH/$FILENAME"

  # Skip if already synced
  if [ -f "$DEST_FILE" ]; then
    continue
  fi

  # Copy the file
  cp "$FILE" "$DEST_FILE"
  NEW_FILES+=("$FILENAME")
  ((NEW_COUNT++))

done < <(find "$GDRIVE_FOLDER" -maxdepth 1 -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
  -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.heic" \
\) -print0)

# ── Nothing new ───────────────────────────────────────────────────────────────
if [ "$NEW_COUNT" -eq 0 ]; then
  echo "[$TIMESTAMP] No new photos." >> "$SYNC_LOG"
  exit 0
fi

# ── Log new files to photos.json ──────────────────────────────────────────────
python3 -c "
import json

new_files = ${NEW_FILES[@]@Q}
" 2>/dev/null

python3 << PYEOF
import json, os

photos_log = '$PHOTOS_LOG'
new_files  = [$(printf '"%s",' "${NEW_FILES[@]}")]
month      = '$MONTH'
timestamp  = '$TIMESTAMP'

try:
    with open(photos_log) as f:
        log = json.load(f)
except:
    log = []

for fname in new_files:
    if not fname:
        continue
    log.insert(0, {
        'filename': fname,
        'path': f'assets/images/uploads/{month}/{fname}',
        'synced': timestamp,
        'month': month
    })

with open(photos_log, 'w') as f:
    json.dump(log, f, indent=2)
PYEOF

# ── Log and notify ─────────────────────────────────────────────────────────────
echo "[$TIMESTAMP] Synced $NEW_COUNT new photo(s) to assets/images/uploads/$MONTH/" >> "$SYNC_LOG"
for f in "${NEW_FILES[@]}"; do
  echo "  + $f" >> "$SYNC_LOG"
done

# macOS notification
osascript -e "display notification \"$NEW_COUNT new photo(s) synced from Google Drive\" with title \"cwclark.com\"" 2>/dev/null

echo ""
echo "  ✓ $NEW_COUNT new photo(s) synced → assets/images/uploads/$MONTH/"
for f in "${NEW_FILES[@]}"; do
  echo "    $f"
done
echo ""
echo "  Run ./_scripts/save.sh to commit and push to cwclark.com"
echo ""
