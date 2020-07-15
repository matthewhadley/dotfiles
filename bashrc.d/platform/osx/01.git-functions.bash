# channel git calls
hash git 2>&- && { export GIT_PATH=$(which git); }

git(){
  if [[ "$1" == "commit" || "$1" == "clone" ]];then
    # let git.corp proxy git cmd
    $GIT_CORP "$@"
  else
    $GIT_PATH "$@"
  fi
}
