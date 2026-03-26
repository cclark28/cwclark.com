#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# seo-score.sh
# Daily SEO audit: Lighthouse scores + meta checks + push report
# to Google Drive reports/seo/
# Runs daily at 8am via LaunchAgent
# ─────────────────────────────────────────────────────────────────

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/cwclark.com")"
REMOTE_NAME="cwclark-gdrive"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
DATE=$(date "+%Y-%m-%d")
REPORT_DIR="$REPO_ROOT/reports/seo"
REPORT_FILE="$REPORT_DIR/${DATE}.json"
LOG="$REPO_ROOT/tasks/sync.log"
SITE_URL="https://cwclark.com"

mkdir -p "$REPORT_DIR"

echo "[$TIMESTAMP] seo-score: starting audit of $SITE_URL" >> "$LOG"

# ── Check for Lighthouse ──────────────────────────────────────────
LIGHTHOUSE=$(which lighthouse 2>/dev/null)
if [ -z "$LIGHTHOUSE" ]; then
  # Try npx
  if command -v npx &>/dev/null; then
    LIGHTHOUSE="npx lighthouse"
  else
    echo "[$TIMESTAMP] seo-score: lighthouse not found. Install: npm i -g lighthouse" >> "$LOG"
    # Fall back to basic meta checks only
    LIGHTHOUSE=""
  fi
fi

# ── Basic meta / HTTP checks (no dependencies) ───────────────────
echo "  → Running meta checks..."

# Fetch homepage
HTTP_RESPONSE=$(curl -sf -o /tmp/cwclark-index.html -w "%{http_code}" "$SITE_URL" 2>/dev/null || echo "000")
HTTP_MOBILE=$(curl -sf -A "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)" \
  -o /dev/null -w "%{http_code}" "$SITE_URL" 2>/dev/null || echo "000")

# Parse meta from fetched page
if [ -f /tmp/cwclark-index.html ]; then
  HAS_TITLE=$(grep -c '<title>' /tmp/cwclark-index.html 2>/dev/null || echo 0)
  HAS_DESC=$(grep -ci 'meta name="description"' /tmp/cwclark-index.html 2>/dev/null || echo 0)
  HAS_OG=$(grep -ci 'og:title' /tmp/cwclark-index.html 2>/dev/null || echo 0)
  HAS_CANONICAL=$(grep -ci 'rel="canonical"' /tmp/cwclark-index.html 2>/dev/null || echo 0)
  HAS_JSONLD=$(grep -c 'application/ld+json' /tmp/cwclark-index.html 2>/dev/null || echo 0)
  HAS_H1=$(grep -ci '<h1' /tmp/cwclark-index.html 2>/dev/null || echo 0)
  HAS_ALT=$(grep -c 'alt=""' /tmp/cwclark-index.html 2>/dev/null || echo 0)
  HAS_VIEWPORT=$(grep -ci 'viewport' /tmp/cwclark-index.html 2>/dev/null || echo 0)
  PAGE_SIZE=$(wc -c < /tmp/cwclark-index.html 2>/dev/null || echo 0)
  rm -f /tmp/cwclark-index.html
else
  HAS_TITLE=0; HAS_DESC=0; HAS_OG=0; HAS_CANONICAL=0
  HAS_JSONLD=0; HAS_H1=0; HAS_ALT=0; HAS_VIEWPORT=0; PAGE_SIZE=0
fi

# ── Run Lighthouse (if available) ────────────────────────────────
LH_PERF=0; LH_ACCESS=0; LH_BEST=0; LH_SEO=0

if [ -n "$LIGHTHOUSE" ]; then
  echo "  → Running Lighthouse..."
  LH_OUT="/tmp/cwclark-lh-${DATE}.json"
  $LIGHTHOUSE "$SITE_URL" \
    --output json \
    --output-path "$LH_OUT" \
    --chrome-flags="--headless --no-sandbox" \
    --quiet 2>/dev/null

  if [ -f "$LH_OUT" ]; then
    LH_PERF=$(python3 -c "import json; d=json.load(open('$LH_OUT')); print(int(d['categories']['performance']['score']*100))" 2>/dev/null || echo 0)
    LH_ACCESS=$(python3 -c "import json; d=json.load(open('$LH_OUT')); print(int(d['categories']['accessibility']['score']*100))" 2>/dev/null || echo 0)
    LH_BEST=$(python3 -c "import json; d=json.load(open('$LH_OUT')); print(int(d['categories']['best-practices']['score']*100))" 2>/dev/null || echo 0)
    LH_SEO=$(python3 -c "import json; d=json.load(open('$LH_OUT')); print(int(d['categories']['seo']['score']*100))" 2>/dev/null || echo 0)
    cp "$LH_OUT" "$REPORT_DIR/lighthouse-${DATE}.json"
    rm -f "$LH_OUT"
  fi
fi

# ── Write JSON report ─────────────────────────────────────────────
python3 -c "
import json, sys
report = {
  'date':       '$DATE',
  'timestamp':  '$TIMESTAMP',
  'url':        '$SITE_URL',
  'http': {
    'desktop_status': $HTTP_RESPONSE,
    'mobile_status':  $HTTP_MOBILE,
  },
  'meta': {
    'has_title':     $HAS_TITLE > 0,
    'has_description': $HAS_DESC > 0,
    'has_og_tags':   $HAS_OG > 0,
    'has_canonical': $HAS_CANONICAL > 0,
    'has_json_ld':   $HAS_JSONLD > 0,
    'has_h1':        $HAS_H1 > 0,
    'empty_alts':    $HAS_ALT,
    'has_viewport':  $HAS_VIEWPORT > 0,
    'page_size_kb':  round($PAGE_SIZE / 1024, 1),
  },
  'lighthouse': {
    'performance':   $LH_PERF,
    'accessibility': $LH_ACCESS,
    'best_practices': $LH_BEST,
    'seo':           $LH_SEO,
  }
}
with open('$REPORT_FILE', 'w') as f:
    json.dump(report, f, indent=2)
print(json.dumps(report, indent=2))
"

# ── Append to rolling scores log ─────────────────────────────────
python3 << PYEOF
import json, os

scores_file = '$REPO_ROOT/reports/seo/scores.json'
try:
    with open(scores_file) as f:
        scores = json.load(f)
except:
    scores = []

new_entry = {
    'date': '$DATE',
    'http_ok': $HTTP_RESPONSE == 200 if '$HTTP_RESPONSE' != '000' else False,
    'lighthouse': {
        'performance': $LH_PERF,
        'accessibility': $LH_ACCESS,
        'best_practices': $LH_BEST,
        'seo': $LH_SEO
    },
    'meta_score': sum([
        $HAS_TITLE > 0,
        $HAS_DESC > 0,
        $HAS_OG > 0,
        $HAS_CANONICAL > 0,
        $HAS_JSONLD > 0,
        $HAS_H1 > 0,
        $HAS_VIEWPORT > 0,
    ])
}

# Remove duplicate date if exists
scores = [e for e in scores if e.get('date') != '$DATE']
scores.insert(0, new_entry)
scores = scores[:90]  # Keep 90 days

with open(scores_file, 'w') as f:
    json.dump(scores, f, indent=2)
PYEOF

# ── Push report to Google Drive ───────────────────────────────────
if rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
  rclone copyto "$REPORT_FILE" \
    "${REMOTE_NAME}:reports/seo/${DATE}.json" 2>/dev/null
  rclone copyto "$REPO_ROOT/reports/seo/scores.json" \
    "${REMOTE_NAME}:reports/seo/scores.json" 2>/dev/null
  echo "  → Report pushed to Google Drive"
fi

echo "[$TIMESTAMP] seo-score: complete." >> "$LOG"
echo ""
echo "  ✓ SEO Report — $DATE"
echo "    HTTP:         $HTTP_RESPONSE (desktop)  $HTTP_MOBILE (mobile)"
echo "    Meta checks:  title=$HAS_TITLE  desc=$HAS_DESC  OG=$HAS_OG  JSON-LD=$HAS_JSONLD"
if [ "$LH_SEO" -gt 0 ]; then
  echo "    Lighthouse:   Perf=$LH_PERF  A11y=$LH_ACCESS  Best=$LH_BEST  SEO=$LH_SEO"
fi
echo "    Report:       reports/seo/${DATE}.json"
echo ""
