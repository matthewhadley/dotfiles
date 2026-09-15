#!/bin/bash
# Pushes the dotfiles repo's unpushed-commit count into the herdr sidebar, as
# the $dotfiles_ahead workspace metadata token rendered by
# ui.sidebar.spaces.rows (see ~/.config/herdr/config.toml).
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
# Only the count: the branch name is the one thing the sidebar already gets
# right, now that the orphan branch is named `bare-repo`.
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
# the landing worktree's. Empty when the branch has no upstream. Only refs are
# walked, so this stays cheap enough to run on every workspace switch, unlike a
# `status` over $HOME -- which is why no dirty marker is reported here.
ahead=$(git --git-dir="$git_dir" rev-list --count '@{u}..HEAD' 2>/dev/null)

# One stable --source: a workspace accepts sequenced token reports from at most
# 32 distinct sources in its lifetime, and clearing or expiry does not give a
# slot back. No --ttl-ms, so the value survives until the next report rather
# than blanking out between refreshes; this script is the only writer.
#
# Cleared rather than reported empty when there is nothing to push, so the row
# doesn't keep a stale "↑" or an orphaned separator.
if [[ ${ahead:-0} -gt 0 ]]; then
  herdr workspace report-metadata "$ws" --source dotfiles \
    --token "dotfiles_ahead=↑$ahead" >/dev/null
else
  herdr workspace report-metadata "$ws" --source dotfiles \
    --clear-token dotfiles_ahead >/dev/null
fi
