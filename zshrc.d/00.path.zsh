# Path
function pathadd {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$1:$PATH"
  fi
}

# Note, edit /etc/paths to put local paths before global
# http://stackoverflow.com/questions/5364614/

#volta
export VOLTA_HOME="$HOME/.volta"
pathadd "$VOLTA_HOME/bin"

#yarn
pathadd "$HOME/.yarn/bin"
pathadd "$HOME/.config/yarn/global/node_modules/.bin"

#openjdk@11
pathadd /opt/homebrew/opt/openjdk@11/bin
