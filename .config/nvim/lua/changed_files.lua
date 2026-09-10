-- Agent-touched files: everything changed against HEAD, most recently written
-- first, with +/- counts.
--
-- The ordering is the whole point. `:Telescope git_status` already lists the
-- same set with a diff preview, but sorts by path -- which buries the file an
-- agent rewrote thirty seconds ago among the twenty it touched earlier in the
-- run. mtime is the only signal here that tracks *recency of work*, and it
-- needs no cooperation from the agent: sidekick's session state knows which
-- tools are attached but nothing about the files they write.

local M = {}

-- Clamped at zero: an mtime ahead of the clock is not hypothetical -- a file
-- copied from a machine whose clock is fast, or an unpacked archive carrying
-- its own timestamps, both produce one, and without the clamp it renders as a
-- negative age and sorts above genuinely recent work.
local function age(secs)
  local d = math.max(0, os.time() - secs)
  if d < 60 then
    return d .. "s"
  elseif d < 3600 then
    return math.floor(d / 60) .. "m"
  elseif d < 86400 then
    return math.floor(d / 3600) .. "h"
  end
  return math.floor(d / 86400) .. "d"
end

local function collect()
  local root = vim.fs.root(0, ".git")
  if not root then
    return nil, nil
  end

  local items = {}

  local function add(path, plus, minus)
    local abs = root .. "/" .. path
    local st = vim.uv.fs_stat(abs)
    items[#items + 1] = {
      path = path,
      abs = abs,
      plus = plus,
      minus = minus,
      mtime = st and st.mtime.sec or 0,
      untracked = plus == nil,
    }
  end

  -- --numstat rather than --stat: machine-readable counts, no bar graph to
  -- parse back out. HEAD, not --cached, so staged and unstaged both land.
  local tracked = vim.system(
    { "git", "-C", root, "diff", "--numstat", "HEAD" }, { text = true }):wait()
  for line in (tracked.stdout or ""):gmatch("[^\n]+") do
    local plus, minus, path = line:match("^(%S+)\t(%S+)\t(.+)$")
    -- Binary files report "-\t-"; keep them, they just have no counts.
    if path then
      add(path, tonumber(plus) or 0, tonumber(minus) or 0)
    end
  end

  -- Agents create files as often as they edit them, and a new file shows up
  -- in neither `diff HEAD` nor `diff --cached` until it is added.
  local new = vim.system(
    { "git", "-C", root, "ls-files", "--others", "--exclude-standard" },
    { text = true }):wait()
  for path in (new.stdout or ""):gmatch("[^\n]+") do
    add(path, nil, nil)
  end

  table.sort(items, function(a, b)
    return a.mtime > b.mtime
  end)

  return items, root
end

function M.pick()
  local items, root = collect()
  if not items then
    return vim.notify("not in a git repository", vim.log.levels.WARN)
  end
  if #items == 0 then
    return vim.notify("no changes against HEAD", vim.log.levels.INFO)
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local previewers = require("telescope.previewers")
  local entry_display = require("telescope.pickers.entry_display")
  local conf = require("telescope.config").values

  local displayer = entry_display.create({
    separator = " ",
    items = { { width = 4 }, { width = 4 }, { width = 6 }, { remaining = true } },
  })

  pickers.new({}, {
    prompt_title = "Changed files, newest first",
    finder = finders.new_table({
      results = items,
      entry_maker = function(item)
        return {
          value = item,
          path = item.abs,
          ordinal = item.path,
          display = function(entry)
            local it = entry.value
            return displayer({
              { it.untracked and "new" or ("+" .. it.plus), "DiffAdded" },
              { it.untracked and "" or ("-" .. it.minus), "DiffRemoved" },
              { age(it.mtime), "Comment" },
              it.path,
            })
          end,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_termopen_previewer({
      get_command = function(entry)
        local it = entry.value
        -- An untracked file has nothing to diff against, so --no-index against
        -- /dev/null renders the whole thing as an addition rather than blank.
        if it.untracked then
          return { "git", "-C", root, "diff", "--no-index", "--color=always",
                   "/dev/null", it.path }
        end
        return { "git", "-C", root, "diff", "--color=always", "HEAD", "--", it.path }
      end,
    }),
  }):find()
end

-- Exposed so the list is usable without the picker -- a statusline count, a
-- quickfix dump, or a test.
M.collect = collect
M.age = age

return M
