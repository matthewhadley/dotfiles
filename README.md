# dotfiles

A landing pad, not the repo's contents. The dotfiles live in a bare repo at
`~/.dotfiles` whose work tree is `$HOME`, so every tracked file sits at its
real path — no copies, no symlinks. This directory is a linked worktree of
that same repo on an orphan `docs` branch, holding nothing but these two
files.

It exists so the setup has somewhere to *open*. `$HOME` is the correct work
tree but a poor project root, and `~/.dotfiles` is a bare git dir — `objects/`,
`refs/`, `HEAD`, nothing to edit.

## Working on the dotfiles

Use the `dotfiles` wrapper rather than raw git; `dotfiles help` lists what it
adds.

    dotfiles nv        tracked files only, as a tree
    dotfiles hunk      review the working tree
    dotfiles lazygit   commit
    dotfiles check     fetch, then report ahead/behind and any local changes

**Run them from `$HOME`, not from here.** The wrapper deliberately does not
pass `-C "$HOME"`, so pathspecs resolve against the current directory — that is
what makes `cd ~/.config/ghostty && dotfiles add config` work. Run from this
directory, the same command looks under `~/dev/dotfiles/` instead.

## Two inherited quirks

`status.showUntrackedFiles` is `no`, set repo-wide because otherwise every file
under `$HOME` shows as untracked. This worktree inherits it, having no such
problem of its own — so a new file here will not appear in `git status`, and
`git add -A` will not find it. Name the path. Per-worktree config would fix
this, but it needs `core.repositoryformatversion` raised from 0 to 1, which is
a repo-wide compatibility change for a papercut.

Commits follow [Scoped Commits](https://scopedcommits.com/): `<scope>:
<description>`, no type field. The `commit-msg` hook lives in the shared
common dir, so it enforces that here too. Query the vocabulary rather than
trusting any copy of it:

    git config --get-all scopedcommits.scopes
