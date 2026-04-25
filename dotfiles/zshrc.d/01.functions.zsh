# get, set, delete keychain values
keychain() {
  key="$1"
  value="$2"

  if [[ "$key" == "" ]]; then
    echo "usage: keychain key [value|null]"
    return
  fi

  if [[ "$value" == "null" ]]; then
    VALUE=$(/usr/bin/security delete-generic-password -s "$key" -a "$USER" 2>&1 >/dev/null)
    if [ $? -ne 0 ];then
      return 1
    fi
  elif [ -n "$value" ]; then
    /usr/bin/security add-generic-password -s "$key" -w "$value" -a "$USER" -U
  elif [ -n "$key" ]; then
    VALUE=$(/usr/bin/security find-generic-password -w -s "$key" 2>&1 >/dev/null)
    if [ $? -eq 0 ];then
      /usr/bin/security find-generic-password -w -s "$key" -a "$USER"
    else
      return 1
    fi
  fi
}

#  display file/directory permissions in octal format
perms() {
  # default to all visible files/directories
  local input=(*);
  if [ ! -z "$1" ]; then
    input=$@
  fi
  # check to also show hidden files/directories
  if [[ "$1" == "-a" ]]; then
    input=(.* *)
  fi
  stat -f '%A %N' "${=input}"
}

# remove known_hosts entry
unknow_host() {
  if [[ -z "$1" ]];then
    echo "error: missing hostname"
    return
  fi
  echo "removing host $1"
  ssh-keygen -R $1 &>/dev/null
}

# cd to parent directory of symlinked file
cds() {
  local realpath=$(readlink $1)
  cd $(dirname "$realpath")
}

# make a directory and cd into it
md() {
  mkdir -p "$@" && cd "$@";
}

# show recently modified files using fd https://github.com/sharkdp/fd
# usage: recent [path] [number of results]
recent() {
  fd -t f -0 . $1 | xargs -0 stat -f "%m%t%Sm %N" | sort -rn | head -n ${2:-20} | cut -f2-
}
# git functions

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

