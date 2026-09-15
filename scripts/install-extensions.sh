#!/usr/bin/env bash
set -euo pipefail

CRX_DIR="/opt/cloakbrowser/extensions"
REGISTRY_DIR="/usr/share/chromium/extensions"

CHROMIUM_VERSION=$(/opt/cloakbrowser/chrome --version | cut -d ' ' -f 2)

# install_extension <name> <store-id>
install_extension() {
  EXTENSION_NAME="${1,,}" # make lowercase
  EXTENSION_ID="$2"

  # Download crx from the chrome store
  curl -sL --progress-bar \
    "https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=${CHROMIUM_VERSION}&x=id%3D${EXTENSION_ID}%26uc" \
    -o "$CRX_DIR/$EXTENSION_NAME.crx"

  # Get version from crx manifest
  # unzip exits 1 on crx3 extra-bytes warning so tolerate it
  EXTENSION_VERSION=$(
    unzip -p "$CRX_DIR/$EXTENSION_NAME.crx" manifest.json |
      jq -r .version
  ) || true

  if [[ -z $EXTENSION_VERSION ]]; then
    echo "ERROR: Cannot read version from $EXTENSION_NAME.crx manifest" >&2
    exit 1
  fi

  # Register extension to external registry
  jq -n \
    --arg crx "$CRX_DIR/$EXTENSION_NAME.crx" \
    --arg version "$EXTENSION_VERSION" \
    '{external_crx: $crx, external_version: $version}' > "$REGISTRY_DIR/$EXTENSION_ID.json"
}

# Create directories
rm -rf "$GLOBAL_EXTENSIONS_DIR"
mkdir -p "$CRX_DIR" "$REGISTRY_DIR" "$GLOBAL_EXTENSIONS_DIR"

# Install extensions
install_extension "ublock-origin-lite" "ddkjiahejlhfcafbddmgiahcphecmpfh"
install_extension "isdcac" "edibdbjcniadpccecjdfdjjppcpchdlm"
install_extension "nopecha" "dknlfmjaanfblgfdfebhijalfmhmjjjo"

# Fix permissions
chown -R browser:browser "$CRX_DIR" "$REGISTRY_DIR"
