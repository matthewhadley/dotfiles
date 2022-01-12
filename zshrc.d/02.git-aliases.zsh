# channel git calls
hash git 2>&- && { export GIT_PATH=$(which git); }

function git(){
  if [[ "$1" == "commit" || "$1" == "clone" ]];then
    # let git.corp proxy git cmd
    $GIT_CORP "$@"
  else
    $GIT_PATH "$@"
  fi
}
# git
alias gp='git push'
alias gl='git pull'
alias gpo='git push origin'
alias gpom='git push origin master'
alias glo='git pull origin'
alias glom='git pull origin master'
alias gfo='git fetch origin'
alias gfom='git fetch origin master'
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
alias gmom='git merge origin/master'
alias gmt='git mergetool'
alias grp='git remote prune'
alias gr='git remote'

# git merge branch - for local merging of feature branches into master, creates a merge commit even for a fast forward
alias gmb='git merge --no-ff'

# formatted git log
alias gl="git log --pretty=format:'%C(yellow bold)%h%Creset -%C(yellow bold)%d%Creset %s %C(white)%cr by %an%Creset' --abbrev-commit --date=relative"

# formatted git log branch pipe graphs
alias glg="git log --graph --pretty=format:'%C(yellow bold)%h%Creset -%C(yellow bold)%d%Creset %s %C(white)%cr by %an%Creset' --abbrev-commit --date=relative"
