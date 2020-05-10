# https://code.google.com/p/iterm2/issues/detail?id=571
# http://stackoverflow.com/questions/3058325/what-is-the-difference-between-ps1-and-prompt-command
# http://stackoverflow.com/questions/1371261/get-current-directory-name-without-full-path-in-bash-script

# Git state in PS1
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1

# show 2 levels of directory listing for iterm2 tab
# check not running on local console
if [ "$(tty | grep pts | wc -l)" -ge "1" ];then
  DEV_PTS=1
fi
two_dirs() {
  if [[ "$PLATFORM" == "osx" || -n "$DEV_PTS" ]];then
    local home_sign="~" # rootbashrc uses "/root"
    local dir="${PWD%/*/*}"
    local last
    if [ "${#dir}" -gt 0 -a "$dir" != "$PWD" ];then
      last="${PWD:${#dir}+1}"
    else
      last="$PWD";
    fi
    if [ "$last" == "$HOME" ];then
      last="$home_sign"
    fi
    if [ "$(dirname "$last")" == "$USER" ];then
      last="$home_sign/${PWD##*/}"
    else
      if [[ "$(echo "$last" | cut -c 1)" != "/" && "$last" != "$home_sign" ]];then
        last="$last" # or ../$last if you want to indicate that at depth
      fi
    fi
    # show hostname if in ssh session
    if [ -n "$SSH_CLIENT" ]; then
      local hostname="[$HOSTNAME] "
    fi
    if [ ! -z "TTY_NUM" ]; then
      local tty_display=" $TTY_NUM "
    fi
    echo -ne "\033]0;${tty_display}${hostname}${last}\007"
  fi
}

prompt_command() {
  # save history as it's generated
  history -a
  if [ -z $PROMPT ];then
    two_dirs
  else
    echo -ne "\033]0;$PROMPT\007"
  fi
}

PROMPT_COMMAND="prompt_command"
