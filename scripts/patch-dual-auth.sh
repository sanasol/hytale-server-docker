#!/bin/bash
# Hytale Server TRUE Dual Authentication Patcher
#
# Enables BOTH official hytale.com AND F2P sanasol.ws authentication on the same server.
#
# Key features:
# - /auth login device flow uses OFFICIAL hytale.com (never patched)
# - F2P server tokens auto-fetched from sanasol.ws on startup
# - JWKS loaded from BOTH backends and keys merged
# - Token validation accepts BOTH issuers
# - Player auth routed based on token's issuer
# - Dual server identity tokens (official + F2P)
#
# Classes injected:
# - DualAuthContext: Thread-local issuer tracking
# - DualAuthHelper: Issuer validation and URL routing
# - DualJwksFetcher: Merged JWKS from both backends
# - DualServerIdentity: F2P server identity management
# - DualServerTokenManager: Stores both official and F2P token sets
#
# Environment variables:
# - HYTALE_AUTH_DOMAIN: F2P domain (default: sanasol.ws)
# - HYTALE_SERVER_AUDIENCE: Server UUID for token requests

set -e

PATCHER_DIR="/opt/issuer-patcher"
PATCH_FLAG_FILE=".patched_dual_auth"

JAR_PATH="${1:-${HYTALE_SERVER_JAR:-/data/server/HytaleServer.jar}}"

echo "=== Hytale Server Dual Authentication Patcher ==="
echo "Target: $JAR_PATH"
echo "F2P Domain: ${HYTALE_AUTH_DOMAIN:-sanasol.ws}"

if [ ! -f "$JAR_PATH" ]; then
    echo "ERROR: JAR not found: $JAR_PATH"
    exit 1
fi

JAR_DIR=$(dirname "$JAR_PATH")

# Check if already patched
PATCH_FLAG="$JAR_DIR/$PATCH_FLAG_FILE"
if [ -f "$PATCH_FLAG" ]; then
    PATCHED_DOMAIN=$(grep "domain=" "$PATCH_FLAG" 2>/dev/null | cut -d= -f2)
    if [ "$PATCHED_DOMAIN" = "${HYTALE_AUTH_DOMAIN:-sanasol.ws}" ]; then
        echo "Server already patched for dual auth with domain $PATCHED_DOMAIN, skipping"
        exit 0
    else
        echo "Server was patched for different domain ($PATCHED_DOMAIN), re-patching..."
        rm -f "$PATCH_FLAG"
    fi
fi

# Check if patcher is available
if [ ! -f "$PATCHER_DIR/DualAuthPatcher.class" ]; then
    echo "ERROR: DualAuthPatcher not found at $PATCHER_DIR"
    exit 1
fi

CLASSPATH="$PATCHER_DIR/lib/asm-9.6.jar:$PATCHER_DIR/lib/asm-tree-9.6.jar:$PATCHER_DIR/lib/asm-util-9.6.jar:$PATCHER_DIR"

# Create backup
BACKUP_PATH="${JAR_PATH}.original"
if [ ! -f "$BACKUP_PATH" ]; then
    echo "Creating backup: $BACKUP_PATH"
    cp "$JAR_PATH" "$BACKUP_PATH"
fi

echo ""
echo "Running dual auth patcher..."
java -cp "$CLASSPATH" DualAuthPatcher "$JAR_PATH"

# Write patch flag
echo "patched=true" > "$PATCH_FLAG"
echo "date=$(date -Iseconds 2>/dev/null || date)" >> "$PATCH_FLAG"
echo "domain=${HYTALE_AUTH_DOMAIN:-sanasol.ws}" >> "$PATCH_FLAG"

echo ""
echo "=== Dual Authentication Patching Complete ==="
