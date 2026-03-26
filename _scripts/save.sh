#!/bin/bash
# Usage: ./_scripts/save.sh "What you changed"
# Commits all changes, updates CHANGELOG, and optionally pushes.

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if [ -z "$1" ]; then
  echo ""
  read -p "  Describe this change: " MSG
else
  MSG="$1"
fi

if [ -z "$MSG" ]; then
  echo "  Cancelled — no message provided."
  exit 1
fi

# Stage everything
git add -A

# Commit
git commit -m "$MSG"

# Get info from the new commit
HASH=$(git log -1 --format="%h")
DATE=$(git log -1 --format="%Y-%m-%d")
STATS=$(git diff-tree --no-commit-id -r --stat HEAD | tail -1 | xargs)

CHANGELOG="CHANGELOG.md"

# Create header if needed
if [ ! -f "$CHANGELOG" ] || ! grep -q "^# Changelog" "$CHANGELOG"; then
  printf "# Changelog — cwclark.com\n\n" > "$CHANGELOG"
fi

# Prepend new entry after header line
TEMP=$(mktemp)
head -2 "$CHANGELOG" > "$TEMP"
printf "## [%s] — %s\n**%s**\n%s\n\n" "$HASH" "$DATE" "$MSG" "$STATS" >> "$TEMP"
tail -n +3 "$CHANGELOG" >> "$TEMP"
mv "$TEMP" "$CHANGELOG"

# Amend commit to include changelog (no-verify prevents any hooks re-running)
git add "$CHANGELOG"
git commit --amend --no-edit --no-verify -q

FINAL_HASH=$(git log -1 --format="%h")
echo ""
echo "  ✓ Saved: [$FINAL_HASH] $MSG"
echo ""

# Push prompt
read -p "  Push to GitHub now? [Y/n]: " PUSH
if [[ "$PUSH" =~ ^[Nn]$ ]]; then
  echo "  Not pushed. Run 'git push' when ready."
else
  TOKEN=$(gh auth token 2>/dev/null)
  if [ -n "$TOKEN" ]; then
    git push "https://cclark28:${TOKEN}@github.com/cclark28/cwclark.com.git" master
    echo "  ✓ Live on GitHub."
  else
    git push
  fi
fi

# Push to Google Drive (silent, runs in background)
SCRIPT_DIR="$(dirname "$0")"
if rclone listremotes 2>/dev/null | grep -q "^cwclark-gdrive:"; then
  echo "  → Syncing to Google Drive..."
  bash "$SCRIPT_DIR/gdrive-push.sh" > /dev/null 2>&1 &
  echo "  ✓ Google Drive sync started (background)"
fi
echo ""
