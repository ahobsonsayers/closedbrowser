#!/bin/bash

get_extension_directories() {
  local EXTENSIONS_DIRECTORY="$1"
  local EXTENSION_DIRECTORIES=""

  for EXTENSION_DIRECTORY in "$EXTENSIONS_DIRECTORY"/*; do

    # Skip directories that have no manifest.json
    [[ -f "$EXTENSION_DIRECTORY/manifest.json" ]] || continue

    EXTENSION_DIRECTORIES="$EXTENSION_DIRECTORIES$EXTENSION_DIRECTORY,"

  done

  echo "$EXTENSION_DIRECTORIES"
}

GLOBAL_EXTENSIONS="$(get_extension_directories "$GLOBAL_EXTENSIONS_DIR")"
USER_EXTENSIONS="$(get_extension_directories "$USER_EXTENSIONS_DIR")"

ALL_EXTENSIONS="${GLOBAL_EXTENSIONS}${USER_EXTENSIONS}"
ALL_EXTENSIONS="${ALL_EXTENSIONS%,}" # Strip trailing comma

if [[ -n $ALL_EXTENSIONS ]]; then
  exec brave-browser --no-sandbox --load-extension="$ALL_EXTENSIONS" "$@"
fi

exec brave-browser --no-sandbox "$@"
