#!/usr/bin/env bash
#
# install-plugins.sh — the herdr plugins this machine expects.
#
# herdr has no declarative plugin manifest: `herdr plugin` can install and
# uninstall, but nothing reads a list and reconciles. plugins.json is state
# herdr writes, never intent it reads — it carries absolute paths with
# content-hash suffixes and install timestamps, so it is useless as a record
# to restore from. This file is the record instead.
#
# Safe to re-run: herdr skips a plugin that is already installed at the same
# ref, and the protocol patch below is a no-op once it matches.

set -euo pipefail

command -v herdr >/dev/null || { echo "herdr not on PATH" >&2; exit 1; }
command -v jq    >/dev/null || { echo "jq not on PATH" >&2; exit 1; }

# wilbeibi.catchup shells out to a `catchup` binary that herdr cannot install:
# it ships as its own release, not as part of the plugin repo. The plugin still
# installs and loads without it, so warn rather than exit — the rest of the list
# is worth installing either way.
command -v catchup >/dev/null || cat >&2 <<'EOF'
warning: catchup not on PATH — every wilbeibi.catchup action will fail.
  brew install wilbeibi/tap/catchup
  or grab a release binary: https://github.com/wilbeibi/catchup/releases
EOF

plugins=(
  vjeantet/herdr-palette         # command palette: built-ins + plugin actions (super+p)
  nicosuave/memex                # session desk: search and resume past agent sessions
  wilbeibi/herdr-catchup         # summarize/fork/hand this pane's session to another agent
  devashish2203/herdr-worktrunk  # git worktrees via the wt CLI, with create/teardown hooks
)

for plugin in "${plugins[@]}"; do
  echo "==> $plugin"
  herdr plugin install "$plugin" --yes
done

# --- Local patch: vjeantet.palette's declared protocol -----------------------
#
# commands.json pins the herdr API protocol it was built against and shows a
# header warning when the running herdr reports a different one. Upstream has
# lagged since 2026-08-31 (declares 20; herdr 0.9.0 reports 22), so the palette
# warns on every open. The number is synced to whatever herdr reports here, and
# the plugin's own check-compat.sh is then run to confirm that the catalog is
# genuinely compatible — every subcommand, flag, positional and default
# keybinding — rather than just silencing the warning. A real incompatibility
# fails this script instead of hiding behind a bumped number.
#
# This lives in the managed checkout under plugins/github/, so it is lost on
# every plugin update. That is why it is here and not applied by hand.

root=$(jq -r '.[] | select(.plugin_id == "vjeantet.palette") | .plugin_root' \
  ~/.config/herdr/plugins.json)
protocol=$(herdr api schema 2>/dev/null | awk -F': ' '/^protocol:/ { print $2; exit }')

if [ -n "$root" ] && [ -n "$protocol" ] && [ -f "$root/commands.json" ]; then
  declared=$(jq -r '.expected_herdr_protocol' "$root/commands.json")
  if [ "$declared" != "$protocol" ]; then
    echo "==> vjeantet.palette: protocol $declared -> $protocol"
    tmp=$(mktemp)
    jq --argjson p "$protocol" '.expected_herdr_protocol = $p' \
      "$root/commands.json" > "$tmp" && mv "$tmp" "$root/commands.json"
  fi
  bash "$root/scripts/check-compat.sh"
fi

herdr server reload-config
echo "done — plugins installed and config reloaded"
