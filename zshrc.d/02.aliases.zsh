# directory listing
alias ls='ls -G'
alias l='ls -lG'

# vim for vi
alias vi=vim

# Recursively delete `.DS_Store` files
alias rm.DS="find . -name '*.DS_Store' -type f -ls -delete"

# ripgrep
alias rg="rg --colors 'match:bg:yellow' --colors 'match:fg:black' --colors 'line:fg:white'"

# npm
alias npm-public='npm --registry https://registry.npmjs.org'

# local webserver github.com/http-party/http-server
# localhost only without caching
alias hs="http-server -a 127.0.0.1 -c-1"
