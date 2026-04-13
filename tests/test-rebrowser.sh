#!/usr/bin/env bash
# Rebrowser test - checks for bot detection flags

set -euo pipefail

BROWSER_URL="ws://localhost:3000/?stealth=true"
TEST_URL="https://bot-detector.rebrowser.net/"

# Cleanup on exit
cleanup() { browser-use close 2>/dev/null || true; }
trap cleanup EXIT

browser-use close 2>/dev/null || true
browser-use --cdp-url "$BROWSER_URL" open "$TEST_URL"
sleep 3

HTML=$(browser-use get html)

echo "$HTML" | htmlq 'table#detections-table tbody tr' -t |
	grep -oP '^[⚪🟢🔴] [^[:space:]]+' |
	sed 's/[0-9.]*$//' |
	while read line; do
		emoji=${line:0:1}
		test=${line:2}
		case "$emoji" in
		"🟢") echo "✅ PASS: $test" ;;
		"🔴") echo "❌ FAIL: $test" ;;
		"⚪") echo "⚪ INFO: $test" ;;
		esac
	done
