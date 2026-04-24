# Path
function pathadd {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$1:$PATH"
  fi
}

# Note, edit /etc/paths to put local paths before global
# http://stackoverflow.com/questions/5364614/

# Homebrew - ensure homebrew binaries take precedence over macOS built-ins
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
