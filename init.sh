#!/bin/bash

# Get a reference to dotfiles location
dotfiles="$HOME/.dotfiles/dotfiles"

# Calculate dotfiles path lenth so it can be used to trim filepaths
len=${#dotfiles}
let len=$len+1
for f in $(find $dotfiles)
do :
  # Don't symlink directories
  if [ -d "$f" ];then continue; fi
  # Strip dotfiles path from file path
  file=${f:$len}
  # If file is nested, create the directory
  path=$(dirname $file)
  if [ "$path" != "." ];then
    mkdir -p $HOME/.$path
  fi
  # Create the symlink inside of $HOME
  ln -sf "$dotfiles/$file" "$HOME/.$file"
done

# vim
rm -rf $HOME/.vim
ln -s $HOME/.dotfiles/vim $HOME/.vim

echo ".dotfiles init'd"

# source all the bash
source $HOME/.dotfiles/dotfiles/bashrc
echo "sourced .dotfiles"
