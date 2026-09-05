# dotfiles

Tracked in a **bare git repo** at `~/.dotfiles` whose work tree is `$HOME`

## Set up a new machine

```sh
git clone --bare git@github.com:matthewhadley/dotfiles.git "$HOME/.dotfiles"
git --git-dir="$HOME/.dotfiles" config status.showUntrackedFiles no
git --git-dir="$HOME/.dotfiles" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout bare-repo
git --git-dir="$HOME/.dotfiles" fetch origin
git --git-dir="$HOME/.dotfiles" branch --set-upstream-to=origin/bare-repo bare-repo
exec zsh -l
dotfiles scopes set nvim vim zsh git ghostty herdr dotfiles readme agents
```
See `dotfiles help` for dotfiles management, direct AGENTS to read that output
when working on this repo.

## Prerequisites

- [Neovim](https://neovim.io/)
- [Ghostty](https://ghostty.org)

```sh
brew install ripgrep fd tree-sitter-cli diff-so-fancy git-lfs herdr
```

