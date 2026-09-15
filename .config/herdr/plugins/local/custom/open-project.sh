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
dir=~/dev
while true; do
  result=$(
    find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort \
      | fzf --expect=enter,right,left \
            --color=fg:blue \
            --prompt="${dir/#$HOME/\~} > " \
            --header='→ = browse into · enter = open this one · ← = up a level · esc = cancel'
  ) || exit 0
  key=$(head -n1 <<<"$result")
  choice=$(tail -n +2 <<<"$result")

  if [[ $key == left ]]; then
    dir=$(dirname "$dir")
    continue
  fi

  [[ -z $choice ]] && exit 0
  dir=$choice
  [[ $key == right ]] || break
done

name=$(basename "$dir")

# ~/dev/dotfiles is a linked worktree of the bare ~/.dotfiles repo on an orphan
# `docs` branch -- an ordinary directory under ~/dev as far as the browser
# above is concerned, so basename already labels it "dotfiles" and nothing
# needs normalising. Only the layout has to be named: the plugin matches
# workspaces on worktree.checkout_path/repo_root, which herdr does not report,
# so a bare `apply` would fall through to globalLayout and hand it `standard`
# -- whose hunk and zsh panes would then resolve `dotfiles` pathspecs against
# the docs worktree instead of $HOME.
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
