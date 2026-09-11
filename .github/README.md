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

### `ccat` / `nvcat`

The `ccat` alias requires [nvcat](https://github.com/brianhuster/nvcat), which
prints files using Neovim's syntax highlighting. Install its prebuilt macOS
binary into `~/.local/bin` (already on the dotfiles shell's PATH):

```sh
(
  set -eu
  version=0.1.5
  case "$(uname -m)" in
    arm64) arch=arm64 ;;
    x86_64) arch=amd64 ;;
    *) echo "Unsupported macOS architecture" >&2; exit 1 ;;
  esac
  archive="nvcat_${version}_darwin_${arch}.tar.gz"
  release="https://github.com/brianhuster/nvcat/releases/download/v${version}"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  cd "$tmp"
  curl -fL "$release/$archive" -o "$archive"
  curl -fL "$release/nvcat_${version}_checksums.txt" -o checksums.txt
  awk -v file="$archive" '$2 == file' checksums.txt > checksum.txt
  test -s checksum.txt
  shasum -a 256 -c checksum.txt
  tar -xzf "$archive" nvcat
  mkdir -p "$HOME/.local/bin"
  install -m 755 nvcat "$HOME/.local/bin/nvcat"
)
rehash
ccat text.md
```

For other platforms, use the matching upstream release, or build with Go 1.22+:
`GOBIN="$HOME/.local/bin" go install github.com/brianhuster/nvcat@v0.1.5`.
