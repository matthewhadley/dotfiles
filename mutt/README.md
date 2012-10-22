# dot mutt files

Config folder/files for [mutt](http://www.mutt.org/). These are my mutt files, but others may find them useful.

# Installation

use [homebrew](http://mxcl.github.com/homebrew/) to install mutt

    brew install mutt
    brew install w3m # used to display html content, you could alternatively `brew install links`

So that you don't have to have your passwords in config files, install [keychain](https://github.com/diffsky/keychain)

Make a cache directory:

    mkdir ~/.mutt/cache

# Usage

Edit the `accounts/<account>.muttrc` to match your details, then `mutt -F ~/.mutt/accounts/<account>.muttrc`

Be sure to check the [mutt documentation](http://www.mutt.org/doc/manual/manual.html)