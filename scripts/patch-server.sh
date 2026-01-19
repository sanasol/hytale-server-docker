#!/bin/bash
# Hytale Server Patcher - Patches HytaleServer.jar to use custom auth domain
# Replaces hytale.com with custom domain (must be same length - 10 chars)

set -e

# Domain configuration - must be same length!
ORIGINAL_DOMAIN="hytale.com"
# Allow override via environment variable, default to sanasol.ws
NEW_DOMAIN="${HYTALE_AUTH_DOMAIN:-sanasol.ws}"
PATCH_FLAG_FILE=".patched_custom"

# Validate domain length
if [ ${#NEW_DOMAIN} -ne ${#ORIGINAL_DOMAIN} ]; then
  echo "ERROR: Domain length mismatch!"
  echo "Original: $ORIGINAL_DOMAIN (${#ORIGINAL_DOMAIN} chars)"
  echo "New: $NEW_DOMAIN (${#NEW_DOMAIN} chars)"
  echo "Domains must be exactly the same length. Falling back to default."
  NEW_DOMAIN="sanasol.ws"
fi

# Default JAR path, can be overridden by env var or argument
JAR_PATH="${HYTALE_SERVER_JAR:-/data/server/HytaleServer.jar}"
if [ -n "$1" ]; then
    JAR_PATH="$1"
fi

echo "=== Hytale Server Patcher ==="
echo "Target: $JAR_PATH"
echo "Domain: $ORIGINAL_DOMAIN -> $NEW_DOMAIN"
echo ""

# Check if JAR exists
if [ ! -f "$JAR_PATH" ]; then
    echo "ERROR: JAR not found: $JAR_PATH"
    exit 1
fi

JAR_DIR=$(dirname "$JAR_PATH")
JAR_NAME=$(basename "$JAR_PATH")

# Check if already patched
PATCH_FLAG="$JAR_DIR/$PATCH_FLAG_FILE"
if [ -f "$PATCH_FLAG" ]; then
    if grep -q "$NEW_DOMAIN" "$PATCH_FLAG" 2>/dev/null; then
        echo "Server already patched for $NEW_DOMAIN, skipping"
        exit 0
    fi
fi

# Create backup if doesn't exist
BACKUP_PATH="${JAR_PATH}.original"
if [ ! -f "$BACKUP_PATH" ]; then
    echo "Creating backup: $BACKUP_PATH"
    cp "$JAR_PATH" "$BACKUP_PATH"
else
    echo "Backup already exists: $BACKUP_PATH"
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Extracting JAR..."
cd "$TEMP_DIR"
unzip -q "$JAR_PATH"

echo "Patching files..."
TOTAL_COUNT=0
PATCHED_FILES=0

# Find and patch files containing the domain
# Using grep -l to find files, then perl for binary-safe replacement
while IFS= read -r -d '' file; do
    # Only process relevant file types
    case "$file" in
        *.class|*.properties|*.json|*.xml|*.yml|*.yaml)
            # Check if file contains the domain
            if grep -q "$ORIGINAL_DOMAIN" "$file" 2>/dev/null; then
                # Count occurrences before patching
                COUNT=$(grep -o "$ORIGINAL_DOMAIN" "$file" 2>/dev/null | wc -l)

                # Use perl for binary-safe replacement (works on .class files)
                perl -pi -e "s/\Q$ORIGINAL_DOMAIN\E/$NEW_DOMAIN/g" "$file"

                REL_PATH="${file#$TEMP_DIR/}"
                echo "  Patched $COUNT occurrences in $REL_PATH"
                TOTAL_COUNT=$((TOTAL_COUNT + COUNT))
                PATCHED_FILES=$((PATCHED_FILES + 1))
            fi
            ;;
    esac
done < <(find . -type f -print0)

if [ $TOTAL_COUNT -eq 0 ]; then
    echo "No occurrences of $ORIGINAL_DOMAIN found in JAR"
    echo "patched_to=$NEW_DOMAIN" > "$PATCH_FLAG"
    echo "patched_files=0" >> "$PATCH_FLAG"
    echo "warning=no_domain_found" >> "$PATCH_FLAG"
    exit 0
fi

echo "Recreating JAR..."
rm -f "$JAR_PATH"
zip -q -r "$JAR_PATH" .

# Write patch flag
echo "patched_to=$NEW_DOMAIN" > "$PATCH_FLAG"
echo "patched_files=$PATCHED_FILES" >> "$PATCH_FLAG"
echo "total_replacements=$TOTAL_COUNT" >> "$PATCH_FLAG"

echo ""
echo "Successfully patched $TOTAL_COUNT occurrences in $PATCHED_FILES files"
echo "=== Patching Complete ==="
