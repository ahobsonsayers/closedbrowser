#!/usr/bin/env bash
# Sannysoft test - checks for bot detection flags

set -euo pipefail

BROWSER_URL="ws://localhost:3000/?stealth=true"
TEST_URL="https://bot.sannysoft.com/"

# Cleanup on exit
cleanup() { browser-use close 2>/dev/null || true; }
trap cleanup EXIT

browser-use close 2>/dev/null || true
browser-use --cdp-url "$BROWSER_URL" open "$TEST_URL"
sleep 5

HTML=$(browser-use get html)

echo "$HTML" | htmlq 'table:first-of-type tr' -t |
	sed '/^$/d;s/^[[:space:]]*//;s/[[:space:]]*$//' |
	awk 'NR%2==1{n=$0} NR%2==0{if(n&&$0&&n!="Test Name"&&$0!="Result")print n": "$0}'
