#!/bin/bash
# Sannysoft test

echo "Fetching..."
HTML=$(curl -s "http://localhost:3000/content" \
	-H "Content-Type: application/json" \
	-X POST \
	-d '{"url":"https://bot.sannysoft.com/","waitForTimeout":8000}')

echo "$HTML" | htmlq 'table:first-of-type tr' -t |
	sed '/^$/d;s/^[[:space:]]*//;s/[[:space:]]*$//' |
	awk 'NR%2==1{n=$0} NR%2==0{if(n&&$0&&n!="Test Name"&&$0!="Result")print n": "$0}'
