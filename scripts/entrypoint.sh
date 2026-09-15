#!/usr/bin/env bash
set -euo pipefail

# Create folder structure
mkdir -p "$DATA_DIR" "$USER_EXTENSIONS_DIR"
chown -R browser:browser "$DATA_DIR" || true

# Run as browser user
cd "$HOME"
exec gosu browser node dist/main.js
