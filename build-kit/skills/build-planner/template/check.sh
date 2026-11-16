#!/bin/bash
# Runs a build planner's checks over every preset in headless Chrome, with no WebGL.
# Usage: check.sh [planner.html]   (defaults to index.html, then build-planner.html, here)
# Exits 1 when any preset fails, so it can gate a commit.
set -u
f="${1:-}"
if [ -z "$f" ]; then for c in index.html build-planner.html; do [ -f "$c" ] && f="$c" && break; done; fi
[ -f "${f:-}" ] || { echo "No planner file found. Pass one: check.sh path/to/planner.html"; exit 2; }
abs="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
chrome="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[ -x "$chrome" ] || chrome="$(command -v google-chrome || command -v chromium || true)"
[ -n "$chrome" ] || { echo "Chrome not found. Set CHROME=/path/to/chrome"; exit 2; }
tmp="$(mktemp -d)"
out="$("$chrome" --headless=new --disable-gpu --no-first-run --user-data-dir="$tmp" --virtual-time-budget=4000 --dump-dom "file://$abs?check" 2>/dev/null)"
rm -rf "$tmp"
report="$(printf '%s' "$out" | sed -n '/<pre id="checkOut">/,/<\/pre>/p' | sed -e 's/.*<pre id="checkOut">//' -e 's/<\/pre>.*//' -e 's/&lt;/</g' -e 's/&amp;/\&/g')"
[ -n "$report" ] || { echo "No check output. Open $f?check in a browser to see why."; exit 2; }
printf '%s\n' "$report"
printf '%s' "$report" | grep -q '^RESULT PASS' || exit 1
