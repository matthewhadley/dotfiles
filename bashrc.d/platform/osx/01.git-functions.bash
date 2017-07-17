# channel git calls
hash git 2>&- && { export GIT_PATH=$(which git); }

git(){
  if [ "$1" == "commit" -o "$1" == "clone" ];then
    $GIT_CORP "$@"
    # if flag GIT_DAYONE set, pass git commit messages through to dayone cli
    if [ "$GIT_DAYONE" == "1" -a "$1" == "commit" -a "$PLATFORM" == "osx" ];then
      git.dayone "$@"
    fi
  else
    $GIT_PATH "$@"
  fi
}

# write git entries to dayone app
git.dayone(){
  local repo=$(basename $(git rev-parse --show-toplevel 2> /dev/null))
  echo -e "$3\n#dev #$repo" | dayone new 1> /dev/null
}
