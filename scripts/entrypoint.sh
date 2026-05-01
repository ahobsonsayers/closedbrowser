#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${EXTENSION_NOPECHA_API_KEY:-}" ]]; then
  MANIFEST="$GLOBAL_EXTENSIONS_DIR/nopecha/manifest.json"
  jq --arg key "$EXTENSION_NOPECHA_API_KEY" '.nopecha.key = $key' "$MANIFEST" > "${MANIFEST}.tmp"
  mv "${MANIFEST}.tmp" "$MANIFEST"
fi

exec /usr/src/app/scripts/start.sh "$@"
