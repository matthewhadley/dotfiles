# directory listing
alias ls='ls -G'
alias l='ls -lG'

# vim for vi
alias vi=vim

# Recursively delete `.DS_Store` files
alias rm.DS="find . -name '.DS_Store' -type f -ls -delete"

# ripgrep
alias rg="rg --colors 'match:bg:yellow' --colors 'match:fg:black' --colors 'line:fg:white'"
rgh() {
  local args="$@"
  rg "$args" ~/.history.d
}

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
