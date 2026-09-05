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

-- Window navigation: <C-h/j/k/l>. Plain Ctrl+letter is a single ASCII control
-- byte, so it survives Ghostty -> Herdr -> nvim. Both Cmd+Shift+arrow and
-- Ctrl+arrow were tried first and neither reaches nvim at all (verified with
-- Ctrl-V literal-insert: nothing arrives) -- the multiplexer eats modified
-- special keys. This also matches sidekick's own terminal nav keys.
-- Insert mode is deliberately NOT mapped: <C-h> is byte 0x08, the same as
-- Backspace in many terminals, so mapping it there would break backspace.
-- Universal fallbacks that always work: <C-w>hjkl, or <C-w> then an arrow.
for lhs, dir in pairs({ ["<C-h>"] = "h", ["<C-j>"] = "j", ["<C-k>"] = "k", ["<C-l>"] = "l" }) do
  vim.keymap.set({ "n", "x" }, lhs, "<C-w>" .. dir, { desc = "Window: move " .. dir })
end
-- Inside the Claude pane, sidekick maps its own <C-h> (nav left), <C-z> (blur),
-- <C-.> (hide) and <C-q> (normal mode) -- no terminal-mode mapping needed here.

-- Mouse drag-select copies to the system clipboard, matching what Ghostty and
-- Herdr do on their own. Needed because mouse=a makes nvim capture the drag,
-- so the terminal never sees a selection of its own to auto-copy.
-- `"+ygv`, not just `"+y`: yanking exits visual mode and drops the cursor at
-- the start of the range, so `gv` puts the highlight straight back.
vim.keymap.set("x", "<LeftRelease>", '"+ygv', { desc = "Copy mouse selection to clipboard, keep selection" })

-- Comment toggling. `gcc` (line) and `gc` (motion/visual) are built into
-- Neovim 0.10+, no plugin needed -- these are just editor-style aliases.
-- remap = true is required: gcc is itself an expr mapping, so a non-recursive
-- map would send the literal keys and do nothing.
-- <D-/> is Cmd+/ and only fires if the terminal forwards the Super modifier.
-- <C-_> is what most terminals actually send for Ctrl+/, kept as a fallback.
for _, lhs in ipairs({ "<D-/>", "<C-/>", "<C-_>" }) do
  vim.keymap.set("n", lhs, "gcc", { remap = true, desc = "Toggle comment" })
  -- `gcgv`, not just `gc`: the operator drops you into normal mode at the top
  -- of the range, so `gv` reselects the same area and the block stays
  -- highlighted for toggling back and forth.
  vim.keymap.set("x", lhs, "gcgv", { remap = true, desc = "Toggle comment, keep selection" })
  vim.keymap.set("i", lhs, "<Esc>gccgi", { remap = true, desc = "Toggle comment" })
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

-- Stock defaults apart from two things: ASCII folder symbols (no Nerd Font on
-- this machine, so the default glyphs render as blanks/boxes) and arrow keys
-- for expand/collapse.
require("neo-tree").setup({
  -- The defaults plus a custom source in lua/neotree_dotfiles.lua, which
  -- renders the bare dotfiles repo's tracked files as a tree. neo-tree
  -- resolves an unrecognised name with a plain require(), so any module on the
  -- runtimepath works. Listing the defaults is required -- naming sources at
  -- all replaces the list rather than adding to it.
  sources = { "filesystem", "buffers", "git_status", "neotree_dotfiles" },
  close_if_last_window = true,   -- don't leave a lone tree holding nvim open
  popup_border_style = "single", -- "rounded" needs glyphs some terminals lack
  enable_git_status = true,
  enable_diagnostics = true,

  default_component_configs = {
    -- ASCII throughout: no Nerd Font on this machine, so glyphs would be tofu.
    indent = {
      with_expanders = false,   -- folder icon alone shows state; avoids "+ + name"
    },
    icon = {
      folder_closed = "+", folder_open = "-", folder_empty = " ",
      default = " ", highlight = "NeoTreeFileIcon",
      -- Passthrough provider. neo-tree's default provider pulls filetype
      -- glyphs from nvim-web-devicons. That plugin is no longer installed, but
      -- this keeps the plain icons above if anything ever reinstalls it as a
      -- transitive dependency.
      provider = function(icon)
        return icon
      end,
    },
    git_status = {
      symbols = {
        added = "A", modified = "M", deleted = "D", renamed = "R",
        untracked = "?", ignored = "", unstaged = "U", staged = "S", conflict = "C",
      },
    },
  },

  window = {
    width = 32,
    mappings = {
      -- <cr> toggles a directory, so it can't double as "expand": <Right> on an
      -- open directory would collapse it. Hence the guard.
      -- Use `open`, not `toggle_directory`: the filesystem source wraps `open`
      -- with the scan callback, the bare common `toggle_directory` no-ops.
      ["<Right>"] = function(state)
        local node = state.tree:get_node()
        if node.type == "directory" and node:is_expanded() then return end
        require("neo-tree.sources.filesystem.commands").open(state)
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
      ["<LeftRelease>"] = "open",
    },
  },

  filesystem = {
    hijack_netrw_behavior = "disabled",  -- nothing auto-opens at startup
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
vim.keymap.set("n", "<leader>f", "<cmd>Neotree reveal<CR>", { desc = "Reveal current file in tree" })
-- Startup layout: `nvim +Neotree` (do NOT pass a directory).
--
-- The dotfiles tree has no keymap: it is a whole-session mode rather than
-- something to flip to mid-edit, so `dotfiles nvim` launches it instead. The
-- source lives in lua/neotree_dotfiles.lua and is still reachable in-session
-- with :Neotree dotfiles left.

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
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = normal.bg, bg = normal.bg })

  -- terafox renders git additions in a muted teal-green (#7AA4A1) that is hard
  -- to tell from its change colour at a glance. Both the gutter sign and the
  -- minimap sign are set, so the two stay consistent -- the minimap group
  -- otherwise inherits from gitsigns.
  for _, group in ipairs({ "GitSignsAdd", "NeominimapGitAddSign" }) do
    vim.api.nvim_set_hl(0, group, { fg = "#6EC47C" })
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

-- ── Fuzzy finder: telescope.nvim ─────────────────────────────────────────
-- plenary.nvim is a hard dependency but is already installed above as a
-- neo-tree dep, so it isn't repeated here. Uses ripgrep for live_grep and fd
-- for find_files; both are on PATH.
vim.pack.add({ "https://github.com/nvim-telescope/telescope.nvim" })
require("telescope").setup()

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope: find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep,  { desc = "Telescope: grep in project" })
vim.keymap.set("n", "<leader>fb", builtin.buffers,    { desc = "Telescope: open buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags,  { desc = "Telescope: help tags" })
vim.keymap.set("n", "<leader>fr", builtin.resume,     { desc = "Telescope: resume last picker" })

-- ── Statusline: lualine.nvim ─────────────────────────────────────────────
-- No nvim-web-devicons: it was only ever pulled in for filetype glyphs, which
-- are disabled in both lualine and neo-tree. Both plugins pcall-require it, so
-- its absence is handled cleanly. The branch icon and powerline separators
-- below come from Ghostty's built-in font, not from devicons.
vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })

require("lualine").setup({
  options = {
    -- nightfox ships a matching lualine theme, so "auto" resolves to terafox.
    theme = "auto",
    globalstatus = true,   -- one bar for the whole editor, not one per window
    disabled_filetypes = {
      statusline = { "neo-tree", "toggleterm" },
    },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },   -- both read gitsigns' status dict
    lualine_c = { { "filename", path = 1 } },
    -- icons_enabled = false only on this component: kills the devicons
    -- filetype glyph while keeping the branch icon and powerline separators.
    lualine_x = { { "filetype", icons_enabled = false } },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  extensions = { "neo-tree", "toggleterm", "fugitive" },
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
    -- nvim-web-devicons is not installed, so no filetype glyphs.
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

-- ── toggleterm.nvim ──────────────────────────────────────────────────────
-- Toggleable terminal windows. Separate from sidekick's Claude pane: that one
-- runs a specific tool, this is for a general shell.
vim.pack.add({ "https://github.com/akinsho/toggleterm.nvim" })

require("toggleterm").setup({
  open_mapping = [[<c-\>]],  -- toggle from normal or terminal mode
  direction = "horizontal",
  size = 15,
  -- Esc leaves terminal-insert mode so <C-h/j/k/l> window nav works from here.
  -- Without this, Esc goes to the shell instead.
  terminal_mappings = true,

  -- Blank the statusline in terminal windows. By default it renders %f, which
  -- for a terminal buffer is the full "term://...//204:/bin/zsh;#toggleterm#1"
  -- path. 'laststatus' is a global option so the bar itself can't be hidden
  -- per-window -- but its contents can be, which is what this does.
  on_open = function()
    vim.wo.statusline = " "
  end,
})

-- <leader>t as an alternative to <C-\>. Note leader mappings only work in
-- normal/visual mode -- inside the terminal, \t would be typed into the shell.
-- Keep <C-\> for toggling back out from terminal-insert mode.
vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm<CR>", { desc = "Toggle terminal" })

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
  auto_enable = true,
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
require("nvim-treesitter").install({
  "bash", "css", "diff", "dockerfile", "gitcommit", "html",
  "javascript", "json", "lua", "markdown", "markdown_inline",
  "query", "regex", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
})

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
  },
})

-- <leader>ca applies eslint's fixes (and any other code action) at the cursor.
vim.keymap.set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })

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
  -- formatters
  "prettierd",
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
    "neo-tree", "toggleterm", "help", "man", "lazy", "mason", "checkhealth",
    "qf", "fugitive", "gitcommit", "TelescopePrompt", "TelescopeResults",
    "neominimap", "sidekick_terminal",
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

-- ── which-key.nvim ───────────────────────────────────────────────────────
-- Popup listing whatever keys can follow the prefix you just typed.
vim.pack.add({ "https://github.com/folke/which-key.nvim" })

require("which-key").setup({
  -- No Nerd Font on this machine, so per-mapping icons would render as tofu.
  -- The separator/group symbols it uses are plain Unicode and render fine.
  icons = { mappings = false },
})

-- Name the prefix groups; without this the popup just shows "+prefix".
-- Leaf keys pick up their label from the `desc` on each vim.keymap.set call.
require("which-key").add({
  { "<leader>a", group = "AI / sidekick" },
  { "<leader>as", group = "summarise" },
  { "<leader>f", group = "find" },
})

-- ── AI: sidekick.nvim ────────────────────────────────────────────────────
vim.pack.add({ "https://github.com/folke/sidekick.nvim" })

require("sidekick").setup({
  -- Next Edit Suggestions are off: they require the copilot-language-server
  -- LSP, which isn't installed. The CLI terminal below is independent of it.
  nes = { enabled = false },

  cli = {
    prompts = {
      -- Added to sidekick's built-ins (explain, review, fix, tests...), all
      -- pickable with <leader>ap.
      --
      -- A prompt may be a function of the context. {file} expands to a bare
      -- reference (`@path`); {line} adds the selected range (`@path :L3-L20`).
      -- Both are references Claude resolves by reading the file itself, so
      -- neither pastes the buffer into the prompt -- which is what you want:
      -- pasting spends tokens on the whole file up front, and a reference lets
      -- Claude read only the parts it needs.
      --
      -- {selection} is the option that *does* inline the text verbatim. It is
      -- deliberately not used here; the only case it wins is asking about
      -- unsaved edits, since a reference reads what is on disk.
      summarize = function(ctx)
        return ctx.range and "Summarise {line}" or "Summarise {file}"
      end,
    },
    context = {
      -- Why not just use the built-in {diagnostics}: when a buffer is clean it
      -- resolves to nothing, and sidekick treats an empty replacement as a
      -- failed render -- it drops the whole message and reports "Nothing to
      -- send". Fine for the dedicated `diagnostics` prompt (you only pick it
      -- when there are errors), fatal for a general-purpose "ask about this
      -- file" prompt. This variant always yields a line, so it is safe to
      -- include unconditionally.
      diags = function(ctx)
        local diags = require("sidekick.cli.context.diagnostics").get(ctx)
        if not diags or vim.tbl_isempty(diags) then
          return "No diagnostics reported for this file."
        end
        return diags
      end,
    },
  },
})

-- Ask the attached AI CLI about the file you are looking at, in free text.
--
-- Agent-agnostic on purpose: `cli.send` routes to whichever tool is currently
-- attached (Claude, Codex, or any other sidekick tool) and applies that tool's
-- own reference formatting -- claude.lua rewrites `:L1-L9` to `#L1-9`, codex
-- takes the plain form. Nothing here needs to know which is running.
--
-- Sidekick sends *references* (`@path/to/file :L12:C5`), not buffer contents,
-- and the agent reads the file from disk -- so an unwritten change is invisible
-- to it. Writing first is what makes "review this" mean what is on screen. It is
-- cheaper than inlining the buffer, and it keeps the agent's own file reads
-- authoritative.
--
-- Diagnostics need no such help: nvim-lint above runs on TextChanged/InsertLeave
-- and LSP servers see the live buffer, so vim.diagnostic is already current for
-- unsaved text.
local function sidekick_ask()
  local Context = require("sidekick.cli.context")

  -- Snapshot context BEFORE opening the input box. sidekick picks its target
  -- window by most-recently-visited, so the input float would otherwise become
  -- "the file you are looking at" and the reference would point at nothing.
  local context = Context.get()
  local buf = context.ctx.buf

  if
    vim.bo[buf].modified
    and vim.bo[buf].buftype == ""
    and vim.bo[buf].modifiable
    and vim.api.nvim_buf_get_name(buf) ~= ""
  then
    vim.api.nvim_buf_call(buf, function()
      -- A plain write, not `noautocmd`: this should behave exactly as if you
      -- had pressed :w, so BufWritePre hooks (vim-strip-trailing-whitespace)
      -- still run and the file the agent reads is the file you would have saved.
      vim.cmd("silent write")
    end)
  end

  -- Name the attached tool in the prompt when there is one, so it is obvious
  -- whether this is going to Claude or Codex. Falls back to a neutral label:
  -- send() will attach (and may show a picker) if nothing is running yet.
  local attached = require("sidekick.cli.state").get({ attached = true })[1]
  local label = attached and attached.tool and attached.tool.name or "agent"

  vim.ui.input({ prompt = "Ask " .. label .. ": " }, function(input)
    if not input or input:match("^%s*$") then
      return
    end
    -- {this} becomes {position} in a real file and falls back to {selection}
    -- elsewhere; {diags} is the always-renders wrapper defined in setup above.
    local _, text = context:render({ msg = input .. "\n\n{this}\n{diags}" })
    if text then
      require("sidekick.cli").send({ text = text })
    end
  end)
end

-- `claude` is one of sidekick's built-in tools, so no cmd config is needed --
-- it runs the claude binary already on your PATH in a scratch terminal.
vim.keymap.set({ "n", "x" }, "<leader>ac", function()
  require("sidekick.cli").toggle({ name = "claude", focus = true })
end, { desc = "Sidekick: toggle Claude" })

vim.keymap.set({ "n", "x" }, "<leader>ax", function()
  require("sidekick.cli").toggle({ name = "codex", focus = true })
end, { desc = "Sidekick: toggle Codex" })

vim.keymap.set({ "n", "x" }, "<leader>aa", function()
  require("sidekick.cli").select()
end, { desc = "Sidekick: pick a CLI tool" })

vim.keymap.set({ "n", "x" }, "<leader>ap", function()
  require("sidekick.cli").prompt()
end, { desc = "Sidekick: send a prompt (with buffer context)" })

-- <leader>as is a group rather than a mapping: the trailing letter picks the
-- tool, matching <leader>ac / <leader>ax above. Both send unsubmitted, so the
-- prompt lands in the tool's input for you to edit or confirm with <CR> --
-- worth having when the message is a bare reference and you often want to add
-- "...focusing on X". focus = true puts the cursor there to do it.
local function sidekick_summarize(name)
  return function()
    require("sidekick.cli").send({
      name = name,
      prompt = "summarize",
      submit = false,
      focus = true,
    })
  end
end

vim.keymap.set({ "n", "x" }, "<leader>asc", sidekick_summarize("claude"),
  { desc = "Sidekick: summarise -- Claude" })

vim.keymap.set({ "n", "x" }, "<leader>asx", sidekick_summarize("codex"),
  { desc = "Sidekick: summarise -- Codex" })

vim.keymap.set({ "n", "x" }, "<leader>ai", sidekick_ask,
  { desc = "Sidekick: ask about this file (saves first, adds diagnostics)" })
