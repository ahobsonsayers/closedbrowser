#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$DATA_DIR" "$DOWNLOAD_DIR" "$EXTENSIONS_DIR"
chown -R blessuser:blessuser "$DATA_DIR" "$DOWNLOAD_DIR" "$EXTENSIONS_DIR"
