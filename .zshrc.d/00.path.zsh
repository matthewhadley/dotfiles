# Path
function pathadd {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$1:$PATH"
  fi
}

# Note, edit /etc/paths to put local paths before global
# http://stackoverflow.com/questions/5364614/

# Homebrew - `brew shellenv` already ran in 00.env.zsh, which loads first.
# Re-running it here re-prepends /opt/homebrew/bin, which pushes ~/.local/bin
# back behind it -- so only the prefix is set. 01.completion.zsh reads it.
if [ -x /opt/homebrew/bin/brew ]; then
  BREW_PREFIX=/opt/homebrew
fi
