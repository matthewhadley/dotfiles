#!/bin/bash
# Pushes the last prompt typed at each agent pane into the herdr sidebar, as the
# $last_prompt pane metadata token rendered by ui.sidebar.agents.rows_by_agent
# (see ~/.config/herdr/config.toml).
#
# Why anything is needed: herdr's pane snapshot carries no prompt of its own,
# only agent_session.value -- the CLI's own id for the session running in the
# pane. The text has to come from the CLI's prompt log, which means the session
# id is the join key and one file format per agent kind. Same approach as
# herdr-bar (Sources/HerdrBarKit/PromptLog.swift), for the same reason.
#
# And terminal_title_stripped is not a substitute, despite the shipped config
# suggesting it for this slot. Claude writes the terminal title once, summarising
# the *first* prompt of a session, and never revises it -- measured on a session
# four prompts in whose subject had changed completely, still titled after prompt
# one. The spinner glyph in the unstripped title does animate, so herdr is
# receiving fresh writes; the text simply never changes. A session label, not an
# activity label.
#
# Run from herdr's [[startup]] hook, on pane.agent_status_changed, and from the
# `Refresh agent prompts` action -- see herdr-plugin.toml for what each is for.

set -uo pipefail

herdr=${HERDR_BIN_PATH:-herdr}

# How much of the prompt to keep. Herdr caps token values at 80 characters, so
# the cut happens here to get an ellipsis rather than a word sliced in half.
# Deliberately wider than the 36 columns sidebar_max_width allows: herdr elides
# an over-long token itself, fitted to whatever width the sidebar actually has,
# so a long value means widening sidebar_max_width shows more of the prompt with
# no change here.
max=${HERDR_LAST_PROMPT_MAX:-72}

# Which panes to refresh. pane.agent_status_changed names the pane it is about,
# and refreshing only that one keeps the event path to a single `pane get` --
# which matters, because the event fires on every idle/working/blocked transition
# of every agent, several times per turn. HERDR_PANE_ID is not used for this: on
# the event it appeared to be the affected pane rather than the focused one, but
# the event payload says so unambiguously and costs nothing to read.
#
# Everything else (startup, the manual action) has no pane in mind and does the
# lot. Startup is the one that matters: token metadata is not restored after a
# server restart, so without it every row comes back blank and stays blank until
# its agent next changes state.
pane_id=$(printf '%s' "${HERDR_PLUGIN_EVENT_JSON:-}" \
  | jq -r '.data.pane_id // empty' 2>/dev/null)

if [[ -n $pane_id ]]; then
  targets=$("$herdr" pane get "$pane_id" 2>/dev/null | jq -r '
    .result.pane
    | select((.agent_session.value // "") != "")
    | [.pane_id, .agent, .agent_session.value] | @tsv')
else
  targets=$("$herdr" agent list 2>/dev/null | jq -r '
    .result.agents[]?
    | select((.agent_session.value // "") != "")
    | [.pane_id, .agent, .agent_session.value] | @tsv')
fi
[[ -n $targets ]] || exit 0

while IFS=$'\t' read -r pane kind session; do
  [[ -n ${session:-} ]] || continue

  # One entry per agent kind whose prompt log is a shared JSONL keyed by session.
  # An agent with no entry here simply gets no prompt row, which is what an
  # unrecognised kind should do. Codex honours CODEX_HOME.
  case $kind in
    claude) file=$HOME/.claude/history.jsonl; skey=sessionId; tkey=display ;;
    codex)  file=${CODEX_HOME:-$HOME/.codex}/history.jsonl; skey=session_id; tkey=text ;;
    *) continue ;;
  esac
  [[ -r $file ]] || continue

  # jq streams JSONL a record at a time, so `select` on the session id and
  # `tail -1` is the whole of "last prompt of this session" -- no map to build,
  # no byte offset to remember. herdr-bar needs that machinery only because it is
  # a long-lived poller; a one-shot can just read the file. Measured at 8ms over
  # 2223 records, which is why there is no tail window either.
  #
  # A record still being written aborts jq at that line, after the complete
  # records before it have already been printed -- so a partial final write
  # costs that one record rather than the answer, and needs no handling.
  #
  # Slash commands are filtered before tail -1, not after: /model, /resume and
  # the rest are addressed to the CLI rather than to the agent, so the last of
  # them says nothing about what the pane is doing, and the last real prompt is
  # the one wanted.
  prompt=$(jq -r --arg s "$session" --arg sk "$skey" --arg tk "$tkey" \
    --argjson max "$max" '
      select(.[$sk] == $s)
      | (.[$tk] // "")
      | gsub("\\s+"; " ") | sub("^ "; "") | sub(" $"; "")
      | select(length > 0)
      | select(startswith("/") | not)
      | if (length > $max) then (.[0:$max-1] + "…") else . end
    ' "$file" 2>/dev/null | tail -n 1)

  # Nothing found means a session that has not reached its log yet, or one whose
  # history persistence is off. Left alone rather than cleared: whatever the row
  # already says is still the last thing actually asked.
  [[ -n $prompt ]] || continue

  # One stable --source: a pane accepts sequenced token reports from at most 32
  # distinct sources in its lifetime, and clearing or expiry does not give a slot
  # back. --seq because this does run concurrently -- status changes arrive fast
  # enough for two invocations to overlap, and without it the one that read the
  # log first could land last. No --ttl-ms: the value should stand until the next
  # prompt replaces it, not blank out mid-task.
  "$herdr" pane report-metadata "$pane" --source prompts \
    --seq "$(date +%s%N)" \
    --token "last_prompt=$prompt" >/dev/null 2>&1
done <<<"$targets"
