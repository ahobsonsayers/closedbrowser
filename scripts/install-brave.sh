#!/usr/bin/env bash
set -euo pipefail

# Add brave browser gpg key
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
	https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

# Add brave browser repository
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com stable main" > \
	/etc/apt/sources.list.d/brave.list

# Install brave browser
apt-get update
apt-get install -y --no-install-recommends brave-browser

# Setup alias to use Brave instead of Chromium
cp /tmp/scripts/chromium-alias.sh /usr/local/bin/chromium
chmod +x /usr/local/bin/chromium
