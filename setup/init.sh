#!/bin/bash

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
ln -s ~/.dotfiles/mutt .mutt

source $HOME/.bashrc
echo ".dotfiles init'd"