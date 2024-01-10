# get, set, delete keychain values
keychain() {
  key="$1"
  value="$2"

  if [[ "$value" == "null" ]]; then
    VALUE=$(/usr/bin/security delete-generic-password -s "$key" -a "$USER" 2>&1 >/dev/null)
    if [ $? -ne 0 ];then
      return 1
    fi
  elif [ -n "$value" ]; then
    /usr/bin/security add-generic-password -s "$key" -w "$value" -a "$USER" -U
  elif [ -n "$key" ]; then
    VALUE=$(/usr/bin/security find-generic-password -w -s "$key" 2>&1 >/dev/null)
    if [ $? -eq 0 ];then
      /usr/bin/security find-generic-password -w -s "$key" -a "$USER"
    else
      return 1
    fi
  fi
}

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
  stat -f '%A %N' "${=input}"
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

# show recently modified files using fd https://github.com/sharkdp/fd
# usage: recent [path] [number of results]
recent() {
  fd -t f -0 . $1 | xargs -0 stat -f "%m%t%Sm %N" | sort -rn | head -n ${2:-20} | cut -f2-
}

# rgh() {
#   rg $1 ~/.history.d
# }
