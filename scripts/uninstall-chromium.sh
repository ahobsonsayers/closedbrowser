#!/usr/bin/env bash
set -euo pipefail

# Remove Chromium if installed (ignore errors if not present)
apt-get purge -y chromium chromium-common chromium-sandbox 2>/dev/null || true
