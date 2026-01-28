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

# Injected class to check for (proves JAR is actually patched)
INJECTED_CLASS="com/hypixel/hytale/server/core/auth/DualAuthContext.class"

JAR_PATH="${1:-${HYTALE_SERVER_JAR:-/data/server/HytaleServer.jar}}"

echo "=== Hytale Server Dual Authentication Patcher ==="
echo "Target: $JAR_PATH"
echo "F2P Domain: ${HYTALE_AUTH_DOMAIN:-auth.sanasol.ws}"

if [ ! -f "$JAR_PATH" ]; then
    echo "ERROR: JAR not found: $JAR_PATH"
    exit 1
fi

JAR_DIR=$(dirname "$JAR_PATH")
PATCH_FLAG="$JAR_DIR/$PATCH_FLAG_FILE"

# Check if JAR is actually patched by looking for injected classes
# This is more reliable than a flag file which can become stale after JAR updates
is_jar_patched() {
    if unzip -l "$JAR_PATH" 2>/dev/null | grep -q "$INJECTED_CLASS"; then
        return 0
    fi
    return 1
}

# Check actual JAR state (not just flag file)
if is_jar_patched; then
    echo "JAR already contains dual auth classes (DualAuthContext found)"
    # Update flag file to match current state
    echo "patched=true" > "$PATCH_FLAG"
    echo "date=$(date -Iseconds 2>/dev/null || date)" >> "$PATCH_FLAG"
    echo "domain=${HYTALE_AUTH_DOMAIN:-sanasol.ws}" >> "$PATCH_FLAG"
    echo "verified=jar_contents" >> "$PATCH_FLAG"
    echo "Server already patched for dual auth, skipping"
    exit 0
fi

# JAR is not patched - clean up stale flag file if it exists
if [ -f "$PATCH_FLAG" ]; then
    echo "WARNING: Flag file exists but JAR is not patched (JAR was likely updated)"
    echo "Removing stale flag file and re-patching..."
    rm -f "$PATCH_FLAG"
fi

# Check if patcher is available
if [ ! -f "$PATCHER_DIR/DualAuthPatcher.class" ]; then
    echo "ERROR: DualAuthPatcher not found at $PATCHER_DIR"
    exit 1
fi

CLASSPATH="$PATCHER_DIR/lib/asm-9.6.jar:$PATCHER_DIR/lib/asm-tree-9.6.jar:$PATCHER_DIR/lib/asm-util-9.6.jar:$PATCHER_DIR"

# Create backup of the unpatched JAR
# If backup exists but JAR was updated, rename old backup and create new one
BACKUP_PATH="${JAR_PATH}.original"
if [ -f "$BACKUP_PATH" ]; then
    # Check if backup is different from current JAR (JAR was updated)
    CURRENT_SIZE=$(stat -c%s "$JAR_PATH" 2>/dev/null || stat -f%z "$JAR_PATH" 2>/dev/null)
    BACKUP_SIZE=$(stat -c%s "$BACKUP_PATH" 2>/dev/null || stat -f%z "$BACKUP_PATH" 2>/dev/null)
    if [ "$CURRENT_SIZE" != "$BACKUP_SIZE" ]; then
        echo "JAR size changed (update detected), creating new backup..."
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$BACKUP_PATH" "${JAR_PATH}.original.${TIMESTAMP}"
        cp "$JAR_PATH" "$BACKUP_PATH"
        echo "Previous backup renamed to: ${JAR_PATH}.original.${TIMESTAMP}"
    else
        echo "Using existing backup: $BACKUP_PATH"
    fi
else
    echo "Creating backup: $BACKUP_PATH"
    cp "$JAR_PATH" "$BACKUP_PATH"
fi

echo ""
echo "Running dual auth patcher..."
java -cp "$CLASSPATH" DualAuthPatcher "$JAR_PATH"

# Verify patch was successful by checking for injected class
if is_jar_patched; then
    echo ""
    echo "Patch verification: SUCCESS (DualAuthContext.class found in JAR)"

    # Write patch flag with verification info
    echo "patched=true" > "$PATCH_FLAG"
    echo "date=$(date -Iseconds 2>/dev/null || date)" >> "$PATCH_FLAG"
    echo "domain=${HYTALE_AUTH_DOMAIN:-sanasol.ws}" >> "$PATCH_FLAG"
    echo "verified=jar_contents" >> "$PATCH_FLAG"
    JAR_SIZE=$(stat -c%s "$JAR_PATH" 2>/dev/null || stat -f%z "$JAR_PATH" 2>/dev/null)
    echo "jar_size=${JAR_SIZE}" >> "$PATCH_FLAG"

    echo ""
    echo "=== Dual Authentication Patching Complete ==="
else
    echo ""
    echo "ERROR: Patch verification FAILED - DualAuthContext.class not found in JAR"
    echo "The patcher may have failed. Check the output above for errors."
    exit 1
fi
