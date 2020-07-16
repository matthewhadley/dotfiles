# Path
function pathadd {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$1:$PATH"
  fi
}

# This formula is keg-only, which means it was not symlinked into /usr/local,
# because this is an alternate version of another formula.
pathadd "/usr/local/opt/node@14/bin"
pathadd "/usr/local/opt/openjdk/bin"

#yarn
pathadd "$HOME/.yarn/bin"
pathadd "$HOME/.config/yarn/global/node_modules/.bin"

# homebrew
pathadd "/usr/local/sbin"
pathadd "/usr/local/bin"

# Note, edit /etc/paths to put local paths before global
# http://stackoverflow.com/questions/5364614/
