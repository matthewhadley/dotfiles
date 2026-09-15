#!/bin/bash
# Bound to a herdr keybinding (see ~/.config/herdr/config.toml). Run from
# inside an existing repo's workspace. Reuses worktrunk's own picker.sh
# (same fzf flow as prefix+shift+g / worktrunk.open) so its hooks still run,
# then force-applies herdr-plugin-workspace-manager's layout regardless of
# the plugin's claim guard -- covers both a brand-new worktree (which the
# automatic hook usually catches on its own) and switching to one that was
# already claimed once, which the automatic hook would otherwise skip.
#
# Detects whether anything actually happened by comparing the focused
# workspace before/after: picker.sh exits 0 both on cancel and on success,
# so an exit code alone can't tell them apart.
set -uo pipefail

# As a plugin pane, $PWD starts at this plugin's own root (dev-scripts/), not
# the pane you actually invoked this from -- unlike the old bare popup
# keybinding, which inherited the originating pane's cwd directly. Resolve
# the real origin via HERDR_PLUGIN_CONTEXT_JSON's focused_pane_id (confirmed
# empirically by other plugins -- popup panes don't get HERDR_PANE_ID) and cd
# there first; everything below (the git check, worktrunk's picker.sh) needs
# to run against the actual repo, not wherever this plugin happens to live.
origin_pane=$(jq -r '.focused_pane_id // empty' <<<"${HERDR_PLUGIN_CONTEXT_JSON:-{}}")
if [[ -n $origin_pane ]]; then
  origin_cwd=$(herdr pane get "$origin_pane" 2>/dev/null | jq -r '.result.pane.cwd // empty')
  [[ -n $origin_cwd && -d $origin_cwd ]] && cd "$origin_cwd"
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '\033[31mnew-worktree: not a git repository: %s\033[0m\n' "$PWD"
  sleep 2
  exit 1
fi

before=$(herdr workspace list | jq -r '.result.workspaces[] | select(.focused) | .workspace_id')

worktrunk_root=$(jq -r '.[] | select(.plugin_id == "worktrunk") | .plugin_root' ~/.config/herdr/plugins.json)
# HERDR_PLUGIN_ROOT: picker.sh sources its own config.sh/helpers.sh via
# ${HERDR_PLUGIN_ROOT:-<its own dirname>} -- if that var is already set
# (inherited from whatever pane context ran this script, e.g. another
# plugin's pane), it trusts that value even though it points at the wrong
# plugin, and several of picker.sh's helper functions silently become
# "command not found". Force it to worktrunk's own root explicitly.
HERDR_PLUGIN_ROOT="$worktrunk_root" bash "$worktrunk_root/picker.sh" --create-base=default

after=$(herdr workspace list | jq -r '.result.workspaces[] | select(.focused) | .workspace_id')

if [[ -n $after && $after != "$before" ]]; then
  # Only force an apply the plugin isn't already doing itself. Its event hook
  # lays out a brand-new linked worktree on workspace.created/focused, and
  # `apply` is NOT idempotent -- plan.rs has no adopt-or-reuse path, it builds
  # the layout fresh -- so running both against one workspace gives it two of
  # everything. That is exactly what happened to ~/dev/herdr-bar.grok: nine
  # tabs, and the hook's `agent start` losing the claude-w12 name to the
  # agent our own apply had just started.
  #
  # Polled rather than checked once, because at this instant the hook may be
  # mid-flight in another process and the workspace looks equally bare either
  # way. Waiting for a second tab distinguishes them: execute_plan creates
  # tabs back-to-back over the socket with nothing blocking in between (the
  # slow parts -- the 15s shell-ready wait, the 60s agent start -- all come
  # after the loop), so if the hook has this workspace, tab two lands within
  # a fraction of a second. Note the count goes 1 -> 1 -> 2: the layout's
  # first tab REPLACES the workspace's root tab, so a rising count, not a
  # changed tab id, is the signal.
  #
  # Two seconds is that latency with a wide margin for a cold binary start --
  # observation bears it out: in the herdr-bar.grok incident the tabs were all
  # up long before the run's 15s pause, which was the shell-ready timeout
  # sitting on Claude's "do you trust this folder" prompt. Nothing appearing
  # in the window means no hook is coming -- the claim for this checkout path
  # was taken the first time round and the hook skipped -- which is the one
  # case this force-apply exists for, and the only case that pays the full
  # wait. A worktree whose workspace is already open and arranged exits on
  # the first poll.
  deadline=$((SECONDS + 2))
  while :; do
    tabs=$(herdr tab list --workspace "$after" 2>/dev/null | jq '.result.tabs | length')
    (( ${tabs:-1} > 1 )) && exit 0
    (( SECONDS >= deadline )) && break
    sleep 0.1
  done

  wsm_root=$(jq -r '.[] | select(.plugin_id == "herdr-plugin-workspace-manager") | .plugin_root' ~/.config/herdr/plugins.json)
  wsm_config_dir=$(herdr plugin config-dir herdr-plugin-workspace-manager)
  # HERDR_WSM_CONFIG: calling the binary directly bypasses herdr's own
  # HERDR_PLUGIN_CONFIG_DIR injection, so the plugin can't otherwise find its
  # real config file -- see open-project.sh for the same issue in detail.
  #
  # Foreground, deliberately: backgrounding this (nohup + disown) didn't
  # survive the pane closing -- see open-project.sh for the full explanation.
  HERDR_WSM_WORKSPACE="$after" HERDR_WSM_CONFIG="$wsm_config_dir/config.yml" \
    sh "$wsm_root/bin/herdr-workspace-manager" apply
fi
