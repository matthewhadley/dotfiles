# bash completion
# brew bash-completion package
if [[ -d $(brew --prefix)/etc/bash_completion.d/ ]]; then
  zstyle ':completion:*:*:git:*' script /usr/local/etc/bash_completion.d/git-completion.bash
  fpath=(~/usr/local/etc/bash_completion.d/ $fpath)
fi
