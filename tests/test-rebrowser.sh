#!/bin/bash
# Rebrowser test

echo "Fetching..."
HTML=$(curl -s "http://localhost:3000/content?headless=false" \
	-H "Content-Type: application/json" \
	-X POST \
	-d '{"url":"https://bot-detector.rebrowser.net/","waitForTimeout":5000}')

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
