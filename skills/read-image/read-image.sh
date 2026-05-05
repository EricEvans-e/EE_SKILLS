#!/usr/bin/env bash
# read-image.sh — Call a vision-capable API to analyze an image.
# Usage: bash read-image.sh <image_path> [prompt]
#
# Config: ./config.yaml (auto-generated on first run if missing)
# Falls back to VISION_* / ANTHROPIC_* env vars when config is absent.

set -euo pipefail

IMAGE_PATH="${1:?Usage: read-image.sh <image_path> [prompt]}"
PROMPT="${2:-Describe this image in detail. If it contains text, transcribe all of it. If it contains code, reproduce it. If it is a diagram or chart, explain its structure and content.}"

if [ ! -f "$IMAGE_PATH" ]; then
  echo "ERROR: File not found: $IMAGE_PATH" >&2
  exit 1
fi

# --- Find a working Python (once, for all later uses) ---
_PY="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo '')"

# --- Detect media type from extension ---
EXT="${IMAGE_PATH##*.}"
EXT_LOWER="$(echo "$EXT" | tr '[:upper:]' '[:lower:]')"
case "$EXT_LOWER" in
  jpg|jpeg) MEDIA_TYPE="image/jpeg" ;;
  png)      MEDIA_TYPE="image/png" ;;
  gif)      MEDIA_TYPE="image/gif" ;;
  webp)     MEDIA_TYPE="image/webp" ;;
  bmp)      MEDIA_TYPE="image/bmp" ;;
  tiff|tif) MEDIA_TYPE="image/tiff" ;;
  *)
    echo "ERROR: Unsupported image format: .$EXT_LOWER" >&2
    echo "Supported: jpg, jpeg, png, gif, webp, bmp, tiff" >&2
    exit 1
    ;;
esac

# --- Base64 encode (cross-platform) ---
if base64 -w 0 < /dev/null >/dev/null 2>&1; then
  IMAGE_B64="$(base64 -w 0 "$IMAGE_PATH")"
elif command -v powershell.exe >/dev/null 2>&1; then
  if command -v cygpath >/dev/null 2>&1; then
    WIN_PATH="$(cygpath -w "$IMAGE_PATH")"
  else
    WIN_PATH="${IMAGE_PATH//\//\\}"
  fi
  IMAGE_B64="$(powershell.exe -Command "[Convert]::ToBase64String([IO.File]::ReadAllBytes('$WIN_PATH'))" | tr -d '\r')"
else
  IMAGE_B64="$(base64 < "$IMAGE_PATH" | tr -d '\n')"
fi

# --- Load API config from YAML ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.yaml"

if [ -f "$CONFIG_FILE" ] && [ -n "$_PY" ]; then
  eval "$(cat "$CONFIG_FILE" | "$_PY" -c "
import sys, re, shlex
for line in sys.stdin:
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    m = re.match(r'^(\w+)\s*:\s*(.+)$', line)
    if m:
        key = m.group(1).upper()
        val = m.group(2).strip().strip('\"').strip(\"'\")
        print(f'{key}={shlex.quote(val)}')
")"
fi

# --- Resolve final values (config > env > default) ---
BASE_URL="${BASE_URL:-${VISION_BASE_URL:-${ANTHROPIC_BASE_URL:-https://api.anthropic.com}}}"
BASE_URL="${BASE_URL%/}"
AUTH_TOKEN="${AUTH_TOKEN:-${VISION_AUTH_TOKEN:-${ANTHROPIC_AUTH_TOKEN:?Set auth_token in config.yaml or ANTHROPIC_AUTH_TOKEN in env}}}"
VISION_MODEL="${MODEL:-${VISION_MODEL:-mimo-v2.5}}"
MAX_TOKENS="${MAX_TOKENS:-4096}"
AUTH_HEADER="${AUTH_HEADER:-x-api-key: @TOKEN@}"
API_VERSION="${API_VERSION:-2023-06-01}"

# Expand @TOKEN@ placeholder in auth header
AUTH_HEADER="${AUTH_HEADER//@TOKEN@/$AUTH_TOKEN}"

# --- Build request JSON to temp file (avoids "arg list too long" on large images) ---
TMPJSON="$(mktemp)"
TMPRESP="$(mktemp)"
trap 'rm -f "$TMPJSON" "$TMPRESP"' EXIT

# Escape prompt for JSON embedding
if [ -n "$_PY" ]; then
  ESCAPED_PROMPT="$(printf '%s' "$PROMPT" | "$_PY" -c 'import sys,json; print(json.dumps(sys.stdin.read()))')"
else
  # Rudimentary fallback: escape backslashes and double quotes
  ESCAPED_PROMPT="\"$(printf '%s' "$PROMPT" | sed 's/\\/\\\\/g; s/"/\\"/g')\""
fi

cat > "$TMPJSON" <<JSONEOF
{
  "model": "$VISION_MODEL",
  "max_tokens": $MAX_TOKENS,
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "image",
          "source": {
            "type": "base64",
            "media_type": "$MEDIA_TYPE",
            "data": "$IMAGE_B64"
          }
        },
        {
          "type": "text",
          "text": $ESCAPED_PROMPT
        }
      ]
    }
  ]
}
JSONEOF

# --- Call API (portable: write body to file, capture HTTP status separately) ---
CURL_ARGS=(-sS -X POST "${BASE_URL}/v1/messages")
CURL_ARGS+=(-H "Content-Type: application/json")
CURL_ARGS+=(-H "$AUTH_HEADER")
if [ -n "$API_VERSION" ]; then
  CURL_ARGS+=(-H "anthropic-version: $API_VERSION")
fi
CURL_ARGS+=(-d "@$TMPJSON" --max-time 120)

HTTP_CODE=$(curl "${CURL_ARGS[@]}" -o "$TMPRESP" -w "%{http_code}")
RESPONSE="$(cat "$TMPRESP")"

if [ "$HTTP_CODE" -ge 400 ]; then
  echo "ERROR: API call failed (HTTP $HTTP_CODE)" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

# --- Extract text from response ---
if [ -n "$_PY" ]; then
  echo "$RESPONSE" | "$_PY" -c "
import sys, json
resp = json.load(sys.stdin)
for block in resp.get('content', []):
    if block.get('type') == 'text':
        print(block['text'])
" 2>/dev/null || echo "$RESPONSE"
else
  # Portable fallback: sed-based extraction (no grep -P dependency)
  echo "$RESPONSE" | sed -n 's/.*"text"[[:space:]]*:[[:space:]]*"//p' | sed 's/"[[:space:]]*,[[:space:]]*"type".*//'
fi
