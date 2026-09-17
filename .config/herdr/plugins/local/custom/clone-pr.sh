#!/bin/bash
# Bound to a herdr action ("Clone PR"). Run from inside a repo's workspace:
# pick one of its open PRs, get a worktree for the PR branch, and open that
# worktree as a herdr workspace with the standard layout.
#
# Two steps, because `wt switch pr:<N>` only does the first. It creates the git
# worktree and stops; the herdr workspace comes from `herdr worktree open`,
# which worktrunk's own picker.sh calls afterwards and which nothing calls when
# `wt` is run straight from a shell. Running `wt switch pr:3` by hand leaves a
# checkout on disk that `herdr worktree list` reports with no open_workspace.
#
# ── Which GitHub, and why it has to be said at all ──────────────────────────
#
# worktrunk resolves the repo to a bare `owner/name` slug and hands that to gh.
# `gh ... --repo owner/name` carries no host, so gh answers it from its DEFAULT
# host -- and with more than one account in `gh auth status`, none of them is
# the default, so gh picks github.com. Against an enterprise remote the repo
# genuinely is not there and the failure reads as a missing PR:
#
#   ✗ PR #3 not found on owner/repo (github remote)
#     gh: Not Found (HTTP 404)
#
# Nothing is wrong with the PR or the auth; only the host was dropped. Bare
# `gh pr list` is unaffected -- repo-scoped commands infer the host from the
# remote -- which is what makes this look so inconsistent from the outside.
#
# So the host is discovered and exported. Discovered via `gh repo view`, not by
# parsing `git remote get-url`: gh already knows how to resolve a remote to a
# forge repo, including `url.<base>.insteadOf` rewrites and SSH host aliases
# from ~/.ssh/config, and repo-scoped resolution is exactly the path that works
# without help. That also keeps every hostname out of these dotfiles -- whatever
# host the checkout points at is the host used, with nothing enumerated here.
set -uo pipefail

die() {
  printf '\033[31mclone-pr: %s\033[0m\n' "$1"
  sleep 2
  exit 1
}

# As a plugin pane, $PWD starts at this plugin's own root, not the pane this was
# invoked from. Resolve the real origin via HERDR_PLUGIN_CONTEXT_JSON's
# focused_pane_id and cd there -- same as new-worktree.sh, see its note.
#
# The default is `null`, not `{}`. `${VAR:-{}}` does not mean what it looks
# like: bash ends the expansion at the first `}`, so it is `${VAR:-{}` -- a
# default of `{` -- followed by a literal `}`. Unset, that concatenates to `{}`
# and looks correct; SET, it appends a stray brace to the real JSON and jq
# reports `parse error: Unmatched '}'`. jq still prints the pane id before
# failing, so it is noise rather than breakage, which is how it went unnoticed.
# `null` is valid JSON and indexes to null, so it needs no braces at all.
origin_pane=$(jq -r '.focused_pane_id // empty' <<<"${HERDR_PLUGIN_CONTEXT_JSON:-null}")
if [[ -n $origin_pane ]]; then
  origin_cwd=$(herdr pane get "$origin_pane" 2>/dev/null | jq -r '.result.pane.cwd // empty')
  [[ -n $origin_cwd && -d $origin_cwd ]] && cd "$origin_cwd"
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not a git repository: $PWD"
command -v gh >/dev/null 2>&1 || die "gh is not on PATH"
command -v fzf >/dev/null 2>&1 || die "fzf is not on PATH"

repo_url=$(gh repo view --json url -q .url 2>/dev/null) \
  || die "gh could not resolve this checkout to a forge repo"
GH_HOST=${repo_url#*://}
GH_HOST=${GH_HOST%%/*}
[[ -n $GH_HOST ]] || die "could not read a host out of: $repo_url"
export GH_HOST

# --limit is generous rather than unbounded: fzf makes a long list navigable,
# but a repo with thousands of open PRs should not hold the popup open while
# gh pages through them.
prs=$(gh pr list --limit 200 \
  --json number,title,author,isDraft,headRefName \
  --template '{{range .}}{{printf "%v\t%s\t%s\t%s\t%s\n" .number .title .author.login (.isDraft | printf "%v") .headRefName}}{{end}}' \
  2>/dev/null) || die "gh pr list failed on $GH_HOST"
# Not an error: a repo with nothing open is an ordinary answer, so it gets a
# plain line rather than die()'s red. Names the host, because the usual cause
# is being in the wrong workspace -- the popup inherits the focused pane's cwd,
# and $HOME is itself the dotfiles work tree, so a stray invocation lands in a
# real repo rather than failing the git check.
if [[ -z $prs ]]; then
  printf 'clone-pr: no open PRs on %s\n' "$GH_HOST"
  sleep 2
  exit 0
fi

# Number first so the eventual cut is trivial, but hidden from the display with
# --with-nth; the number is already in the rendered line.
choice=$(printf '%s\n' "$prs" \
  | awk -F'\t' '{printf "%s\t#%s  %s  \033[90m%s@%s%s\033[0m\n", $1, $1, $2, $3, $5, ($4=="true" ? "  (draft)" : "")}' \
  | fzf --ansi --with-nth=2.. --delimiter='\t' \
        --prompt="PR > " \
        --header="↵ → worktree for the PR branch · esc → cancel")
[[ -n $choice ]] || exit 0
pr_number=${choice%%$'\t'*}

before=$(herdr workspace list | jq -r '.result.workspaces[] | select(.focused) | .workspace_id')

# --no-cd because this pane is not where the user ends up; the workspace below
# is. --format=json for the resolved branch and path -- `pr:<N>` tells us
# neither on its own.
if ! result=$(wt switch "pr:$pr_number" --no-cd --format=json); then
  printf '\n\033[31m%s\033[0m press any key to close' "wt switch pr:$pr_number failed (see above)."
  read -r -n1
  exit 1
fi
branch=$(jq -r '.branch // empty' <<<"$result")
wtpath=$(jq -r '.path // empty' <<<"$result")
[[ -n $wtpath ]] || die "worktrunk returned no worktree path for pr:$pr_number"

# Register under the repo's ROOT workspace, not this pane's. Invoked from
# inside an existing worktree's workspace, $HERDR_WORKSPACE_ID is a linked
# worktree's own workspace and `worktree open` rejects it -- picker.sh resolves
# the root for the same reason, and herdr reuses or creates the parent.
source_json=$(herdr worktree list --cwd "$PWD" --json 2>/dev/null)
repo_root=$(jq -r '.result.source.repo_root // empty' <<<"$source_json")
[[ -n $repo_root ]] || die "could not resolve the repository root for $PWD"

# The awkward ${arr[@]+"${arr[@]}"} rather than a plain "${label_args[@]}":
# under `set -u`, bash 3.2 treats expanding an empty array as an unbound
# variable and aborts. This pane runs whatever `bash` the herdr server's PATH
# resolves, and /bin/bash on macOS is still 3.2, so the homebrew bash that an
# interactive shell finds is not guaranteed here. Only reachable when worktrunk
# returns no branch, which is why it went unnoticed.
label_args=()
[[ -n $branch ]] && label_args=(--label "$branch")
herdr worktree open --cwd "$repo_root" --path "$wtpath" \
  ${label_args[@]+"${label_args[@]}"} --focus --json >/dev/null \
  || die "herdr worktree open failed for $wtpath"

after=$(herdr workspace list | jq -r '.result.workspaces[] | select(.focused) | .workspace_id')
[[ -n $after && $after != "$before" ]] || exit 0

# Force-apply the layout only when workspace-manager's own hook is not going to.
# `apply` is not idempotent, so running both against one workspace gives it two
# of everything -- new-worktree.sh carries the full account of how that went
# wrong, and the same 2s/second-tab poll distinguishes "the hook has this" from
# "the claim was taken earlier and the hook skipped".
deadline=$((SECONDS + 2))
while :; do
  tabs=$(herdr tab list --workspace "$after" 2>/dev/null | jq '.result.tabs | length')
  (( ${tabs:-1} > 1 )) && exit 0
  (( SECONDS >= deadline )) && break
  sleep 0.1
done

wsm_root=$(jq -r '.[] | select(.plugin_id == "herdr-plugin-workspace-manager") | .plugin_root' ~/.config/herdr/plugins.json)
wsm_config_dir=$(herdr plugin config-dir herdr-plugin-workspace-manager)
HERDR_WSM_WORKSPACE="$after" HERDR_WSM_CONFIG="$wsm_config_dir/config.yml" \
  sh "$wsm_root/bin/herdr-workspace-manager" apply
