#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_HTML="$ROOT_DIR/index.html"
TMP_JS="$(mktemp --suffix=.js)"
trap 'rm -f "$TMP_JS"' EXIT

if [[ ! -f "$INDEX_HTML" ]]; then
  echo "ERROR: index.html not found at $INDEX_HTML" >&2
  exit 1
fi

python3 - <<'PY' "$INDEX_HTML" "$TMP_JS"
import pathlib, re, sys
html_path = pathlib.Path(sys.argv[1])
out_js = pathlib.Path(sys.argv[2])
text = html_path.read_text(encoding='utf-8')
match = re.search(r'<script>([\s\S]*?)</script>', text)
if not match:
    print('ERROR: <script> block not found in index.html', file=sys.stderr)
    raise SystemExit(1)
out_js.write_text(match.group(1), encoding='utf-8')
PY

node --check "$TMP_JS" >/dev/null

required_ids=(
  'id="leftBtn"'
  'id="rightBtn"'
  'id="jumpBtn"'
  'id="hintBtn"'
  'id="answer"'
  'id="checkBtn"'
)

for needle in "${required_ids[@]}"; do
  if ! grep -q "$needle" "$INDEX_HTML"; then
    echo "ERROR: required element missing: $needle" >&2
    exit 1
  fi
done

echo "OK: smoke-check passed"
