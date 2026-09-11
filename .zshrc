#zsh

function source_rc() {
  for rc in $1/*; do
    if [ -f $rc ]; then
      source $rc
    fi
  done
}

source_rc $HOME/.zshrc.d

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
