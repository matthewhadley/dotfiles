#!/bin/bash

if [ "$1" == "all" ];then
  echo "Updating git submodules..."
  # setup git submodules
  owd=$PWD
  cd $HOME/.dotfiles
  git submodule update --init --recursive
  git submodule foreach 'git fetch origin;git merge origin/master;git checkout master'
  cd $owd
fi

for i in $HOME/.dotfiles/dotfiles/*
do :
  FILE=`basename "$i"`
  LINK="$i"
  ln -sf "$LINK" "$HOME/.$FILE"
done

# # ssh
mkdir -p $HOME/.ssh
cp $HOME/.dotfiles/ssh/config* $HOME/.ssh

if [ "$DOMAIN" = "osx" ];then
  # setup mutt
  rm -f $HOME/.mutt 2> /dev/null
  ln -s $HOME/.dotfiles/mutt $HOME/.mutt
fi

# vim
rm -rf $HOME/.vim
ln -s $HOME/.dotfiles/vim $HOME/.vim

# warn about bash-completion package not installed
bash_warn="warn: package bash completion not present"
if [[ "$DOMAIN" = "osx" && ! -f /usr/local/etc/bash_completion ]]; then
  echo $bash_warn
fi
if [[ "$DOMAIN" = "centos" && ! -f /etc/bash_completion ]]; then
  echo $bash_warn
fi

# symlinks
if [ "$DOMAIN" = "osx" ];then
  ln -s $HOME/dev/python/keychain/keychain.py /usr/local/bin/keychain &> /dev/null
fi

echo ".dotfiles init'd"

# source all the bash
source $HOME/.dotfiles/dotfiles/bashrc
echo "sourced .dotfiles"

exit 0
