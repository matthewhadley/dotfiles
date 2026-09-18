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
# Matches are painted in the same yellow as a search hit in Neovim: #FFE066 on
# #202020, the Search group theme_tweaks() sets in ~/.config/nvim/init.lua. Not
# terafox's own Search, which is a teal and reads as a selection -- the nvim
# config has its own note on why. Copied as a hex rather than shared, because
# nothing reads that Lua from a shell; if the yellow moves, it moves twice.
#
# rg is not asked to draw it. Truecolor is spelled "\e[48;2;255;224;102m" and
# those semicolons collide with the record separator: the entry branch below
# cuts at the first ";", and a match landing on the epoch or elapsed digits
# would put the escape ahead of the real separator and cut the line inside it.
# The old "match:bg:yellow" got away with a semicolon-free "\e[43m", but that
# is the 16-colour palette, and which yellow it actually is belongs to the
# terminal, not here.
#
# So rg draws a plain underline instead -- "match:none" first, to discard the
# bg/fg the alias injected at parse time, since later --colors win -- and that
# marker is swapped for the real colours on the way out. It is exactly
# "\e[0m\e[4m", carries no semicolons, and appears nowhere else in the output.
#
# Which is why the case below assigns and a single printf closes the loop,
# rather than each branch printing for itself: the cut runs first, on a line
# whose only escapes are semicolon-free, and the substitution happens after it.
# The trailing "\e[0m" rg already emits closes the highlight.
#
# The filename headings are #73a3b7, replacing rg's default magenta. That is
# terafox's blue.bright, palette 12 in its Ghostty theme, and the shade terafox
# itself gives functions and titles -- which is what a heading is. The base
# blue, #5a93aa at palette 4, is the same hue a step darker and sits too close
# to the body text to separate at a glance.
#
# Since rg has no name for a bright colour, only the eight base ones, this has
# to be a decimal triple. That costs the property a name would have had: it no
# longer follows the theme, so it joins the match yellow as a second hex to
# revisit if terafox is ever swapped out.
#
# The semicolons in "\e[38;2;115;163;183m" are harmless here, unlike in the
# match colour above. A heading never reaches the record cut -- that branch is
# anchored on a leading ": ", and a coloured heading starts with the escape.
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
#      carry no record prefix, and rg's blank group separators. These need no
#      rewriting, so the case has no third branch and they fall through to the
#      printf untouched.
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
  # $'...' does not expand inside the double quotes around the printf argument,
  # so both sequences are built here and referenced as plain parameters there.
  local mark=$'\e[0m\e[4m'
  local hl=$'\e[0m\e[38;2;32;32;32m\e[48;2;255;224;102m'
  rg --colors 'match:none' --colors 'match:style:underline' \
     --colors 'path:fg:115,163,183' \
     --color=always --heading --no-line-number --sort modified \
     "${flags[@]}" -- "${(j: :)@}" ~/.history.d 2>/dev/null \
    | while IFS= read -r line; do
        case "$line" in
          ': '[0-9]*\;*)         line=${line#*;} ;;
          # The "~" is quoted: this is an assignment now rather than an
          # argument to printf, so an unquoted one is a filename-expansion
          # tilde and turns straight back into $HOME.
          *"$HOME/.history.d/"*) line=${line/$HOME/'~'} ;;
        esac
        printf '%s\n' "${line//$mark/$hl}"
      done
  # The while-loop is the last command in the pipeline, so $? would be its
  # status -- always 0. Report rg's instead, so `rgh foo && ...` still means
  # "found something", as it did before the pipeline existed.
  return $pipestatus[1]
}

# Ctrl+Shift+R: the same every-pane history as rgh, but fuzzy and interactive,
# with the chosen line placed on the command line rather than printed.
#
# Ctrl+R is left alone. fzf binds it to fzf-history-widget, which runs `fc -rl 1`
# against zsh's in-memory list -- this pane's $HISTFILE as loaded at startup plus
# what has been typed since, and nothing else, since share_history is off. That
# narrowness is the point of the per-pane HISTFILE above, so it keeps its key.
#
# The chord arrives as F7, not as itself: Shift is not encoded in a C0 control
# byte, so Ctrl+Shift+R and Ctrl+R are both 0x12 and indistinguishable here.
# ~/.config/ghostty/config rewrites it to \e[18~ upstream. Consequence worth
# knowing: this key is Ghostty-only, so it does nothing over ssh or in another
# terminal, where Ctrl+R still works.
#
# `fc -AI` first, same as rgh, so commands from this session are findable
# immediately rather than at shell exit.
#
# Entries are parsed rather than grepped. EXTENDED_HISTORY writes
# ": <epoch>:<elapsed>;<command>", so the epoch gives a true global ordering
# across files -- concatenating them in filename or mtime order would interleave
# panes wrongly. Sorted newest-first, then deduplicated, so the surviving copy of
# a repeated command is its most recent use.
#
# Same limitation as rgh, for the same reason: a multi-line command is stored
# with its continuation lines carrying no record prefix, so only the first line
# is offered. Anchoring on that prefix is what keeps a semicolon inside a jq
# filter from being mistaken for the record separator.
#
# --no-sort keeps that recency order when the query is empty; fzf would
# otherwise impose its own. --scheme=history tunes the scoring for command
# lines. The current buffer seeds --query, matching what fzf's own Ctrl+R does.
#
# No --reverse, so fzf's default layout applies: the prompt sits at the bottom
# and the list grows upward from it. That pairs with the newest-first ordering
# above to put the most recent command immediately above the prompt, where the
# cursor already is -- and it matches where Ctrl+R puts its prompt, so the two
# keys do not move the box around between them.
_fzf_all_history() {
  emulate -L zsh
  fc -AI 2>/dev/null || true

  local selected
  selected=$(
    # LC_ALL=C throughout: ~/.history.d holds at least one line of invalid
    # UTF-8, and macOS awk aborts the record with "towc: multibyte conversion
    # failure" when it meets one -- a warning that would land on the prompt on
    # every press. Byte semantics sidestep the decode entirely; nothing here
    # case-folds or counts characters, so there is nothing to lose by it, and
    # fzf does its own UTF-8 handling downstream.
    LC_ALL=C cat -- ${HOME}/.history.d/*(.N) 2>/dev/null \
      | LC_ALL=C awk '
          /^: [0-9]+:[0-9]*;/ {
            ts = substr($0, 3)
            sub(/:.*/, "", ts)
            cmd = substr($0, index($0, ";") + 1)
            if (cmd != "") printf "%s\t%s\n", ts, cmd
          }
        ' \
      | LC_ALL=C sort -rn -k1,1 \
      | LC_ALL=C cut -f2- \
      | LC_ALL=C awk '!seen[$0]++' \
      | fzf --scheme=history --no-sort --height=60% \
            --prompt='all history > ' --query="$BUFFER"
  )

  if [[ -n $selected ]]; then
    BUFFER=$selected
    CURSOR=$#BUFFER
  fi

  # Redraw unconditionally: fzf has painted over the prompt whether or not
  # anything was chosen, so an escape out of it needs the line back too.
  zle reset-prompt
}
zle -N _fzf_all_history
bindkey '\e[18~' _fzf_all_history
