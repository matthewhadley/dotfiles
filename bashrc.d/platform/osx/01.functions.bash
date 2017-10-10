# show recently modified files using fd https://github.com/sharkdp/fd
recent() {
  fd -t f -0 . $1 | xargs -0 stat -f "%m%t%Sm %N" | sort -rn | head -n ${2:-20} | cut -f2-
}
