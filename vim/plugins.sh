#!/bin/bash

REPOS=(
  # better javascript syntax highlighting
  'jelera/vim-javascript-syntax'
  # eslint linting via ale
  'w0rp/ale'
  # editorconfig support
  'editorconfig/editorconfig-vim'
  # file tree explorer
  'scrooloose/nerdtree'
  # git gutter
  'airblade/vim-gitgutter'
  # multiple cursor editing (like sublime)
  'terryma/vim-multiple-cursors'
  # better block code commenting (key g-c)
  'tpope/vim-commentary'
  # fzf file searching
  'junegunn/fzf.vim'
  # show linked highlighting groups for cursor position (for colorschemes)
  'gerw/vim-HiLinkTrace'
)

# Using vim 8's native plugin loading
# add plugins to ~/.vim/pack/bundle[/start] for autostart
DIR="$HOME/.vim/pack/bundle/start"
rm -rf $DIR
for REPO in ${REPOS[@]}; do
  git clone --depth 1 git@github.com:${REPO}.git $DIR/${REPO#*/}
done
