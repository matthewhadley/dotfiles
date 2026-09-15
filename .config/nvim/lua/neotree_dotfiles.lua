-- A neo-tree source: the files tracked in the bare dotfiles repo at
-- ~/.dotfiles, rendered as a filesystem tree rooted at $HOME.
--
-- Why a source rather than a filter on the filesystem source:
--
--   * filtered_items has no allowlist mode and no filter-function hook. Its
--     options can only subtract from a directory listing, and the tracked
--     files are scattered across $HOME among thousands of untracked ones.
--   * The .neotreeignore route looks like it would work -- neo-tree parses it
--     with full gitignore semantics, negation included -- but mark_ignored()
--     walks parent directories all the way to "/". An ignore file at $HOME
--     would therefore apply to every tree beneath it, blanking every project
--     under ~/dev.
--
-- A source builds its own item list, so it filters by construction and affects
-- nothing else.

local common_commands = require("neo-tree.sources.common.commands")
local events = require("neo-tree.events")
local file_items = require("neo-tree.sources.common.file-items")
local git = require("neo-tree.git")
local git_parser = require("neo-tree.git.parser")
local log = require("neo-tree.log")
local manager = require("neo-tree.sources.manager")
local renderer = require("neo-tree.ui.renderer")
local utils = require("neo-tree.utils")

-- Commands built from the common set rather than the filesystem source's.
--
-- The filesystem source wraps `open` so that expanding a directory calls
-- fs_scan.get_items, which rescans the real directory and reads
-- state.filtered_items -- a field only the filesystem source's config
-- populates. Borrowing its commands therefore crashed on any click that
-- expanded or collapsed a folder:
--
--   ignored.lua:81: attempt to index field 'filtered_items' (a nil value)
--
-- Even with that field supplied it would be wrong: a rescan lists everything
-- on disk, and this tree is meant to hold only the tracked files. The common
-- `open` takes no toggle_directory callback, so it just expands or collapses
-- the node that navigate() already built. Same reason git_status uses these.
local commands = {}
common_commands._add_common_commands(commands)

---@class neotree.sources.Dotfiles : neotree.Source
local M = {
  name = "dotfiles",
  display_name = " Dotfiles ",
  -- neo-tree looks for `<module>.components` and `<module>.commands` as
  -- submodules unless the module supplies them directly, which is what keeps
  -- this a single file rather than a package directory. Components still come
  -- from the filesystem source: the global renderers reference its components
  -- (icon, container, git_status, diagnostics), and merge_renderers only
  -- copies a renderer whose components all exist here -- a narrower set would
  -- silently render nothing.
  components = require("neo-tree.sources.filesystem.components"),
  commands = commands,
}

M.refresh = function()
  manager.refresh(M.name)
end

-- `refresh` is a per-source command, not one of the common ones added above,
-- so the default `R` mapping has nothing to resolve to and neo-tree logs
-- "[Neo-tree WARN] Invalid mapping for R : refresh" while binding keys. The
-- module's own M.refresh takes no state argument, which is fine -- a command
-- is called as command(state) and this one just ignores it.
commands.refresh = M.refresh

-- ls-files only reports paths under the directory it runs in, so cwd must be
-- the work tree root or this silently returns nothing.
local function tracked_files()
  local home = assert(vim.env.HOME)
  local res = vim.system({
    "git",
    "--git-dir=" .. home .. "/.dotfiles",
    "--work-tree=" .. home,
    "ls-files",
  }, { cwd = home, text = true }):wait()

  if res.code ~= 0 then
    return nil, vim.trim(res.stderr or "git ls-files failed")
  end

  local paths = {}
  for _, rel in ipairs(vim.split(vim.trim(res.stdout or ""), "\n", { plain = true })) do
    if rel ~= "" then
      paths[#paths + 1] = home .. "/" .. rel
    end
  end
  return paths
end

-- Register $HOME as a git worktree, so the git_status component has something
-- to find for these nodes.
--
-- The component takes nothing off `state`: it calls git.find_existing_worktree
-- to walk a module-global registry that git.status() populates. git.status()
-- cannot populate it here, because it locates the repo by running rev-parse
-- from the path -- and $HOME holds no .git, the repo being bare at
-- ~/.dotfiles. Discovery fails, no worktree is ever registered, and every node
-- renders without a marker. Hence building the entry by hand.
--
-- Writing to that global registry is safe because it is keyed by worktree root
-- and find_existing_worktree returns the *longest* root containing the path. A
-- project under ~/dev keeps its own status; only paths with no nearer worktree
-- fall through to this entry, and for those the dotfiles status is the right
-- answer rather than a leak. This is the opposite of the .neotreeignore
-- problem described at the top: that one imposed $HOME's rules on subtrees
-- that had their own, this one is shadowed by them.
--
-- -uno rather than leaning on the repo's own status.showUntrackedFiles=no: an
-- untracked path bubbles "?" up to its parent directories, and those
-- directories are in this tree even when the file that explains the marker is
-- not.
---@return boolean? ok
---@return string? err
local function load_git_status(home)
  local res = vim.system({
    "git",
    "--git-dir=" .. home .. "/.dotfiles",
    "--work-tree=" .. home,
    "status",
    "--porcelain=v1",
    "-z",
    "-uno",
  }, { cwd = home, text = true }):wait()

  if res.code ~= 0 then
    return nil, vim.trim(res.stderr or "git status failed")
  end

  -- -z gives NUL-terminated records with paths unquoted and relative to the
  -- work tree root; the parser makes them absolute and bubbles each status up
  -- to the parent directories, which is what colours a collapsed folder.
  local status =
    git_parser.parse_status_porcelain(1, home, utils.gsplit_plain(res.stdout or "", "\0"), false)

  local worktree = git.worktrees[home]
  if worktree then
    worktree.status = status
  else
    git.worktrees[home] = {
      git_dir = home .. "/.dotfiles",
      status = status,
      status_diff = {},
      status_progress = {},
    }
    -- Misses are memoised as `false`, so any path probed before now is pinned
    -- at "no worktree above this". Dropping the cache on a new registration is
    -- what neo-tree does for its own.
    git._upward_worktree_cache = setmetatable({}, { __mode = "kv" })
  end

  return true
end

---@param state neotree.State
M.navigate = function(state, path, path_to_reveal, callback, async)
  local home = assert(vim.env.HOME)
  state.path = home
  state.dirty = false

  local files, err = tracked_files()
  if not files then
    log.error("dotfiles: " .. err)
    return
  end

  local context = file_items.create_context()
  context.state = state

  local root = file_items.create_item(context, home, "directory")
  root.name = vim.fn.fnamemodify(home, ":~")
  root.loaded = true
  context.folders[root.path] = root

  -- create_item fills in any missing parent directories on the way down, so
  -- the intermediate folders appear without being listed explicitly.
  for _, abs in ipairs(files) do
    local ok, item = pcall(file_items.create_item, context, abs, "file")
    if not ok then
      log.error("dotfiles: could not add " .. abs .. ": " .. tostring(item))
    end
  end

  -- Expand everything: the whole point is seeing the tracked set at a glance,
  -- and there are few enough files that collapsed folders only cost clicks.
  state.default_expanded_nodes = {}
  for id in pairs(context.folders) do
    table.insert(state.default_expanded_nodes, id)
  end

  -- Non-fatal: a tree with no markers still lists the right files, so a git
  -- failure should not cost you the tree. Must run before show_nodes, which is
  -- what invokes the components.
  local _, git_err = load_git_status(home)
  if git_err then
    log.error("dotfiles: " .. git_err)
  end

  file_items.advanced_sort(root.children, state)
  renderer.show_nodes({ root }, state)

  if type(callback) == "function" then
    vim.schedule(callback)
  end
end

-- Refresh on write, so the markers do not go stale the moment you save.
--
-- navigate() is the only thing that loads the git status, and nothing else
-- calls it. The filesystem source stays current via FS_EVENT from a libuv
-- watcher, which is not available here: a watcher watches a directory, and
-- this tree's contents come from a git query rather than any one directory.
-- That leaves the write event, which is what neo-tree falls back to when the
-- watcher is off.
--
-- VIM_BUFFER_CHANGED is neo-tree's name for BufWritePost, debounced 200ms, so
-- a flurry of saves collapses into one git call.
--
-- Cheap when the tree is closed: manager.refresh skips any state whose window
-- does not exist, flagging it dirty instead, so saves in unrelated projects do
-- not trigger a git query -- and the tree still reloads when next opened.
M.setup = function(config, global_config)
  if global_config.enable_refresh_on_write == false then
    return
  end

  manager.subscribe(M.name, {
    event = events.VIM_BUFFER_CHANGED,
    handler = function(arg)
      -- Rejects neo-tree's own buffers and every non-empty buftype. Without
      -- it, writing any scratch or plugin buffer would spend a git status.
      if utils.is_real_file(arg.afile or "") then
        manager.refresh(M.name)
      end
    end,
  })
end

return M
