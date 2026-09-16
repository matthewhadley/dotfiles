# dotfiles

Tracked in a **bare git repo** at `~/.dotfiles` whose work tree is `$HOME`

## Set up a new machine

```sh
git clone --bare git@github.com:matthewhadley/dotfiles.git "$HOME/.dotfiles"
git --git-dir="$HOME/.dotfiles" config status.showUntrackedFiles no
git --git-dir="$HOME/.dotfiles" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout main
git --git-dir="$HOME/.dotfiles" fetch origin
git --git-dir="$HOME/.dotfiles" branch --set-upstream-to=origin/main main
exec zsh -l
dotfiles scopes set nvim vim zsh git ghostty herdr dotfiles readme agents
```
See `dotfiles help` for dotfiles management, direct AGENTS to read that output
when working on this repo.

## Prerequisites

- [Homebrew](https://brew.sh)
- [Ghostty](https://ghostty.org)

Everything else is declared in [`.config/dotfiles/Brewfile`](../.config/dotfiles/Brewfile)
and installed by:

```sh
dotfiles deps
```

That runs `brew bundle` against the Brewfile, then any matching
`.config/dotfiles/brew-post-install.d/<formula>` hook, then herdr's
`install-plugins.sh`. `dotfiles brew` does the Homebrew half alone.

The Brewfile is the single source of truth for dependencies — add
new ones there rather than here, and annotate anything whose reason
is not obvious from the name.

