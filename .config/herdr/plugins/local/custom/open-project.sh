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
#
# ── Two phases, because a clone cannot happen inside its own layout ─────────
#
# Pasting a git URL runs this script twice. Phase 1 is the popup: it picks the
# destination, validates the URL, then opens a full-size tab in the CURRENT
# workspace and hands off to phase 2 there. Phase 2 does the clone, and on
# success runs the same workspace-create/layout tail every other path uses, so
# the new workspace is created and focused only once there is a repo to open.
#
# It cannot be the new workspace's own zsh tab, which is the obvious place to
# want it. The `standard` layout stands up lazygit, `hunk diff --watch`,
# `hunk --staged --watch`, hunk-branch-diff, nvim and a claude agent at the
# same moment as that zsh pane, and none of them re-reads the directory later:
# lazygit would come up on its "initialize a new repo?" prompt, the three hunk
# panes with no repo to diff, and the agent with an empty cwd. Cloning into a
# layout that is already running means six broken panes that a finished clone
# does not repair. So the ordering is fixed -- repo first, layout second -- and
# the clone gets a tab of its own in the workspace you started from.
#
# Phase 2 is entered via the environment, not argv: `herdr tab create --env`
# carries the URL and destination as JSON, so neither is ever spliced into a
# shell command line and there is no quoting to get wrong (verified with a path
# containing a single quote and a space). `herdr pane run` types into the new
# pane's interactive shell and returns immediately, which is what lets phase 1
# exit and close its popup while the clone runs.
set -uo pipefail

# Absolute, because phase 2 runs with the new tab's cwd, not the plugin root
# that herdr gives a plugin pane -- a relative $0 would not resolve there.
self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")

# Three actions, one script, one code path: "Open project", "Clone git repo"
# (--clone) and "New project" (--new). Splitting them into separate scripts would
# mean either duplicating the workspace-create/layout tail at the bottom three
# times or re-entering this one anyway.
#
# --clone only changes the header; pasting a URL works from any of the three,
# because a URL is never a name you would want a directory called. --new is the
# one that changes a meaning: Enter creates the typed name instead of opening
# whatever the query matched. That is the whole reason it exists as its own
# entry point -- in the other two, "ap" where "apple" exists can only ever open
# ~/dev/apple, per the usual fzf convention, and no character appended to the
# query could mark "create this instead" (a trailing slash looks like it would,
# but the rows are full paths containing slashes, so `de/` fuzzy-matches
# ~/dev/docker).
clone_hint=
new_hint=
case ${1:-} in
  --clone) clone_hint=1 ;;
  --new)   new_hint=1 ;;
esac

# Set only by phase 1, and their presence IS the phase-2 signal. That also makes
# closing $HERDR_TAB_ID safe at the end: a tab is only ever closed when this run
# was spawned into one, never when the script is invoked by hand from an
# ordinary pane.
clone_url=${HERDR_CUSTOM_CLONE_URL:-}
clone_dest=${HERDR_CUSTOM_CLONE_DEST:-}

# Phase 2 errors need no `sleep` to be readable: the tab keeps its scrollback
# and hands back to a shell prompt. Phase 1 is a popup that vanishes on exit,
# which is why its messages below are followed by one.
fail() {
  printf '\033[31m%s\033[0m\n' "$1"
  exit 1
}

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
# Enter with nothing highlighted -- i.e. a typed name that matches no existing
# directory -- creates it under $dir only in --new. Open project and Clone git
# repo treat it as a miss and close: creating used to live here too, which meant
# every mistyped name silently became a directory, and it is New project's job
# now. --print-query is what makes the typed text available at all: with no match
# there is no selection line to read, and fzf otherwise discards the query on
# accept. Output order is query, then the --expect key, then the selection.
#
# A query that *does* substring-match something still opens the match, per
# the usual fzf convention -- typing "foo" where "foobar" exists cannot
# create "foo". That asymmetry is why --new exists as its own entry point
# rather than as a key inside this one.
#
# A query that looks like a git URL is the exception to all of that: it
# clones. It is tested before the selection is consulted, so a URL that
# happens to fuzzy-match a directory still clones rather than opening the
# match. The browsing position is the destination -- there is no separate
# path prompt, because "which directory is this going into" is the question
# the browser already answers, and the answer is already on screen in the
# prompt.
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

# SSH only: the shorthand (git@host:org/repo.git) or an explicit ssh:// URL.
#
# Deliberately not the bare owner/repo form gh accepts: that is
# indistinguishable from a nested directory name, which is a thing this picker
# legitimately creates.
#
# Nothing a real directory would be called can match -- a path component may
# contain @ and :, but "user@host:" at the very front of a typed name is not
# something anyone means as a subdirectory of $dir.
is_git_url() {
  [[ $1 =~ ^([A-Za-z0-9._-]+@[A-Za-z0-9.-]+:|ssh://) ]]
}

# The clone URLs that are recognised in order to be turned down: http(s),
# because cloning over it is not wanted here, and git://, because it is
# unauthenticated, unencrypted and effectively dead.
#
# Recognised rather than simply not matched, which would be one line shorter:
# unmatched means the create-a-directory path below takes the URL as a name and
# `mkdir -p`s a tree out of it -- `https:/github.com/org` with a `repo.git`
# inside it -- which then has to be noticed and deleted. Saying no costs
# nothing and names the fix.
is_rejected_url() {
  [[ $1 =~ ^(https?|git):// ]]
}

# Create $1 as a directory (under $2, or at face value if it is absolute or
# ~-rooted) and set $target to it.
#
# mkdir -p, so "clients/acme" creates both levels, and a query given as an
# absolute or ~ path is taken at face value rather than nested under $2 -- the
# rows are displayed in that form, so one can be pasted.
#
# git init, because the layout assumes a repo: globalLayout `standard` gives
# every workspace a lazygit tab and a `hunk diff --watch` tab, and in a plain
# directory both open broken -- lazygit on its "initialize a new repo?" prompt,
# hunk with nothing to diff. Creating a directory through this picker already
# means "this is a project".
#
# Only a directory this call actually CREATED is initialised, which is why the
# existence test comes before the mkdir. Otherwise a query naming a directory
# that exists but is not listed would init it, and the listing hides plenty:
# every dotfile directory, so typing `.config` from $HOME reaches ~/.config,
# where `rev-parse` fails (the dotfiles work tree is $HOME but its git dir is
# the bare ~/.dotfiles, which discovery never finds) and a stray `git init`
# would land in the middle of the real config tree. Same shape of accident as
# init-ing ~/dev/apple, which holds twenty unrelated checkouts.
#
# The rev-parse guard is still wanted on top of that: typing a name while
# browsing inside a checkout (say ~/dev/some-repo/docs) would otherwise nest a
# repo in a repo, which is a nuisance to unpick and never the intent. rev-parse
# failing outright is the only safe signal -- it means no work tree encloses
# $target. A successful one covers both "already a repo root" and "inside
# somebody else's", and neither wants another init.
#
# Nothing beyond `init`: no first commit, no README, no .gitignore. That is
# scaffolding, a separate decision from "make this a repo". An unborn HEAD suits
# both panes fine. init.templateDir installs the commit-msg hook here, and with
# no scopedcommits.scopes set in the new repo it allows any scope, so it will
# not block the early commits.
create_project_dir() {
  local query=$1 base=$2 fresh toplevel

  case $query in
    /* | '~'/*) target=${query/#\~/$HOME} ;;
    *)          target=$base/$query ;;
  esac

  fresh=1
  [[ -e $target ]] && fresh=

  mkdir -p "$target" \
    || { printf '\033[31mmkdir %s failed\033[0m\n' "$target"; sleep 2; exit 1; }

  if [[ -n $fresh ]]; then
    toplevel=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null)
    if [[ -z $toplevel ]]; then
      git -C "$target" init --quiet \
        || { printf '\033[31mgit init %s failed\033[0m\n' "$target"; sleep 2; exit 1; }
    fi
  fi
}

# Trailing slash first, so a URL written with one still has its .git stripped;
# then the last path component, then the last colon component for the SSH
# shorthand, where there may be no slash at all (git@host:repo.git).
#
# Run in both phases. Phase 1 checks it so the popup can refuse without leaving
# a tab behind; phase 2 checks it again because it is reachable on its own, and
# a name is what an `rm -rf` path is built from.
repo_name_from_url() {
  local n=${1%/}
  n=${n%.git}
  n=${n##*/}
  n=${n##*:}
  [[ -n $n && $n != . && $n != .. ]] || return 1
  printf '%s\n' "$n"
}

# Phase 1's half of the handoff: a focused tab in the workspace this was invoked
# from, with the clone's inputs in its environment, and the script itself typed
# into its shell.
spawn_clone() {
  local dest=$1 url=$2 label=$3
  local ws=${HERDR_WORKSPACE_ID:-} tab tab_id pane

  # HERDR_WORKSPACE_ID is the invoking workspace even for a plugin popup pane
  # (clone-pr.sh relies on the same thing). The fallback is for a hand-run
  # invocation, where nothing injected it.
  if [[ -z $ws ]]; then
    ws=$(herdr workspace list 2>/dev/null \
      | jq -r '.result.workspaces[]? | select(.focused) | .workspace_id' | head -n1)
  fi

  local args=(--cwd "$dest" --label "clone: $label" --focus)
  [[ -n $ws ]] && args+=(--workspace "$ws")

  tab=$(herdr tab create "${args[@]}" \
          --env "HERDR_CUSTOM_CLONE_URL=$url" \
          --env "HERDR_CUSTOM_CLONE_DEST=$dest") || return 1
  tab_id=$(jq -r '.result.tab.tab_id // .result.root_pane.tab_id // empty' <<<"$tab")
  pane=$(jq -r '.result.root_pane.pane_id // empty' <<<"$tab")
  [[ -n $pane ]] || return 1

  # A guess, like the one in config.toml's prefix+shift+o binding: the pane's
  # shell has to be far enough up to read what `pane run` types, and zsh's line
  # editor starting up is the part that could swallow it. Shorten or lengthen if
  # the command ever lands garbled.
  sleep 0.4

  # Only the script path is typed, and it is a fixed path under ~/.config with
  # no shell metacharacters in it. Everything variable went via --env above.
  #
  # No `bash` prefix, unlike the manifest's own pane commands: those are an
  # argv array herdr execs with cwd at the plugin root, where naming the
  # interpreter also saves a `./`. This is text typed into an interactive shell
  # that shows up on screen, so the shebang does the job and the word would be
  # noise. The file is 755 in git as well as on disk, so a fresh checkout keeps
  # the bit -- and if it ever lost it, the tab would say "permission denied"
  # rather than failing quietly.
  #
  # Not `exec`: replacing the tab's interactive shell would leave nothing behind
  # when the script exits, so a failed clone would take its own error message
  # down with it as herdr reclaimed the dead pane. Run as a child and the prompt
  # comes back underneath the output instead.
  herdr pane run "$pane" "'$self'" >/dev/null || return 1
  printf 'cloning in tab %s\n' "${tab_id:-?}"
}

# Phase 2. Sets $target on success.
clone_repo() {
  local dest=$1 url=$2 name staging

  is_rejected_url "$url" && fail "only SSH clone URLs are accepted: $url"
  is_git_url "$url" || fail "not an SSH clone URL: $url"
  name=$(repo_name_from_url "$url") || fail "could not read a repo name out of $url"
  [[ -d $dest ]] || fail "destination directory does not exist: $dest"

  target=$dest/$name
  # Refuse rather than adopt. An existing directory of the right name is
  # usually the same repo already cloned, and opening it would be right --
  # but "usually" is doing real work there, and quietly opening an unrelated
  # checkout that happens to share a basename is worse than saying so. Open
  # it from the listing (it is one row up in the picker) or move it aside.
  #
  # Checked in phase 1 as well, so the popup can say so without spending a tab
  # on it. Repeated here because a slow clone leaves a real window in which the
  # answer can change.
  [[ -e $target ]] && fail "${target/#$HOME/\~} already exists"

  # Clone to a hidden sibling and move it into place, so an abandoned clone
  # never leaves a half-repo where a project should be.
  #
  # Not a substitute for git's own cleanup, which is better than it looks: a
  # clone that *fails* -- bad host, no such repo, no key -- removes the
  # directory it created, verified. What it does not clean up is being
  # interrupted after the objects have transferred: on TERM, INT and KILL
  # alike, git reports "Clone succeeded, but checkout failed" and keeps the
  # directory, with an incomplete working tree. That is the leftover this
  # guards against, and it is the bad kind -- a directory that reads as a
  # checkout, with files missing.
  #
  # It matters here rather than being tidiness because the destination is
  # refused if it exists (above). Debris at the real path would brick the
  # action for that repo until it is deleted by hand -- and the refusal would
  # not explain why. Staged, the next attempt just removes it and proceeds.
  # The two decisions are a pair; drop one and the other stops being worth
  # much.
  #
  # Cleanup cannot be done on the way out instead: closing the tab kills its
  # process group, and a SIGKILL runs no trap. So the guarantee has to be
  # structural -- the visible path is only ever created by a clone that
  # finished. The leading dot keeps the debris out of the picker's own listing,
  # which filters `.*`, and out of everything else that ignores dotfiles.
  #
  # That leading dot also rules out colliding with a branch-derived sibling
  # directory -- a worktree for a branch named `cloning`, say. Git rejects a
  # ref component that starts with `.` (`git check-ref-format` refuses
  # `refs/heads/.pulse.cloning`), so no branch can produce this name however
  # a tool chooses to spell a worktree path. `rm -rf` below makes that worth
  # being sure about.
  #
  # Removed up front rather than only on failure, for exactly that reason:
  # the leftover from a killed run is the normal case, and `git clone`
  # refuses a non-empty directory.
  staging=$dest/.$name.cloning
  rm -rf "$staging"

  # Said explicitly because git will announce the staging path, not this one,
  # and "Cloning into '.pulse.cloning'" on its own reads like a mistake.
  printf '\033[1mcloning\033[0m %s\n\033[1m     to\033[0m %s\n\n' \
    "$url" "${target/#$HOME/\~}"

  # Not quiet: clone progress is the reason this runs in a tab at all. No
  # keypress to hold the output either -- the shell prompt comes back under it
  # and the tab stays until closed, which is the whole advantage over the popup.
  if ! git clone "$url" "$staging"; then
    rm -rf "$staging"
    printf '\n\033[31mgit clone failed -- see above.\033[0m\n'
    exit 1
  fi

  # Re-checked, because `mv` onto an existing directory moves the source
  # *inside* it rather than failing, and macOS mv has no --no-target-directory
  # to forbid that. Only reachable if something created $target during the
  # clone, so the staging directory is left for salvage rather than deleted.
  [[ -e $target ]] && fail \
    "${target/#$HOME/\~} appeared during the clone; the clone is at ${staging/#$HOME/\~}"
  mv "$staging" "$target" || fail "mv ${staging/#$HOME/\~} failed"

  # No git init here, unlike the create-a-directory path in the picker, and no
  # need for its is-this-already-a-repo guard: a clone is a repo.
  # init.templateDir applies to `clone` too, so the commit-msg hook lands the
  # same way, and with no scopedcommits.scopes set in the new checkout it allows
  # any scope.
  printf '\n\033[1mcloned\033[0m %s -- opening workspace\n' "${target/#$HOME/\~}"
}

# Last thing this script does when it was spawned into a tab: the clone tab has
# served its purpose once the new workspace is up, and leaving it would put a
# stale "clone: name" tab in the workspace you started from. Closing it kills
# this very process, so nothing may follow it.
#
# Not called on the failure paths, deliberately -- a failed clone's output is
# the only record of why, and it should stay on screen.
close_clone_tab() {
  [[ -n $clone_url && -n ${HERDR_TAB_ID:-} ]] || return 0
  herdr tab close "$HERDR_TAB_ID" >/dev/null 2>&1
}

if [[ -n $clone_url ]]; then
  clone_repo "$clone_dest" "$clone_url"
  dir=$target
else
  # The prompt already names the destination on every row, so the header only
  # has to say what the gesture is. Built once: the loop re-runs fzf on each
  # navigation, and the hint should survive descending.
  #
  # --color rides along in the array purely so it is never empty. Under
  # `set -u`, bash 3.2 rejects "${arr[@]}" on an empty array as an unbound
  # variable, and the pane runs whatever `bash` the herdr server's PATH resolves
  # -- /bin/bash on macOS is still 3.2, and a GUI-launched server does not
  # necessarily have homebrew's bin ahead of it.
  #
  # Plain "Open project" and "New project" get no header: the pane title already
  # names the action, and a row of chrome restating it earns nothing. Clone is the
  # exception -- pasting a URL is a gesture the picker gives no other hint of.
  fzf_args=(--color=fg:blue)
  [[ -n $clone_hint ]] && fzf_args+=(
    --header="↵ on a pasted git SSH URL → clone into this directory · ←/→ browse"
  )

  # `sort -r` so the list READS a-z. fzf's default layout puts the prompt at the
  # bottom and grows the list upward from it, which means the first input line
  # lands nearest the prompt and plain `sort` renders z-at-the-top. Reversing the
  # data is the fix that leaves the prompt where it is; --layout=reverse would
  # also do it, by moving the prompt to the top instead.
  #
  # Consequence worth knowing: the cursor starts on the first INPUT line, which
  # is now the alphabetically last directory -- bottom of the list, next to the
  # prompt, where the cursor already was.
  dir=~/dev
  while true; do
    result=$(
      find "$dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | sort -r \
        | tilde \
        | fzf --expect=enter,right,left \
              --print-query \
              "${fzf_args[@]}" \
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

    if [[ $key != right ]] && is_rejected_url "$query"; then
      printf '\033[31monly SSH clone URLs are accepted -- paste the git@ or ssh:// one\033[0m\n'
      sleep 3
      exit 1
    fi

    # A pasted git URL clones into the directory being browsed. Tested before
    # $choice is looked at, so a fuzzy match is not consulted at all -- see the
    # header comment. Right is excluded because it means "descend", and a URL
    # is not something to descend into.
    #
    # Nothing is cloned here: this hands off to a tab and the popup closes. See
    # the two-phase note at the top for why the clone cannot happen in the new
    # workspace it is destined for.
    if [[ $key != right ]] && is_git_url "$query"; then
      repo=$(repo_name_from_url "$query") || {
        printf '\033[31mcould not read a repo name out of %s\033[0m\n' "$query"
        sleep 2
        exit 1
      }
      if [[ -e $dir/$repo ]]; then
        printf '\033[31m%s already exists\033[0m\n' "${dir/#$HOME/\~}/$repo"
        sleep 2
        exit 1
      fi
      spawn_clone "$dir" "$query" "$repo" || {
        printf '\033[31mcould not open a tab for the clone\033[0m\n'
        sleep 2
        exit 1
      }
      exit 0
    fi

    # "New project": Enter creates the typed name in the directory being
    # browsed, whatever the query matched. The browsing position is the parent,
    # the same way it is the clone destination -- ←/→ pick where it goes, the
    # query is what it is called.
    #
    # Right is excluded so descending still works; Left was handled above.
    #
    # An empty query has nothing to create, so Enter on one re-prompts instead
    # of acting. It must not fall through to open the highlighted row -- this
    # action never opens anything that already exists, which is what makes it
    # predictable enough to be worth its own entry point -- and closing on a
    # keystroke that expressed no intent is just as wrong. Esc is how you leave.
    #
    # Placed after the URL branches deliberately: a pasted URL means clone here
    # too, since it is never a name you would want a directory called.
    if [[ -n $new_hint && $key != right ]]; then
      [[ -n $query ]] || continue
      create_project_dir "$query" "$dir"
      dir=$target
      break
    fi

    # Nothing matched, and it was not a URL. Nothing left to do: this action
    # opens what exists, and creating is New project's job.
    #
    # In --new the only way to arrive here is Right with nothing to descend into,
    # which re-prompts for the same reason Enter on an empty query does -- a key
    # that could not do anything should not close the popup.
    #
    # Otherwise it is said rather than closing silently. A typed name that
    # vanishes without a word is indistinguishable from one that worked -- and it
    # used to work, which is exactly the habit this will be caught by. Not red: a
    # query that matches nothing is an ordinary answer, not an error. Short
    # enough not to punish a typo.
    if [[ -z $choice ]]; then
      [[ -n $new_hint ]] && continue
      [[ -n $query ]] && {
        printf 'no match for %s -- "New project" creates\n' "$query"
        sleep 1.5
      }
      exit 0
    fi

    dir=$choice
    [[ $key == right ]] || break
  done
fi

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
  close_clone_tab
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

close_clone_tab
