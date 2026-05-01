#!/usr/bin/env bash
set -euo pipefail

# Create folder structure
mkdir -p /data "$DATA_DIR" "$DOWNLOAD_DIR" "$USER_EXTENSIONS_DIR"
chown -R blessuser:blessuser /data

# Configure NopeCHA with API Key
if [[ -n "${EXTENSION_NOPECHA_API_KEY:-}" ]]; then
  MANIFEST="$GLOBAL_EXTENSIONS_DIR/nopecha/manifest.json"
  jq --arg key "$EXTENSION_NOPECHA_API_KEY" '.nopecha.key = $key' "$MANIFEST" > "${MANIFEST}.tmp"
  mv "${MANIFEST}.tmp" "$MANIFEST"
fi

# Run original base image entrypoint
exec /usr/src/app/scripts/start.sh "$@"
