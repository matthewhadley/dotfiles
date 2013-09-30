# Keychain

if [ -f $HOME/.ssh/id_rsa ];then
  /usr/bin/keychain --quiet $HOME/.ssh/id_rsa
fi
if [ -f $HOME/.ssh/cl_id_rsa ];then
  /usr/bin/keychain --quiet $HOME/.ssh/cl_id_rsa
fi
if [ -f $HOME/.keychain/$HOSTNAME-sh ];then
  source $HOME/.keychain/$HOSTNAME-sh
fi
