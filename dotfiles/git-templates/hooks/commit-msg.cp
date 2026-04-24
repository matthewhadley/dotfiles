#!/bin/bash
+MSG=$(head -1 "$1")

# commit message format (allow merge commit message)
if ! [[ $MSG =~ ^Merge.*|(feat|fix|chore|docs|style|refactor|test)(\([^\(^\)]+\))?:( ).* ]]; then
	echo "Rejected commit: message format"
	echo "<type>[optional scope]: <description>"
	echo "   \`feat|fix|chore|docs|style|refactor|test"
	echo "see: conventionalcommits.org"
	exit 1
fi
# commit message length
if [[ ${#MSG} -gt 70 ]]; then
	echo "Rejected commit: message length"
	echo "${MSG:0:70}..."
	exit 1
fi
