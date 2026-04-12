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

GLOBAL_EXTENSIONS="$(get_extension_directories "$EXTENSIONS_DIR")"
USER_EXTENSIONS="$(get_extension_directories "$DATA_DIR/extensions")"

ALL_EXTENSIONS="${GLOBAL_EXTENSIONS}${USER_EXTENSIONS}"
ALL_EXTENSIONS="${ALL_EXTENSIONS%,}" # Strip trailing comma

# Filter out --enable-automation flag that exposes automation
FILTERED_ARGS=()
for arg in "$@"; do
	if [[ "$arg" != "--enable-automation" ]]; then
		FILTERED_ARGS+=("$arg")
	fi
done

CHROME_REAL="$(dirname "$0")/chrome.real"

if [[ -n $ALL_EXTENSIONS ]]; then
	exec "$CHROME_REAL" --load-extension="$ALL_EXTENSIONS" "${FILTERED_ARGS[@]}"
fi

exec "$CHROME_REAL" "${FILTERED_ARGS[@]}"
