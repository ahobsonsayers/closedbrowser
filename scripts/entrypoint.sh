#!/usr/bin/env bash
set -euo pipefail

# Create folder structure
mkdir -p "$DATA_DIR" "$USER_EXTENSIONS_DIR"
chown -R browser:browser "$DATA_DIR" || true

# Configure NopeCHA with API Key
if [[ -n ${EXTENSION_NOPECHA_API_KEY:-} ]]; then
  MANIFEST="$GLOBAL_EXTENSIONS_DIR/nopecha/manifest.json"
  jq --arg key "$EXTENSION_NOPECHA_API_KEY" '.nopecha.key = $key' "$MANIFEST" > "${MANIFEST}.tmp"
  mv "${MANIFEST}.tmp" "$MANIFEST"
fi

# Run as browser user
cd "$HOME"
exec gosu browser bun dist/main.js
