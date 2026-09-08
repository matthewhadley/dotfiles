# directory listing -- macOS/BSD ls colours with -G, GNU and BusyBox with --color
if [[ $OSTYPE == darwin* ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi
alias l='ls -l'

# vim for vi
alias vi=vim

# Recursively delete `.DS_Store` files
alias rm.DS="find . -name '.DS_Store' -type f -ls -delete"

# npm
alias npm-public='npm --registry https://registry.npmjs.org'

# local webserver github.com/http-party/http-server
# localhost only without caching
alias hs="http-server -a 127.0.0.1 -c-1"

# git

# git updating
alias gp='git push'
alias gpom='git push origin main'
alias glo='git pull origin'
alias glom='git pull origin main'
alias gfo='git fetch origin'
alias gfom='git fetch origin main'

# getting, resetting, adding and committing
alias gcl='git clone'
alias gch='git checkout'
alias ga='git add -A'
alias gc='git commit -m'
alias gac='git add -A && git commit -m'

# git statuses
alias gs='git status -sb'
alias gb='git branch'
alias gbv='git branch -va'
alias gd='git diff'

# git merge branch - for local merging of feature branches into main, creates a merge commit even for a fast forward
alias gmb='git merge --no-ff'

# nvim, with the file tree only when there is no specific file to open.
#
#   nv                -> tree on the left, empty edit pane on the right
#   nv some/dir       -> same, rooted at that directory
#   nv path/file.txt  -> just the file, no tree
#
# A directory cannot be passed to nvim alongside +Neotree: the argument is
# consumed as the tree's own window and you get a single full-width tree. So for
# a directory we cd into it and launch with no path. cd'ing (rather than
# `Neotree dir=`) also points nvim's cwd at the target, so telescope and
# :Neotree agree on the project root. The subshell keeps the calling shell's cwd
# unchanged.
#
# Given files, the tree is deliberately skipped -- naming a file means you want
# that file, and the tree only costs width. Open it with \e when wanted.
#
# Was an alias; zsh expands an existing alias in the function-name position, so
# re-sourcing without this guard is a parse error.
unalias nv 2>/dev/null
nv() {
  [[ $1 == -- ]] && shift   # our own -- is added below; don't pass two
  if (( $# == 0 )); then
    nvim +Neotree
  elif (( $# == 1 )) && [[ -d $1 ]]; then
    ( cd -- "$1" && nvim +Neotree )
  else
    nvim -- "$@"
  fi
}
