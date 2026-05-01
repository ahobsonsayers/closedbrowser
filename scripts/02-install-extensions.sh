#!/usr/bin/env bash
set -euo pipefail

# install_extension <github-repo> <name>
install_extension() {
  EXTENSION_REPO="$1"
  EXTENSION_NAME="${2,,}" # make extensions name lowercase

  EXTENSION_URL=$(
    curl -s "https://api.github.com/repos/$EXTENSION_REPO/releases/latest" |
      jq -r '
				[
					.assets[] | select(
						.name | ascii_downcase |
						(contains("chrome") or contains("chromium"))
					)
				] |
				sort_by(.name) |
				.[0].browser_download_url
			'
  )

  if [[ -z $EXTENSION_URL ]]; then
    echo "ERROR: No chrome extension found for $EXTENSION_REPO" >&2
    exit 1
  fi

  # Download and unzip extension
  curl -sL --progress-bar "$EXTENSION_URL" -o "/tmp/$EXTENSION_NAME.zip"
  unzip -q "/tmp/$EXTENSION_NAME.zip" -d "/tmp/$EXTENSION_NAME"
  rm "/tmp/$EXTENSION_NAME.zip"

  # Find extension directory
  MANIFEST_PATH=$(find "/tmp/$EXTENSION_NAME" -name "manifest.json" | head -1)
  EXTENSION_DIR=$(dirname "$MANIFEST_PATH")

  # Move extension
  mv "$EXTENSION_DIR" "$GLOBAL_EXTENSIONS_DIR/$EXTENSION_NAME"
  rm -rf "/tmp/$EXTENSION_NAME"
}

# Create extensions directory
rm -rf "$GLOBAL_EXTENSIONS_DIR"
mkdir -p "$GLOBAL_EXTENSIONS_DIR"

install_extension "OhMyGuus/I-Still-Dont-Care-About-Cookies" "isdcac"
install_extension "NopeCHALLC/nopecha-extension" "nopecha"
