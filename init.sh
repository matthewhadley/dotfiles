#!/bin/bash
set -euo pipefail

dotfiles="$(cd "$(dirname "$0")" && pwd)/dotfiles"

find "$dotfiles" -type f -print0 | while IFS= read -r -d '' f; do
  file="${f#"$dotfiles/"}"
  path="$(dirname "$file")"
  if [[ "$path" != "." ]]; then
    mkdir -p "$HOME/.$path"
  fi
  cp -f "$dotfiles/$file" "$HOME/.$file"
done

echo ".dotfiles init'd"
