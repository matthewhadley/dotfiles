#!/bin/bash
# Bound to a herdr action ("Browse PR"). Opens the pull request for the branch
# in the current pane's checkout, in a browser.
#
# The point is the missing step in tuicr: `:copy-url` puts the PR URL on the
# clipboard and there is no open-in-browser command, nor any way to add one --
# `editor` is the only command tuicr's config exposes, and it takes the focused
# file rather than a URL. A herdr action fills that gap from outside, and since
# herdr intercepts keys above the pane it works without leaving tuicr.
#
# No clipboard involved, though. `gh pr view --web` resolves the PR from the
# checked-out branch directly, so the copy step is not needed at all -- which
# also means this works from any pane in the workspace, not only from a tuicr
# that happens to have a PR loaded.
#
# No GH_HOST either. This is repo-scoped, and repo-scoped gh commands infer the
# host from the remote; it is only the ones handed an explicit `--repo` slug,
# or host-scoped ones like `gh search`, that fall back to github.com and need
# telling. See clone-pr.sh, which does need it.
#
# Errors go to a herdr notification rather than stdout: a plain action has no
# pane, so anything printed here is visible only in
# `herdr plugin log list --plugin custom`.
set -uo pipefail

note() {
  herdr notification show "Browse PR" --body "$1" >/dev/null 2>&1
  echo "browse-pr: $1" >&2
  exit 1
}

# Resolve the pane this was invoked from. A plugin action starts at the
# plugin's own root, not the focused pane's cwd. Popup panes get
# HERDR_PLUGIN_CONTEXT_JSON and no HERDR_PANE_ID; a pane's own shell gets the
# reverse, so both are tried before falling back to wherever this started.
#
# The default is `null`, not `{}`: bash ends a parameter expansion at the first
# `}`, so `${VAR:-{}}` is a default of `{` followed by a literal `}` -- correct
# by accident when unset, and a stray brace appended to real JSON when set.
origin_pane=$(jq -r '.focused_pane_id // empty' <<<"${HERDR_PLUGIN_CONTEXT_JSON:-null}")
[[ -z $origin_pane ]] && origin_pane=${HERDR_PANE_ID:-}
if [[ -n $origin_pane ]]; then
  origin_cwd=$(herdr pane get "$origin_pane" 2>/dev/null | jq -r '.result.pane.cwd // empty')
  [[ -n $origin_cwd && -d $origin_cwd ]] && cd "$origin_cwd"
fi

command -v gh >/dev/null 2>&1 || note "gh is not on PATH"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || note "not a git repository: $PWD"

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Resolved before opening, so "no PR for this branch" is a notification rather
# than a browser tab full of gh's error text. --json also keeps gh from trying
# to be interactive when several PRs match.
url=$(gh pr view --json url -q .url 2>/dev/null)
if [[ -z $url || $url != http* ]]; then
  note "no open PR for ${branch:-this branch}"
fi

gh pr view --web >/dev/null 2>&1 || note "failed to open $url"
