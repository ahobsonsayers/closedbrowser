#!/usr/bin/env bash
set -euo pipefail

# Create folder structure
mkdir -p /data "$USER_EXTENSIONS_DIR"
chown -R pptruser:pptruser /data || true

# Configure NopeCHA with API Key
if [[ -n ${EXTENSION_NOPECHA_API_KEY:-} ]]; then
  MANIFEST="$GLOBAL_EXTENSIONS_DIR/nopecha/manifest.json"
  jq --arg key "$EXTENSION_NOPECHA_API_KEY" '.nopecha.key = $key' "$MANIFEST" > "${MANIFEST}.tmp"
  mv "${MANIFEST}.tmp" "$MANIFEST"
fi

# Run original base image entrypoint (as pptruser)
cd "$APP_DIR"
exec gosu pptruser node dist/main.js