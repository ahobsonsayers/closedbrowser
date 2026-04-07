#!/usr/bin/env bash
set -euo pipefail

#########################
# Install Brave Browser #
#########################

# Add brave browser gpg key
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
  https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

# Add brave browser repository
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com stable main" > \
  /etc/apt/sources.list.d/brave.list

# Install brave browser
apt-get update
apt-get install -y --no-install-recommends brave-browser

# Setup alias
mv /tmp/scripts/chromium-alias.sh /usr/local/bin/chromium

######################
# Install Extensions #
######################

# Create global extensions directory
mkdir -p "$GLOBAL_EXTENSIONS_DIR"

# Install "uBlock Origin"
UBLOCK_URL=$(curl -s https://api.github.com/repos/gorhill/uBlock/releases/latest |
  jq -r '.assets[] | select(.name | contains("chromium")) | .browser_download_url')
curl -sL --progress-bar "$UBLOCK_URL" -o /tmp/ublock.zip
unzip -q /tmp/ublock.zip -d /tmp
mv /tmp/uBlock0.chromium "$GLOBAL_EXTENSIONS_DIR/ublock"
rm /tmp/ublock.zip

# Install "I Still Don't Care About Cookies"
ISDCAC_URL=$(curl -s https://api.github.com/repos/OhMyGuus/I-Still-Dont-Care-About-Cookies/releases/latest |
  jq -r '.assets[] | select(.name | contains("chrome")) | .browser_download_url')
curl -sL --progress-bar "$ISDCAC_URL" -o /tmp/isdcac.zip
unzip -q /tmp/isdcac.zip -d "$GLOBAL_EXTENSIONS_DIR/isdcac"
rm /tmp/isdcac.zip

# Set global extensions ownership
chown -R kernel:kernel "$GLOBAL_EXTENSIONS_DIR"
