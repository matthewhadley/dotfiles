#!/bin/bash

# setup git submodules
cd $HOME/.dotfiles
git submodule init
git submodule update

DIR=".dotfiles/dotfiles"
cd $HOME
for i in $DIR/*
do :
  FILE=`basename "$i"`
  LINK="$i"
  if [ -h .$FILE ] || [ -f .$FILE ]; then
    rm .$FILE
  fi
  ln -s "$LINK" ".$FILE"
done

# setup mutt
if [ -h .$FILE ] || [ -f .$FILE ]; then
  rm .mutt
fi
ln -s ~/.dotfiles/mutt .mutt

source $HOME/.bashrc
echo ".dotfiles init'd"