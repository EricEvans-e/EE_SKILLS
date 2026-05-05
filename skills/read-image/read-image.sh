#!/usr/bin/env bash
# read-image.sh — Call Anthropic API with a vision-capable model to analyze an image.
# Usage: bash read-image.sh <image_path> [prompt]
#
# Requires: ANTHROPIC_AUTH_TOKEN and ANTHROPIC_BASE_URL env vars (or falls back to defaults).

set -euo pipefail

IMAGE_PATH="${1:?Usage: read-image.sh <image_path> [prompt]}"
PROMPT="${2:-Describe this image in detail. If it contains text, transcribe all of it. If it contains code, reproduce it. If it is a diagram or chart, explain its structure and content.}"

if [ ! -f "$IMAGE_PATH" ]; then
  echo "ERROR: File not found: $IMAGE_PATH" >&2
  exit 1
fi

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
  # GNU coreutils (Linux, Git Bash on Windows)
  IMAGE_B64="$(base64 -w 0 "$IMAGE_PATH")"
elif command -v powershell.exe >/dev/null 2>&1; then
  # Windows PowerShell fallback
  IMAGE_B64="$(powershell.exe -Command "[Convert]::ToBase64String([IO.File]::ReadAllBytes('$(cygpath -w "$IMAGE_PATH")'))" | tr -d '\r')"
else
  # macOS / BSD base64 (no -w, wraps at 76 chars — API accepts this)
  IMAGE_B64="$(base64 < "$IMAGE_PATH" | tr -d '\n')"
fi

# --- API config ---
BASE_URL="${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"
# Strip trailing slash
BASE_URL="${BASE_URL%/}"
AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN:?Set ANTHROPIC_AUTH_TOKEN in your environment}"
VISION_MODEL="${VISION_MODEL:-mimo-v2.5}"

# --- Build request JSON to temp file (avoids "arg list too long" on large images) ---
TMPJSON="$(mktemp)"
trap 'rm -f "$TMPJSON"' EXIT

# Escape prompt for JSON embedding
ESCAPED_PROMPT="$(printf '%s' "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo "\"$PROMPT\"")"

cat > "$TMPJSON" <<JSONEOF
{
  "model": "$VISION_MODEL",
  "max_tokens": 4096,
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

# --- Call API (read JSON from file) ---
RESPONSE="$(curl -sS --fail-with-body \
  -X POST "${BASE_URL}/v1/messages" \
  -H "Content-Type: application/json" \
  -H "x-api-key: ${AUTH_TOKEN}" \
  -H "anthropic-version: 2023-06-01" \
  -d "@$TMPJSON" \
  --max-time 120)" || {
    echo "ERROR: API call failed" >&2
    echo "$RESPONSE" >&2
    exit 1
  }

# --- Extract text from response ---
# Try python3 first, fallback to grep/sed
if command -v python3 >/dev/null 2>&1; then
  echo "$RESPONSE" | python3 -c "
import sys, json
resp = json.load(sys.stdin)
for block in resp.get('content', []):
    if block.get('type') == 'text':
        print(block['text'])
" 2>/dev/null || echo "$RESPONSE"
elif command -v python >/dev/null 2>&1; then
  echo "$RESPONSE" | python -c "
import sys, json
resp = json.load(sys.stdin)
for block in resp.get('content', []):
    if block.get('type') == 'text':
        print(block['text'])
" 2>/dev/null || echo "$RESPONSE"
else
  # Fallback: crude extraction
  echo "$RESPONSE" | grep -oP '"text"\s*:\s*"\K[^"]*' | sed 's/\\n/\n/g'
fi
