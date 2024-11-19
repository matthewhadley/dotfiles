# bash completion

autoload -U compinit
compinit

# brew bash-completion package
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

# superuser.com/questions/1092033/how-can-i-make-zsh-tab-completion-fix-capitalization-errors-for-directories-and/1092328
# tab completion capital letters also match small letters
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
