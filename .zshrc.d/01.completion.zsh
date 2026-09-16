# zsh completion

# The only compinit in this directory, deliberately. A second call used to live
# in 00.env.zsh, gated on HOMEBREW_PREFIX where this one gates on BREW_PREFIX --
# both are /opt/homebrew, so both ran. That cost ~550ms of a ~590ms startup, and
# not because compinit is inherently slow: each call prepended zsh-completions
# to FPATH again, so the second saw an fpath ~/.zcompdump did not match and
# rebuilt it, leaving a dump the *first* call then rejected on the next startup.
# Every shell rebuilt the dump twice, forever. One call, stable fpath, dump
# reused: ~48ms.
#
# So if this ever needs to move, move it -- do not add a second one.
if [ -n "$BREW_PREFIX" ]; then
  # Idempotent, in the style of pathadd in 00.env.zsh. zsh marks FPATH exported
  # when it finds it in the environment at startup, so a plain prepend adds a
  # copy per nesting level -- and a nested shell's fpath then differs from a
  # top-level one's, which is precisely the mismatch that sends compinit off to
  # rebuild the dump. herdr panes never saw this (the herdr server's own
  # environment carries no FPATH, so each pane starts clean), but `zsh` inside
  # `zsh` is common enough to be worth closing.
  _zsh_completions=$BREW_PREFIX/share/zsh-completions
  fpath=("$_zsh_completions" "${(@)fpath:#"$_zsh_completions"}")
  unset _zsh_completions

  autoload -Uz compinit
  compinit
fi

# superuser.com/questions/1092033/how-can-i-make-zsh-tab-completion-fix-capitalization-errors-for-directories-and/1092328
# tab completion capital letters also match small letters
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
