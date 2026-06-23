#!/bin/bash
# Push 1.8MB dylib straight to GitHub Releases via API

set -e

DYLIB="80pool1.dylib"
REPO="$1"  # e.g., "username/8ball-pool"
TOKEN="$2"  # GitHub Personal Access Token

if [ -z "$REPO" ] || [ -z "$TOKEN" ]; then
    echo "[!] Usage: $0 <owner/repo> <github_token>"
    exit 1
fi

if [ ! -f "$DYLIB" ]; then
    echo "[!] File not found: $DYLIB"
    exit 1
fi

SIZE=$(stat -c%s "$DYLIB")
echo "[+] Uploading $DYLIB ($SIZE bytes) to $REPO..."

# Create release
TAG="dylib-$(date +%s)"
RELEASE_JSON=$(cat <<EOF
{
  "tag_name": "$TAG",
  "name": "80pool1.dylib Release",
  "body": "1.8MB dylib extraction — ready for analysis",
  "draft": false,
  "prerelease": false
}
EOF
)

RELEASE_RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "$RELEASE_JSON" \
  "https://api.github.com/repos/$REPO/releases")

RELEASE_ID=$(echo "$RELEASE_RESPONSE" | grep -o '"id": [0-9]*' | head -1 | grep -o '[0-9]*')

if [ -z "$RELEASE_ID" ]; then
    echo "[!] Failed to create release"
    echo "$RELEASE_RESPONSE"
    exit 1
fi

echo "[+] Release created (ID: $RELEASE_ID)"

# Upload dylib asset
UPLOAD_URL="https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets"

curl -s -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @"$DYLIB" \
  "$UPLOAD_URL?name=$(basename $DYLIB)" > /dev/null

echo "[+] Dylib uploaded boss man"
echo "[+] Download: https://github.com/$REPO/releases/tag/$TAG"
