# https://code.google.com/p/iterm2/issues/detail?id=571
# http://stackoverflow.com/questions/3058325/what-is-the-difference-between-ps1-and-prompt-command
# http://stackoverflow.com/questions/1371261/get-current-directory-name-without-full-path-in-bash-script

# Git state in PS1
setopt PROMPT_SUBST
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
source $(brew --prefix)/etc/bash_completion.d/git-prompt.sh

two_dirs() {
  # show 2 levels of directory listing for iterm2 tab
  local dir="${PWD%/*/*}"
  local last
  if [ "${#dir}" -gt 0 -a "$dir" != "$PWD" ];then
    last="${PWD:${#dir}+1}"
  else
    last="$PWD";
  fi
  if [[ "$last" == "$HOME" ]];then
    last="~"
  fi
  if [[ "$(dirname "$last")" == "$USER" ]];then
    last="~/${PWD##*/}"
  else
    if [[ "$(echo "$last" | cut -c 1)" != "/" && "$last" != "~" ]];then
      last="$last" # or ../$last if you want to indicate that at depth
    fi
  fi
  # show hostname if in ssh session
  if [[ -n "$SSH_CLIENT" ]]; then
    local hostname="[$HOSTNAME] "
  fi
  if [[ ! -z "TTY_NUM" ]]; then
    local tty_display=" $TTY_NUM "
  fi

  # set iterm tab display
  echo -ne "\033]0;${tty_display}${hostname}${last}\007"
}

prompt_command() {
  two_dirs
  # set prompt
  NEWLINE=$'\n'
  PROMPT="%F{white}%m: %~$(__git_ps1)${NEWLINE}%F%(!.#.$) "
}
# have zsh call prompt_command for prompt setting
precmd() { prompt_command }

# do no use highlighted percent symbol at end of line
# unix.stackexchange.com/questions/167582/why-zsh-ends-a-line-with-a-highlighted-percent-symbol
PROMPT_EOL_MARK=''
