-- ~/.config/nvim/init.lua
-- Neovim config. `:h <option>` in nvim explains any of these, e.g. `:h number`

-- ── Line numbers ─────────────────────────────────────────────────────────
vim.opt.number = true          -- plain absolute line numbers
vim.opt.relativenumber = false -- set true for "hybrid": every other line shows
                               -- its distance from the cursor, which doubles as
                               -- the count for a motion (a line showing 5 is `5k`)

vim.opt.signcolumn = "yes"    -- reserve the gutter so text doesn't jump around

-- ── Basics carried over from your ~/.vim/vimrc ───────────────────────────
vim.opt.hidden = true         -- let you switch buffers with unsaved changes
vim.opt.ignorecase = true     -- searches ignore case...
vim.opt.smartcase = true      -- ...unless you type a capital letter
vim.opt.scrolloff = 3         -- keep 3 lines of context above/below the cursor
vim.opt.cursorline = true     -- highlight the line you're on
vim.opt.fillchars:append({ eob = " " }) -- hide `~` on empty buffer lines
vim.opt.title = true          -- set the terminal window title
vim.opt.mouse = "a"           -- mouse works (fine to keep while learning)
vim.opt.clipboard = "unnamed" -- y/p use the system clipboard
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.modeline = false
vim.opt.undofile = true       -- undo history survives closing the file

-- Reload buffers on external edits. Neovim 0.12 has no filesystem watcher for
-- this, so poll for it at the usual trigger points; 0.13 does autoread via a
-- real watcher, so once on 0.13 this autocmd can go and `autoread` alone will
-- pick up changes in real time.
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  command = "checktime",
})

-- ── Indentation ──────────────────────────────────────────────────────────
vim.opt.tabstop = 4           -- a tab character renders 4 wide
vim.opt.shiftwidth = 4        -- >> and << shift by 4
vim.opt.expandtab = false     -- true = insert spaces instead of tab characters

-- ── Search ───────────────────────────────────────────────────────────────
-- hlsearch and incsearch are already on by default in Neovim.
-- <Esc> in normal mode clears the leftover search highlight:
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- ── Keymaps ──────────────────────────────────────────────────────────────
vim.keymap.set("n", ";", ":", { desc = "Enter command mode without Shift" })

-- `q` and `Q` are both disabled, because every way either fires here is an
-- accident on the way to quitting.
--
-- `q<register>` starts recording a macro, and worse, `q:`, `q/` and `q?` open
-- the command-line and search history windows -- a real buffer in a modal
-- split that looks like a broken editor when you did not ask for it, and that
-- `:q` then closes instead of quitting. A stray `q` before `:q` lands in one
-- or the other every time.
--
-- `Q` was briefly given the recording job instead, which was a bad trade: the
-- `:Q` command further down aliases `:qa`, so `Q` is quit-adjacent in exactly
-- the same way and would collect exactly the same accidents. Its own default
-- -- repeat the last recorded register -- is worthless with recording gone, so
-- it is a no-op too.
--
-- Mapped to <Nop> rather than removed: both are built-ins, not mappings, so
-- there is nothing to delete -- a no-op mapping is what shadows them.
--
-- This does not touch the `q` that closes help, quickfix, fugitive and other
-- plugin windows: those are buffer-local mappings, and a buffer-local mapping
-- takes precedence over a global one. Nor does it touch the `:Q` command --
-- that is an ex command typed after a colon, not this keypress.
--
-- Macro recording is therefore unreachable, which suits a workflow that has
-- never used it: pattern edits go through \fs and \fS, and a one-off
-- structural repeat is `:'<,'>normal <keys>`, which needs no recording at all.
-- `:nunmap q` brings it back for a session if that ever changes; `@` and the
-- registers are untouched, so an already-recorded macro still replays.
for _, key in ipairs({ "q", "Q" }) do
  vim.keymap.set("n", key, "<Nop>", { desc = "Disabled -- see :normal for repeats" })
end

-- Shift+arrows extend a selection, like most editors. "startsel" makes a
-- shifted cursor key begin the selection, "stopsel" makes an unshifted one end
-- it. Selection lands in Visual mode (not Select mode) because 'selectmode' is
-- left empty -- that matters: it means every vim operator still works on the
-- result, so d/y/gc/> all apply to what you highlighted.
vim.opt.keymodel = { "startsel", "stopsel" }

-- <Del> already deletes a Visual selection, but into the unnamed register --
-- which 'clipboard=unnamed' makes the system clipboard, so deleting a
-- selection silently destroys whatever you had copied. "_d routes it to the
-- black hole register instead, matching what every other editor does.
--
-- <BS> is mapped for the same reason it is elsewhere: unmapped, it does
-- nothing at all on a selection, which is surprising when <Del> works.
for _, key in ipairs({ "<Del>", "<BS>" }) do
  vim.keymap.set("x", key, '"_d', { desc = "Delete the selection, keep the clipboard" })
end

-- The same problem, and the same fix, for the operators you reach for far more
-- often. 'clipboard=unnamed' makes the unnamed register the system clipboard,
-- so `x` on a character and `dd` on a line both overwrite whatever you last
-- copied -- which is never what you meant by "delete this".
--
-- The tradeoff, taken deliberately: deleted text is *gone*, not cut, so `dd`
-- followed by `p` pastes the clipboard rather than the line just removed.
-- Vim's numbered registers do not rescue it either -- writing to "_ skips them
-- as well. That is the same bargain every non-modal editor makes, and it is
-- the one the <Del>/<BS> maps above already made for selections.
--
-- Two consequences worth knowing, both verified rather than assumed:
--
-- `ddp` -- the swap-this-line-with-the-next idiom -- stops working, and pastes
-- whatever is on the clipboard instead. Use `:m+1` to move a line down and
-- `:m-2` to move it up; neither touches a register at all.
--
-- Naming a register does NOT opt out. Typing `"add` sends `"a` and then the
-- mapping's own `"_`, which wins -- the line goes to the black hole and `"ap`
-- fails with E353. To cut deliberately, go through ex, which never sees the
-- normal-mode mapping: `:.d a` then `"ap`. Yanking is unaffected, so `"ayy`
-- also still works.
for _, key in ipairs({ "x", "X", "d", "D", "c", "C", "s", "S" }) do
  vim.keymap.set({ "n", "x" }, key, '"_' .. key,
    { desc = "As " .. key .. ", but keep the clipboard" })
end

-- Window navigation: <C-h/j/k/l>. Plain Ctrl+letter is a single ASCII control
-- byte, so it survives Ghostty -> Herdr -> nvim. Both Cmd+Shift+arrow and
-- Ctrl+arrow were tried first and neither reaches nvim at all (verified with
-- Ctrl-V literal-insert: nothing arrives) -- the multiplexer eats modified
-- special keys.
-- Insert mode is deliberately NOT mapped: <C-h> is byte 0x08, the same as
-- Backspace in many terminals, so mapping it there would break backspace.
-- Universal fallbacks that always work: <C-w>hjkl, or <C-w> then an arrow.
for lhs, dir in pairs({ ["<C-h>"] = "h", ["<C-j>"] = "j", ["<C-k>"] = "k", ["<C-l>"] = "l" }) do
  vim.keymap.set({ "n", "x" }, lhs, "<C-w>" .. dir, { desc = "Window: move " .. dir })
end

-- Mouse drag-select copies to the system clipboard, matching what Ghostty and
-- Herdr do on their own. Needed because mouse=a makes nvim capture the drag,
-- so the terminal never sees a selection of its own to auto-copy.
-- `"+ygv`, not just `"+y`: yanking exits visual mode and drops the cursor at
-- the start of the range, so `gv` puts the highlight straight back.
vim.keymap.set("x", "<LeftRelease>", '"+ygv', { desc = "Copy mouse selection to clipboard, keep selection" })

-- Comment toggling. `gcc` (line) and `gc` (motion/visual) are built into
-- Neovim 0.10+, no plugin needed -- these are just editor-style aliases.
-- <D-/> is Cmd+/ and only fires if the terminal forwards the Super modifier.
-- <C-_> is what most terminals actually send for Ctrl+/, kept as a fallback.

-- `gcc` is a no-op on a blank line. vim._comment calls a range commented when
-- every *non-blank* line in it is, so a range of nothing but blank lines
-- passes that test vacuously, takes the uncomment branch, and finds nothing to
-- strip. Write the marker in ourselves for that case, indented to match the
-- nearest code -- above by preference, below when the line opens a block.
-- Reads the buffer 'commentstring', so unlike gcc this is not injection-aware:
-- a blank line in a markdown code block gets markdown's comment rather than
-- the embedded language's.
local function comment_blank_line()
  local left, right = vim.bo.commentstring:match("^(.-)%%s(.-)$")

  if not left then
    return
  end

  local lnum = vim.fn.line(".")
  local ref = vim.fn.prevnonblank(lnum - 1)

  if ref == 0 then
    ref = vim.fn.nextnonblank(lnum + 1)
  end

  -- Copy the reference line's leading whitespace rather than rebuilding it
  -- from shiftwidth, so tabs stay tabs. Trimmed parts, matching what
  -- vim._comment writes for a blank line inside a larger range: `--`, with no
  -- trailing space left behind.
  local indent = ref == 0 and "" or vim.fn.getline(ref):match("^%s*")
  local line = indent .. vim.trim(left) .. vim.trim(right)

  vim.api.nvim_set_current_line(line)
  vim.api.nvim_win_set_cursor(0, { lnum, #line })
end

local function is_blank_line()
  return vim.api.nvim_get_current_line():match("^%s*$") ~= nil
end

-- These are global mappings, so they also fire in buffers that hold no text to
-- comment -- neo-tree, the minimap, help, quickfix. vim._comment does not
-- check first: it reports the empty 'commentstring' and then throws E5108
-- "Buffer is not 'modifiable'" on the write. Swallow the keypress instead.
--
-- 'modifiable' is the test rather than 'commentstring' being empty, because
-- treesitter can resolve a commentstring for the cursor position when the
-- buffer-local one is unset -- so an empty value does not prove there is
-- nothing to toggle, whereas a buffer you cannot write to does.
local function can_comment()
  return vim.bo.modifiable
end

for _, lhs in ipairs({ "<D-/>", "<C-/>", "<C-_>" }) do
  -- Fed back rather than mapped straight to "gcc" so the blank-line case can
  -- branch first. Mode "m" is the feedkeys equivalent of remap = true, needed
  -- because gcc is itself an expr mapping -- sent non-recursively the literal
  -- keys would do nothing. A count means the range reaches past this line, so
  -- leave those to gcc.
  vim.keymap.set("n", lhs, function()
    if not can_comment() then
      return
    end

    if vim.v.count == 0 and is_blank_line() then
      return comment_blank_line()
    end

    vim.api.nvim_feedkeys(vim.v.count1 .. "gcc", "m", false)
  end, { desc = "Toggle comment" })
  -- `gcgv`, not just `gc`: the operator drops you into normal mode at the top
  -- of the range, so `gv` reselects the same area and the block stays
  -- highlighted for toggling back and forth. Fed back rather than mapped to
  -- the string so this can be guarded too, matching the other two modes.
  vim.keymap.set("x", lhs, function()
    if not can_comment() then
      return
    end

    vim.api.nvim_feedkeys("gcgv", "m", false)
  end, { desc = "Toggle comment, keep selection" })
  vim.keymap.set("i", lhs, function()
    if not can_comment() then
      return
    end

    if is_blank_line() then
      return comment_blank_line()
    end

    vim.api.nvim_feedkeys(vim.keycode("<Esc>gccgi"), "m", false)
  end, { desc = "Toggle comment" })
end

-- ── File explorer: neo-tree ──────────────────────────────────────────────
-- Installed with vim.pack, Neovim 0.12's built-in plugin manager. Clones into
-- ~/.local/share/nvim/site/pack/core/opt/ and pins revisions in
-- ~/.config/nvim/nvim-pack-lock.json. plenary and nui are hard dependencies.
vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-neo-tree/neo-tree.nvim",
})

-- Plenary's scandir module probes getpwuid/getgrgid with ID 1000 at load
-- time. On this Mac that reaches corporate LDAP and blocks startup on VPN.
-- Probe the current local IDs instead (26s -> 0.11s in the startup test).
-- Patch only the loaded source: keep the workaround in dotfiles, without
-- modifying the plugin checkout or losing it when plugins are reinstalled.
-- Plenary is no longer maintained; remove this if its probes are fixed upstream.
do
  package.preload["plenary.scandir"] = function()
    local path = assert(vim.api.nvim_get_runtime_file("lua/plenary/scandir.lua", false)[1],
      "plenary.scandir not found")
    local source = table.concat(vim.fn.readfile(path), "\n")
    local count = 0
    source = source:gsub("pcall%(ffi_func, {}, 1000%)", function()
      count = count + 1
      local id = count == 1 and "getuid" or "getgid"
      return "pcall(ffi_func, {}, vim.uv." .. id .. "())"
    end)
    -- Zero matches permits an upstream fix; a partial match needs review.
    assert(count == 0 or count == 2, "Plenary lookup probes changed; review startup patch")
    return assert(loadstring(source, "@" .. path))()
  end
end

-- Was the left button released at the end of a drag, rather than a click?
--
-- <LeftRelease> fires however the button went down, including at the end of a
-- window-separator drag. `open` then acts on the node under the *cursor*, and
-- a press on the separator never moves the cursor -- so on a freshly opened
-- tree it acted on line 1, the root, and collapsed the whole tree. Once the
-- cursor has been parked on a file the same misfire just reopens that file,
-- which is why only the first resize appeared to do anything.
--
-- vim.on_key observes input without consuming it, so the separator keeps
-- resizing normally. <LeftMouse> clears the flag at the start of every click,
-- so a drag that ends outside the tree cannot leave it set and swallow the
-- next genuine click. Registered against a namespace so re-sourcing this file
-- replaces the callback instead of stacking another one.
local mouse_dragged = false
do
  local leftmouse = vim.keycode("<LeftMouse>")
  local leftdrag = vim.keycode("<LeftDrag>")
  vim.on_key(function(key, typed)
    local k = (typed and typed ~= "") and typed or key
    if k == leftdrag then
      mouse_dragged = true
    elseif k == leftmouse then
      mouse_dragged = false
    end
  end, vim.api.nvim_create_namespace("neotree_mouse_drag"))
end

-- Stock defaults apart from arrow keys for expand/collapse and the icon
-- component below, which is blanked.
require("neo-tree").setup({
  -- The defaults plus a custom source in lua/neotree_dotfiles.lua, which
  -- renders the bare dotfiles repo's tracked files as a tree. neo-tree
  -- resolves an unrecognised name with a plain require(), so any module on the
  -- runtimepath works. Listing the defaults is required -- naming sources at
  -- all replaces the list rather than adding to it.
  sources = { "filesystem", "buffers", "git_status", "neotree_dotfiles" },

  -- No filetype or folder glyphs. `provider` is the hook that reaches for
  -- nvim-web-devicons, so overriding it with a no-op stops the lookup rather
  -- than letting devicons answer and then blanking the result. The folder_*
  -- strings and `default` cover the paths that never consult the provider,
  -- and padding = 0 closes the column the glyph used to occupy.
  --
  -- git_status and diagnostic symbols carry information rather than
  -- decoration, so they stay -- but as the letters they stand for. neo-tree's
  -- defaults for these are Nerd Font glyphs, which is what puts a column of
  -- boxes down the right-hand edge of the tree.
  default_component_configs = {
    icon = {
      folder_closed = "",
      folder_open = "",
      folder_empty = "",
      default = "",
      padding = 0,
      provider = function(icon)
        icon.text = ""
        icon.highlight = nil
      end,
    },
    git_status = {
      symbols = {
        added = "A", modified = "M", deleted = "D", renamed = "R",
        untracked = "?", ignored = "", unstaged = "U", staged = "S", conflict = "C",
      },
    },
  },

  close_if_last_window = true,   -- don't leave a lone tree holding nvim open
  popup_border_style = "single", -- box-drawing, drawn by Ghostty itself
  enable_git_status = true,
  enable_diagnostics = true,
  -- Default is false, which sorts by byte value, so every capitalised name
  -- lands above every lowercase one -- "Zoo.md" before "apple.md". Barely
  -- noticeable in a code tree; obvious in a vault, where note names are prose
  -- and the capitalisation is arbitrary.
  sort_case_insensitive = true,

  window = {
    width = 32,
    mappings = {
      -- <cr> toggles a directory, so it can't double as "expand": <Right> on an
      -- open directory would collapse it. Hence the guard.
      -- Use `open`, not `toggle_directory`: the filesystem source wraps `open`
      -- with the scan callback, the bare common `toggle_directory` no-ops.
      --
      -- Through state.commands, which is how neo-tree resolves a mapping given
      -- as a plain string -- so each source gets its own `open`. Naming the
      -- filesystem module directly imposes its command on every tree, and the
      -- dotfiles source cannot run it: that `open` rescans the real directory
      -- and reads state.filtered_items, which only the filesystem source's
      -- config populates, so it errors with
      --   ignored.lua:81: attempt to index field 'filtered_items'
      -- on any click that expands a folder. See lua/neotree_dotfiles.lua, which
      -- builds its commands off the common set for exactly this reason.
      ["<Right>"] = function(state)
        local node = state.tree:get_node()
        if node.type == "directory" and node:is_expanded() then return end
        state.commands.open(state)
      end,
      -- close_node already does both halves: collapse an expanded directory,
      -- otherwise collapse the parent and move focus up to it.
      ["<Left>"] = "close_node",
      -- Single click acts: toggles a directory, opens a file in the edit pane.
      -- neo-tree only binds <2-LeftMouse> by default. `open` covers both cases --
      -- it is the same command <cr> uses.
      --
      -- Bound on release rather than press: the cursor moves on press, so by
      -- release the node under the cursor is the one that was clicked.
      --
      -- Guarded, because a separator drag also ends in a release -- see
      -- mouse_dragged above. state.commands.open for the reason under <Right>.
      ["<LeftRelease>"] = function(state)
        if mouse_dragged then
          mouse_dragged = false
          return
        end
        state.commands.open(state)
      end,
    },
  },

  filesystem = {
    hijack_netrw_behavior = "disabled",  -- nothing auto-opens at startup
    use_libuv_file_watcher = true,        -- notice external file creates/deletes/renames
    filtered_items = {
      visible = true,           -- dotfiles and gitignored files stay listed
      hide_dotfiles = false,
      hide_gitignored = false,
      -- never_show wins over `visible = true`, unlike hide_by_name which it
      -- would override. These are noise you never want to open from the tree.
      never_show = { ".git", ".DS_Store" },
    },
    follow_current_file = { enabled = false },
  },
})

vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle neo-tree" })
-- Reveal is <leader>fe, not <leader>f: a bare <leader>f leaf collides with the
-- <leader>f "find" group (ff, fg, ...). vim treats <leader>f as complete but
-- waits 'timeoutlen' for a continuation, so a slightly slow <leader>ff instead
-- fired reveal -- opening the filesystem tree rooted at $HOME. Folding it into
-- the group as "find: reveal in explorer" leaves <leader>f a pure prefix.
vim.keymap.set("n", "<leader>fe", "<cmd>Neotree reveal<CR>", { desc = "Reveal current file in tree" })

-- Stage a path into the dotfiles bare repo, with the same
-- --git-dir/--work-tree invocation lua/neotree_dotfiles.lua uses. A no-op on
-- anything that is not a file on disk (a directory, a vanished path); reports
-- a non-zero exit rather than failing silently.
local function dotfiles_stage(path)
  if not (path and vim.uv.fs_stat(path) and vim.fn.isdirectory(path) == 0) then
    return
  end
  local home = assert(vim.env.HOME)
  local res = vim.system({
    "git", "--git-dir=" .. home .. "/.dotfiles", "--work-tree=" .. home, "add", path,
  }, { text = true }):wait()
  if res.code ~= 0 then
    vim.notify("dotfiles: git add failed: " .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
  end
end

-- The window id of a neo-tree window open in the current tabpage, if any --
-- so <leader>n from an edit pane can still drive the tree's new-file dialog.
local function visible_neotree_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if pcall(vim.api.nvim_buf_get_var, vim.api.nvim_win_get_buf(win), "neo_tree_source") then
      return win
    end
  end
end

-- Open a freshly created file in a real edit window and drop into insert
-- mode. `prefer_win` (the window <leader>n was pressed in) is used when it is
-- still a normal window; otherwise the first non-neo-tree window in the tab.
-- Deferred, not just scheduled: neo-tree's popup teardown and the source
-- refresh that runs first both queue their own redraws, and this has to land
-- after all of them or focus snaps back to the tree.
local function open_new_file(path, prefer_win)
  vim.defer_fn(function()
    if not (path and vim.uv.fs_stat(path) and vim.fn.isdirectory(path) == 0) then
      return
    end
    local function is_tree(w)
      return not vim.api.nvim_win_is_valid(w)
        or vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neo-tree"
    end
    local target = (prefer_win and not is_tree(prefer_win)) and prefer_win or nil
    if not target then
      for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if not is_tree(w) then
          target = w
          break
        end
      end
    end
    if target then
      vim.api.nvim_set_current_win(target)
    end
    vim.cmd.edit(vim.fn.fnameescape(path))
    vim.cmd.startinsert()
  end, 10)
end

-- Run neo-tree's own new-file dialog (the popup the built-in `a` shows)
-- against a resolved source state, then reveal the new file in the tree and
-- open it. All sources go through the common `add`; the tree is then updated
-- per source:
--
--   * filesystem: show_new_children() rescans and expands down to the new
--     file. Its focus_node call -- and the position.restore after the redraw
--     -- both pass do_not_focus_window, so this moves the tree's cursor line
--     without pulling focus off the edit pane.
--   * dotfiles: staged first (the view is rebuilt from `git ls-files`, so an
--     untracked file would never appear -- and staging is the intent for a
--     file added to the tracked-set view; reversible with `dotfiles reset`),
--     then a plain refresh, then focus_node to move the tree cursor to it.
--
-- state.config is primed to {} because neo-tree only sets it while
-- dispatching a mapped command; calling `add` directly would otherwise hit a
-- nil field in get_folder_node until some neo-tree mapping had run.
local function neotree_add(state, dest_win)
  local mgr = require("neo-tree.sources.manager")
  local renderer = require("neo-tree.ui.renderer")
  state.config = state.config or {}
  require("neo-tree.sources.common.commands").add(state, function(path)
    if state.name == "filesystem" then
      pcall(require("neo-tree.sources.filesystem").show_new_children, state, path)
    else
      if state.name == "dotfiles" then
        dotfiles_stage(path)
      end
      pcall(mgr.refresh, state.name)
      vim.schedule(function()
        pcall(renderer.focus_node, state, path, true)
      end)
    end
    open_new_file(path, dest_win)
  end)
end

-- <leader>n: new file. Whenever a neo-tree window is open it drives that
-- tree's new-file dialog -- the popup -- whether the cursor is in the tree or
-- in an edit pane. From an edit pane the tree cursor is first nudged to the
-- current file (a no-op if it is not a node in the tree) so the new file
-- lands beside it. A trailing `/` makes a directory.
--
-- With no tree open at all it falls back to a command-line prompt (no popup
-- vim.ui.input is installed), prefilled with the current buffer's directory
-- or cwd; it creates any missing parents, writes the file, and opens it. An
-- existing path is just opened, never rewritten.
vim.keymap.set("n", "<leader>n", function()
  local cur_win = vim.api.nvim_get_current_win()
  local tree_win = vim.bo.filetype == "neo-tree" and cur_win or visible_neotree_win()

  if tree_win then
    local state = require("neo-tree.sources.manager").get_state_for_window(tree_win)
    if state and state.tree then
      if tree_win ~= cur_win then
        local cur = vim.api.nvim_buf_get_name(0)
        if cur ~= "" then
          pcall(require("neo-tree.ui.renderer").focus_node, state, cur, true)
        end
      end
      neotree_add(state, cur_win)
      return
    end
  end

  local here = vim.fn.expand("%:p:h")
  if here == "" then
    here = vim.fn.getcwd()
  end

  vim.ui.input({ prompt = "New file: ", default = here .. "/", completion = "file" }, function(input)
    if not input or input == "" or input:sub(-1) == "/" then
      return
    end
    local path = vim.fs.normalize(input)
    if vim.uv.fs_stat(path) then
      vim.cmd.edit(vim.fn.fnameescape(path))
      return
    end
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.cmd.edit(vim.fn.fnameescape(path))
    vim.cmd.write()
    vim.schedule(vim.cmd.startinsert)
  end)
end, { desc = "New file" })

-- Startup layout: `nvim +Neotree` (do NOT pass a directory).
--
-- The dotfiles tree has no keymap: it is a whole-session mode rather than
-- something to flip to mid-edit, so `dotfiles nvim` launches it instead. The
-- source lives in lua/neotree_dotfiles.lua and is still reachable in-session
-- with :Neotree dotfiles left.

-- ── Unsupported file types ───────────────────────────────────────────────
-- Clicking a png in the tree otherwise fills the buffer with the file's bytes
-- rendered as text, which is unreadable and slow on anything large.
--
-- Two guards, because neither alone is sufficient.
--
-- The extension list is the fast path: BufReadCmd *replaces* the read rather
-- than reacting to it, so for anything named here not a byte is read and
-- nothing is ever drawn. That is the only way to guarantee no flash of
-- garbage, and it costs no I/O -- but a name is all it can judge by.
--
-- The content check below catches everything the list does not know about.
-- Looking for a NUL byte in the first 1KB is what git and grep do, and it
-- needs no list to maintain. It cannot run on BufReadCmd though: to allow the
-- text files through it would have to perform the normal read itself, which
-- means reimplementing nvim's encoding, BOM and fileformat handling. So it
-- runs on BufReadPost, one frame later, and accepts a brief flash.

local function refuse(buf, file)
  vim.notify("unsupported file type: " .. vim.fn.fnamemodify(file, ":t"),
    vim.log.levels.WARN)
  -- Scheduled: wiping a buffer from inside its own read event leaves the
  -- window without one. nvim_buf_delete with force = true, unlike :bdelete,
  -- closes any window that would otherwise be left showing nothing rather
  -- than falling back to the alternate buffer -- confirmed by reproducing
  -- headlessly: a two-window split where this window's buffer gets replaced
  -- by a refused path left that window invalid, and the sibling window (e.g.
  -- neo-tree) inherited its space, which is what "the file tree grows huge"
  -- actually was. So point every window showing this buffer at something
  -- else first, same pattern as close_buffer_keep_window below.
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    local alt = vim.fn.bufnr("#")
    if alt == buf or alt == -1 or not (vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buflisted) then
      alt = nil
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if b ~= buf and vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= "" then
          alt = b
          break
        end
      end
    end

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == buf then
        vim.api.nvim_win_set_buf(win, alt or vim.api.nvim_create_buf(true, false))
      end
    end

    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)
end

local unsupported_ft = {
  "png", "jpg", "jpeg", "gif", "webp", "avif", "bmp", "ico", "icns", "tiff",
  "pdf", "mp3", "mp4", "mov", "m4a", "wav", "avi", "mkv",
  "zip", "gz", "tgz", "bz2", "xz", "7z", "rar", "dmg", "pkg",
  "ttf", "otf", "woff", "woff2", "eot",
  "key", "numbers", "pages", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
  "sqlite", "sqlite3", "db", "o", "so", "dylib", "a", "bin", "exe", "wasm",
}

vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = vim.tbl_map(function(ext) return "*." .. ext end, unsupported_ft),
  desc = "Refuse known-binary extensions without reading them",
  callback = function(ev)
    refuse(ev.buf, ev.file)
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  desc = "Refuse anything else whose first 1KB contains a NUL byte",
  callback = function(ev)
    -- io.open rather than vim.fn.system: system() replaces NUL with SOH, so it
    -- strips the very byte being looked for. And :find with plain = true, not
    -- :match -- a Lua pattern is a C string, so "\0" terminates it, leaving an
    -- empty pattern that matches anything and returns "", which is truthy.
    local f = io.open(ev.file, "rb")
    if not f then
      return
    end
    local chunk = f:read(1024) or ""
    f:close()
    if chunk:find("\0", 1, true) then
      refuse(ev.buf, ev.file)
    end
  end,
})

-- ── netrw (built in, kept as a fallback) ─────────────────────────────────
-- Worth knowing: it's on every machine you ssh into, where plugins won't be.
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 25
vim.keymap.set("n", "<leader>E", "<cmd>Lexplore<CR>", { desc = "Toggle netrw sidebar" })

-- ── Colours ──────────────────────────────────────────────────────────────
vim.pack.add({ "https://github.com/EdenEast/nightfox.nvim" })
vim.opt.termguicolors = true   -- nightfox is a 24-bit gui scheme

-- setup() is optional. Seven variants ship as separate colorscheme names --
-- swap the line below for any of these:
--   dark:  nightfox | duskfox | nordfox | terafox | carbonfox
--   light: dayfox | dawnfox
vim.cmd.colorscheme("terafox")

-- Window separator: terafox sets WinSeparator's fg but leaves bg unset, so the
-- one-column strip between splits falls through to the terminal background
-- (Ghostty's #151C23) while the panes either side are painted by the scheme --
-- which reads as a thin black seam. Painting both fg and bg to match Normal
-- makes it vanish; neo-tree's own darker background is enough to divide the
-- panes without a rule.
--
-- On ColorScheme because :colorscheme resets every highlight group; setting it
-- directly would be wiped the next time a scheme loads.
local function theme_tweaks()
  -- One yellow palette for every search UI: Neovim's own buffer search, match
  -- .nvim's dialog, and grug-far's results and source preview.
  --
  -- Search and CurSearch are included so ordinary `/` highlighting uses it too.
  -- terafox's own are teals -- #425e5e for Search and #7aa4a1 for CurSearch --
  -- which read as a selection rather than a match, and sat oddly beside the
  -- yellow the two search *plugins* were already using.
  --
  -- The split is Vim's own: Search is every match, CurSearch the one under the
  -- cursor, IncSearch the match being previewed while the pattern is still
  -- being typed. So the current match and the incremental preview share the
  -- brighter shade, and everything else takes the flatter one.
  --
  -- Setting these globally is what lets open_match further down be a one-line
  -- wrapper: it used to force the same mapping window-by-window through winhl.
  for _, group in ipairs({ "Search", "MatchSearch", "GrugFarResultsMatch", "GrugFarResultsMatchRemoved" }) do
    vim.api.nvim_set_hl(0, group, { fg = "#202020", bg = "#FFE066" })
  end
  for _, group in ipairs({ "CurSearch", "IncSearch", "MatchCurrentSearch", "GrugFarCurrentMatch" }) do
    vim.api.nvim_set_hl(0, group, { fg = "#202020", bg = "#FFF59D", bold = true })
  end
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = normal.bg, bg = normal.bg })

  -- terafox renders git additions in a muted teal-green (#7AA4A1) that is hard
  -- to tell from its change colour at a glance. Both the gutter sign and the
  -- minimap sign are set, so the two stay consistent -- the minimap group
  -- otherwise inherits from gitsigns.
  for _, group in ipairs({ "GitSignsAdd", "NeominimapGitAddSign" }) do
    vim.api.nvim_set_hl(0, group, { fg = "#6EC47C" })
  end

  -- mini.indentscope's guide is structural furniture rather than content, but
  -- terafox paints it #73a3b7 -- a saturated blue brighter than Comment, which
  -- makes a full-height rule the loudest thing in a deeply indented buffer.
  -- NonText is the register the scheme already uses for exactly this class of
  -- mark (the end-of-buffer filler, listchars guides), so borrowing it keeps
  -- the guide readable without competing with the code beside it.
  --
  -- Read off the group rather than hardcoded, so it follows whatever scheme is
  -- loaded. SymbolOff is set alongside it: it is the same colour by default and
  -- only shows up in the try_as_border case, but leaving it bright would make
  -- the guide change loudness depending on where the cursor sits.
  local nontext = vim.api.nvim_get_hl(0, { name = "NonText", link = false })
  for _, group in ipairs({ "MiniIndentscopeSymbol", "MiniIndentscopeSymbolOff" }) do
    vim.api.nvim_set_hl(0, group, { fg = nontext.fg })
  end

end
vim.api.nvim_create_autocmd("ColorScheme", { callback = theme_tweaks })
theme_tweaks()

-- ── Colour-code highlighting ─────────────────────────────────────────────
-- Renders #rrggbb, rgb(), colour names etc. in their actual colour, in-place.
-- Needs termguicolors, which is set above.
-- catgoose's fork, not norcalli's original -- the original was last touched in
-- April 2021 and warns about deprecated vim.tbl_flatten on every startup.
vim.pack.add({ "https://github.com/catgoose/nvim-colorizer.lua" })
require("colorizer").setup()

-- ── Git: gitsigns.nvim ───────────────────────────────────────────────────
-- Shows added/changed/deleted lines in the sign column, plus hunk navigation,
-- staging and blame. Uses the signcolumn reserved at the top of this file.
vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })
-- worktrees: the dotfiles bare repo. Its files live directly in $HOME, where
-- normal git discovery finds nothing (there is no ~/.git). Gitsigns falls back
-- to these entries when ordinary attaching fails, so signs work when editing
-- ~/.zshrc, this file, and so on.
require("gitsigns").setup({
  worktrees = {
    { toplevel = vim.env.HOME, gitdir = vim.env.HOME .. "/.dotfiles" },
  },
  -- Well above the diagnostic sign priority of 5. With signcolumn = "yes" there
  -- is one column and the highest-priority sign takes it; diagnostics place a
  -- blank sign on every flagged line purely so linehl can tint it, and without
  -- this that blank wins and the git bar disappears as soon as linting runs.
  sign_priority = 20,
})

-- vim-fugitive: a full git porcelain as vim commands (:Git, :Gdiffsplit,
-- :Gblame...). No setup() call -- it's a classic vimscript plugin with no Lua
-- config. Complements gitsigns rather than overlapping: gitsigns is per-line
-- gutter decoration, fugitive is whole-repo operations.
vim.pack.add({ "https://github.com/tpope/vim-fugitive" })

-- ── Merge conflicts: diffview.nvim ───────────────────────────────────────
-- A file panel listing every conflicted file plus a three-way view, with
-- per-conflict choose ours/theirs/both/base -- the part git mergetool's
-- four-pane nvimdiff leaves you to do by hand. :DiffviewOpen during a rebase
-- picks up the conflict set on its own, so it needs no arguments. No setup()
-- call: the commands come from the plugin's own plugin/ dir and the defaults
-- are what we want. plenary.nvim is a dependency, already installed above as
-- a neo-tree dep, so it is not repeated here.
vim.pack.add({ "https://github.com/sindrets/diffview.nvim" })

-- ── Fuzzy finder: telescope.nvim ─────────────────────────────────────────
-- plenary.nvim is a hard dependency but is already installed above as a
-- neo-tree dep, so it isn't repeated here. Uses ripgrep for live_grep and fd
-- for find_files; both are on PATH.
--
-- telescope-ui-select overrides vim.ui.select, which is otherwise
-- vim.fn.inputlist() -- a numbered list printed into the message area that you
-- answer by typing a digit, with no filtering and a hit-enter prompt once the
-- list is long. Everything that asks you to pick from a list goes through it:
-- <leader>ca (code actions, where eslint and ts_ls together routinely offer a
-- dozen), <leader>at (herdr-sidekick's other-agent picker), :TermSelect, and
-- mason's language filter. It does not touch vim.ui.input.
--
-- telescope-frecency ranks files by how often *and* how recently you have
-- opened them, so the file you keep coming back to floats to the top --
-- unlike find_files, which walks the directory and knows nothing about your
-- history. It keeps its own store under stdpath("data"); older guides pair it
-- with kkharji/sqlite.lua, which 1.0 dropped. It requires nvim 0.11.7+ and
-- refuses to load below that. fd and ripgrep make its workspace listing much
-- faster and are already on PATH. Devicons glyphs are switched off in
-- `defaults` below, so results are plain paths.
vim.pack.add({
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-telescope/telescope-ui-select.nvim",
  "https://github.com/nvim-telescope/telescope-frecency.nvim",
})

require("telescope").setup({
  -- The dotfiles bare repo lives at ~/.dotfiles with its work tree at $HOME,
  -- and $HOME has no ~/.git -- so from there telescope's git builtins cannot
  -- infer a repo and fall back to walking the whole home directory. This is
  -- the documented escape hatch: when cwd sits under one of these toplevels,
  -- git_files and friends get --git-dir/--work-tree spelled out. Same shape
  -- as gitsigns' `worktrees` above, and only consulted when ordinary
  -- discovery fails, so it is inert inside a normal project.
  --
  -- Note that `disable_devicons` is NOT a valid `defaults` key -- it appears
  -- nowhere in telescope's config schema and is only ever read from a picker's
  -- own opts, so setting it here silently does nothing. What actually keeps
  -- glyphs out of every picker is nvim-web-devicons not being installed:
  -- utils.transform_devicons pcall-requires it and returns the plain display
  -- when it is missing.
  defaults = {
    git_worktrees = {
      { toplevel = vim.env.HOME, gitdir = vim.env.HOME .. "/.dotfiles" },
    },
  },
  extensions = {
    -- The dropdown theme rather than telescope's default three-pane layout:
    -- these lists are short and have nothing worth previewing, so the full
    -- layout is mostly empty space. get_cursor() is the other reasonable
    -- choice -- it opens at the cursor, which suits code actions, but it is
    -- cramped for the longer prompt list.
    ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
    -- frecency does not read telescope's `defaults`. It keeps its own option
    -- of the same name, defaulting to false, and its entry_maker consults that
    -- -- so <leader>fF kept drawing filetype glyphs while every other picker
    -- had them off.
    frecency = { disable_devicons = true },
  },
})

-- Must come after setup(): load_extension reads the extensions table above.
require("telescope").load_extension("ui-select")
-- frecency takes no config here; the defaults are the documented setup.
require("telescope").load_extension("frecency")

local builtin = require("telescope.builtin")

-- `dotfiles edit` launches nvim with cwd $HOME so the tabline and :Neotree
-- filesystem line up with the dotfiles tree's root. The cost is that an
-- unscoped find_files/live_grep from there walks every untracked file under
-- $HOME -- thousands of them -- instead of the ~three dozen tracked ones. It
-- sets DOTFILES_EDIT so the two project pickers can scope themselves to the
-- bare repo: git_files reads its tracked list (via the git_worktrees entry
-- above), and live_grep is handed that same list as explicit paths, since it
-- is not a git builtin and has no other way to be told.
if vim.env.DOTFILES_EDIT then
  local home = assert(vim.env.HOME)

  local function tracked_files()
    local res = vim.system({
      "git", "--git-dir=" .. home .. "/.dotfiles", "--work-tree=" .. home,
      "ls-files", "--full-name",
    }, { cwd = home, text = true }):wait()
    local paths = {}
    for _, rel in ipairs(vim.split(vim.trim(res.stdout or ""), "\n", { plain = true })) do
      if rel ~= "" then
        paths[#paths + 1] = home .. "/" .. rel
      end
    end
    return paths
  end

  vim.keymap.set("n", "<leader>ff", function()
    builtin.git_files({ cwd = home })
  end, { desc = "Telescope: find tracked dotfiles" })
  vim.keymap.set("n", "<leader>fg", function()
    builtin.live_grep({ cwd = home, search_dirs = tracked_files() })
  end, { desc = "Telescope: grep tracked dotfiles" })
else
  vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope: find files" })
  vim.keymap.set("n", "<leader>fg", builtin.live_grep,  { desc = "Telescope: grep in project" })
end

vim.keymap.set("n", "<leader>fb", builtin.buffers,    { desc = "Telescope: open buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags,  { desc = "Telescope: help tags" })
vim.keymap.set("n", "<leader>fr", builtin.resume,     { desc = "Telescope: resume last picker" })

-- A separate key rather than replacing <leader>ff: the two answer different
-- questions -- "what is in this project" versus "what have I been working on".
-- Unqualified, it ranks every file you have ever opened; `:Telescope frecency
-- workspace=CWD` confines it to the current project, and typing `:CWD:` in the
-- prompt does the same from inside the picker.
vim.keymap.set("n", "<leader>fF", "<cmd>Telescope frecency<cr>", { desc = "Telescope: frecent files" })

-- ── Search and replace: match.nvim ──────────────────────────────────────
vim.pack.add({ "https://github.com/ankushbhagats/match.nvim" })
require("match").setup({ border = "rounded" })

-- Opens match.nvim's dialog, prefilled with `text` as the search term when one
-- is given. A wrapper only because the keymaps below call it both ways.
--
-- It used to do considerably more: remap Search, CurSearch and IncSearch to
-- the yellow groups in the source window through winhl, then restore the
-- window's original winhl on WinClosed. Those three are that yellow globally
-- now (see theme_tweaks), so all of it amounted to setting a colour to the
-- value it already had.
local function open_match(text)
  vim.api.nvim_cmd({ cmd = "Match", args = text and { text } or {} }, {})
end

vim.keymap.set("n", "<leader>fs", function() open_match() end, { desc = "Find and replace in current file" })
-- Capture the active selection without changing the clipboard or yank registers.
vim.keymap.set("x", "<leader>fs", function()
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
    type = vim.fn.mode(),
    exclusive = vim.o.selection == "exclusive",
  })
  if #lines ~= 1 then
    vim.notify("match.nvim supports single-line search text; select text on one line.", vim.log.levels.INFO)
    return
  end
  vim.cmd.normal({ args = { vim.keycode("<Esc>") }, bang = true })
  open_match(lines[1])
  local search_win = vim.api.nvim_get_current_win()
  -- Let Match finish its scheduled search update before focusing Replace.
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(search_win) and vim.api.nvim_get_current_win() == search_win then
      local switch = vim.fn.maparg("<Tab>", "i", false, true)
      if type(switch.callback) == "function" then switch.callback() end
    end
  end)
end, { desc = "Find and replace selected text in current file" })

-- Native macOS shortcut; Ghostty forwards the same shortcut as F12 through Herdr.
for _, key in ipairs({ "<D-S-f>", "<F12>" }) do
  for _, mode in ipairs({ "n", "x" }) do
    local mapping = vim.fn.maparg("<leader>fs", mode, false, true)
    vim.keymap.set(mode, key, mapping.callback, { desc = mapping.desc })
  end
  vim.keymap.set("i", key, function()
    vim.cmd.stopinsert()
    open_match()
  end, { desc = "Find and replace in current file" })
end

-- grug-far complements Match with project-wide search and replacement. Its
-- buffer-local actions use localleader; keep that on the familiar backslash.
vim.g.maplocalleader = vim.g.maplocalleader or "\\"
vim.pack.add({ "https://github.com/MagicDuck/grug-far.nvim" })
require("grug-far").setup({ icons = { enabled = false } })

local function open_grug_project()
  require("grug-far").open()
end

local function open_grug_project_selection()
  local instance = require("grug-far").with_visual_selection()
  instance:when_ready(function() instance:goto_input("replacement") end)
end

vim.keymap.set("n", "<leader>fS", open_grug_project, { desc = "Find and replace in project" })
vim.keymap.set("x", "<leader>fS", open_grug_project_selection,
  { desc = "Find and replace selected text in project" })

-- Native macOS shortcut; Ghostty forwards it as F11 through Herdr. Was F13:
-- Herdr's own keystroke pipeline doesn't forward that one through at all
-- (confirmed with a scratch pane and `herdr pane send-keys`, independent of
-- Ghostty or which physical key triggers it), so this mirrors <F12> above.
for _, key in ipairs({ "<D-S-r>", "<F11>" }) do
  vim.keymap.set("n", key, open_grug_project, { desc = "Find and replace in project" })
  vim.keymap.set("x", key, open_grug_project_selection,
    { desc = "Find and replace selected text in project" })
  vim.keymap.set("i", key, function()
    vim.cmd.stopinsert()
    open_grug_project()
  end, { desc = "Find and replace in project" })
end
-- Everything changed against HEAD, most recently written first -- see
-- lua/changed_files.lua for why mtime rather than :Telescope git_status's
-- alphabetical order. required inside the callback so the module loads on
-- first press rather than at startup.
vim.keymap.set("n", "<leader>fc", function()
  require("changed_files").pick()
end, { desc = "Telescope: changed files, newest first" })

-- ── Statusline: lualine.nvim ─────────────────────────────────────────────
-- Icons are off (see icons_enabled below). The powerline separators are drawn
-- by Ghostty itself, not by devicons, so they are unaffected.
vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })

-- Builds a lualine component that counts one diagnostic severity in the
-- current buffer and names it in words -- "1 error", "2 warnings" -- rather
-- than abbreviating. Returns "" at zero, so the component disappears entirely
-- on a clean buffer instead of showing a 0.
--
-- Both words here pluralise with a plain "s", so this does not need a table of
-- irregulars; it would if the set ever grew past error/warning/hint. Never
-- "warning(s)" -- the count is always known by the time this renders, so the
-- parenthesis would only ever be hedging about something already decided.
local function diagnostic_count(severity, word)
  return function()
    local n = vim.diagnostic.count(0)[severity] or 0
    if n == 0 then
      return ""
    end
    return n .. " " .. word .. (n == 1 and "" or "s")
  end
end

-- A language server that is attached and running but cannot do its job.
--
-- Worth a permanent indicator, because every other signal says the server is
-- healthy: it attached, it is connected, `:checkhealth vim.lsp` lists it -- it
-- simply reports nothing, so a file with real violations looks clean. The
-- notification a server raises times out, which is the wrong shape for a
-- condition that lasts until you fix it.
--
-- Recorded on the client object rather than in a table keyed by client id, so
-- it needs no cleanup: the object is discarded when the server stops, and a
-- restart that works never records anything. "Until resolved" falls out of
-- that for free.
--
-- The latest complaint wins, not the first. An earlier version kept the first
-- and went stale in exactly the case that matters: eslint said "no library",
-- the dependencies were installed, and the bar still said "no library" while
-- the server was busy reporting a different failure entirely. A repeat of the
-- same message is a no-op, which is what keeps the common case -- one
-- complaint restated per document -- from churning.
--
-- Returns true when something actually changed, so callers can notify on the
-- change rather than on every occurrence.
local function record_lsp_problem(client_id, message)
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then
    return false
  end
  message = vim.trim(tostring(message or ""):gsub("%s+", " "))
  if message == "" then
    return false
  end
  -- Servers write for a dialog box, not a status bar. 48 columns is about what
  -- the bar can spare next to the diagnostic counts before it starts pushing
  -- the position indicator around.
  if #message > 48 then
    message = message:sub(1, 47) .. "…"
  end
  if client.lsp_problem == message then
    return false
  end
  client.lsp_problem = message
  return true
end

-- Generic: whatever any attached server last complained about.
local function lsp_problem()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if client.lsp_problem then
      return client.name .. ": " .. client.lsp_problem
    end
  end
  return ""
end

-- Search match count, replacing lualine's stock `searchcount` component.
--
-- That one keys off v:hlsearch, which Neovim only sets once a search is
-- submitted -- so nothing appeared while the pattern was being typed, even
-- though incsearch was already highlighting the matches in the buffer. This
-- counts against the partially typed pattern instead, via getcmdline(), so the
-- total shows from the first keystroke.
--
-- Only a total while typing, never a position. The cursor has not moved yet at
-- that point -- incsearch scrolls the view, not the cursor -- so searchcount
-- reports current = 0, and "0 of 6" would be wrong rather than merely
-- incomplete. Once the search is committed the position is real and is shown.
--
-- pcall is not defensive padding: a half-typed pattern is routinely an invalid
-- regex, and `/foo\(` on the way to `/foo\(bar\)` throws outright. Confirmed,
-- not assumed.
local function search_count()
  local cmdtype = vim.fn.getcmdtype()
  local typing = cmdtype == "/" or cmdtype == "?"
  local pattern = typing and vim.fn.getcmdline() or nil

  if typing then
    if pattern == "" then
      return ""
    end
  elseif vim.v.hlsearch ~= 1 then
    return ""
  end

  local ok, res = pcall(vim.fn.searchcount, {
    pattern = pattern,
    recompute = true,
    maxcount = 999,
    timeout = 100,
  })
  if not ok or type(res) ~= "table" or (res.total or 0) == 0 then
    return ""
  end

  local total = math.min(res.total, res.maxcount)
  if typing then
    return total .. (total == 1 and " match" or " matches")
  end
  return res.current .. " of " .. total
end

-- lualine's refresh events do not include CmdlineChanged, and the statusline
-- is not redrawn on its own while the command line is active, so the count
-- above would sit stale until the search was submitted -- which is the whole
-- problem it exists to fix.
--
-- Scoped by pattern to the two search prompts. CmdlineChanged matches on the
-- command-line type, so an ordinary `:` command does not force a statusline
-- redraw on every keystroke. CmdlineLeave is included so the count clears the
-- moment a search is abandoned rather than lingering until the next redraw.
vim.api.nvim_create_autocmd({ "CmdlineChanged", "CmdlineLeave" }, {
  pattern = { "/", "?" },
  desc = "Keep the statusline search count live while a search is typed",
  callback = function()
    vim.cmd.redrawstatus()
  end,
})

require("lualine").setup({
  options = {
    -- nightfox ships a matching lualine theme, so "auto" resolves to terafox.
    theme = "auto",
    -- No devicons glyphs. The `filetype` component below falls back to the
    -- filetype as plain text ("markdown"), which is the point -- the name is
    -- what was wanted, the glyph was not.
    icons_enabled = false,
    globalstatus = true,   -- one bar for the whole editor, not one per window
    disabled_filetypes = {
      statusline = { "neo-tree" },
    },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },   -- both read gitsigns' status dict
    lualine_c = { { "filename", path = 1 } },
    lualine_x = {
      -- Error and warning counts, as two separate components rather than
      -- lualine's own `diagnostics`. That one renders every severity in a
      -- single field and needs its symbols overridden to stay glyph-free;
      -- these are two plain phrases that vanish when the count is zero, so a
      -- clean buffer shows nothing at all.
      --
      -- Errors and warnings only, no info or hint. The same call the rest of
      -- this config makes: linehl tints these two severities and
      -- tiny-inline-diagnostic keeps these two always visible, both because
      -- ts_ls emits hints liberally -- an unused import puts one on its line
      -- -- so a count including them would be dominated by noise and stop
      -- meaning anything.
      --
      -- Spelled out rather than abbreviated to E2/W2: the bar has the room at
      -- globalstatus, and the count is the thing worth reading at a glance
      -- while the letter needs decoding.
      --
      -- `color` is given as a highlight group name rather than a hex, so both
      -- track the colourscheme and match what the gutter and the inline
      -- message are already using for that severity.
      {
        diagnostic_count(vim.diagnostic.severity.ERROR, "error"),
        color = "DiagnosticError",
      },
      {
        diagnostic_count(vim.diagnostic.severity.WARN, "warning"),
        color = "DiagnosticWarn",
      },

      -- Sits with the counts because it makes the same kind of claim about
      -- this buffer, and takes the same colour: a warning that the counts
      -- beside it may be understating things, a server contributing none.
      {
        lsp_problem,
        color = "DiagnosticWarn",
      },

      -- Format-on-save state, and a click target to flip it.
      --
      -- conform's format_on_save hook reads vim.g/vim.b conform_disable, which
      -- :FormatDisable and :FormatEnable set. That state is otherwise entirely
      -- invisible, so a save that quietly does not reformat is
      -- indistinguishable from a formatter that crashed or a file that was
      -- already clean.
      --
      -- Always rendered, unlike the two counts above, and that is the price of
      -- making it clickable: a component returning "" has no region on the bar
      -- to click, so it could only ever be switched back on, never off.
      -- "auto format" is given Comment so the normal state stays quiet and
      -- only the disabled state draws the eye.
      --
      -- Spelled out rather than fmt/no-fmt. It costs a dozen columns in a bar
      -- that has them, and "no-fmt" is the kind of abbreviation that reads
      -- fine the week it is written and not at all a year later -- the point
      -- of the indicator is that this state is otherwise unguessable.
      --
      -- on_click needs 'mouse', set at the top of this file; lualine wraps the
      -- component in a %@...@ click region.
      --
      -- Clicking while disabled clears *both* scopes, matching what
      -- :FormatEnable does. Otherwise a buffer-local `:FormatDisable!` would
      -- survive a click that looked like it had re-enabled everything.
      {
        function()
          return (vim.g.conform_disable or vim.b.conform_disable)
            and "no auto format" or "auto format"
        end,
        color = function()
          return (vim.g.conform_disable or vim.b.conform_disable) and "DiagnosticWarn" or "Comment"
        end,
        on_click = function()
          if vim.g.conform_disable or vim.b.conform_disable then
            vim.g.conform_disable = false
            vim.b.conform_disable = false
          else
            vim.g.conform_disable = true
          end
          vim.cmd.redrawstatus()
        end,
      },
      -- Filetype as plain text; icons_enabled = false above drops the glyph.
      { "filetype" },
    },
    -- searchcount sits with progress and location rather than over in
    -- lualine_x with the diagnostics: all three answer "where am I", and x is
    -- already carrying three components.
    --
    -- Renders "6 matches" while a pattern is being typed and "3 of 6" once it
    -- is submitted. search_count above, not lualine's stock "searchcount"
    -- string, which shows nothing at all until the search is submitted -- see
    -- its comment for why.
    --
    -- Coloured with MatchSearch, the yellow defined in theme_tweaks above --
    -- not terafox's own Search, which is a teal (#425e5e) and would read as
    -- just another statusline section. As a group name rather than a hex, so
    -- the count and the highlighted matches in the buffer stay the same colour
    -- if that yellow is ever changed in one place.
    --
    -- Only this component takes it; progress keeps the section's normal
    -- background.
    lualine_y = { { search_count, color = "MatchSearch" }, "progress" },
    lualine_z = { "location" },
  },
  extensions = { "neo-tree", "fugitive" },
})

-- ── bufferline.nvim ──────────────────────────────────────────────────────
-- Buffer tabs along the top. Used instead of lualine's tabline purely for
-- `offsets`: it indents the tab strip past neo-tree so the tabs begin where
-- the edit pane begins, rather than spanning the whole width.
vim.pack.add({ "https://github.com/akinsho/bufferline.nvim" })

local bufferline = require("bufferline")

-- Close a buffer without taking its window down with it.
--
-- :bdelete closes every window showing the buffer. With the tree open that
-- leaves neo-tree as the only window, and since bufferline offsets the tab
-- strip past the tree, a full-width tree pushes the entire strip off screen --
-- it looks like every tab closed at once. So point each affected window at
-- another buffer first, and only then delete.
--
-- Takes a bufnr because bufferline passes one: the × can be clicked on a tab
-- that is not the focused buffer, and may even be on no window at all.
local function close_buffer_keep_window(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if vim.bo[buf].modified then
    vim.notify("Unsaved changes in " .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t"),
      vim.log.levels.WARN)
    return
  end

  -- Prefer the alternate buffer, so closing a tab lands where :bprevious would.
  local alt = vim.fn.bufnr("#")
  if alt == buf or alt == -1 or not (vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buflisted) then
    alt = nil
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if b ~= buf and vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= "" then
        alt = b
        break
      end
    end
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      -- No other file open: fall back to a scratch buffer so the window
      -- survives. The [No Name] autocmd below leaves it alone while displayed.
      vim.api.nvim_win_set_buf(win, alt or vim.api.nvim_create_buf(true, false))
    end
  end
  pcall(vim.api.nvim_buf_delete, buf, {})
end

bufferline.setup({
  options = {
    -- no_italic drops the italics bufferline applies to the selected buffer.
    -- It is a preset rather than a highlight override because italic is set on
    -- ~20 derived groups; overriding buffer_selected alone would miss the rest.
    style_preset = bufferline.style_preset.no_italic,
    -- indicator.style defaults to "icon", the bright bar down the left edge of
    -- the selected tab. "none" removes it; the tab's own background already
    -- shows which is selected.
    indicator = { style = "none" },
    numbers = "none",
    -- No devicons filetype glyphs on the tabs; the name alone identifies them.
    show_buffer_icons = false,
    -- A close button on the right edge of each tab. bufferline makes the icon
    -- its own clickable region and runs close_command with the buffer number,
    -- so this needs no keymap -- but it does need `mouse` set, which line 20
    -- does. "×" is U+00D7, not the letter x: it sits on the text baseline at
    -- roughly half-width, so it reads as a button rather than a filename
    -- character. Plain Unicode, so no Nerd Font dependency.
    show_buffer_close_icons = true,
    buffer_close_icon = "×",
    -- Default is `bdelete! %d`, which both discards unsaved changes and takes
    -- the window down with it. See close_buffer_keep_window above.
    close_command = close_buffer_keep_window,
    -- Shown in place of the close icon while a buffer has unsaved changes, so
    -- the tab strip doubles as a "what have I not written yet" indicator.
    modified_icon = "●",
    -- The far-right button that closes the whole tab page -- unrelated to the
    -- per-buffer icons above, and not wanted.
    show_close_icon = false,
    separator_style = "thin",   -- a plain bar; the powerline chevron reads as nesting
    always_show_bufferline = true,   -- visible even with a single file open
    offsets = {
      {
        filetype = "neo-tree",
        text = "",
        -- separator = false: it drew a thin bar between the tree gutter and the
        -- first tab, matching the window separator that was removed below it.
        separator = false,
      },
    },
  },
})

-- Drop the empty [No Name] buffer once a real file is open, and hide the bar
-- entirely until a named buffer exists.
--
-- always_show_bufferline = true keeps the bar up for a single file, but at
-- startup `nvim +Neotree` has only the empty edit-pane buffer, which would
-- render as a nameless tab. It cannot simply be deleted then -- it is on
-- screen, and deleting a displayed buffer closes the window -- so the bar is
-- suppressed via showtabline until there is something real to show.
local function bufferline_visibility()
  local named = 0
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= "" then
      named = named + 1
    end
  end
  vim.o.showtabline = named > 0 and 2 or 0
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufDelete", "BufEnter" }, {
  desc = "Wipe the startup [No Name] buffer; show the bar only once a file is open",
  callback = function()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[b].buflisted
        and vim.api.nvim_buf_get_name(b) == ""
        and not vim.bo[b].modified
        and vim.fn.bufwinid(b) == -1
        and vim.api.nvim_buf_line_count(b) == 1
        and vim.api.nvim_buf_get_lines(b, 0, 1, false)[1] == ""
      then
        pcall(vim.api.nvim_buf_delete, b, {})
      end
    end
    vim.schedule(bufferline_visibility)
  end,
})
vim.api.nvim_create_autocmd("VimEnter", { callback = function() vim.schedule(bufferline_visibility) end })

-- Positional jumps, left to right, even though no numbers are displayed.
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. i, "<cmd>BufferLineGoToBuffer " .. i .. "<CR>",
    { desc = "Go to buffer " .. i })
end
vim.keymap.set("n", "]b", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "[b", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
-- Same helper the tab × uses, so both routes behave identically.
vim.keymap.set("n", "<leader>x", function()
  close_buffer_keep_window()
end, { desc = "Close buffer, keep the window" })

-- \X deletes the file \x was showing. Paired deliberately: lowercase closes the
-- buffer, uppercase closes it and takes the file with it.
--
-- Recoverable where the platform offers it, permanent where it does not. Probed
-- in platform-convention order: `trash` ships with macOS 14+, `trash-put` is
-- trash-cli on Linux, `gio trash` is the freedesktop fallback. Only if none is
-- present does it fall back to os.remove -- and the prompt says which of the two
-- it is about to do, so a permanent delete is never a surprise.
local function trash_argv(path)
  for _, cmd in ipairs({ { "trash" }, { "trash-put" }, { "gio", "trash" } }) do
    if vim.fn.executable(cmd[1]) == 1 then
      local argv = vim.deepcopy(cmd)
      table.insert(argv, path)
      return argv, table.concat(cmd, " ")
    end
  end
  return nil, nil
end

vim.keymap.set("n", "<leader>X", function()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)

  if vim.bo[buf].buftype ~= "" or path == "" then
    vim.notify("Not a file buffer", vim.log.levels.WARN)
    return
  end
  if vim.uv.fs_stat(path) == nil then
    vim.notify(vim.fn.fnamemodify(path, ":~:.") .. " is not on disk", vim.log.levels.WARN)
    return
  end

  local short = vim.fn.fnamemodify(path, ":~:.")
  local argv, tool = trash_argv(path)
  local prompt = argv
    and ("Move to Trash?  (" .. tool .. ")\n" .. short)
    or ("DELETE PERMANENTLY?  (no trash utility found)\n" .. short)

  -- Default 2 = No, so a stray <CR> on the prompt does nothing.
  if vim.fn.confirm(prompt, "&Yes\n&No", 2) ~= 1 then
    return
  end
  -- confirm() leaves its dialog sitting in the message area. Without clearing it
  -- first, the success message below lands on a second line, overflows cmdheight
  -- and triggers the "Press ENTER or type command to continue" prompt.
  vim.cmd("redraw")

  if argv then
    local res = vim.system(argv, { text = true }):wait()
    if res.code ~= 0 then
      -- Deliberately does NOT fall through to os.remove: a trash tool that is
      -- present but failing is a problem to look at, not to route around.
      vim.notify(tool .. " failed: " .. ((res.stderr or ""):gsub("%s+$", "")),
        vim.log.levels.ERROR)
      return
    end
  else
    local ok, err = os.remove(path)
    if not ok then
      vim.notify("delete failed: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
  end

  -- Clear `modified` first: close_buffer_keep_window refuses on unsaved changes,
  -- which is the right guard for \x but pointless here -- the file is gone.
  vim.bo[buf].modified = false
  close_buffer_keep_window(buf)

  -- Keep the tree in sync immediately after this command; the filesystem
  -- watcher also catches changes made outside Neovim.
  pcall(function()
    require("neo-tree.sources.manager").refresh("filesystem")
  end)

  -- Scheduled, and via nvim_echo rather than vim.notify: this runs after the
  -- buffer close and tree refresh have finished redrawing, so it is the only
  -- thing in the message area. `false` keeps it out of :messages history -- it is
  -- transient confirmation, not a log entry.
  vim.schedule(function()
    vim.api.nvim_echo({ { (argv and "Trashed " or "Deleted ") .. short } }, false, {})
  end)
end, { desc = "Delete this buffer's file (to Trash), close buffer" })

-- ── neominimap.nvim ──────────────────────────────────────────────────────
-- Code minimap. No setup() call -- it reads vim.g.neominimap, and its
-- config module does so at require time, which plugin/neominimap.lua triggers
-- the moment vim.pack.add runs. So the table MUST be set first; the README
-- shows the opposite order and the config would be ignored.
--
-- layout = "split" rather than the default "float": the float overlays the
-- right edge of your text, and upstream's fix for that is sidescrolloff = 36,
-- which is a heavy global change to editing behaviour. A split just takes its
-- own column, which suits a layout that already has neo-tree on the left.
vim.g.neominimap = {
  auto_enable = false, -- disabled for now; toggle on demand with <leader>m
  layout = "split",
  split = {
    -- 14 = 12 columns of map + a 2-column sign gutter for the git bars.
    minimap_width = 14,
    direction = "right",
    fix_width = true,             -- otherwise the pane resizes with the layout
    close_if_last_window = true,  -- don't let the minimap hold nvim open
  },


  -- Git status as a bar in the sign column, matching how gitsigns marks the
  -- main window, rather than a full-row background highlight.
  git = {
    enabled = true,
    mode = "sign",
  },

  -- signcolumn must be forced on. The default "auto" makes the gutter appear
  -- only once a sign exists, which steals two columns mid-scroll and makes the
  -- map jump about; "yes:1" keeps the text area a constant width.
  winopt = function(opt)
    opt.signcolumn = "yes:1"
  end,
}

-- The minimap renders exactly minimap_width cells per row, but its window has
-- wrap=false, and with wrap off nvim scrolls right past the end of the content
-- -- so `zl` or a stray mouse scroll leaves you staring at blank space.
--
-- wrap=true looks like the fix but is not: the window uses signcolumn="auto",
-- so as soon as a git or diagnostic sign appears the text area narrows by two
-- columns, every full-width row then wraps, and the map breaks up while
-- scrolling. Pinning the horizontal scroll offset instead is independent of
-- gutter width.
vim.api.nvim_create_autocmd({ "WinScrolled", "CursorMoved", "BufEnter" }, {
  desc = "Keep neominimap windows pinned to column 0",
  callback = function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_get_option_value("filetype", { buf = buf }) == "neominimap" then
        vim.api.nvim_win_call(win, function()
          local view = vim.fn.winsaveview()
          if view.leftcol ~= 0 then
            view.leftcol = 0
            vim.fn.winrestview(view)
          end
        end)
      end
    end
  end,
})

vim.pack.add({ "https://github.com/Isrothy/neominimap.nvim" })

vim.keymap.set("n", "<leader>m", "<cmd>Neominimap Toggle<CR>", { desc = "Toggle minimap" })
-- Per-window and per-tab control is available as :Neominimap WinToggle /
-- TabToggle; not bound, to keep the leader namespace small.

-- ── nvim-treesitter ──────────────────────────────────────────────────────
-- Neovim bundles only 7 parsers (c, lua, vim, vimdoc, query, markdown,
-- markdown_inline), so everything else falls back to regex syntax highlighting.
-- This adds the rest, which also lets terafox's treesitter capture groups apply.
--
-- Requires the tree-sitter CLI to build parsers: `brew install tree-sitter-cli`.
-- Note that is a different formula from `tree-sitter`, which is the library
-- alone and ships no binary.
--
-- version = "main" is deliberate. The long-standing `master` branch has a
-- setup() call and `ensure_installed`; `main` is a rewrite driven by an
-- install() API with no setup(). Most documentation online describes master.
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

-- Parsers compile on demand, so this is a no-op once they exist. Left async
-- deliberately: :wait() here would block startup for minutes on a fresh machine.
--
-- The missing set is worked out here and then forced, because install() cannot
-- be trusted to work it out itself. install.lua's skip test is
--
--   if not force and vim.list_contains(config.get_installed(), lang)
--
-- and get_installed() with no argument returns parsers *and queries* merged --
-- config.lua reads both install dirs unless told which one. nvim-treesitter
-- ships queries for every language it supports, so on a machine with no parsers
-- at all every entry below still looks already-installed, and the call returns
-- success having built nothing.
--
-- Measured before this fix: get_installed() reported 22 languages,
-- get_installed("parsers") reported 0, and site/parser was empty. So this list
-- had never built a thing, and everything outside Neovim's seven bundled
-- parsers was on regex syntax rather than treesitter -- including the
-- TypeScript this config spends most of its LSP section on.
--
-- Hence both halves. The filter is what keeps this a no-op once the parsers
-- exist: `force` alone would bypass the broken check and then recompile all
-- nineteen on every startup. Asking get_installed("parsers") explicitly is the
-- question the skip test meant to ask in the first place.
do
  local wanted = {
    "bash", "css", "diff", "dockerfile", "gitcommit", "html",
    "javascript", "json", "lua", "markdown", "markdown_inline",
    "query", "regex", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
  }

  local have = {}
  for _, lang in ipairs(require("nvim-treesitter.config").get_installed("parsers")) do
    have[lang] = true
  end

  local missing = vim.tbl_filter(function(lang)
    return not have[lang]
  end, wanted)

  if #missing > 0 then
    require("nvim-treesitter").install(missing, { force = true })
  end
end

-- Markdown code fences: undo the query's concealment of the ``` lines.
--
-- Neovim 0.11 started concealing fenced_code_block_delimiter with
-- `conceal_lines`, which unlike plain `conceal` removes the whole line from the
-- display rather than hiding its characters. Combined with conceallevel = 2 --
-- set on markdown further down, for obsidian.nvim's own rendering -- the ```
-- vanishes as soon as the cursor leaves the line, so a block being typed
-- collapses underneath you and its extent stops being visible at all. The
-- cursor line itself is exempt, which is what makes it read as a glitch rather
-- than a setting: the fence is there while you type it and gone once you move.
--
-- Both directives go, not just conceal_lines. Dropping that one alone leaves
-- `conceal ""` behind, which renders the fence as an empty line -- a mystery
-- gap, worse than either extreme.
--
-- Patched in memory rather than by shipping a replacement query file: query
-- files do not merge unless the later one opens with a `;; extends` modeline,
-- so a copy of our own under ~/.config/nvim/queries would replace the whole
-- thing and then have to be kept in step with upstream by hand. This is the
-- same shape as the plenary patch near the top of this file -- read what is
-- actually on the runtimepath, rewrite the two lines, and assert the count so
-- that an upstream change is noticed rather than silently doing nothing.
--
-- The file this reads is nvim-treesitter's own copy under site/queries, not
-- $VIMRUNTIME's: the plugin ships the same query, and with no `;; extends` on
-- it that copy replaces the bundled one outright. get_files reports whichever
-- is genuinely in effect, so this follows it without having to care.
--
-- conceallevel is deliberately left alone. Turning it off for markdown would
-- fix the fences and take obsidian.nvim's link and checkbox rendering with
-- them; this touches only the one query that was hiding whole lines.
do
  local sources = {}
  for _, file in ipairs(vim.treesitter.query.get_files("markdown", "highlights")) do
    sources[#sources + 1] = table.concat(vim.fn.readfile(file), "\n")
  end

  local count = 0
  local patched = table.concat(sources, "\n")
    :gsub('%s*%(#set! conceal ""%)\n%s*%(#set! conceal_lines ""%)', function()
      count = count + 1
      return ""
    end)

  -- Zero allows for upstream dropping this of its own accord; any count other
  -- than the two fence patterns means the query has moved and this needs a look
  -- rather than a silent no-op.
  assert(count == 0 or count == 2, "markdown fence conceal query changed; review this patch")

  if count > 0 then
    vim.treesitter.query.set("markdown", "highlights", patched)
  end
end

-- On the main branch nothing is enabled automatically -- highlighting is
-- Neovim's own feature and needs starting per buffer. Guarded with pcall rather
-- than a filetype list so it self-maintains: any filetype with a parser lights
-- up, any without is skipped silently.
vim.api.nvim_create_autocmd("FileType", {
  desc = "Start treesitter highlighting where a parser exists",
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

-- Folding, off the same parsers. `za` toggles the fold under the cursor, which
-- is the only fold command this is here to serve -- see `:h fold-commands` for
-- the rest (zo/zc open and close one, zR/zM open and close everything, zj/zk
-- jump between them).
--
-- foldlevelstart = 99 is the setting that makes this bearable: without it
-- foldlevel starts at 0 and every file opens with everything already collapsed,
-- which is a startling way to be introduced to folding. 99 means "deeper than
-- anything real", so files open fully expanded and a fold only ever closes
-- because it was asked to.
--
-- Set globally rather than per-filetype. vim.treesitter.foldexpr() returns 0
-- for a buffer with no parser, so a plain text file simply has no folds --
-- measured at 38ms to open and draw a 20,000-line .txt, with no folds and no
-- error, which is why this needs no guard. Window-local options are also
-- genuinely awkward to set from a FileType autocmd, since one buffer can be
-- shown in several windows and can be opened in a new one later.
--
-- foldcolumn is deliberately left at 0. It would show where the folds are, but
-- this signcolumn is already carrying gitsigns, diagnostics and the lightbulb,
-- and a toggle-under-the-cursor workflow does not need to see them in advance.
-- `:setlocal foldcolumn=2` for a buffer where it helps.
--
-- foldtext = "" is Neovim 0.10's addition, and it replaces the stock
-- `foldtext()` output -- `+---  5 lines: export interface AppOptions`, a
-- summary line with its own filler and no syntax colouring. Empty disables
-- foldtext entirely and, in the option's own words, the line "is displayed
-- normally with highlighting and no line wrapping" -- so a folded interface
-- reads as its real first line, treesitter colours intact, which is the line
-- you were looking at before folding it.
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 99
vim.opt.foldtext = ""

-- <Space> toggles the fold under the cursor. Free here because 'mapleader' is
-- never set, so leader is the default backslash and Space is claimed by
-- nothing; its stock job -- move right one character -- is what `l` already
-- does. Being an unmodified key it also survives the terminal chain, unlike
-- anything involving a modifier plus a special key.
--
-- Worth knowing if leader is ever reconsidered: Space is by far the most common
-- choice for it, and this takes that option off the table without a reshuffle.
--
-- Guarded rather than a bare `za` mapping, which is the whole reason this is a
-- function. `za` on a line that is not inside a fold does not no-op, it raises
-- E490: No fold found -- fine for a deliberate z-prefixed command, a beep on
-- every stray press of a key this frequently used. foldlevel() is 0 exactly
-- when there is nothing to toggle, so that is the test.
--
-- Silent when there is no fold rather than falling through to the stock
-- rightward motion: a key that means "fold" and occasionally moves the cursor
-- instead would be worse than one that occasionally does nothing.
vim.keymap.set("n", "<Space>", function()
  if vim.fn.foldlevel(vim.fn.line(".")) > 0 then
    vim.cmd("normal! za")
  end
end, { desc = "Toggle fold under cursor" })

-- ── LSP ──────────────────────────────────────────────────────────────────
-- nvim-lspconfig is used purely as data: it ships an lsp/ directory of ~414
-- server definitions (command, filetypes, root markers) which Neovim's own
-- vim.lsp.enable() discovers from the runtimepath. No setup() call, no
-- on_attach boilerplate.
--
-- The older require("lspconfig").<server>.setup{} API still exists in the
-- plugin and is what most tutorials show. It is deprecated, and tsserver was
-- renamed ts_ls.
--
-- Server binaries come from mason. lua_ls is installed but deliberately not
-- enabled yet.
vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })

vim.lsp.enable({
  "ts_ls",    -- typescript-language-server
  "yamlls",   -- yaml-language-server
  "bashls",   -- bash-language-server; its diagnostics are shellcheck
  "eslint",   -- eslint-lsp: rule violations, and applyAllFixes as a code action
})

-- Feed the lsp_problem statusline component, generically.
--
-- window/showMessage is the protocol's own way for a server to say something
-- went wrong, and Neovim already routes it to vim.notify. Recording the
-- warnings and errors as well gives every server a persistent indicator for
-- free, rather than a toast that times out.
--
-- Wrapped rather than replaced, so the notification still happens -- the first
-- occurrence is when an explanation is most useful, and the full text is there
-- rather than the 48 columns the bar keeps.
--
-- Info and Log are dropped. Servers use those for progress chatter ("project
-- loaded", index counts), which fidget already draws and which would otherwise
-- park in the bar forever.
local lsp_show_message = vim.lsp.handlers["window/showMessage"]
vim.lsp.handlers["window/showMessage"] = function(err, result, ctx)
  local ERROR, WARNING = 1, 2
  if result and (result.type == ERROR or result.type == WARNING) then
    record_lsp_problem(ctx.client_id, result.message)
  end
  return lsp_show_message(err, result, ctx)
end

-- A third channel, and the one that actually caught the eslint plugin failure:
-- a request that comes back as a JSON-RPC error rather than a notification.
-- Neither window/showMessage nor a server's own method -- it is the response to
-- a request nvim made, reported as
--
--   eslint: -32603: Request textDocument/diagnostic failed with message: ...
--
-- Wrapping the handler table catches these for every method with a default
-- handler, textDocument/diagnostic among them, which is where a linter that
-- cannot load its config surfaces. Keys are collected first because assigning
-- into a table while iterating it with pairs() is only defined for keys that
-- already exist.
--
-- Cancellation is not a problem with the server. ContentModified means the
-- buffer changed while the request was in flight, which happens constantly
-- while typing, and the two cancelled codes are routine; nvim's own reporting
-- skips them for the same reason, so recording them would fill the bar with
-- noise from ordinary editing.
local LSP_CANCELLED = {
  [-32800] = true, -- RequestCancelled
  [-32801] = true, -- ContentModified
  [-32802] = true, -- ServerCancelled
}
for _, method in ipairs(vim.tbl_keys(vim.lsp.handlers)) do
  local handler = vim.lsp.handlers[method]
  vim.lsp.handlers[method] = function(err, result, ctx, config)
    if err and err.message and not LSP_CANCELLED[err.code] then
      record_lsp_problem(ctx.client_id, err.message)
    end
    return handler(err, result, ctx, config)
  end
end

-- eslint reports one generic "Parsing error: ..." when a file will not parse,
-- duplicating ts_ls -- which says it better, giving several specific messages
-- where eslint gives one. Filtered out here; every other eslint diagnostic is a
-- rule violation ts_ls does not cover, so there is no overlap once it parses.
--
-- This must hook textDocument/diagnostic, not publishDiagnostics: eslint
-- advertises diagnosticProvider and therefore serves *pull* diagnostics, while
-- ts_ls uses the older push notification. Both are wired up regardless.
local function drop_parse_errors(list)
  return vim.tbl_filter(function(d)
    return not tostring(d.message or ""):match("^Parsing error:")
  end, list or {})
end

vim.lsp.config("eslint", {
  handlers = {
    ["textDocument/diagnostic"] = function(err, result, ctx)
      if result then
        result.items = drop_parse_errors(result.items)
      end
      return vim.lsp.handlers["textDocument/diagnostic"](err, result, ctx)
    end,
    ["textDocument/publishDiagnostics"] = function(err, result, ctx)
      if result then
        result.diagnostics = drop_parse_errors(result.diagnostics)
      end
      return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx)
    end,

    -- An adapter, not a special case. eslint is one of the twenty-odd servers
    -- in lspconfig's 414 that report trouble through a method of their own
    -- rather than window/showMessage, so the generic wrapper above never sees
    -- this one -- it arrives as `eslint/noLibrary`. Feeding the same store
    -- keeps the statusline component generic and confines the server-specific
    -- knowledge to these few lines.
    --
    -- It means eslint found a config file -- the only reason it attaches at
    -- all -- but not the library that config needs. Nearly always a checkout
    -- whose dependencies are not installed, which is the default state of a
    -- fresh `git worktree add`: eslint.config.mjs is tracked, node_modules is
    -- not.
    --
    -- This replaces lspconfig's own handler, which only calls vim.notify, and
    -- does so on every occurrence -- the server asks again for each document
    -- it is told to validate, so opening a few files in an uninstalled
    -- checkout produces a stack of identical toasts. record_lsp_problem keeps
    -- the first per client, and the notify here matches it.
    ["eslint/noLibrary"] = function(_, _, ctx)
      if record_lsp_problem(ctx.client_id, "no library") then
        vim.notify(
          "eslint attached but found no ESLint library -- dependencies are probably not installed",
          vim.log.levels.WARN
        )
      end
      return {}
    end,
  },
})

-- ── Code actions: actions-preview.nvim ───────────────────────────────────
-- Replaces the picker vim.lsp.buf.code_action() puts up, which is a bare list
-- of titles. ts_ls routinely answers a single cursor position with sixteen
-- actions whose names differ by a word or two ("Convert default export to
-- named export" next to "Convert named export to default export"), so the
-- title alone rarely identifies the one that does what you meant. This
-- previews the diff each action would actually apply, which is the only
-- reliable way to tell them apart.
--
-- It also answers the case of a fix that reads correctly and is not: the
-- SC2164 suggestion shellcheck offers on an `A && B` line appends `|| exit`,
-- which changes the control flow so the script quits when the test merely
-- fails. A diff shows that; a list of titles cannot.
--
-- A fork of vim.lsp.buf.code_action() rather than a reimplementation, so it
-- takes the same opts -- `filter` below is core's own -- and builds its
-- preview by applying the action's edit to a scratch copy and diffing that
-- against the buffer.
--
-- rachartier/tiny-code-action.nvim was trialled alongside this and dropped.
--
-- Neovim's own `gra` is left alone and still runs the stock picker,
-- unfiltered and with no preview.
vim.pack.add({ "https://github.com/aznhe21/actions-preview.nvim" })

require("actions-preview").setup({
  -- Trimmed from the shipped list of four. mini.pick and snacks are not
  -- installed -- only mini.indentscope, trailspace and cursorword are, and
  -- snacks not at all -- so those two entries could never be reached. nui is
  -- kept as a genuine fallback: it ships with neo-tree, so it is always there.
  --
  -- The nui backend was tried as the primary and reverted. It uses nui.menu,
  -- so there is no fuzzy prompt -- arrows and <CR> only, which suits a
  -- three-row list -- but telescope's window is the better one to read a diff
  -- in, mainly because <C-u>/<C-d> scroll the preview and nui has no
  -- equivalent.
  backend = { "telescope", "nui" },

  -- A priority list, each entry guarded by its own is_available, so the first
  -- one actually on PATH wins. Only delta is listed: difftastic and
  -- diff-highlight are not installed, and diff-so-fancy was removed from the
  -- Brewfile rather than kept as a fallback nobody wants to fall back to.
  --
  -- Worth knowing: hl.delta() shells out to bare `delta`, which reads git
  -- config, so this already inherits the whole terafox delta setup from
  -- ~/.config/git/delta-terafox.gitconfig -- syntax-theme, the plus/minus
  -- styles, line numbers, tabs=4. Nothing needs restating here, and the
  -- preview matches what `git diff` looks like in a terminal.
  --
  -- One deliberate difference: core.pager adds --side-by-side above 160
  -- columns, and this does not. A telescope preview pane is far narrower than
  -- the terminal, so side-by-side would be cramped.
  --
  -- If delta ever goes missing this list is empty and the preview falls back
  -- to a plain uncoloured diff, which is the plugin's own default behaviour --
  -- degraded, not broken.
  highlight_command = {
    require("actions-preview.highlight").delta(),
  },

  -- Handed straight to vim.diff(), so its whole option set is available rather
  -- than just ctxlen.
  --
  -- histogram over the default myers: it is the algorithm git itself reaches
  -- for on code, and it keeps related lines together instead of producing the
  -- shortest edit script. indent_heuristic shifts hunk boundaries to line up
  -- with indentation, which stops a inserted block being attributed to the
  -- closing brace of the one above it.
  --
  -- ignore_whitespace is deliberately NOT set, though the plugin's own FAQ
  -- suggests it: an action whose entire effect is reindentation would preview
  -- as an empty diff, which is exactly the case worth seeing.
  --
  -- ctxlen 3 is the default, stated because a one-line edit like appending
  -- `|| exit` is unreadable without its surroundings.
  diff = {
    ctxlen = 3,
    algorithm = "histogram",
    indent_heuristic = true,
  },
})

-- The filter drops actions the server marked `disabled`. ts_ls answers a
-- cursor position with every refactor it knows -- "Extract function", "Move to
-- a new file", "Convert to template string" and a dozen more -- and marks the
-- ones that do not apply there with a reason ("Could not find export
-- statement", and so on) rather than leaving them out. Measured on
-- scratch.ts:7, that is 16 disabled entries against 2 real ones.
--
-- A disabled action carries no edit and no data, so codeAction/resolve returns
-- it just as bare: there is nothing to apply and nothing to preview, which is
-- what "No preview available for this action" means on those rows. Filtering
-- them is what makes the preview worth having -- otherwise the list is mostly
-- entries that cannot do anything and the real fix is buried among them.
--
-- Anything genuinely applicable is not disabled, so nothing useful is lost:
-- make a visual selection and the extract refactors come back enabled.
local function code_action()
  require("actions-preview").code_actions({
    filter = function(action)
      return not action.disabled
    end,
  })
end

vim.keymap.set({ "n", "x" }, "<leader>ca", code_action, { desc = "Code action" })

-- gra is Neovim's own default for code actions, one of the six it binds
-- whenever a server attaches (grn rename, gra code action, grr references, gri
-- implementation, grt type definition, gO document symbol). Repointed here
-- rather than deleted: deleting would leave a hole in that family, so typing
-- it out of habit would silently do nothing, and the stock picker is not
-- wanted either -- unfiltered, so ts_ls's sixteen inapplicable refactors come
-- back with it, and no preview. Both keys now reach the same place.
vim.keymap.set({ "n", "x" }, "gra", code_action, { desc = "Code action" })

-- ── Code action availability: nvim-lightbulb ─────────────────────────────
-- Marks the cursor line when a server actually has an action there, so \ca
-- stops being a guess. In scratch.sh that means lines 14 (SC2086) and 31
-- (SC2164) are marked and line 35 is not: shellcheck ships machine-applicable
-- fix data for the first two and none for SC2046/SC2005, and bashls only
-- forwards what shellcheck gives it.
--
-- The filter is the same one \ca uses, and it is what makes this worth having:
-- ts_ls returns sixteen *disabled* refactors at every position in a TypeScript
-- file, so unfiltered the lamp is lit on every line and tells you nothing.
-- Note the signature differs from actions-preview's -- here the client name is
-- passed first and the action second.
vim.pack.add({ "https://github.com/kosayoda/nvim-lightbulb" })

require("nvim-lightbulb").setup({
  -- Only light up for actual fixes. Without this the lamp stays lit on lines
  -- that have just been fixed, because ts_ls still offers refactors there --
  -- "Move to a new file" and "Inline variable" are available on most top-level
  -- statements in a TypeScript file, so the marker ends up meaning "this is a
  -- line of code" rather than "there is something to do here".
  --
  -- This becomes context.only on the request, so the *server* filters by kind
  -- and returns less, rather than the results being thrown away here.
  --
  -- quickfix alone: verified that it keeps everything worth marking -- ts_ls's
  -- "Remove import from ...", and bashls forwarding shellcheck's SC2086 and
  -- SC2164 fixes, are all kind=quickfix. source.fixAll and
  -- source.organizeImports are deliberately excluded: they apply to the whole
  -- file, so they would light every line equally and say nothing about where
  -- the cursor is.
  --
  -- This narrows the *marker* only. \ca and gra still offer the full set,
  -- refactors included, which is right -- asking for actions is deliberate,
  -- whereas the lamp has to earn its place by being quiet.
  action_kinds = { "quickfix" },

  -- Off by default: without this nothing ever fires and update_lightbulb() has
  -- to be called by hand.
  --
  -- Note this sets the *global* updatetime to 200ms, down from 4000. That is
  -- the documented way to make CursorHold usable, and it also speeds up the
  -- checktime autocmd at the top of this file, but it is a side effect on
  -- everything that hangs off CursorHold rather than a local setting.
  --
  -- CursorHold rather than CursorMoved deliberately: every trigger is a
  -- textDocument/codeAction round-trip, so this fires once the cursor stops,
  -- not on every motion.
  autocmd = { enabled = true, updatetime = 200 },

  -- A sign, at a priority above everything else in the column.
  --
  -- The `number` handler was tried first and rendered nothing visible, which
  -- makes sense in hindsight: the bulb only ever appears on the cursor line,
  -- and that line's number is already painted by CursorLineNr, so recolouring
  -- it had nothing to win against.
  --
  -- priority 25 puts it above gitsigns (20) and diagnostics (5). That is a
  -- deliberate reversal of the ordering set up for those two: on the one line
  -- where an action exists and the cursor is sitting, the bulb covers the git
  -- bar. Acceptable because it is one line, only while the cursor is on it,
  -- and only when there is genuinely something to apply -- and a marker that
  -- loses the column half the time would not be worth having.
  --
  -- U+03DF, Greek koppa, not the default emoji: emoji-class glyphs render
  -- double-width and shift the gutter (measured -- the bulb and high-voltage
  -- emoji are both 2 cells, every geometric alternative is 1). Chosen for its
  -- shape rather than its meaning: it reads as a lightning bolt, which carries
  -- the same "something available here" sense as the bulb it replaces.
  --
  -- Deliberately not a bar or line. gitsigns owns those in this column --
  -- U+2503 for add and change, U+2506 untracked, U+2581/U+2594 for deletes --
  -- so a glyph with no vertical stroke is distinguishable at a glance even
  -- before colour. Also avoids U+25CF, which bufferline already uses to mean
  -- "unsaved buffer".
  --
  -- lens_text is the hollow circle and is decorative: code lenses only fire
  -- for servers advertising codeLensProvider, and of the four enabled here
  -- only ts_ls does -- with its two lens settings off by default, so it
  -- returns none.
  sign = {
    enabled = true,
    text = "\u{03DF}",
    lens_text = "\u{25CB}",
  },
  priority = 25,
  number = { enabled = false },

  -- Two jobs. `disabled` is the ts_ls case described above.
  --
  -- The client check is a workaround for a bug in obsidian.nvim, not a
  -- preference. obsidian-ls answers textDocument/codeAction from the *note*
  -- rather than the position: its handler reads params.textDocument.uri and
  -- nothing else -- no range, no context -- and returns all eighteen of its
  -- actions ("Add file property", "Merge current note into another note") at
  -- every line of a vault note. So the lamp was lit on every line of prose.
  --
  -- action_kinds above cannot reach it. That becomes context.only on the
  -- request, which works by asking the server to filter, and this handler
  -- never reads params.context. There is nothing to match on in the responses
  -- either: the actions carry no `kind` at all, the source having a literal
  -- `-- TODO: kind` where the field belongs.
  --
  -- Checked upstream before working around it rather than after: v3.16.7 is
  -- the newest release -- there is no 3.17.0 or 4.x despite what the changelog
  -- notes referenced above imply -- and `main` still carries that TODO. No
  -- version to move to.
  --
  -- This narrows the marker only, same as the rest of this block. \ca still
  -- offers the obsidian actions, which is right: they are real and useful,
  -- just not per-line, so they are worth asking for and not worth a lamp on
  -- every line.
  --
  -- nvim-lightbulb also has `ignore.actions_without_kind`, which would catch
  -- this and any other server with the same defect. Not used: it would also
  -- drop legitimate kind-less actions from servers that are behaving.
  filter = function(client_name, action)
    return client_name ~= "obsidian-ls" and not action.disabled
  end,
})

-- ── LSP progress and notifications: fidget.nvim ──────────────────────────
-- Two separate halves in one plugin, and both are wanted here:
--
--   progress      draws the `$/progress` reports a language server sends while
--                 it works -- ts_ls indexing a project, eslint-lsp starting up
--                 -- as a spinner in the bottom-right corner that clears
--                 itself when the server finishes. Without it those reports go
--                 nowhere visible, so a server that takes ten seconds to come
--                 up is indistinguishable from a hung editor.
--
--   notification  a vim.notify implementation. Everything this file notifies
--                 about -- mason's installs, the unsupported-file-type
--                 refusal, conform's format failures -- currently lands on the
--                 command line, one line high, where a long message forces a
--                 hit-enter prompt and a short one sits there until something
--                 else happens to overwrite it. As toasts they stack, time out
--                 on their own, and `:Fidget history` keeps what scrolled by.
--
-- No Nerd Font dependency, in keeping with the rest of this config: the
-- default spinner is braille (U+28xx) and the done marker is U+2714, both
-- plain Unicode that Ghostty draws from its own fonts.
vim.pack.add({ "https://github.com/j-hui/fidget.nvim" })

require("fidget").setup({
  notification = {
    -- Off by default, which leaves vim.notify alone and makes this half of the
    -- plugin reachable only through fidget.notify() -- i.e. nothing already
    -- written here would use it.
    override_vim_notify = true,
    window = {
      -- Default is 100, meaning fully transparent: the toast has no background
      -- of its own and its text is drawn straight over whatever code sits
      -- underneath. Fine above a blank buffer, illegible above a full one. 0
      -- gives it terafox's Normal background instead.
      winblend = 0,
      -- Needed once winblend is 0: with a solid background and no border the
      -- toast is a bare rectangle of text butted against the code. "single" is
      -- the same box-drawing style neo-tree's popups use above.
      border = "single",
    },
  },
})

-- ── nvim-lint ────────────────────────────────────────────────────────────
-- For linters with no language server. It writes into vim.diagnostic under its
-- own namespace, so signs, ]d/[d and the inline renderer treat its output
-- exactly like LSP diagnostics.
--
-- Nothing here should duplicate a server: shellcheck is already covered by
-- bashls, and eslint would be better served by the eslint language server than
-- by eslint_d here.
vim.pack.add({ "https://github.com/mfussenegger/nvim-lint" })

local lint = require("lint")

lint.linters_by_ft = {
  dockerfile = { "hadolint" },
  -- overlaps yamlls, but they check different things: yamlls does schema
  -- validation, yamllint does style and structure.
  yaml = { "yamllint" },
}

-- yamllint resolves its .yamllint config from the *working directory*, not from
-- the file being linted, so a project's rules were ignored unless nvim happened
-- to be started inside that project. This searches upward from the file for the
-- nearest .yamllint and runs yamllint from there.
--
-- Bounded at the git repo root rather than left to reach "/": an unbounded
-- upward search would happily pick up a ~/.yamllint and apply one project's
-- rules to every YAML file on the machine, which is the global-config problem
-- this arrangement exists to avoid. `stop` is the root's *parent* so the root
-- itself is still searched.
--
-- `linter.cwd` must be a *string*: nvim-lint reads it as `linter.cwd or
-- getcwd()` and hands it straight to `vim.cmd.cd()` without evaluating
-- callables, so assigning a function here fails at lint time with "Invalid
-- 'args': Cannot convert given Lua type". Hence a helper that is called for the
-- current buffer and whose result is assigned just before each run, below.
local function yamllint_cwd(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  local root = vim.fs.root(buf, ".git")
  local found = vim.fs.find(".yamllint", {
    upward = true,
    path = dir,
    stop = root and vim.fs.dirname(root) or nil,
  })[1]
  return found and vim.fs.dirname(found) or dir
end

-- Debounced so linting follows typing rather than waiting for a save. Each
-- keystroke restarts the timer; the linters run once, 700ms after you stop.
-- Without this every keystroke would spawn a process.
--
-- try_lint() accepts linter names, so a slow linter can be split onto its own
-- autocmd firing only on BufWritePost, per the nvim-lint maintainer's advice in
-- issue #540. Everything configured here is fast, so one timer covers it.
local lint_timer = assert(vim.uv.new_timer())

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave", "BufReadPost", "BufWritePost" }, {
  desc = "Run nvim-lint, debounced",
  callback = function()
    lint_timer:stop()
    lint_timer:start(700, 0, vim.schedule_wrap(function()
      lint.linters.yamllint.cwd = yamllint_cwd(vim.api.nvim_get_current_buf())
      lint.try_lint()
    end))
  end,
})

-- ── Formatting: conform.nvim ─────────────────────────────────────────────
-- The counterpart to nvim-lint above, and the same shape: a filetype -> tool
-- table, binaries from mason. The difference is that it rewrites the buffer
-- rather than writing diagnostics.
--
-- Why not vim.lsp.buf.format() with the servers already enabled: ts_ls formats
-- with tsserver's own built-in style, which ignores the project's .prettierrc,
-- and nothing enabled here formats shell at all. conform runs the same binaries
-- the project's npm scripts and CI run, so the result matches -- and it still
-- falls through to a language server where no CLI formatter is configured, see
-- lsp_format below.
--
-- prettier and shfmt come from the mason list further down. Plain prettier,
-- not prettierd: the daemon is the faster option on paper -- it stays warm,
-- avoiding node's startup on every run -- but on this machine it does not work
-- at all. Every invocation returns "Could not connect", it never writes its
-- ~/.prettierd state file, and `prettierd start`, `pkill -f prettierd` and a
-- full :MasonInstall reinstall each failed to fix it; the suspect is Node
-- v26.8.1 being newer than @fsouza/prettierd 0.29 expects. A formatter that
-- silently does nothing is worse than a slower one.
--
-- The cost turns out to be small anyway: measured on this machine, prettier
-- takes ~220ms cold and ~60ms warm over this config's own YAML, not the ~300ms
-- node startup usually quoted as the reason to prefer the daemon. Worth
-- retrying prettierd after a node or prettierd upgrade -- it is a one-word
-- change back.
vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

local conform = require("conform")

conform.setup({
  -- A filetype absent from this table is simply never formatted (lua, for one
  -- -- stylua is deliberately not installed, see the mason list below).
  formatters_by_ft = {
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    less = { "prettier" },
    html = { "prettier" },
    graphql = { "prettier" },
    -- Overlaps yamllint the way prettier always overlaps a linter: yamllint
    -- reports the style problem, prettier removes it. They agree on the
    -- defaults in play here, and a project that configures either usually
    -- configures both.
    yaml = { "prettier" },
    -- Configured so <leader>cf works on a README, but excluded from
    -- format-on-save -- see format_on_save.
    markdown = { "prettier" },
    -- shfmt's default indentation is tabs, which is what 'expandtab = false' at
    -- the top of this file asks for, so it needs no arguments. It also reads
    -- .editorconfig, which overrides that per project.
    sh = { "shfmt" },
    bash = { "shfmt" },
  },

  -- A function rather than a table, so the on-save set can be narrower than the
  -- set of filetypes conform knows how to format. Returning nil skips the
  -- format; returning a table passes it to format() as options.
  format_on_save = function(buf)
    if vim.g.conform_disable or vim.b[buf].conform_disable then
      return
    end

    -- Markdown is formatted on demand only. The Obsidian vaults are markdown,
    -- and prettier edits prose in ways that are pure noise in a note --
    -- renumbering ordered lists, rewriting bullet characters, escaping stray
    -- punctuation -- on files that are read in an app, not diffed.
    if vim.bo[buf].filetype == "markdown" then
      return
    end

    -- Synchronous, so the bytes written are the formatted ones. If the timeout
    -- is hit the write goes ahead unformatted rather than blocking; 500ms is
    -- comfortable for prettier, measured at ~220ms cold and ~60ms warm.
    return { timeout_ms = 500, lsp_format = "fallback" }
  end,

  -- Reporting is done by the ConformFormatPost hook below instead. See there.
  notify_on_error = false,
})

-- conform notifies about the *first* failure of a given formatter and then
-- stays quiet until that formatter next succeeds -- `last_run_errored` in its
-- runner.lua, which sets `debounce_message` on the error and is not exposed as
-- an option. It is keyed by formatter name and lives for the whole session, so
-- it is not even per-buffer. That suits a setup that formats on every
-- keystroke; here a save is deliberate, and one that silently did not format
-- looks exactly like one that did.
--
-- ConformFormatPost fires on every run regardless of the debounce, so the
-- notification is raised from here and conform's own is switched off above.
-- The message is better for it, too: conform throws the real one away and
-- substitutes "Formatter failed. See :ConformInfo for details", where
-- err.message is the formatter's own stderr -- "SyntaxError: Nested mappings
-- are not allowed in compact mappings (22:16)" -- which is usually the whole
-- answer without opening anything.
--
-- Execution errors only. A timeout or an interrupted run still goes through
-- conform's own path: notify_on_error does not gate those, they are not
-- debounced, and it already reports them with their real message -- so
-- handling them here as well would just print them twice.
vim.api.nvim_create_autocmd("User", {
  pattern = "ConformFormatPost",
  desc = "Report a failed format on every save, not only the first",
  callback = function(ev)
    local err = ev.data and ev.data.err
    if not (err and require("conform.errors").is_execution_error(err.code)) then
      return
    end

    -- The first line only, with ANSI SGR sequences stripped. prettier follows
    -- its message with a syntax-highlighted code frame, which is unreadable
    -- once the escapes are literal text and redundant anyway -- those lines
    -- are already on screen in the buffer the error came from.
    --
    -- Not prefixed with the formatter's name: conform builds every one of
    -- these as "Formatter '<name>' error: ...", so it is already in there.
    local first = vim.split(err.message or "", "\n", { plain = true })[1] or ""
    vim.notify(vim.trim((first:gsub("\27%[[%d;]*m", ""))), vim.log.levels.ERROR)
  end,
})

-- Format the buffer, or the range given as :'<,'>Format. conform takes a
-- (line, col) byte range, so the last line's length has to be looked up.
vim.api.nvim_create_user_command("Format", function(args)
  local range
  if args.count ~= -1 then
    local last = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = { start = { args.line1, 0 }, ["end"] = { args.line2, #last } }
  end
  conform.format({ async = true, lsp_format = "fallback", range = range })
end, { range = true, desc = "Format the buffer or the given range" })

-- For the times a format would bury a one-line change under a whole-file
-- reflow -- a file nobody has run prettier over before, or someone else's
-- branch. `:FormatDisable!` is this buffer only, plain `:FormatDisable` is
-- every buffer; both are the pattern from conform's own README.
vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    vim.b.conform_disable = true
  else
    vim.g.conform_disable = true
  end
end, { bang = true, desc = "Turn off format-on-save (! for this buffer only)" })

vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.conform_disable = false
  vim.g.conform_disable = false
end, { desc = "Turn format-on-save back on" })

vim.keymap.set({ "n", "x" }, "<leader>cf", function()
  conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer or selection" })

-- Makes `gq` -- the built-in format operator, normally a text wrapper -- run
-- conform over the motion instead, falling back to the default behaviour for
-- any filetype with no formatter configured.
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

-- ── tiny-inline-diagnostic.nvim ──────────────────────────────────────────
-- Renders diagnostics inline: boxed, severity-coloured, wrapped rather than
-- truncated, and only for the cursor's line instead of every line at once.
--
-- Nothing is drawn until something produces diagnostics -- this only styles
-- them. Neovim's own virtual_text handler must stay off (it is off by default)
-- or every diagnostic renders twice.
vim.pack.add({ "https://github.com/rachartier/tiny-inline-diagnostic.nvim" })

require("tiny-inline-diagnostic").setup({
  -- "nonerdfont" is the fallback if the box-drawing glyphs render as tofu.
  preset = "modern",
  -- The rounded end caps are the preset's signs.left/right half-circle glyphs.
  -- Blanking them keeps modern's colours and layout but squares off the box.
  -- diag defaults to "\u{25CF}", a full-size black circle, and repeats once per
  -- diagnostic on the line. U+2022 (bullet) is smaller, which matters here
  -- because it repeats once per diagnostic. The gutter draws nothing at all --
  -- the line tint marks the line instead. Avoid the emoji-class glyphs
  -- (U+26AB, U+23FA, U+274C): they render double-width and shift the gutter.
  -- arrow removed entirely. It is drawn from a single highlight group while
  -- the message box is coloured per severity, so any colour chosen for it
  -- mismatches three of the four levels -- an error-red arrow beside a teal
  -- hint box, for instance. With no arrow there is no region to mismatch.
  signs = { left = "", right = "", diag = "\u{2022}", arrow = "" },
  options = {
    -- Long messages wrap onto further lines rather than being cut off.
    -- enabled: long messages wrap rather than being cut off.
    -- always_show + severity: errors and warnings stay visible on every line,
    -- so a mistake elsewhere in the file is readable without putting the cursor
    -- on it. Hints and info still only show on the cursor's line -- ts_ls emits
    -- hints liberally and showing those everywhere buries the real problems.
    multilines = {
      enabled = true,
      always_show = true,
      severity = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN },
    },
    -- Cursor's line only, so an error-heavy file stays readable.
    -- true: show every diagnostic on the cursor's line. With false the plugin
    -- only renders diagnostics whose range covers the cursor *column*, so an
    -- error on the first word of a line stayed invisible unless the cursor sat
    -- on that word -- the line was tinted with no message beside it.
    show_all_diags_on_cursorline = true,
    enable_on_insert = false,
    -- The plugin attaches its renderer on LspAttach by default, so a buffer with
    -- no language server never gets one -- a Dockerfile linted by nvim-lint/hadolint
    -- showed the line tint but no message, because the tint comes from
    -- vim.diagnostic itself while the message comes from this plugin.
    -- DiagnosticChanged fires for every producer, LSP or not.
    overwrite_events = { "DiagnosticChanged", "BufEnter" },
  },
})

-- severity_sort puts errors above warnings. virtual_text stays off (Neovim's
-- default) because tiny-inline-diagnostic draws the inline text instead.
--
-- signs.text replaces Neovim's default gutter letters (E/W/I/H) so the gutter
-- matches the inline marker instead of shouting a capital letter.
vim.diagnostic.config({
  severity_sort = true,
  signs = {
    -- Below gitsigns' priority of 6. The sign column holds one sign, and the
    -- highest priority wins -- diagnostics default to 10, so the blank glyph
    -- below was silently hiding gitsigns' change bar on any line that also had
    -- a diagnostic. linehl still applies regardless of which sign is drawn.
    priority = 5,
    -- The gutter belongs to gitsigns. Diagnostics are conveyed by the line tint
    -- below instead, so no glyph is drawn -- but a sign still has to be *placed*
    -- for linehl to apply, hence a space rather than nothing.
    --
    -- priority 5 sits below gitsigns' 6. The sign column holds one sign and the
    -- highest priority wins; diagnostics default to 10, so without this the
    -- blank space took the column and gitsigns' bar vanished the moment a
    -- diagnostic arrived.
    priority = 5,
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
    -- linehl tints the whole line instead. This lives under `signs` rather than
    -- being a top-level option, so signs must stay enabled for it to apply.
    --
    -- Errors and warnings only. ts_ls emits HINT diagnostics liberally -- an
    -- unused import puts a hint on its line -- so tinting those colours most of
    -- the file and the signal is lost. VSCode tints the same two levels.
    linehl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticLineError",
      [vim.diagnostic.severity.WARN] = "DiagnosticLineWarn",
    },
  },
})

-- Full-line tints for diagnostics, matching the inline box exactly by reading
-- the plugin's own highlight groups rather than hardcoding hexes -- so they
-- track the colourscheme and any change to the plugin's blend settings.
--
-- Defined here, not in theme_tweaks further up: those groups do not exist until
-- tiny-inline-diagnostic has been set up.
local function diagnostic_line_tints()
  local pairs_ = {
    { line = "DiagnosticLineError", box = "TinyInlineDiagnosticVirtualTextError", fallback = "#433131" },
    { line = "DiagnosticLineWarn", box = "TinyInlineDiagnosticVirtualTextWarn", fallback = "#48413B" },
  }
  for _, spec in ipairs(pairs_) do
    local box = vim.api.nvim_get_hl(0, { name = spec.box, link = false })
    local bg = box.bg and string.format("#%06x", box.bg) or spec.fallback
    vim.api.nvim_set_hl(0, spec.line, { bg = bg })
  end

  -- The line tint sits behind the sign column too -- linehl covers the whole
  -- line and cannot be restricted to the text area. terafox's change and delete
  -- colours are close in hue to the reddish error tint, so brighten them enough
  -- to read against it.
  vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#FFC08A" })
  vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#FF7B6B" })

end

vim.api.nvim_create_autocmd("ColorScheme", { callback = diagnostic_line_tints })
diagnostic_line_tints()

vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Previous diagnostic" })
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic detail" })

-- ── Diagnostic and symbol lists: trouble.nvim ────────────────────────────
-- A navigable list view over things that are otherwise only reachable one at a
-- time. ]d and [d step through diagnostics in the current buffer and
-- <leader>d shows one in a float; this gives the whole set at once, grouped by
-- file, with the source line beside each entry -- which is what you want when
-- deciding *which* problem to fix rather than fixing the one you are on.
--
-- Also fronts the quickfix and location lists, and LSP symbols. Nothing here
-- replaces a keymap that already exists.
--
-- Under <leader>q, not folke's usual <leader>x: that is taken here by "close
-- buffer, keep the window". q because these are all quickfix-shaped lists, and
-- <leader>t -- the other obvious choice -- is the terminal toggle.
vim.pack.add({ "https://github.com/folke/trouble.nvim" })

-- Every symbol-kind icon is a Nerd Font glyph, as are the folder and fold
-- markers, so all of them render as tofu here -- the same reason devicons is
-- not installed and neo-tree's icons are blanked.
--
-- The kinds are blanked in a loop rather than listed: there are twenty-six,
-- and they are exactly the LSP SymbolKind names, so the protocol table is the
-- authoritative source and cannot drift out of step with trouble's own list.
local trouble_kinds = {}
for _, kind in ipairs(vim.lsp.protocol.SymbolKind) do
  if type(kind) == "string" then
    trouble_kinds[kind] = ""
  end
end

-- Returns focus to the trouble list once the code action picker has gone,
-- however it went -- action applied, cancelled with <Esc>, or nothing offered.
-- Without this, `a` leaves you in the code window and the list has to be
-- re-entered by hand for every diagnostic, which defeats keeping it open.
--
-- Polling the window list rather than a callback, because there is no event to
-- hang this on: actions-preview's code_actions() takes no completion callback,
-- and telescope emits nothing for teardown -- it has TelescopeFindPre and
-- TelescopeKeymap and no counterpart for closing. So the prompt window
-- vanishing is the only observable signal.
--
-- Armed only once a prompt window genuinely exists, checked on a short defer.
-- On a line with no applicable actions the picker never opens, and an
-- unconditional watcher would sit there and then yank focus into the list the
-- next time any window anywhere was closed.
local function trouble_refocus(list_win)
  local function prompt_open()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "TelescopePrompt" then
        return true
      end
    end
    return false
  end

  vim.defer_fn(function()
    if not prompt_open() then
      return
    end

    local id
    id = vim.api.nvim_create_autocmd("WinClosed", {
      desc = "Return focus to trouble when the code action picker closes",
      callback = function()
        -- Scheduled: during WinClosed the window being closed is still in the
        -- list, so an immediate check would always still see the prompt.
        -- telescope also closes several windows, so this fires more than once
        -- and only acts on the pass where none are left.
        vim.schedule(function()
          if prompt_open() then
            return
          end
          pcall(vim.api.nvim_del_autocmd, id)
          if vim.api.nvim_win_is_valid(list_win) then
            pcall(vim.api.nvim_set_current_win, list_win)
          end
        end)
      end,
    })
  end, 100)
end

require("trouble").setup({
  -- Close the window once the last item is gone. Default is false, which
  -- leaves an empty box sitting there after the final diagnostic is fixed --
  -- and since `a` keeps the list open to work through several in a row, that
  -- is exactly how a session ends. auto_refresh is already on by default, so
  -- entries disappear as they are resolved; this just finishes the job.
  --
  -- Note the sibling auto_open is deliberately left off: trouble itself warns
  -- against setting it globally, and a list that appears unbidden the moment a
  -- server reports anything would fight the inline diagnostics rather than
  -- complement them.
  auto_close = true,

  -- Focus the list when it opens. Default is false, which leaves the cursor in
  -- the code and means every use starts with a window switch -- wrong here,
  -- because the reason for opening it is always to work through it.
  focus = true,

  -- A float rather than the default bottom split, sitting at the bottom.
  --
  -- height is 10 *lines*, not a fraction: trouble treats a size <= 1 as a
  -- proportion of the editor and anything above it as an absolute count, so
  -- 0.8 would be 80% and 10 is ten rows. The default float is 80% tall, which
  -- for a nine-item list was mostly empty.
  --
  -- position is { row, col }. A value of 1 or less is a fraction of the
  -- *leftover* space rather than of the editor -- 0 flush to the top, 1 flush
  -- to the bottom -- but 1 would put the float over the statusline and command
  -- line, since parent_size is the whole of vim.o.lines. A value above 1 is an
  -- absolute row and a negative one counts back from the bottom, which is what
  -- keeps this pinned to the bottom at any window height instead of drifting
  -- as a fraction would.
  --
  -- -15 was measured rather than derived: ten content rows plus a border row
  -- either side comes to twelve, but -13 put the bottom border on the
  -- statusline rather than above it, so the border is evidently not counted
  -- the way the arithmetic suggests. -15 leaves one clear row between the
  -- float and the statusline. Nudge this one number to move it.
  --
  -- 0.5 horizontally leaves it centred.
  win = {
    type = "float",
    border = "single",
    size = { width = 0.8, height = 10 },
    position = { -15, 0.5 },

    -- A key hint on the bottom border. trouble passes title/footer straight
    -- through to nvim_open_win, so this costs no rows -- it is drawn on the
    -- border that is there anyway, unlike a header line inside the window.
    --
    -- Three keys only, not the whole map. `s` and `a` because neither is
    -- guessable -- `s` cycles a severity filter and `a` is the code action
    -- binding added below, and nothing on screen would otherwise suggest
    -- either exists. `?` because it opens the full list, so the footer can stay
    -- short rather than trying to be complete. <CR> and q are left out on the
    -- grounds that they are what anyone would try first anyway.
    --
    -- U+00B7 as the separator: single cell, no Nerd Font.
    footer = " ? help \u{00B7} s severity \u{00B7} a code action ",
    footer_pos = "center",
  },

  -- `a` runs the code action picker on the item under the cursor, so a
  -- diagnostic can go from "listed" to "fixed" without leaving the list and
  -- finding the line by hand.
  --
  -- jump, then the picker on a scheduled tick. jump moves the real cursor to
  -- the diagnostic's position -- which is what the LSP request is made against
  -- -- and hands focus to the code window, leaving the list open behind it.
  --
  -- The list is deliberately *not* closed. Neither trouble nor telescope sets
  -- a zindex, so both take nvim's default of 50 and the later window wins,
  -- which is the picker -- there is no stacking problem to avoid. Keeping it
  -- open means working through several diagnostics in one pass instead of
  -- reopening the list after each fix, and trouble refreshes itself when the
  -- diagnostics change, so entries disappear as they are resolved. q or <Esc>
  -- in the list closes it when you are done.
  --
  -- Reuses the same code_action local that \ca and gra call, so all three
  -- share the actions-preview picker and the `disabled` filter rather than
  -- this one quietly being the stock one.
  keys = {
    a = {
      action = function(view)
        local list_win = view.win.win
        view:jump()
        vim.schedule(function()
          code_action()
          trouble_refocus(list_win)
        end)
      end,
      desc = "Code action",
    },
  },

  icons = {
    -- indent's top/middle/last are box-drawing and survive as they are; only
    -- the two fold markers are Nerd Font. Replaced with geometric triangles,
    -- single cell, the same class of glyph as the indentscope guide.
    indent = {
      fold_open = "\u{25BE} ",
      fold_closed = "\u{25B8} ",
    },
    -- Blank rather than lettered. The file path is already on the line, so a
    -- folder marker is pure decoration -- unlike neo-tree's git_status column,
    -- which was kept as letters because it carries information.
    folder_closed = "",
    folder_open = "",
    kinds = trouble_kinds,
  },
})

-- <leader>t is the everyday one -- the workspace diagnostics list -- and is a
-- single press because that is the view opened by far the most. It is a leaf,
-- not a prefix: the other modes live under <leader>q instead, because a key
-- that is both a complete mapping and the start of a longer one makes vim wait
-- 'timeoutlen' before firing it, so a slightly slow <leader>tt would run the
-- leaf. That is the same collision the <leader>fe mapping above exists to
-- avoid.
--
-- <leader>t was toggleterm's until that was removed; t for trouble is the
-- obvious claim on it.
vim.keymap.set("n", "<leader>t", "<cmd>Trouble diagnostics toggle<cr>",
  { desc = "Trouble: diagnostics (workspace)" })

for _, map in ipairs({
  { "qb", "diagnostics toggle filter.buf=0", "Diagnostics (this buffer)" },
  { "qs", "symbols toggle", "Symbols" },
  { "ql", "loclist toggle", "Location list" },
  { "qf", "qflist toggle", "Quickfix list" },
}) do
  vim.keymap.set("n", "<leader>" .. map[1], "<cmd>Trouble " .. map[2] .. "<cr>",
    { desc = "Trouble: " .. map[3] })
end

-- ── mason.nvim ───────────────────────────────────────────────────────────
-- Installs language servers, linters and formatters into
-- ~/.local/share/nvim/mason/bin and prepends that to *Neovim's* PATH. Nothing
-- lands system-wide, which also means the tools are not on your shell's PATH --
-- running eslint in a terminal still needs a project-local or Homebrew copy.
vim.pack.add({ "https://github.com/mason-org/mason.nvim" })

require("mason").setup({})

-- mason.nvim has no ensure_installed of its own; that is what the separate
-- mason-tool-installer plugin exists for. Its install API is public though, so
-- the list below is installed from here without adding a plugin.
--
-- Mason only puts these on PATH. Installing a server does not enable it (that
-- needs nvim-lspconfig plus vim.lsp.enable), and a linter or formatter binary
-- does nothing until something runs it. So this list is inert on its own.
--
-- Deliberately absent:
--   efm       -- lints on save only, which defeats on-type diagnostics
--   luacheck  -- a Lua rock needing luarocks; mason cannot install it. Use
--                selene instead, though lua-language-server covers most of it
--   stylua    -- not wanted
local mason_tools = {
  -- language servers
  "typescript-language-server",
  "yaml-language-server",
  "lua-language-server",
  "bash-language-server",
  -- linters
  "eslint-lsp",   -- the eslint *server*, not eslint_d: on-type diagnostics plus
                  -- applyAllFixes as a code action, which a linter runner
                  -- cannot offer. Remove the old binary with
                  -- :MasonUninstall eslint_d
  "shellcheck",
  "hadolint",
  "yamllint",
  -- formatters, run by conform.nvim above
  "prettier",
  "shfmt",
}

vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Install any missing mason-managed tool",
  once = true,
  callback = function()
    if #mason_tools == 0 then
      return
    end
    vim.schedule(function()
      local ok, registry = pcall(require, "mason-registry")
      if not ok then
        return
      end

      -- refresh() first: a cold registry knows about no packages at all, so
      -- every is_installed() check would report false and reinstall the lot.
      registry.refresh(function()
        local missing = {}
        for _, name in ipairs(mason_tools) do
          local found, pkg = pcall(registry.get_package, name)
          if found and not pkg:is_installed() then
            missing[#missing + 1] = pkg
          end
        end

        if #missing == 0 then
          return
        end

        vim.notify(("mason: installing %d tool(s)"):format(#missing))
        for _, pkg in ipairs(missing) do
          pkg:install():once("closed", function()
            vim.schedule(function()
              if pkg:is_installed() then
                vim.notify("mason: installed " .. pkg.name)
              else
                vim.notify("mason: FAILED " .. pkg.name, vim.log.levels.ERROR)
              end
            end)
          end)
        end
      end)
    end)
  end,
})

-- ── mini.indentscope + mini.trailspace + mini.cursorword ─────────────────
-- Standalone repos from nvim-mini rather than the mini.nvim bundle, so only
-- these two modules are installed.
vim.pack.add({
  "https://github.com/nvim-mini/mini.indentscope",
  "https://github.com/nvim-mini/mini.trailspace",
  "https://github.com/nvim-mini/mini.cursorword",
  -- Strips trailing whitespace on save, but only from lines you actually
  -- edited -- it tracks those in a splay tree -- so saving a file that already
  -- had whitespace problems does not rewrite lines you never touched and fill
  -- the diff with noise. Plain vimscript; states Neovim 0.5+ support.
  "https://github.com/axelf4/vim-strip-trailing-whitespace",
})

require("mini.indentscope").setup({
  -- The default animation slides the guide into place on every cursor move,
  -- which reads as motion in the periphery while you type. `none` draws it
  -- immediately instead.
  draw = { animation = require("mini.indentscope").gen_animation.none() },
  symbol = "\u{2502}",  -- box-drawings light vertical
})

require("mini.trailspace").setup({})

-- Underlines other occurrences of the word under the cursor. The delay stops it
-- flickering as the cursor travels across a line.
require("mini.cursorword").setup({ delay = 250 })

-- Neither belongs in a UI buffer: an indent guide down the file tree, or
-- trailing-whitespace highlighting in a terminal, is just noise. Both modules
-- honour a buffer-local disable flag.
vim.api.nvim_create_autocmd("FileType", {
  desc = "Disable the mini modules in UI buffers",
  pattern = {
    "neo-tree", "help", "man", "lazy", "mason", "checkhealth",
    "qf", "fugitive", "gitcommit", "TelescopePrompt", "TelescopeResults",
    "neominimap",
  },
  callback = function(ev)
    vim.b[ev.buf].miniindentscope_disable = true
    vim.b[ev.buf].minitrailspace_disable = true
    vim.b[ev.buf].minicursorword_disable = true
  end,
})

-- Terminal buffers have no filetype, so the FileType hook above misses them.
vim.api.nvim_create_autocmd("TermOpen", {
  desc = "Disable these modules in terminals",
  callback = function(ev)
    vim.b[ev.buf].miniindentscope_disable = true
    vim.b[ev.buf].minitrailspace_disable = true
    vim.b[ev.buf].minicursorword_disable = true
  end,
})

-- The two whitespace plugins split the work: mini.trailspace highlights it so
-- it is visible, vim-strip-trailing-whitespace removes it on save. No :Trim
-- command here -- the latter provides :StripTrailingWhitespace for a whole-file
-- pass, which is the same job.
--
-- mini.trailspace also has trim_last_lines() for blank lines at end of file,
-- which the other plugin does not cover:
vim.api.nvim_create_user_command("TrimLastLines", function()
  require("mini.trailspace").trim_last_lines()
end, { desc = "Remove blank lines at end of file" })

vim.api.nvim_create_user_command("Q", "qa<bang>", { bang = true, desc = "Quit all (alias for :qa)" })

-- ── which-key.nvim ───────────────────────────────────────────────────────
-- Popup listing whatever keys can follow the prefix you just typed.
vim.pack.add({ "https://github.com/folke/which-key.nvim" })

require("which-key").setup({
  -- No per-mapping glyphs; the popup is a list of keys and descriptions.
  icons = { mappings = false },
})

-- Name the prefix groups; without this the popup just shows "+prefix".
-- Leaf keys pick up their label from the `desc` on each vim.keymap.set call.
require("which-key").add({
  { "<leader>a", group = "herdr-sidekick" },
  { "<leader>c", group = "code" },
  { "<leader>f", group = "find" },
  { "<leader>o", group = "obsidian" },
  { "<leader>q", group = "trouble lists" },
})

-- ── AI: herdr-sidekick ───────────────────────────────────────────────────
-- Replaces folke/sidekick.nvim + UN-9BOT/sidekick_herdr. Both embedded the
-- CLI tool in a Neovim `:terminal` (sidekick's default) or tried to patch in
-- a herdr backend against an API herdr no longer exposes (`herdr agent start`
-- used to accept --cwd and create its own pane; 0.9.0 requires an existing
-- --pane already at a shell prompt, plus --kind -- confirmed against the
-- installed herdr, not assumed). herdr-sidekick is a from-scratch replacement
-- that only ever talks to the current herdr CLI, so the agent is a first-class
-- herdr agent (visible to annotate, catchup, memex, herdr-topbar, `herdr
-- agent list`) from the moment it starts. See ~/dev/herdr-sidekick.
--
-- Local dev checkout, not vim.pack: the plugin has no GitHub remote yet.
-- Swap this for `vim.pack.add({ "https://github.com/<you>/herdr-sidekick" })`
-- once it has one.
vim.opt.rtp:prepend(vim.fn.expand("~/dev/herdr-sidekick"))

-- The current buffer is often a UI buffer, not a file -- e.g. the neo-tree
-- sidebar, if that's what was focused when the agent started. Falls back to
-- the most recently used real file buffer instead of reporting something
-- like "neo-tree filesystem [1]" as the open file.
---@return string?
local function herdr_sidekick_open_file()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
    return vim.api.nvim_buf_get_name(buf)
  end
  local best, best_time
  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if vim.bo[info.bufnr].buftype == "" and info.name ~= "" then
      if not best_time or info.lastused > best_time then
        best, best_time = info.name, info.lastused
      end
    end
  end
  return best
end

-- Built fresh each start (not a static string): the open-file line has to
-- reflect whatever buffer is current the moment the agent actually starts,
-- not whatever happened to be open when this config was loaded.
local function herdr_sidekick_orientation()
  local prompt = "You are running in a herdr pane opened from Neovim"
  local open_file = herdr_sidekick_open_file()
  if open_file then
    prompt = prompt .. " with open file: " .. vim.fn.fnamemodify(open_file, ":.")
  end
  return prompt
end

require("herdr-sidekick").setup({
  -- More than one entry means start_sidekick_agent_pane() with no explicit kind
  -- shows a vim.ui.select chooser instead of starting `claude` directly.
  -- `cmd` is extra CLI args for the kind's own canonical executable, not
  -- the binary name again -- `herdr agent start --kind claude` already
  -- runs `claude`.
  --
  -- Both tools' cmd sends the same orientation text, but through different
  -- mechanisms verified against each CLI (not assumed): claude's
  -- --append-system-prompt is documented; codex has no such flag, but `-c
  -- developer_instructions=...` was confirmed with `codex debug
  -- prompt-input` to land as its own role:"developer" message
  -- (generic.developer_instructions) ahead of the user's turn, same
  -- placement class as claude's flag. Both are invisible in the transcript
  -- and not a turn -- unlike a greeting pasted into the input box (tried and
  -- reverted: it just sat there needing to be cleared before typing).
  --
  -- json_encode produces a quoted, escaped string that's also valid TOML
  -- basic-string syntax, which is what `-c key=value` expects for a string
  -- value (see its own examples, e.g. `-c model="o3"`).
  tools = {
    claude = {
      cmd = function()
        -- --append-system-prompt-file, not --append-system-prompt: `herdr
        -- agent start` types the launch command into the pane's shell
        -- keystroke by keystroke, so the whole prompt text otherwise sits
        -- there wrapped across several lines of scrollback above the TUI,
        -- persisting after launch. A short file path keeps the typed line
        -- to one. Verified the flag is real (not guessed) by pointing it at
        -- a missing file and getting a file-not-found error rather than an
        -- unknown-option one.
        local path = vim.fn.tempname()
        vim.fn.writefile({ herdr_sidekick_orientation() }, path)
        return { "--append-system-prompt-file", path }
      end,
    },
    codex = {
      -- No file-based or env-var equivalent found (checked
      -- `developer_instructions_file` and a CODEX_DEVELOPER_INSTRUCTIONS
      -- env var against `codex debug prompt-input`; neither did anything),
      -- so this one unavoidably types out in full and wraps in scrollback.
      cmd = function()
        return { "-c", "developer_instructions=" .. vim.fn.json_encode(herdr_sidekick_orientation()) }
      end,
    },
  },
  -- Silently pre-assign the default sidekick agent at startup when there's
  -- an unambiguous one to pick (this pane's own tab, or failing that the
  -- workspace's first tab) -- see herdr-sidekick's own README for the exact
  -- rules. Otherwise unset until <leader>ad or the first <leader>ap/\an.
  auto_assign_default = true,
})

vim.keymap.set({ "n", "x" }, "<leader>ac", function()
  require("herdr-sidekick").start_sidekick_agent_pane({ kind = "claude" })
end, { desc = "Open Claude pane" })

vim.keymap.set({ "n", "x" }, "<leader>ax", function()
  require("herdr-sidekick").start_sidekick_agent_pane({ kind = "codex" })
end, { desc = "Open Codex pane" })

vim.keymap.set({ "n", "x" }, "<leader>aa", function()
  require("herdr-sidekick").start_sidekick_agent_pane()
end, { desc = "Open agent pane" })

vim.keymap.set({ "n", "x" }, "<leader>ap", function()
  require("herdr-sidekick").prompt()
end, { desc = "Prompt agent" })

vim.keymap.set("x", "<leader>as", function()
  require("herdr-sidekick").send_selection()
end, { desc = "Send selection reference to agent" })

vim.keymap.set("n", "<leader>as", function()
  require("herdr-sidekick").send()
end, { desc = "Send selection to agent" })

-- <leader>at, mirroring ap/as: sends to a *different* running herdr agent
-- instead of the one tied to this project (e.g. handing a selection to a
-- review session someone else has open). Sends directly when there is
-- exactly one other agent, otherwise shows a picker. herdr-sidekick focuses
-- the target automatically (no option needed here for it), but only when
-- it turns out to share this pane's tab -- which excludes most
-- send_to_agent() targets by its own default (exclude_self), but not
-- necessarily all of them.
vim.keymap.set("x", "<leader>at", function()
  require("herdr-sidekick").send_selection_to_agent()
end, { desc = "Send selection to other agent" })

vim.keymap.set("n", "<leader>at", function()
  require("herdr-sidekick").send_to_agent()
end, { desc = "Send selection to other agent" })

-- <leader>an: annotate the selection (or the cursor line with none) with a
-- short comment, without sending anything yet -- build up several of these
-- while reading through code, then batch-send them from <leader>al's list
-- view. <leader>al opens that list.
vim.keymap.set({ "n", "x" }, "<leader>an", function()
  require("herdr-sidekick").annotate()
end, { desc = "Annotate selection/line" })

vim.keymap.set("n", "<leader>al", function()
  require("herdr-sidekick").annotation_list()
end, { desc = "List annotations" })

-- <leader>ad: pin a specific running agent (any tab/workspace) as the one
-- send()/prompt()/annotate() target by default from now on, overriding the
-- normal "whichever agent is in this tab" lookup -- until it stops running,
-- at which point the picker comes back up automatically on the next send.
vim.keymap.set("n", "<leader>ad", function()
  require("herdr-sidekick").assign_default_agent()
end, { desc = "Assign default sidekick agent" })

-- ── Notes: obsidian.nvim ─────────────────────────────────────────────────
-- Writing and navigating the Obsidian vaults in iCloud without leaving nvim:
-- `[[` link completion, backlinks, vault-wide search through telescope, and
-- rename that rewrites every link pointing at the note.
--
-- obsidian-nvim/obsidian.nvim, not epwalsh/obsidian.nvim. The latter is the
-- original and is not archived, so it still turns up first in search results,
-- but it went unmaintained -- this is the community fork that took over.
--
-- The vaults live in the corporate iCloud Drive container, so the paths only
-- exist on a Mac signed in to that account. Building the workspace list from
-- the directories that are actually present means this whole block is skipped
-- elsewhere rather than erroring: setup() rejects an empty `workspaces`.
local obsidian_vaults = vim.fn.expand("~/Library/Mobile Documents/com~apple~icloud~applecorporate/Documents")
local obsidian_workspaces = {}

for _, name in ipairs({ "Obsidian", "Reviews" }) do
  local path = obsidian_vaults .. "/" .. name
  if vim.fn.isdirectory(path) == 1 then
    table.insert(obsidian_workspaces, { name = name:lower(), path = path })
  end
end

if #obsidian_workspaces > 0 then
  -- Pinned to 3.x. 4.0.0 removes `legacy_commands`, which is set below, and
  -- the 3.17.0 notes move the refactoring subcommands to LSP code actions --
  -- both would change the commands this section binds.
  vim.pack.add({
    { src = "https://github.com/obsidian-nvim/obsidian.nvim", version = vim.version.range("3") },
  })

  require("obsidian").setup({
    workspaces = obsidian_workspaces,

    -- The old one-command-per-action interface (:ObsidianSearch and friends),
    -- superseded by `:Obsidian <subcommand>`. Off so only the new form exists
    -- and 4.0.0 removing it is a no-op here.
    legacy_commands = false,

    -- Already installed and configured above, so pickers, tag lists and
    -- quick-switch all reuse it rather than pulling in a second finder.
    picker = { name = "telescope.nvim" },

    -- The default is `zettel_id`, which ignores what you type and names the
    -- file after os.time() plus four random letters -- the title survives only
    -- as a frontmatter alias. `title_id` uses the title instead: lowercased,
    -- punctuation stripped, spaces to hyphens, so "Rome July" becomes
    -- rome-july.md. It is called with the target directory as well, and walks
    -- rome-july-2, -3 and so on when the name is taken.
    note_id_func = require("obsidian.builtin").title_id,

    -- Off. The default writes an id/aliases/tags block into every new note,
    -- and nothing already in these vaults has frontmatter -- they are plain
    -- markdown. Inline #tags still work and are still what `:Obsidian tags`
    -- reads; this only stops the YAML header being added.
    frontmatter = { enabled = false },
  })

  -- Its extmarks conceal the markdown syntax around links and checkboxes, and
  -- conceal does nothing at the default conceallevel of 0 -- the plugin warns
  -- on startup if it is left there. Window-local on markdown rather than
  -- global: conceallevel applies to every filetype, and hiding syntax is only
  -- wanted in notes.
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    desc = "Let obsidian.nvim's conceal-based rendering take effect",
    callback = function()
      vim.opt_local.conceallevel = 2
    end,
  })

  -- `[[` link completion, `#` tags and `[^` footnotes are served by an
  -- in-process LSP the plugin starts in vault notes, named obsidian-ls. It
  -- advertises those as trigger characters, but something has to be listening:
  -- with no completion plugin in this config -- no nvim-cmp, no blink -- the
  -- triggers go nowhere and `[[` does nothing. vim.lsp.completion is Neovim's
  -- own client-side completion, so this needs no plugin.
  --
  -- Deliberately scoped to obsidian-ls by name rather than every client that
  -- supports completion: switching autotrigger on for ts_ls, yamlls, bashls and
  -- eslint would change how the editor behaves in every other filetype.
  vim.api.nvim_create_autocmd("LspAttach", {
    desc = "Autocomplete [[wiki links]] and #tags from obsidian-ls",
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client and client.name == "obsidian-ls" then
        vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })
      end
    end,
  })

  -- Inside a vault note the plugin also binds three buffer-local keys of its
  -- own: <CR> follows a link, toggles a checkbox or folds a heading depending
  -- on what is under the cursor, and ]o / [o jump between links. Set
  -- vim.g.obsidian_default_keymap = false to suppress them.
  local function obsidian(subcommand)
    return "<cmd>Obsidian " .. subcommand .. "<cr>"
  end

  vim.keymap.set("n", "<leader>oq", obsidian("quick_switch"), { desc = "Obsidian: quick switch note" })
  vim.keymap.set("n", "<leader>os", obsidian("search"),       { desc = "Obsidian: grep in vault" })
  vim.keymap.set("n", "<leader>ob", obsidian("backlinks"),    { desc = "Obsidian: backlinks to this note" })
  vim.keymap.set("n", "<leader>og", obsidian("tags"),         { desc = "Obsidian: browse tags" })
  vim.keymap.set("n", "<leader>oc", obsidian("toc"),          { desc = "Obsidian: table of contents" })
  vim.keymap.set("n", "<leader>on", obsidian("new"),          { desc = "Obsidian: new note" })
  vim.keymap.set("n", "<leader>ot", obsidian("today"),        { desc = "Obsidian: today's daily note" })
  vim.keymap.set("n", "<leader>or", obsidian("rename"),       { desc = "Obsidian: rename note, rewriting links" })

  -- Switches between the two vaults; with no argument it prompts.
  vim.keymap.set("n", "<leader>ow", obsidian("workspace"), { desc = "Obsidian: switch vault" })

  -- Hands the note to the Obsidian app, for the things that need it -- graph
  -- view, plugins, anything this plugin deliberately does not reimplement.
  vim.keymap.set("n", "<leader>oo", obsidian("open"), { desc = "Obsidian: open note in Obsidian.app" })
end
