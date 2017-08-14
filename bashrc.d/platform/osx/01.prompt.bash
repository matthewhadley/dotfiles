local prompt_color=$BLDWHT
if [ ! -z "$NAVE" ]; then
  NAVE_VERSION=" $BLDRED(NAVE $NAVE)$TXTDEF"
fi
PS1="$prompt_color\h: \w\$(__git_ps1)$TXTDEF$NAVE_VERSION\n\$ "
