#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# optimize-images.sh
# Compress and resize new images after every Drive pull.
#
# What it does:
#   · Converts HEIC/HEIF → JPEG (iPhone photos)
#   · Resizes anything wider than 2400px → 2400px max (retina safe)
#   · Recompresses JPEG at quality 82 (visually lossless, ~65% smaller)
#   · Recompresses PNG at quality 85
#   · Generates WebP sidecar files if cwebp is installed (Homebrew)
#   · Skips already-optimised files (tracked in .opt-manifest)
#   · Skips files already under 150KB (fast-loading as-is)
#   · Never touches SVG, GIF, or files outside uploads/
#
# Tools used:
#   · sips     — built-in macOS, always available
#   · cwebp    — optional, install with: brew install webp
#
# Run manually: ./_scripts/optimize-images.sh
# Runs automatically after every gdrive-pull.sh
# ─────────────────────────────────────────────────────────────────

set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/cwclark.com")"
UPLOADS_DIR="$REPO_ROOT/assets/images/uploads"
MANIFEST="$UPLOADS_DIR/.opt-manifest"
LOG="$REPO_ROOT/tasks/optimize.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")

# ── Config ────────────────────────────────────────────────────────
MAX_WIDTH=2400        # Max pixel width (2400 = 1200px @ retina)
JPEG_QUALITY=82       # JPEG compression quality (0–100; 82 = visually lossless)
PNG_QUALITY=85        # PNG quality via sips
SKIP_BELOW_KB=150     # Skip files already under this size in KB
WEBP_QUALITY=80       # WebP quality (if cwebp is installed)

# ── Setup ─────────────────────────────────────────────────────────
mkdir -p "$REPO_ROOT/tasks"
touch "$MANIFEST"
HAS_CWEBP=$(command -v cwebp &>/dev/null && echo "yes" || echo "no")

echo ""
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║  cwclark.com · Image Optimiser                      ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Scanning: $UPLOADS_DIR"
echo "  Max width: ${MAX_WIDTH}px · JPEG quality: ${JPEG_QUALITY} · WebP: $HAS_CWEBP"
echo ""

echo "[$TIMESTAMP] optimize-images: starting..." >> "$LOG"

PROCESSED=0
SKIPPED=0
SAVED_KB=0

# ── Process each image ────────────────────────────────────────────
while IFS= read -r -d '' FILE; do
  FILENAME="$(basename "$FILE")"
  EXT="${FILENAME##*.}"
  EXT_LOWER="$(echo "$EXT" | tr '[:upper:]' '[:lower:]')"

  # Skip non-image files and manifest itself
  case "$EXT_LOWER" in
    svg|gif|webp|opt-manifest) continue ;;
    jpg|jpeg|png|heic|heif|bmp|tiff) ;;
    *) continue ;;
  esac

  # Build manifest key: relative path + file size
  REL_PATH="${FILE#"$UPLOADS_DIR/"}"
  FILE_SIZE_KB=$(( $(stat -f%z "$FILE" 2>/dev/null || echo 0) / 1024 ))
  MANIFEST_KEY="${REL_PATH}:${FILE_SIZE_KB}"

  # Skip if already in manifest (already optimised at this size)
  if grep -qF "$MANIFEST_KEY" "$MANIFEST" 2>/dev/null; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Skip tiny files (already fast-loading)
  if [ "$FILE_SIZE_KB" -lt "$SKIP_BELOW_KB" ] && [[ "$EXT_LOWER" != "heic" && "$EXT_LOWER" != "heif" ]]; then
    echo "$MANIFEST_KEY" >> "$MANIFEST"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  SIZE_BEFORE=$FILE_SIZE_KB
  BASENAME_NOEXT="${FILENAME%.*}"
  DIR="$(dirname "$FILE")"

  printf "  %-50s " "$REL_PATH"

  # ── Step 1: Convert HEIC/HEIF → JPEG ──────────────────────────
  if [[ "$EXT_LOWER" == "heic" || "$EXT_LOWER" == "heif" ]]; then
    JPEG_OUT="$DIR/${BASENAME_NOEXT}.jpg"
    sips -s format jpeg -s formatOptions "$JPEG_QUALITY" "$FILE" --out "$JPEG_OUT" &>/dev/null
    rm -f "$FILE"
    FILE="$JPEG_OUT"
    FILENAME="${BASENAME_NOEXT}.jpg"
    EXT_LOWER="jpg"
    echo -n "[HEIC→JPG] "
  fi

  # ── Step 2: Get current image dimensions ──────────────────────
  IMG_WIDTH=$(sips -g pixelWidth "$FILE" 2>/dev/null | awk '/pixelWidth:/{print $2}')
  IMG_WIDTH=${IMG_WIDTH:-0}

  # ── Step 3: Resize if too wide ────────────────────────────────
  if [ "$IMG_WIDTH" -gt "$MAX_WIDTH" ]; then
    sips --resampleWidth "$MAX_WIDTH" "$FILE" &>/dev/null
    echo -n "[resize→${MAX_WIDTH}px] "
  fi

  # ── Step 4: Recompress ────────────────────────────────────────
  TEMP_OUT="/tmp/cw_opt_$$.${EXT_LOWER}"
  case "$EXT_LOWER" in
    jpg|jpeg)
      sips -s format jpeg -s formatOptions "$JPEG_QUALITY" "$FILE" --out "$TEMP_OUT" &>/dev/null
      ;;
    png)
      sips -s format png -s formatOptions "$PNG_QUALITY" "$FILE" --out "$TEMP_OUT" &>/dev/null
      ;;
  esac

  # Only replace if the result is actually smaller
  if [ -f "$TEMP_OUT" ]; then
    SIZE_AFTER=$(( $(stat -f%z "$TEMP_OUT" 2>/dev/null || echo 0) / 1024 ))
    if [ "$SIZE_AFTER" -lt "$SIZE_BEFORE" ]; then
      mv "$TEMP_OUT" "$FILE"
      SAVED=$((SIZE_BEFORE - SIZE_AFTER))
      SAVED_KB=$((SAVED_KB + SAVED))
      echo -n "[${SIZE_BEFORE}KB→${SIZE_AFTER}KB, -${SAVED}KB] "
    else
      rm -f "$TEMP_OUT"
    fi
  fi

  # ── Step 5: Generate WebP sidecar (optional) ─────────────────
  if [ "$HAS_CWEBP" = "yes" ]; then
    WEBP_OUT="$DIR/${BASENAME_NOEXT}.webp"
    if [ ! -f "$WEBP_OUT" ]; then
      cwebp -q "$WEBP_QUALITY" -quiet "$FILE" -o "$WEBP_OUT" 2>/dev/null && echo -n "[+webp] "
    fi
  fi

  echo "✓"

  # Mark as done in manifest
  NEW_SIZE_KB=$(( $(stat -f%z "$FILE" 2>/dev/null || echo 0) / 1024 ))
  echo "${REL_PATH}:${NEW_SIZE_KB}" >> "$MANIFEST"

  PROCESSED=$((PROCESSED + 1))
  echo "[$TIMESTAMP] optimised: $REL_PATH (${SIZE_BEFORE}KB → ${NEW_SIZE_KB}KB)" >> "$LOG"

done < <(find "$UPLOADS_DIR" -type f -print0 | sort -z)

# ── Summary ───────────────────────────────────────────────────────
echo ""
echo "  ┌────────────────────────────────────────────────────┐"
printf "  │  Optimised: %-4s  Skipped: %-4s  Saved: ~%dKB %*s│\n" \
  "$PROCESSED" "$SKIPPED" "$SAVED_KB" $(( 13 - ${#SAVED_KB} )) ""
echo "  └────────────────────────────────────────────────────┘"
echo ""

if [ "$PROCESSED" -eq 0 ]; then
  echo "  ✓ All images already optimised."
else
  echo "  ✓ $PROCESSED image(s) optimised, saved ~${SAVED_KB}KB total."
fi
echo ""

echo "[$TIMESTAMP] optimize-images: done. processed=$PROCESSED saved=${SAVED_KB}KB" >> "$LOG"

# ── Tip: install cwebp for WebP output ───────────────────────────
if [ "$HAS_CWEBP" = "no" ] && [ "$PROCESSED" -gt 0 ]; then
  echo "  ℹ  Install cwebp for WebP generation: brew install webp"
  echo ""
fi
