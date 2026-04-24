#!/bin/bash

# Get a reference to dotfiles location
dotfiles="$HOME/.dotfiles/dotfiles"

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
  # Files ending in .cp get copied (with .cp stripped), otherwise symlinked
  if [[ "$file" == *.cp ]];then
    target="${file%.cp}"
    cp -f "$dotfiles/$file" "$HOME/.$target"
  else
    ln -sf "$dotfiles/$file" "$HOME/.$file"
  fi
done

echo ".dotfiles init'd"
