#!/bin/bash

# Get a reference to dotfiles location
dotfiles="$HOME/.dotfiles/dotfiles"

# Calculate dotfiles path length so it can be used to trim filepaths
len=${#dotfiles}
let len=$len+1

# First pass: handle .ln directories (symlink whole directory)
for d in $(find "$dotfiles" -maxdepth 1 -type d -name "*.ln")
do :
  dir=${d:$len}
  target="${dir%.ln}"
  rm -rf "$HOME/.$target"
  ln -sf "$dotfiles/$dir" "$HOME/.$target"
done

# Second pass: handle individual files (skip .ln directories entirely)
for f in $(find "$dotfiles" -name "*.ln" -prune -o -type f -print)
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
