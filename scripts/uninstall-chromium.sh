#!/usr/bin/env bash
set -euo pipefail

# Install chromedriver
apt-get install -y --no-install-recommends chromium-driver
cp /usr/bin/chromedriver /usr/local/bin/chromedriver

# Remove Chromium
apt-get purge -y --ignore-missing chromium chromium-common chromium-sandbox
