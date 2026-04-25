#!/bin/bash

# Resolve dotfiles location relative to this script
dotfiles="$(cd "$(dirname "$0")" && pwd)/dotfiles"

# Calculate dotfiles path length so it can be used to trim filepaths
len=${#dotfiles}
let len=$len+1

for f in $(find "$dotfiles" -type f)
do :
  file=${f:$len}
  path=$(dirname "$file")
  if [ "$path" != "." ];then
    mkdir -p "$HOME/.$path"
  fi
  cp -f "$dotfiles/$file" "$HOME/.$file"
done

echo ".dotfiles init'd"
