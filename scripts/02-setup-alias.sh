#!/usr/bin/env bash
set -euo pipefail

# Get the path where playwright expects to find chrome
CHROME_PATH=$(
	node -e "
    const pw = require('playwright-core');
    console.log(pw.chromium.executablePath());
  "
)

CHROME_DIR=$(dirname "$CHROME_PATH")

# Rename real chrome binary (keep as backup)
mv "$CHROME_PATH" "$CHROME_DIR/chrome.backup"

# Install chromium alias in its place that will call Brave instead
mv /tmp/scripts/chromium-alias.sh "$CHROME_PATH"
chmod +x "$CHROME_PATH"
