#!/bin/bash
# Shows a visual log of all site versions

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  cwclark.com — Site History"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

i=1
while IFS= read -r line; do
  printf "  [%2d]  %s\n" "$i" "$line"
  ((i++))
done < <(git log --pretty=format:"%h  %ad  %s" --date=format:"%Y-%m-%d %H:%M")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Run ./_scripts/rollback.sh to restore a version"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
