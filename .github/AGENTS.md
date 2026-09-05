# Working on this machine

## Terminal chain

Neovim runs inside Herdr inside Ghostty. Only two kinds of key survive the
whole chain:

- `Ctrl`+letter — a single ASCII control byte, passes straight through
- `Cmd`+printable

`Ctrl`+arrow and `Cmd`+arrow never arrive. Modified special keys need CSI-u
encoding to carry the modifier, and Herdr drops or rewrites those; Ghostty also
binds several `Cmd+Shift` chords to Herdr prefix sequences before anything
downstream sees them. Don't propose keybindings that cannot work — verify with
`Ctrl-v` literal-insert in Neovim first.

## Ghostty has two config paths

`~/.config/ghostty/config` (tracked in dotfiles) and `~/Library/Application
Support/com.mitchellh.ghostty/config`. The Library one is applied **last**, so
it wins on any key both define, and `Cmd+,` opens that one rather than the
tracked file. Edit the tracked file; keep the Library one comments-only.

## The dotfiles repo

A bare repo at `~/.dotfiles` whose work tree is `$HOME`, so files live at their
real paths — no copies, no symlinks. Use the `dotfiles` wrapper rather than
raw git; `dotfiles help` lists what it adds.

`status.showUntrackedFiles` is off, because otherwise every file in `$HOME`
shows as untracked. That means `dotfiles add -A` discovers nothing — name the
paths explicitly.

## mason binaries are not on the shell's PATH

mason installs into `~/.local/share/nvim/mason/bin` and prepends that to
*Neovim's* `PATH` only. `yamllint`, `hadolint`, `shellcheck` and the language
servers are therefore `command not found` from a shell — use the full path
rather than concluding they aren't installed.

## Validation

Make the change and let me validate it. Don't run long headless verification
loops; a quick check that a thing loads is fine, minutes of automated probing
is not. Where a behaviour needs a real UI — a TUI, a terminal keybinding, a
colorscheme — say it's unverified rather than inventing a way to test it.

## Commit messages

[Scoped Commits](https://scopedcommits.com/): `<scope>: <description>`. No type
field — `feat`/`fix`/`chore` carry little information once every subject names
the area it touched, and this repo has no releases to derive from them.

Scopes for this repo: `nvim`, `vim`, `zsh`, `git`, `ghostty`, `herdr`,
`dotfiles` (the wrapper script), `readme`, `agents` (this file).

Comma-separate when a change spans areas (`nvim, zsh: ...`). Merges, reverts
and the root commit are exempt. A `commit-msg` hook in `.git-templates/hooks/`
enforces this; `git config scopedcommits.scopes "..."` restricts the
vocabulary per repo.
