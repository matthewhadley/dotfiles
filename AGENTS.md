# AGENTS.md

Machine-wide guidance lives in `~/.github/AGENTS.md`, tracked on this repo's
`main` branch. Read that file. It is deliberately not duplicated here:
`~/.claude/CLAUDE.md` imports it, so a copy would only ever drift out of
agreement with the version actually in force.

What is specific to this directory, and the reason this file exists at all:

**Run `dotfiles` commands from `$HOME`, not from here.** The wrapper does not
pass `-C "$HOME"` — deliberately, so pathspecs resolve against the caller's
directory, which is what makes `cd ~/.config/ghostty && dotfiles add config`
work. Run from here they resolve into this worktree instead, and git skips
paths inside a nested repo: `dotfiles add README.md` stages nothing and still
exits 0, with no output to say so. `dotfiles add .` fails less quietly but
worse — it stages `dev/dotfiles` onto `main` as an embedded git
repository. `cd ~` first.

**Nothing tracked on `main` is reachable from this directory.** Editing
the dotfiles means absolute paths into `$HOME` — `~/.config/nvim/init.lua`,
`~/.zshrc`, `~/.local/bin/dotfiles`. `Grep` and `Glob` rooted here will find
only these two files, so give them an explicit path.
