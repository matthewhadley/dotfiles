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
  ln -sf "$LINK" ".$FILE"
done

if [ "$DOMAIN" = "osx" ];then
  # setup mutt
  rm -f ~/.mutt 2> /dev/null
  ln -s .dotfiles/mutt .mutt
fi

# vim
rm -rf $HOME/.vim
ln -s $HOME/.dotfiles/vim $HOME/.vim

# ~/bin symlinks
DIR="$HOME/bin"
rm -rf $DIR
mkdir $DIR
cd $DIR
ln -sf ~/dev/bash/git.corp/git.corp.sh git.corp
ln -sf ~/dev/bash/git-ssh/git-ssh.sh git-ssh
ln -sf ~/dev/perl/cloc/cloc-1.56.pl cloc
ln -sf ~/dev/perl/git-moo/git-moo git-moo
ln -sf ~/dev/bash/bashbin/copykeys copykeys
ln -sf ~/dev/bash/bashbin/perms perms
if [ "$DOMAIN" = "osx" ];then
  # hide ~/bin
  chflags hidden $DIR
  # osx only ~/bin symlinks
  ln -sf /Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl sb
  ln -sf ~/dev/bash/git.dayone/git.dayone.sh git.dayone
  ln -sf ~/dev/python/gtasks/gtasks.py gtasks
  ln -sf ~/dev/python/keychain/keychain.py keychain
  ln -sf /Applications/openmeta openmeta
  ln -sf ~/dev/bash/bashbin/sbp sbp
  ln -sf ~/dev/bash/bashbin/tp tp
  ln -sf ~/dev/bash/bashbin/tpadd tpadd
fi

# clone git/ssh
DIR="$HOME/dev/bash"
mkdir -p "$DIR"
cd $DIR
if [ ! -d "$DIR/git.corp" ];then
  git clone git@github.com:diffsky/git.corp.git
fi
if [ ! -d "$DIR/git-ssh" ];then
  git clone git@github.com:diffsky/git-ssh.git
fi
if [ ! -d "$DIR/git.channel" ];then
  git clone git@github.com:diffsky/git.channel.git
fi

# lead bashrc
source $HOME/.dotfiles/dotfiles/bashrc

echo ".dotfiles init'd$bin (bin symlinks created)"
