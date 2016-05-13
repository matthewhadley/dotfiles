local prompt_color=$BLDBLU
if [ "$(id -u)" == "0" ];then
  # running as root
  local pre_prompt="$BLDRED\u$BLDWHT@$TXTDEF"
fi
if [ -n "$ARM_DEVICE" ];then
  # simpler PS1 for arm devices (beaglebone black, raspberry pi) that's less taxing on cpu
  PS1="$pre_prompt$prompt_color\h:$BLDWHT \w$TXTDEF\n\$ "
else
  PS1="$pre_prompt$prompt_color\h:$BLDWHT \w\$(__git_ps1)$TXTDEF\n\$ "
fi
