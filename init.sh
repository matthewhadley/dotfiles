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

# setup mutt
rm -f ~/.mutt 2> /dev/null
ln -s .dotfiles/mutt .mutt

source $HOME/.bashrc

if [ "$DOMAIN" = "local" ];then
  DIR="$HOME/bin"
  if [ ! -d $DIR ]; then
    mkdir $DIR
  fi
  cd $DIR
  ln -sf ~/dev/bash/git.corp.identity/git.corp.identity.sh git.corp.identity
  ln -sf ~/dev/perl/cloc/cloc-1.56.pl cloc
  ln -sf ~/dev/perl/git-moo/git-moo git-moo
  ln -sf ~/dev/bash/spark/spark spark
  ln -sf ~/dev/utils/jq/jq jq
  ln -sf /Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl sb
  ln -sf ~/dev/bash/git.dayone/git.dayone.sh git.dayone
  ln -sf ~/dev/python/gtasks/gtasks.py gtasks
  ln -sf ~/dev/python/keychain/keychain.py keychain
  ln -sf /Applications/openmeta openmeta

  bin=" (bin symlinks created)"
fi

echo ".dotfiles init'd$bin"