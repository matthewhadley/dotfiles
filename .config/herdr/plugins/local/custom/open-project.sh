#!/bin/bash
# Bound to a herdr keybinding (see ~/.config/herdr/config.toml). Picks a
# directory under ~/dev, opens it as a new herdr workspace, and force-applies
# herdr-plugin-workspace-manager's layout regardless of the plugin's own
# claim/idempotency guard (cmd_apply bypasses it; only the automatic
# workspace.created hook checks it). Only leaves HERDR_WSM_WORKSPACE set --
# resolve_target derives tab/pane/cwd from the workspace itself.
#
# Calling the plugin binary directly (not through `herdr plugin action
# invoke`) means herdr never injects HERDR_PLUGIN_CONFIG_DIR for it, so its
# own config-file lookup falls through to an unused ~/.herdr/plugins/...
# fallback and fails with "no config file found" -- HERDR_WSM_CONFIG below
# points it at the real file directly.
set -uo pipefail

# Interactive browser: no "." / ".." sentinel rows -- just the real
# subdirectories of $dir. --expect reports which key triggered acceptance
# (fzf always outputs the highlighted line either way) so the three keys can
# mean different things: Right descends into the highlighted dir and keeps
# browsing; Enter selects the highlighted dir as the final target and stops
# (the normal fzf accept convention -- to open a directory itself rather
# than a child, pick it from its *parent's* listing instead of descending
# into it first); Left always ascends a level regardless of what's
# highlighted. Esc/no selection exits the whole script via `|| exit 0`.
#
# Enter with nothing highlighted -- i.e. a typed name that matches no
# existing directory -- creates it under $dir and opens that. --print-query
# is what makes the typed text available at all: with no match there is no
# selection line to read, and fzf otherwise discards the query on accept.
# Output order is query, then the --expect key, then the selection.
#
# A query that *does* substring-match something still opens the match, per
# the usual fzf convention -- typing "foo" where "foobar" exists cannot
# create "foo". Descend into the parent and type a name nothing matches, or
# make the directory in a shell.
#
# Rows are displayed tilde-abbreviated, matching the prompt -- /Users/mhadley
# is the same 14 columns on every row and says nothing. Only while browsing
# inside $HOME, though: pressing Left past it lists /Users/mhadley alongside
# /Users/Shared, where it is one ordinary directory among siblings and the
# abbreviation would make it look like something else. The rewrite matches
# $HOME as a whole path component, so a sibling like /Users/mhadleyfoo is
# left alone, and the expansion after the picker puts the real path back
# before anything uses it.
#
# Hidden directories are excluded: nothing openable as a project is named
# with a leading dot, and listing them buries the real entries under .git,
# .venv, node_modules-adjacent caches and (after pressing Left up to $HOME)
# the whole of the dotfiles tree. The bare ~/.dotfiles repo is not a loss --
# it is checked out at ~/dev/dotfiles, which is what this picker should open.
tilde() {
  if [[ $dir == "$HOME" || $dir == "$HOME"/* ]]; then
    sed "s|^$HOME/|~/|"
  else
    cat
  fi
}

dir=~/dev
while true; do
  result=$(
    find "$dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | sort \
      | tilde \
      | fzf --expect=enter,right,left \
            --print-query \
            --color=fg:blue \
            --prompt="${dir/#$HOME/\~} > "
  )
  status=$?
  # Exit 1 means the query matched nothing. With --print-query that is a
  # usable answer -- the typed name -- not a cancel, so only a real abort
  # (130 from Esc/Ctrl-C) or an unexpected error ends the script here.
  [[ $status == 0 || $status == 1 ]] || exit 0
  query=$(sed -n 1p <<<"$result")
  key=$(sed -n 2p <<<"$result")
  choice=$(sed -n 3p <<<"$result")
  # Safe unconditionally: rows are absolute paths unless tilde() rewrote
  # them, and it only ever writes the ~ at the front. A directory genuinely
  # named ~something keeps its tilde.
  choice=${choice/#\~/$HOME}

  if [[ $key == left ]]; then
    dir=$(dirname "$dir")
    continue
  fi

  # Nothing matched. Enter on a non-empty query creates it; anything else
  # (Right, which has nothing to descend into, or an empty query) is a no-op
  # and quits. mkdir -p, so "clients/acme" creates both levels, and a query
  # given as an absolute or ~ path is taken at face value rather than nested
  # under $dir -- the rows are displayed in that form, so one can be pasted.
  #
  # Tested for "not Right" rather than "is Enter": fzf leaves the --expect
  # line empty when acceptance came from anything other than one of the
  # listed keys, and an empty key here still means accept.
  if [[ -z $choice ]]; then
    [[ $key != right && -n $query ]] || exit 0

    case $query in
      /* | '~'/*) target=${query/#\~/$HOME} ;;
      *)          target=$dir/$query ;;
    esac
    mkdir -p "$target" \
      || { printf '\033[31mmkdir %s failed\033[0m\n' "$target"; sleep 2; exit 1; }

    # git init, because the layout assumes a repo: globalLayout `standard`
    # gives every workspace a lazygit tab and a `hunk diff --watch` tab, and
    # in a plain directory both open broken -- lazygit on its "initialize a
    # new repo?" prompt, hunk with nothing to diff. Creating a directory
    # through this picker already means "this is a project".
    #
    # Unless something already claims it: typing a name while browsing inside
    # a checkout (say ~/dev/some-repo/docs) would otherwise nest a repo in a
    # repo, which is a nuisance to unpick and never the intent. rev-parse
    # failing outright is the only safe signal -- it means no work tree
    # encloses $target. A successful one covers both "already a repo root"
    # and "inside somebody else's", and neither wants another init.
    #
    # Nothing beyond `init`: no first commit, no README, no .gitignore. That
    # is scaffolding, a separate decision from "make this a repo". An unborn
    # HEAD suits both panes fine. init.templateDir installs the commit-msg
    # hook here, and with no scopedcommits.scopes set in the new repo it
    # allows any scope, so it will not block the early commits.
    toplevel=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null)
    if [[ -z $toplevel ]]; then
      git -C "$target" init --quiet \
        || { printf '\033[31mgit init %s failed\033[0m\n' "$target"; sleep 2; exit 1; }
    fi

    dir=$target
    break
  fi

  dir=$choice
  [[ $key == right ]] || break
done

name=$(basename "$dir")

# Already open? Focus that workspace instead of standing a second one up on the
# same checkout.
#
# No override key, deliberately. Wanting a repo open twice is what worktrees are
# for: `wt` or `herdr worktree create` gives an isolated checkout at its own
# path, which this check then treats as the separate thing it is. A second
# workspace on the *same* checkout means two nvims and two agents over one set
# of files, and both would land in the switcher under the same basename label.
#
# `herdr worktree list --cwd` reports an open_workspace_id per worktree, which
# is the authoritative mapping. Pane cwds are not: a pane can cd anywhere -- the
# dotfiles layout's own zsh pane cds to $HOME -- and one workspace routinely
# holds panes from several projects at once, so matching on those would both
# miss and misfire.
#
# Filtering on .path because the listing covers every worktree of the repo, not
# only the one asked about: ~/dev/dotfiles also returns the bare ~/.dotfiles
# alongside it. The []? and // empty between them absorb the two non-matches --
# a repo that simply isn't open, and the error object returned for a path in no
# repo at all. That second case is ordinary here rather than exceptional, since
# most of ~/dev is plain directories.
open_ws=$(herdr worktree list --cwd "$dir" 2>/dev/null \
  | jq -r --arg d "$dir" '.result.worktrees[]? | select(.path == $d) | .open_workspace_id // empty' \
  | head -n1)

# The check above is authoritative, but only inside a checkout: for a plain
# directory `herdr worktree list` returns not_git_worktree and there is no
# open_workspace_id to find, so the guard never fired and every repeat call
# stood up another workspace on the same directory.
#
# The label is the only thing left to match on. herdr records no cwd against a
# workspace -- `workspace list` and `workspace get` both return just
# label/number/counts/ids -- so there is no path to compare. That makes this
# weaker than the worktree lookup: two directories sharing a basename
# (~/dev/a/docs and ~/dev/b/docs) collide, and the second would focus the
# first's workspace rather than opening its own. Accepted, because the
# switcher already lists both under that one name -- the same ambiguity the
# comment above notes -- and silently multiplying workspaces is the worse of
# the two failures.
#
# Gated on the authoritative check being unable to run at all, not merely on
# it finding nothing, so behaviour inside a repo is exactly as it was.
if [[ -z $open_ws ]] && ! git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  open_ws=$(herdr workspace list 2>/dev/null \
    | jq -r --arg l "$name" '.result.workspaces[]? | select(.label == $l) | .workspace_id' \
    | head -n1)
fi

if [[ -n $open_ws ]]; then
  herdr workspace focus "$open_ws" >/dev/null \
    || { printf '\033[31mfocus %s failed\033[0m\n' "$open_ws"; sleep 2; exit 1; }
  exit 0
fi

# ~/dev/dotfiles is a linked worktree of the bare ~/.dotfiles repo on an orphan
# `bare-repo` branch -- an ordinary directory under ~/dev as far as the browser
# above is concerned, so basename already labels it "dotfiles" and nothing
# needs normalising. Only the layout has to be named: the plugin matches
# workspaces on worktree.checkout_path/repo_root, which herdr does not report,
# so a bare `apply` would fall through to globalLayout and hand it `standard`
# -- whose hunk and zsh panes would then resolve `dotfiles` pathspecs against
# the landing worktree instead of $HOME.
layout=
[[ $dir == "$HOME/dev/dotfiles" ]] && layout=dotfiles

ws=$(herdr workspace create --cwd "$dir" --label "$name" --focus) || exit 1
ws_id=$(jq -r '.result.workspace.workspace_id // empty' <<<"$ws")
[[ -z $ws_id ]] && { printf '\033[31mworkspace create failed: %s\033[0m\n' "$ws"; sleep 2; exit 1; }

wsm_root=$(jq -r '.[] | select(.plugin_id == "herdr-plugin-workspace-manager") | .plugin_root' ~/.config/herdr/plugins.json)
wsm_config_dir=$(herdr plugin config-dir herdr-plugin-workspace-manager)

# Via `env` and an array rather than an inline `${layout:+VAR=...}` prefix:
# bash fixes which words are assignment prefixes at parse time, so a word that
# only *becomes* VAR=value after expansion is taken as the command name
# instead. `env` sidesteps that -- to it they're ordinary arguments.
wsm_env=(HERDR_WSM_WORKSPACE="$ws_id" HERDR_WSM_CONFIG="$wsm_config_dir/config.yml")
[[ -n $layout ]] && wsm_env+=(HERDR_WSM_LAYOUT="$layout")

# Foreground, deliberately: backgrounding this (nohup + disown) didn't survive
# the pane closing -- herdr appears to kill the whole pane process group, which
# nohup only protects a process from SIGHUP, not a group-wide kill, so the
# background job never got a chance to run. The "agent" tab's
# `herdr agent start --timeout 60000` can still take up to a minute (and
# occasionally fails outright) starting a second Claude Code agent from a pane
# that's already running one -- that's a real wait, not a hang.
env "${wsm_env[@]}" sh "$wsm_root/bin/herdr-workspace-manager" apply
