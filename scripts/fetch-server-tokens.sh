#!/bin/bash
# Fetch server tokens from auth server for dedicated server authentication
# Sets HYTALE_SERVER_SESSION_TOKEN and HYTALE_SERVER_IDENTITY_TOKEN

set -e

# Build auth server URL from domain or use explicit URL
AUTH_DOMAIN="${HYTALE_AUTH_DOMAIN:-sanasol.ws}"
AUTH_SERVER="${HYTALE_AUTH_SERVER:-https://sessions.${AUTH_DOMAIN}}"
SERVER_UUID="${HYTALE_SERVER_UUID:-$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen | tr '[:upper:]' '[:lower:]')}"
SERVER_NAME="${HYTALE_SERVER_NAME:-DedicatedServer}"

echo "=== Fetching Server Tokens ==="
echo "Auth server: $AUTH_SERVER"
echo "Server UUID: $SERVER_UUID"
echo "Server name: $SERVER_NAME"

# Request tokens from auth server
RESPONSE=$(curl -s -X POST "${AUTH_SERVER}/game-session/new" \
  -H "Content-Type: application/json" \
  -d "{\"uuid\": \"${SERVER_UUID}\", \"name\": \"${SERVER_NAME}\"}" \
  2>/dev/null || echo "")

if [ -z "$RESPONSE" ]; then
  echo "WARNING: Could not connect to auth server at ${AUTH_SERVER}"
  echo "WARNING: Server will start without session tokens"
  exit 0
fi

# Extract tokens from response
SESSION_TOKEN=$(echo "$RESPONSE" | jq -r '.sessionToken // .SessionToken // empty')
IDENTITY_TOKEN=$(echo "$RESPONSE" | jq -r '.identityToken // .IdentityToken // empty')

if [ -n "$SESSION_TOKEN" ] && [ "$SESSION_TOKEN" != "null" ]; then
  export HYTALE_SERVER_SESSION_TOKEN="$SESSION_TOKEN"
  echo "Session token: [obtained]"
else
  echo "WARNING: No session token received"
fi

if [ -n "$IDENTITY_TOKEN" ] && [ "$IDENTITY_TOKEN" != "null" ]; then
  export HYTALE_SERVER_IDENTITY_TOKEN="$IDENTITY_TOKEN"
  echo "Identity token: [obtained]"
else
  echo "WARNING: No identity token received"
fi

# Write tokens to file for entrypoint to source
TOKEN_FILE="/tmp/server_tokens.env"
echo "HYTALE_SERVER_SESSION_TOKEN='${SESSION_TOKEN}'" > "$TOKEN_FILE"
echo "HYTALE_SERVER_IDENTITY_TOKEN='${IDENTITY_TOKEN}'" >> "$TOKEN_FILE"

echo "=== Tokens Ready ==="
