#!/bin/bash
LINKS=('bash_profile' 'bashrc' 'gitconfig' 'gitignore' 'screenrc' 'vim' 'vimrc' 'mutt')

cd $HOME
DIR=".dotfiles"
if [ ! -d $DIR ]; then
  mkdir $DIR
fi
for i in "${LINKS[@]}"
do
  :
  rm .$i
  ln -s $DIR/$i .$i
done
echo ".dotfiles init'd"