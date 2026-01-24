#!/bin/sh
# Fetch server tokens from F2P auth server
# This is used when HYTALE_AUTO_FETCH_TOKENS=true

set -eu

log() {
  printf '%s\n' "$*" >&2
}

HYTALE_AUTH_DOMAIN="${HYTALE_AUTH_DOMAIN:-auth.sanasol.ws}"

# F2P always uses single endpoint without subdomains
# All traffic routes to https://{domain} (no sessions., account-data., etc.)
AUTH_SERVER_URL="${HYTALE_AUTH_SERVER_URL:-https://${HYTALE_AUTH_DOMAIN}}"

# Generate a server ID based on hostname + data dir
if [ -n "${HYTALE_SERVER_ID:-}" ]; then
  SERVER_ID="${HYTALE_SERVER_ID}"
elif [ -f "/data/.server-id" ]; then
  SERVER_ID="$(cat /data/.server-id)"
else
  # Generate a new server ID
  if command -v uuidgen >/dev/null 2>&1; then
    SERVER_ID="$(uuidgen)"
  else
    SERVER_ID="$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "server-$(hostname)-$(date +%s)")"
  fi
  # Persist it
  printf '%s' "${SERVER_ID}" > "/data/.server-id" 2>/dev/null || true
fi

SERVER_NAME="${HYTALE_SERVER_NAME:-Hytale Server}"

log "Fetching server tokens from ${AUTH_SERVER_URL}..."
log "  Server ID: ${SERVER_ID}"
log "  Server Name: ${SERVER_NAME}"

# Call the auto-auth endpoint
RESPONSE=$(curl -s -X POST "${AUTH_SERVER_URL}/server/auto-auth" \
  -H "Content-Type: application/json" \
  -d "{\"server_id\": \"${SERVER_ID}\", \"server_name\": \"${SERVER_NAME}\"}" \
  --connect-timeout 10 \
  --max-time 30 \
  2>/dev/null) || {
    log "ERROR: Failed to connect to auth server at ${AUTH_SERVER_URL}"
    exit 1
  }

# Check if response is valid JSON with tokens
if ! echo "${RESPONSE}" | grep -q "sessionToken"; then
  log "ERROR: Invalid response from auth server:"
  log "${RESPONSE}"
  exit 1
fi

# Extract tokens using grep/sed (avoid jq dependency)
SESSION_TOKEN=$(echo "${RESPONSE}" | sed -n 's/.*"sessionToken"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
IDENTITY_TOKEN=$(echo "${RESPONSE}" | sed -n 's/.*"identityToken"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

if [ -z "${SESSION_TOKEN}" ] || [ -z "${IDENTITY_TOKEN}" ]; then
  log "ERROR: Could not extract tokens from response"
  log "${RESPONSE}"
  exit 1
fi

# Write tokens to env file for sourcing
cat > /tmp/server_tokens.env << EOF
HYTALE_SERVER_SESSION_TOKEN="${SESSION_TOKEN}"
HYTALE_SERVER_IDENTITY_TOKEN="${IDENTITY_TOKEN}"
EOF

log "Successfully fetched server tokens"
log "  Session token: [set]"
log "  Identity token: [set]"
