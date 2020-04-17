# Path
function pathadd {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$1:$PATH"
  fi
}

pathadd "/usr/local/sbin"
pathadd "/usr/local/bin"
pathadd "/usr/local/opt/node@12/bin"
pathadd "/usr/local/opt/openjdk/bin"

# Note, edit /etc/paths to put local paths before global
# http://stackoverflow.com/questions/5364614/
