# stackoverflow.com/questions/23128353/zsh-shortcut-ctrl-a-not-working
bindkey -e

# allow #comments in shell
setopt interactivecomments

# Get TTY number, last 2 digits
TTY_NUM=$(tty|cut -c11-)

# Prevent tar include "._" file resource forks
export COPYFILE_DISABLE=true

# Editor. Both point at nvim. EDITOR was vim for a while, on the reasoning that
# VISUAL is what most tools check first so nvim would win anyway -- but the
# tools that read only EDITOR then get vim, and each one needs its own override:
# yazi's edit opener is hardcoded to ${EDITOR:-vi} and never looks at VISUAL,
# lazygit's `e` is the same. Setting both retires that class of workaround.
#
# Nothing is lost by it: typing `vim` or `vi` runs those binaries directly and
# never consults either variable.
export EDITOR=nvim
export VISUAL=nvim

# lazygit resolves its config dir through adrg/xdg: ~/.config on Linux, but
# ~/Library/Application Support on macOS. The config is tracked at the Linux
# path so one file serves both, and this points macOS at it.
#
# Guarded on the file existing rather than on the OS: LG_CONFIG_FILE is
# error-if-missing, so an unconditional export would turn a missing config into
# a hard failure instead of lazygit falling back to its defaults.
if [ -f "$HOME/.config/lazygit/config.yml" ]; then
  export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
fi

# Keep both arrays free of duplicates, first occurrence winning. This is here
# for `brew shellenv` below, which is not idempotent and does not always know
# to skip itself: it emits
#
#   fpath[1,0]="/opt/homebrew/share/zsh/site-functions";
#   export FPATH;
#   export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
#
# and short-circuits to no output only when /opt/homebrew/bin is *first* on
# PATH. pathadd below deliberately moves ~/.local/bin in front of it, so every
# nested zsh re-runs the whole block: without -U, `zsh` inside `zsh` gained one
# fpath entry and two PATH entries per level, without limit.
#
# It also matters for more than tidiness. `export FPATH` on line 2 above means
# a child inherits the list, so an un-deduped nested shell ends up with an
# fpath that a compinit dump built by a top-level shell does not match -- and
# compinit answers a mismatch by rebuilding the dump, which is the ~250ms
# mistake 01.completion.zsh exists to avoid. With -U every depth converges on
# the same fpath and the dump is shared.
#
# -g is not optional. .zshrc sources these fragments from inside the source_rc
# function, so a bare `typeset` would declare locals that shadow path and fpath
# for the rest of the loop -- brew shellenv's exports would land in the shadow
# and vanish with it, leaving the shell with a four-entry PATH and no homebrew.
typeset -gU path fpath

# Path
function pathadd {
  if [[ -d "$1" ]]; then
    # Move existing entries to the front too, including after brew shellenv.
    path=("$1" "${(@)path:#"$1"}")
  fi
}

# Homebrew - ensure homebrew binaries take precedence over macOS built-ins
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# After brew, deliberately: both pathadd and `brew shellenv` prepend, so
# whichever runs last ends up in front. This is what puts ~/.local/bin ahead of
# /opt/homebrew/bin.
pathadd "$HOME/.local/bin"
