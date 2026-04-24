# zsh completion

if [ -n "$BREW_PREFIX" ]; then
  FPATH=$BREW_PREFIX/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi

# superuser.com/questions/1092033/how-can-i-make-zsh-tab-completion-fix-capitalization-errors-for-directories-and/1092328
# tab completion capital letters also match small letters
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
