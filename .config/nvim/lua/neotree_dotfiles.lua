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
local file_items = require("neo-tree.sources.common.file-items")
local log = require("neo-tree.log")
local manager = require("neo-tree.sources.manager")
local renderer = require("neo-tree.ui.renderer")

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

  file_items.advanced_sort(root.children, state)
  renderer.show_nodes({ root }, state)

  if type(callback) == "function" then
    vim.schedule(callback)
  end
end

M.setup = function(config, global_config) end

return M
