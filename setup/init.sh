#!/bin/bash
LINKS=('bash_profile' 'bashrc' 'gitconfig' 'gitignore' 'screenrc' 'vim' 'vimrc' 'mutt' 'editorconfig')

cd $HOME
DIR=".dotfiles"
if [ ! -d $DIR ]; then
  mkdir $DIR
fi
for i in "${LINKS[@]}"
do
  :
    if [ -h .$i ] || [ -f .$i ]; then
    rm .$i
  fi
  ln -s $DIR/$i .$i
done
echo ".dotfiles init'd"
