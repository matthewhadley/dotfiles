# reveal a function defintion and where it is defined
whence() {
  shopt -s extdebug;declare -F $1;shopt -u extdebug
  type -a $1
}

# show recently modified files using fd https://github.com/sharkdp/fd
# usage: recent [path] [number of results]
recent() {
  fd -t f -0 . $1 | xargs -0 stat -f "%m%t%Sm %N" | sort -rn | head -n ${2:-20} | cut -f2-
}

# anybar
anybar() {
  echo -n $1 | nc -4u -w0 localhost ${2:-1738}
}
