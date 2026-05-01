# https://code.google.com/p/iterm2/issues/detail?id=571
# http://stackoverflow.com/questions/3058325/what-is-the-difference-between-ps1-and-prompt-command
# http://stackoverflow.com/questions/1371261/get-current-directory-name-without-full-path-in-bash-script

# Git state in PS1
setopt PROMPT_SUBST
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats ' (%b%u%c)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a%u%c)'
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr ' *'
zstyle ':vcs_info:git:*' stagedstr ' +'

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
  if [[ ! -z "$TTY_NUM" ]]; then
    local tty_display=" $TTY_NUM "
  fi

  # set iterm tab display
  echo -ne "\033]0;${tty_display}${hostname}${last}\007"
}

prompt_command() {
  vcs_info
  two_dirs
  NEWLINE=$'\n'
  PROMPT="%F{white}%m: %~\${vcs_info_msg_0_}${NEWLINE}%F%(!.#.$) "
}
precmd() { prompt_command }

# do no use highlighted percent symbol at end of line
# unix.stackexchange.com/questions/167582/why-zsh-ends-a-line-with-a-highlighted-percent-symbol
PROMPT_EOL_MARK=''
