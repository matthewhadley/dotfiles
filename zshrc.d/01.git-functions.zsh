# git functions

# Determine if a git repo has uncomitted changes in it
parse_git_dirty() {
  # Requires git 1.8. ver 1.7 responds with "no changes added "
  [[ "$(git status 2> /dev/null | tail -n1 | cut -c 1-17)" != "nothing to commit" ]] && echo "*"
}

# Get the git branch name of current directory and wrap in parens if exists (for PS1)
parse_git_branch() {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/ (\1$(parse_git_dirty))/"
}

# echo git branch of current directory
get_git_branch() {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

# git push origin branch
gpob() {
  git push origin $(get_git_branch)
}

# git pull origin branch
glob() {
  git pull origin $(get_git_branch)
}

# git squash all commits on current branch
# gsqa "msg"      <- squash against current branch origin...BRANCH
# gsqa NUM "msg"  <- squash N commits
# gsqa REF "msg"  <- squash against REF...BRANCH (where REF can be BRANCH or ALIAS/BRANCH)
gsqa() {
  local msg
  local count
  local branch
  if [ $# -eq "0" ];then
    echo "missing commit message"
    return
  elif [ $# -eq "1" ];then
    msg="$1"
    branch="$(get_git_branch)"
    # default to compare revisions against origin of current branch
    count=$(git rev-list --count origin/$branch...$branch)
  elif [ $# -eq "2" ];then
    msg="$2"
    if [[ $1 =~ ^-?[0-9]+$ ]]; then
      # $1 is exact number of commits to squash
      count="$1"
    else
      # $2 is REF to compare revisions against
      count=$(git rev-list --count $1...$(get_git_branch))
    fi
  else
    echo "unexpected number of arguments"
    return
  fi
  git reset --soft HEAD~$count && git add -A . && git commit -m "$msg"
}

# git fetch pull request
gfpr() {
  local remote='origin'
  if [ ! -z "$2" ];then
    remote=$2
  fi
  git show-ref --verify --quiet refs/heads/pr-$1
  if [[ $? == 0 ]];then
    echo "error: pr branch already exists"
    git checkout pr-$1
    return
  fi
  echo "attempting to fetch pull request for $remote pull/$1/head:pr-$1"
  git fetch $remote pull/$1/head:pr-$1
  git checkout pr-$1
}

# git fetch upstream pull request
gfpru() {
  if [ -z "$1" ];then
    echo "error: no pr number specified"
  else
    gfpr $1 "upstream"
  fi
}

# github unpublish branch
gunpb() {
  local oifs=$IFS
  IFS='/'
  local branch=($1)
  IFS=$oifs
  git push ${branch[0]} --delete ${branch[1]}
}

# rebase remote
glr() {
  git fetch origin && git rebase --rebase-merges origin/$(get_git_branch)
}

# ghi (https://github.com/stephencelis/ghi) with CORP support
ghi() {
  local GIT_CORP_ORG=$(git config --global corp.org)
  local TOKEN_TYPE="GHI_TOKEN"
  if [ ! -z "$GIT_CORP_ORG" ]; then
    local CONFIG=$(git rev-parse --show-toplevel 2> /dev/null)
    if [ -f ${CONFIG}/.git/config ];then
      IFS=';' read -r ADDR <<< "$GIT_CORP_ORG"
      for i in "${ADDR[@]}"; do
        CORP_GIT=$(grep "${i}" ${CONFIG}/.git/config | wc -l)
        if [ "$CORP_GIT" -ge "1" ]; then
          TOKEN_TYPE="GHI_CORP_TOKEN"
          local HOST
          HOST=$(keychain "GIT_CORP_HOST")
          if [[ $? == 1 ]];then
            echo "missing keychain value for GIT_CORP_HOST"
            return 1
          fi
          git config github.host "$HOST"
          break
        fi
      done
    fi
  fi
  GHI_TOKEN=$(keychain "$TOKEN_TYPE") TERM=xterm-256color /usr/local/bin/ghi --no-pager "$@"
}
