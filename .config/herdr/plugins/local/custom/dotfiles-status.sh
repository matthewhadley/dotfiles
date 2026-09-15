#!/bin/bash
# Pushes the dotfiles repo's ahead/behind counts into the herdr sidebar, as
# the $dotfiles_ahead and $dotfiles_behind workspace metadata tokens rendered
# by ui.sidebar.spaces.rows (see ~/.config/herdr/config.toml).
#
# Why anything is needed: the sidebar's built-in `branch` and `git_status`
# tokens come from git discovery at the workspace's own path, and for this
# workspace that path is ~/dev/dotfiles -- a linked worktree on the orphan
# `bare-repo` branch holding two files. That branch is named for what the
# workspace IS rather than for a line of work, which is what makes the branch
# line read well; but it has no upstream and never will, so its git_status is
# permanently empty. The commits worth seeing are the ones on `main`, whose
# work tree is $HOME.
#
# And no other workspace root would do better. $HOME is not a discoverable
# work tree (`herdr worktree list --cwd ~` answers not_git_worktree), and
# ~/.dotfiles is bare -- herdr lists it with no `branch` field at all. Nothing
# to point a cwd at, so the count is reported in instead.
#
# Only the counts: the branch name is the one thing the sidebar already gets
# right, now that the orphan branch is named `bare-repo`.
#
# Run from ~/.config/dotfiles/hooks/reference-transaction on every relevant
# ref change, from herdr's [[startup]] hook, on workspace.focused (which
# populates a freshly opened workspace, tokens being keyed by workspace id),
# and from the `Refresh dotfiles status` action.
#
# Read-only ref queries, so this calls git with --git-dir directly rather than
# going through the `dotfiles` wrapper: no work tree is involved, no pathspec
# resolves against a cwd, and the wrapper may not be on a plugin hook's PATH.
set -uo pipefail

git_dir=$HOME/.dotfiles
landing_worktree=$HOME/dev/dotfiles

# Which workspace to decorate. Matching on the worktree listing rather than the
# workspace label: the label is just a string a rename could change, while
# open_workspace_id is herdr's own mapping from checkout path to workspace.
# Nothing to do when the dotfiles workspace isn't open.
ws=$(herdr worktree list --cwd "$landing_worktree" 2>/dev/null \
  | jq -r --arg d "$landing_worktree" \
      '.result.worktrees[]? | select(.path == $d) | .open_workspace_id // empty' \
  | head -n1)
[[ -n $ws ]] || exit 0

# HEAD of the bare repo, i.e. whatever branch $HOME's work tree is on -- not
# the landing worktree's. Both counts come from one walk; empty when the
# branch has no upstream. Only refs are walked, so this stays cheap enough for
# a hook that fires on every ref transaction, unlike a `status` over $HOME --
# which is why no dirty marker is reported here.
#
# Behind is only ever as fresh as the last fetch: origin/main is a local ref,
# so another machine's push is invisible until something here fetches. The
# reference-transaction hook covers that too, since a fetch moves the ref.
counts=$(git --git-dir="$git_dir" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)
behind=$(printf '%s' "$counts" | awk '{print $1}')
ahead=$(printf '%s' "$counts" | awk '{print $2}')

# One stable --source: a workspace accepts sequenced token reports from at most
# 32 distinct sources in its lifetime, and clearing or expiry does not give a
# slot back. No --ttl-ms, so a value survives until the next report rather
# than blanking out between refreshes; this script is the only writer.
#
# Cleared rather than reported empty when a count is zero, so the row doesn't
# keep a stale arrow or an orphaned separator.
report() {
  if [[ ${2:-0} -gt 0 ]]; then
    herdr workspace report-metadata "$ws" --source dotfiles \
      --token "$1=$3$2" >/dev/null
  else
    herdr workspace report-metadata "$ws" --source dotfiles \
      --clear-token "$1" >/dev/null
  fi
}

report dotfiles_ahead "${ahead:-0}" '↑'
report dotfiles_behind "${behind:-0}" '↓'
