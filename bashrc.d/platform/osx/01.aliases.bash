# directory listing
alias ls='ls -G'
alias l='ls -lG'

# automatically add github token to mdchangelog
alias mdchangelog='MDCHANGELOG_TOKEN=$(keychain -g GITHUB_TOKEN) mdchangelog'

# gmail (via notifier)
alias gu='~/dev/bash/gmail-notifier/gmail-notifier/gmail-notifier -c'

# Recursively delete `.DS_Store` files
alias rm.DS="find . -name '*.DS_Store' -type f -ls -delete"

# sublime text
alias sb='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
alias sbn='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl -n .'

# docker
alias docker-init='. /Applications/Docker/Docker\ Quickstart\ Terminal.app/Contents/Resources/Scripts/start.sh'

