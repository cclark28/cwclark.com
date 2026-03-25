#!/bin/bash
# Safely roll back to any previous commit

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  cwclark.com — Rollback Tool"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Recent versions:"
echo ""

# Build indexed list of commits
COMMITS=()
i=1
while IFS= read -r line; do
  printf "  [%2d]  %s\n" "$i" "$line"
  COMMITS+=("$line")
  ((i++))
done < <(git log --pretty=format:"%h  %ad  %s" --date=format:"%Y-%m-%d %H:%M")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "  Enter number to select a version (q to quit): " CHOICE

if [[ "$CHOICE" == "q" || -z "$CHOICE" ]]; then
  echo "  Cancelled."
  exit 0
fi

# Get hash and message for chosen entry
LINE="${COMMITS[$((CHOICE-1))]}"
TARGET_HASH=$(echo "$LINE" | awk '{print $1}')
TARGET_MSG=$(echo "$LINE" | cut -d' ' -f4-)

if [ -z "$TARGET_HASH" ]; then
  echo "  Invalid selection."
  exit 1
fi

echo ""
echo "  Selected: [$TARGET_HASH] $TARGET_MSG"
echo ""
echo "  What would you like to do?"
echo "  1) Preview only  (creates a temp branch — files only, nothing changes on master)"
echo "  2) Restore this version  (creates a new commit on master, safe to undo)"
echo "  3) Cancel"
echo ""
read -p "  Choose [1/2/3]: " ACTION

case $ACTION in
  1)
    BRANCH="preview-$TARGET_HASH"
    git checkout -b "$BRANCH" "$TARGET_HASH" -q
    echo ""
    echo "  ✓ Now on branch: $BRANCH"
    echo "  Browse the files freely. When done:"
    echo "    git checkout master          — return to current site"
    echo "    git branch -D $BRANCH   — delete preview branch"
    ;;
  2)
    echo ""
    read -p "  Restore site to [$TARGET_HASH]? This is safe — creates a new commit. [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      git checkout master -q
      git checkout "$TARGET_HASH" -- .
      git add -A
      git commit -m "Restore to [$TARGET_HASH]: $TARGET_MSG" --no-verify -q
      FINAL=$(git log -1 --format="%h")
      echo ""
      echo "  ✓ Restored. New commit: [$FINAL]"
      read -p "  Push to GitHub now? [Y/n]: " PUSH
      if [[ ! "$PUSH" =~ ^[Nn]$ ]]; then
        TOKEN=$(gh auth token 2>/dev/null)
        if [ -n "$TOKEN" ]; then
          git push "https://cclark28:${TOKEN}@github.com/cclark28/cwclark.com.git" master
          echo "  ✓ Live on GitHub."
        else
          git push
        fi
      fi
    else
      echo "  Cancelled."
    fi
    ;;
  3)
    echo "  Cancelled."
    ;;
  *)
    echo "  Invalid option."
    ;;
esac
echo ""
