#!/bin/bash

if [ "$1" != "local" ];then
  echo "Updating git submodules..."
  # setup git submodules
  owd=$PWD
  cd $HOME/.dotfiles
  git submodule update --init --recursive
  # git submodule foreach 'git fetch origin;git merge origin/master;git checkout master'
  cd $owd
fi

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

# ssh
mkdir -p $HOME/.ssh
cp $HOME/.dotfiles/ssh/config* $HOME/.ssh
chmod 0644 $HOME/.ssh/config*

if [ "$DOMAIN" = "osx" ];then
  # setup mutt
  rm -f $HOME/.mutt 2> /dev/null
  ln -s $HOME/.dotfiles/mutt $HOME/.mutt
fi

# Marks
mkdir -p $HOME/.marks

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
  ln -s $HOME/dev/bash/gitstate.sh /usr/local/bin/gitstate &> /dev/null
fi

echo ".dotfiles init'd"

# source all the bash
source $HOME/.dotfiles/dotfiles/bashrc
echo "sourced .dotfiles"

exit 0
