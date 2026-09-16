# Don't add commands that start with a space
setopt HIST_IGNORE_SPACE
# Don't add duplicate commands
setopt HIST_IGNORE_DUPS
# Append history instead of rewriting it
setopt appendhistory
# Immediately append to the history file, not just when a term is killed
setopt incappendhistory
# Add timestamps to history entries
setopt EXTENDED_HISTORY

# Allow a larger history file
SAVEHIST=1000000
HISTSIZE=1000000

# History per herdr pane, falling back to per-TTY.
#
# TTY_NUM (00.env.zsh) is the last two digits of the pty, and macOS allocates
# pty numbers from a low pool -- this machine has never gone past /dev/ttys028
# -- so every pane that has ever existed maps into one of ~30 buckets and new
# panes inherit unrelated old panes' history. That is observable, not
# theoretical: `herdr agent start` *types* `claude` into an agent pane's shell
# rather than spawning it as the pane's command, so it is recorded like
# anything typed, and it is usually the only command that pane ever runs.
# `claude` was the last line of 8 of the 31 buckets, which is why Up in a hunk
# or zsh pane offered it.
#
# HERDR_PANE_ID (w17:p2) is allocated from a per-workspace counter kept in
# ~/.config/herdr/session.json and is never reused: a workspace on its 25th
# pane has live numbers 2,5,6,15,18..23 -- gaps where panes closed -- and the
# counter still only goes up. So a pane keeps its own history for as long as it
# exists, across herdr restarts. The colon becomes a dash because it is legal
# in an APFS filename but Finder renders it as "/".
#
# TTY_NUM remains the fallback outside herdr, and is itself empty in a shell
# with no controlling terminal, because `tty` prints "not a tty" and its
# `cut -c11-` returns nothing -- without that last fallback HISTFILE would name
# the directory itself and those shells would silently record no history.
#
# Searching across panes is unaffected: rgh below has always read the whole
# directory rather than $HISTFILE.
mkdir -p "$HOME/.history.d"
HISTFILE="$HOME/.history.d/${${HERDR_PANE_ID//:/-}:-${TTY_NUM:-no-tty}}"

# ripgrep
alias rg="rg --colors 'match:bg:yellow' --colors 'match:fg:black' --colors 'line:fg:white'"
# Search every TTY's history, not just this shell's. `fc -AI` flushes the
# current session first so what you just typed is findable.
#
# Only the directory is passed. Naming $HISTFILE alongside it searched the
# current session's file twice -- it lives in there -- and errored out with
# exit 2 in any shell whose file did not exist yet, which defeated the
# $pipestatus check below.
#
# --color=always and --heading are forced because rg turns both off when it
# sees a pipe rather than a terminal, which is what the while-loop makes it.
#
# The case sorts rg's output into three line kinds:
#
#   1. A history entry. EXTENDED_HISTORY writes these as
#      ": <epoch>:<elapsed>;<command>", and in --heading mode nothing precedes
#      the ": " -- no escape codes, no line number -- so the leading ": " plus
#      a digit identifies one positively. Only then is it safe to cut at the
#      first ";", which is the record separator.
#   2. A filename heading. $HOME is shortened to "~".
#   3. Anything else: the continuation lines of a multi-line command, which
#      carry no record prefix, and rg's blank group separators. Printed as-is.
#
# Case 3 is why the test is anchored rather than just "*;*". About a tenth of
# the lines in ~/.history.d are continuations, 85 of them contain a semicolon
# of their own (jq filters, `for` loops), and a bare "*;*" cuts those at it --
# turning `map(select(length > 0) | gsub("..."; ""))` into ` ""))`.
#
# Note this stays line-oriented, so a match that falls on a continuation line
# still prints without the command it belongs to. Fixing that means treating
# an entry as a record rather than a line, which is a program, not a case
# statement. See atuin or zsh-histdb for tools that model it that way.
# --sort because rg searches the directory across threads and prints whichever
# file finishes first, so repeat searches came back in a different order each
# time. Sorting disables that parallelism, which costs nothing across 18 small
# files. "modified" is ascending, so the history file written most recently
# lands last -- closest to the prompt, where you are already looking.
#
# Leading flags are peeled off and everything after them is joined into one
# pattern, so `rgh git diff` searches for "git diff" rather than searching for
# "git" in a file called "diff" -- which is what rg does with a bare "$@", and
# it fails quietly because the resulting "No such file" goes to /dev/null.
# The limitation: a flag that takes a separate value (`-m 5`) stops the peel,
# because "5" does not start with "-", and would be swallowed into the pattern.
# Attached forms (-i, -w, -C2, -m5) are fine.
rgh() {
  fc -AI 2>/dev/null || true
  local -a flags
  while [[ ${1-} == -* ]]; do flags+=("$1"); shift; done
  (( $# )) || { print -u2 'rgh: no search pattern'; return 2 }
  rg --color=always --heading --no-line-number --sort modified \
     "${flags[@]}" -- "${(j: :)@}" ~/.history.d 2>/dev/null \
    | while IFS= read -r line; do
        case "$line" in
          ': '[0-9]*\;*)         printf '%s\n' "${line#*;}" ;;
          *"$HOME/.history.d/"*) printf '%s\n' "${line/$HOME/~}" ;;
          *)                     printf '%s\n' "$line" ;;
        esac
      done
  # The while-loop is the last command in the pipeline, so $? would be its
  # status -- always 0. Report rg's instead, so `rgh foo && ...` still means
  # "found something", as it did before the pipeline existed.
  return $pipestatus[1]
}
