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

# lead bashrc
source $HOME/.dotfiles/dotfiles/bashrc

if [ "$DOMAIN" = "osx" ];then
  # setup mutt
  rm -f ~/.mutt 2> /dev/null
  ln -s .dotfiles/mutt .mutt
fi

DIR="$HOME/bin"
rm -rf $DIR
mkdir $DIR
chflags hidden $DIR
cd $DIR
# ~/bin symlinks
ln -sf ~/dev/bash/git.corp.identity/git.corp.identity.sh git.corp.identity
ln -sf ~/dev/bash/git-ssh/git-ssh.sh git-ssh
ln -sf ~/dev/perl/cloc/cloc-1.56.pl cloc
ln -sf ~/dev/perl/git-moo/git-moo git-moo
ln -sf ~/dev/bash/bashbin/copykeys copykeys
ln -sf ~/dev/bash/bashbin/perms perms
if [ "$DOMAIN" = "osx" ];then
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

echo ".dotfiles init'd$bin (bin symlinks created)"
