#!/usr/bin/env bash
set -euo pipefail

# Remove Chromium
apt-get purge -y --ignore-missing chromium chromium-common chromium-sandbox
