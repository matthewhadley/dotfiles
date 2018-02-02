# directory listing
alias ls='ls -G'
alias l='ls -lG'

# vim for vi
alias vi=vim

# Recursively delete `.DS_Store` files
alias rm.DS="find . -name '*.DS_Store' -type f -ls -delete"

# sublime text
alias sb='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
alias sbg='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl `git diff --name-only | tr "\n" " "`'
alias sbn='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl -n .'
alias sbng='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl -n . `git diff --name-only | tr "\n" " "`'

# ripgrep
alias rg="rg --colors 'match:bg:yellow' --colors 'match:fg:black' --colors 'line:fg:magenta'"

# LOTS
alias lots='LOTS_RG=1 lots'

# npm
alias npm-public='npm --registry https://registry.npmjs.org'
