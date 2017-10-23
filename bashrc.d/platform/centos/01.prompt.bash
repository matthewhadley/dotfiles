local prompt_color=$BLDBLU
local pre_prompt
if [ "$(id -u)" == "0" ]; then
  # running as root
  pre_prompt="$BLDRED\u$BLDWHT@$TXTDEF"
elif [ "$(whoami)" == "vagrant" ]; then
  # running as vagrant
  pre_prompt="$BLDGRE\u$BLDWHT@$TXTDEF"
fi
if [ "$(whoami)" == "vagrant" ]; then
  # disable git status in vagrant as it is slow on shared folders
  PS1="$pre_prompt$prompt_color\H:$BLDWHT \w$TXTDEF\n\$ "
else
  PS1="$pre_prompt$prompt_color\H:$BLDWHT \w\$(__git_ps1)$TXTDEF\n\$ "
fi
