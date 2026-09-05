# directory listing
alias ls='ls -G'
alias l='ls -lG'

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
alias gp='git push'
alias gl='git pull'
alias gpo='git push origin'
alias gpom='git push origin main'
alias glo='git pull origin'
alias glom='git pull origin main'
alias gfo='git fetch origin'
alias gfom='git fetch origin main'
alias gs='git status -sb'
alias ga='git add -A'
alias gf='git fetch'
alias grm='git rm'
alias gc='git commit -m'
alias gac='git add -A && git commit -m'
alias gb='git branch'
alias gbv='git branch -va'
alias gbD='git branch -D'
alias gd='git diff'
alias gdt='git difftool -y'
alias gch='git checkout'
alias gm='git merge'
alias gmom='git merge origin/main'
alias gmt='git mergetool'
alias grp='git remote prune'
alias gr='git remote'

# git merge branch - for local merging of feature branches into main, creates a merge commit even for a fast forward
alias gmb='git merge --no-ff'

# formatted git log
alias glog="git log --pretty=format:'%C(yellow bold)%h%Creset -%C(yellow bold)%d%Creset %s %C(white)%cr by %an%Creset' --abbrev-commit --date=relative"

# formatted git log branch pipe graphs
alias glg="git log --graph --pretty=format:'%C(yellow bold)%h%Creset -%C(yellow bold)%d%Creset %s %C(white)%cr by %an%Creset' --abbrev-commit --date=relative"

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
