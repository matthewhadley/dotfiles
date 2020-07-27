# bash completion

autoload -U compinit
compinit

# brew bash-completion package
if [[ -d $(brew --prefix)/etc/bash_completion.d/ ]]; then
  zstyle ':completion:*:*:git:*' script /usr/local/etc/bash_completion.d/git-completion.bash
  fpath=(~/usr/local/etc/bash_completion.d/ $fpath)
fi

# superuser.com/questions/1092033/how-can-i-make-zsh-tab-completion-fix-capitalization-errors-for-directories-and/1092328
# tab completion capital letters also match small letters
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
