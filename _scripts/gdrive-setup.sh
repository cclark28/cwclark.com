#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# gdrive-setup.sh
# One-time setup: authenticate rclone with Google Drive and create
# the cwclark.com folder structure inside the shared Drive folder.
#
# Run once: ./_scripts/gdrive-setup.sh
# ─────────────────────────────────────────────────────────────────

REMOTE_NAME="cwclark-gdrive"
GDRIVE_ROOT_ID="14AaVS3se9Nakyl4XN-S9oe-HaQDDFRHG"

echo ""
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║  cwclark.com · Google Drive Setup                   ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo ""

# ── Check rclone ──────────────────────────────────────────────────
if ! command -v rclone &>/dev/null; then
  echo "  ✗ rclone not found. Install with: brew install rclone"
  exit 1
fi

# ── Check if remote already configured ───────────────────────────
if rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
  echo "  ✓ Remote '${REMOTE_NAME}' already configured."
else
  echo "  Setting up Google Drive remote '${REMOTE_NAME}'..."
  echo "  A browser window will open for Google OAuth."
  echo ""
  rclone config create "${REMOTE_NAME}" drive \
    scope drive \
    root_folder_id "${GDRIVE_ROOT_ID}"
  echo ""
  echo "  ✓ Remote configured."
fi

# ── Create folder structure in Google Drive ───────────────────────
echo ""
echo "  Creating folder structure in Google Drive..."
echo ""

FOLDERS=(
  "assets"
  "assets/images"
  "assets/images/uploads"
  "assets/fonts"
  "assets/graphics"
  "content"
  "content/blog"
  "content/updates"
  "content/location"
  "backups"
  "reports"
  "reports/seo"
  "reports/lighthouse"
)

for folder in "${FOLDERS[@]}"; do
  rclone mkdir "${REMOTE_NAME}:${folder}" 2>/dev/null
  echo "    + ${folder}"
done

echo ""
echo "  ✓ Folder structure created in Google Drive."
echo ""
echo "  ┌─────────────────────────────────────────────────────┐"
echo "  │  Drive folder: bit.ly/cwclark-drive                 │"
echo "  │  Remote name:  ${REMOTE_NAME}                       │"
echo "  │  Root ID:      ${GDRIVE_ROOT_ID}                    │"
echo "  └─────────────────────────────────────────────────────┘"
echo ""
echo "  Next steps:"
echo "    Run ./_scripts/gdrive-push.sh   to push assets → Drive"
echo "    Run ./_scripts/gdrive-pull.sh   to pull assets ← Drive"
echo ""
