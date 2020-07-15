#  display file/directory permissions in octal format
perms() {
  # default to all visible files/directories
  local input=(*);
  if [ ! -z "$1" ]; then
    input=$@
  fi
  # check to also show hidden files/directories
  if [[ "$1" == "-a" ]]; then
    input=(.* *)
  fi
  if [[ "$(uname)" == "Darwin" ]]; then
    stat -f '%A %N' "${=input}"
  else
    stat -c '%A %a %n' $input 2>/dev/null
  fi
}

# remove known_hosts entry
unknow_host() {
  if [[ -z "$1" ]];then
    echo "error: missing hostname"
    return
  fi
  echo "removing host $1"
  ssh-keygen -R $1 &>/dev/null
}

# cd to parent directory of symlinked file
cds() {
  local realpath=$(readlink $1)
  cd $(dirname "$realpath")
}

# make a directory and cd into it
md() {
  mkdir -p "$@" && cd "$@";
}
