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

The vocabulary lives in git config, per repo, under `scopedcommits.scopes`.
Query it rather than working from a list written down anywhere — including
here, because any such copy drifts:

```sh
git config --get scopedcommits.scopes      # any repo
dotfiles scopes                            # this repo; $HOME is not a repo
```

Either form works: one space-separated string, or `--add` once per scope — the
hook reads with `--get-all`. In this repo `dotfiles scopes add|rm|set` writes
the string form. Ask before extending the vocabulary — a controlled list is the
point of having one.

Comma-separate when a change spans areas (`nvim, zsh: ...`). Merges, reverts
and the root commit are exempt. A `commit-msg` hook in `.git-templates/hooks/`
enforces this; leaving `scopedcommits.scopes` unset allows any scope.

## Diffing a branch against its base

In a worktree, "what does this branch change" is a diff against the **merge
base**, not against the base branch's tip. Two dots compares the two tips, so
anything that landed on `main` after you branched appears inverted, as your
deletion:

```sh
git diff main         # f | 1 +   other | 1 -   <- you never touched other
git diff main...HEAD  # f | 1 +
```

Three dots is shorthand for the merge base, and is what a pull request shows.
Commit *ranges* are unaffected — `git log A..B` and tuicr's `-r A..B` already
mean "reachable from B, not A", so two dots is right there. It is only
`git diff` where the dots change the answer.

Find the base branch with `git rev-parse --abbrev-ref origin/HEAD` rather than
assuming `main`.

| tool | command |
| --- | --- |
| pager (delta) | `git diff origin/main...` |
| hunk | `hunk diff origin/main...HEAD` |
| tuicr | `tuicr -r origin/main..HEAD` |
| a real PR | `tuicr pr <N>` — the forge's own diff |

hunk honours the dots the same way git does: `hunk diff main` and
`hunk diff main..HEAD` both report the base's own new files as your deletions,
`hunk diff main...HEAD` does not. `~/.local/bin/hunk-branch-diff` finds the
base and runs in the `branch` tab of the standard herdr layout.

**lazygit's diffing mode (`W`) is two-dot.** `DiffHelper.DiffArgs()` passes two
plain refs with no `...`, so in a worktree that has been open a while it will
show other people's commits as your deletions. Its Commits panel is fine — a
commit range is unambiguous — and `ctrl+t` hands the pair to `git difftool`.
