#!/usr/bin/env bash
set -euo pipefail

CHROME_PATH=$(
  node -e "
    const pw = require('playwright-core');
    console.log(pw.chromium.executablePath());
  "
)

CHROME_DIR=$(dirname "$CHROME_PATH")

# Rename real chrome binary
mv "$CHROME_PATH" "$CHROME_DIR/chrome.real"

# Install chromium alias in its place
mv /tmp/scripts/chromium-alias.sh "$CHROME_PATH"
chmod +x "$CHROME_PATH"
