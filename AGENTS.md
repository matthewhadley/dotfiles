# AGENTS.md

Machine-wide guidance lives in `~/.github/AGENTS.md`, tracked on this repo's
`bare-repo` branch. Read that file. It is deliberately not duplicated here:
`~/.claude/CLAUDE.md` imports it, so a copy would only ever drift out of
agreement with the version actually in force.

What is specific to this directory, and the reason this file exists at all:

**Run `dotfiles` commands from `$HOME`, not from here.** The wrapper does not
pass `-C "$HOME"` — deliberately, so pathspecs resolve against the caller's
directory. This directory is a linked worktree on an orphan `docs` branch, so
`dotfiles add foo` run here targets `~/dev/dotfiles/foo` rather than the file
you meant. `cd ~` first.

**Nothing tracked on `bare-repo` is reachable from this directory.** Editing
the dotfiles means absolute paths into `$HOME` — `~/.config/nvim/init.lua`,
`~/.zshrc`, `~/.local/bin/dotfiles`. `Grep` and `Glob` rooted here will find
only these two files, so give them an explicit path.
