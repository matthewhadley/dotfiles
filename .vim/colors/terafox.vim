" terafox for Vim
"
" A hand-written port of terafox from nightfox.nvim, which is Lua and so
" cannot be loaded by Vim. Colours are taken verbatim from
" lua/nightfox/palette/terafox.lua; the blended diff and message backgrounds
" are computed with the same linear RGB interpolation nightfox uses
" (Color:blend -- (other - self) * f + self), so this matches what Neovim
" renders rather than approximating it.
"
" Palette
"   bg0  #0f1c1e  status line, floats      fg0  #eaeeee  lighter fg
"   bg1  #152528  default bg               fg1  #e6eaea  default fg
"   bg2  #1d3337  colorcolumn, folds       fg2  #cbd9d8  status line fg
"   bg3  #254147  cursor line              fg3  #587b7b  line numbers
"   bg4  #2d4f56  conceal, borders         sel0 #293e40  visual selection
"                                          sel1 #425e5e  search
"
" Requires a true-colour terminal (`set termguicolors`). No cterm *colours* are
" defined -- the palette has no sensible 256-colour equivalent, and every
" terminal in use here does 24-bit. cterm *attributes* are defined though, and
" have to be: with termguicolors Vim takes colours from gui* but bold, italic
" and underline from cterm=, so gui= alone is inert in a terminal. Groups that
" would otherwise inherit an attribute from Vim's defaults -- CursorLine comes
" with cterm=underline -- clear it with an explicit cterm=NONE.

hi clear
if exists("syntax_on")
  syntax reset
endif

set background=dark
let g:colors_name = "terafox"

" ── Editor ───────────────────────────────────────────────────────────────
hi Normal        guifg=#e6eaea guibg=#152528 gui=NONE cterm=NONE
hi NormalFloat   guifg=#e6eaea guibg=#0f1c1e gui=NONE cterm=NONE
hi FloatBorder   guifg=#2d4f56 guibg=#0f1c1e gui=NONE cterm=NONE
hi Cursor        guifg=#152528 guibg=#e6eaea gui=NONE cterm=NONE
hi CursorLine    guibg=#254147 gui=NONE cterm=NONE
hi CursorColumn  guibg=#254147 gui=NONE cterm=NONE
hi ColorColumn   guibg=#1d3337 gui=NONE cterm=NONE
hi LineNr        guifg=#587b7b gui=NONE cterm=NONE
hi CursorLineNr  guifg=#fda47f gui=bold cterm=bold
hi SignColumn    guibg=#152528 gui=NONE cterm=NONE
hi VertSplit     guifg=#1d3337 guibg=#152528 gui=NONE cterm=NONE
hi Folded        guifg=#6d7f8b guibg=#1d3337 gui=NONE cterm=NONE
hi FoldColumn    guifg=#587b7b guibg=#152528 gui=NONE cterm=NONE
hi Conceal       guifg=#2d4f56 gui=NONE cterm=NONE
hi NonText       guifg=#4e5157 gui=NONE cterm=NONE
hi SpecialKey    guifg=#4e5157 gui=NONE cterm=NONE
hi Whitespace    guifg=#2d4f56 gui=NONE cterm=NONE
hi MatchParen    guifg=#ff8349 guibg=#425e5e gui=bold cterm=bold
" guifg=NONE on the selections: Vim's default Visual sets guifg=LightGrey,
" which would flatten selected text to grey instead of letting the syntax
" colours show through the background.
hi Visual        guifg=NONE guibg=#293e40 gui=NONE cterm=NONE
hi VisualNOS     guifg=NONE guibg=#293e40 gui=NONE cterm=NONE
hi Search        guifg=#e6eaea guibg=#425e5e gui=NONE cterm=NONE
hi IncSearch     guifg=#152528 guibg=#fda47f gui=NONE cterm=NONE
hi CurSearch     guifg=#152528 guibg=#fda47f gui=NONE cterm=NONE
hi Directory     guifg=#5a93aa gui=NONE cterm=NONE
hi Title         guifg=#73a3b7 gui=bold cterm=bold
hi Underlined    guifg=#5a93aa gui=underline cterm=underline
hi Ignore        guifg=#4e5157 gui=NONE cterm=NONE
hi QuickFixLine  guibg=#293e40 gui=NONE cterm=NONE

" ── Chrome ───────────────────────────────────────────────────────────────
hi StatusLine    guifg=#cbd9d8 guibg=#0f1c1e gui=NONE cterm=NONE
hi StatusLineNC  guifg=#587b7b guibg=#0f1c1e gui=NONE cterm=NONE
hi TabLine       guifg=#587b7b guibg=#0f1c1e gui=NONE cterm=NONE
hi TabLineFill   guibg=#0f1c1e gui=NONE cterm=NONE
hi TabLineSel    guifg=#e6eaea guibg=#254147 gui=NONE cterm=NONE
hi WildMenu      guifg=#152528 guibg=#5a93aa gui=NONE cterm=NONE
hi Pmenu         guifg=#e6eaea guibg=#293e40 gui=NONE cterm=NONE
hi PmenuSel      guifg=#e6eaea guibg=#425e5e gui=NONE cterm=NONE
hi PmenuSbar     guibg=#1d3337 gui=NONE cterm=NONE
hi PmenuThumb    guibg=#425e5e gui=NONE cterm=NONE

" ── Messages ─────────────────────────────────────────────────────────────
hi ErrorMsg      guifg=#e85c51 gui=NONE cterm=NONE
hi WarningMsg    guifg=#fda47f gui=NONE cterm=NONE
hi ModeMsg       guifg=#cbd9d8 gui=NONE cterm=NONE
hi MoreMsg       guifg=#7aa4a1 gui=NONE cterm=NONE
hi Question      guifg=#7aa4a1 gui=NONE cterm=NONE
hi Error         guifg=#e85c51 guibg=#352d2e gui=NONE cterm=NONE
hi Todo          guifg=#152528 guibg=#fda47f gui=bold cterm=bold

" ── Syntax ───────────────────────────────────────────────────────────────
" Roles follow nightfox's spec.syntax table rather than being invented, so a
" file looks the same here as it does in Neovim.
hi Comment       guifg=#6d7f8b gui=italic cterm=italic
hi Constant      guifg=#ff9664 gui=NONE cterm=NONE
hi String        guifg=#7aa4a1 gui=NONE cterm=NONE
hi Character     guifg=#7aa4a1 gui=NONE cterm=NONE
hi Number        guifg=#ff8349 gui=NONE cterm=NONE
hi Boolean       guifg=#ff9664 gui=NONE cterm=NONE
hi Float         guifg=#ff8349 gui=NONE cterm=NONE
hi Identifier    guifg=#a1cdd8 gui=NONE cterm=NONE
hi Function      guifg=#73a3b7 gui=NONE cterm=NONE
hi Statement     guifg=#ad5c7c gui=NONE cterm=NONE
hi Conditional   guifg=#b97490 gui=NONE cterm=NONE
hi Repeat        guifg=#b97490 gui=NONE cterm=NONE
hi Label         guifg=#ad5c7c gui=NONE cterm=NONE
hi Operator      guifg=#cbd9d8 gui=NONE cterm=NONE
hi Keyword       guifg=#ad5c7c gui=NONE cterm=NONE
hi Exception     guifg=#b97490 gui=NONE cterm=NONE
hi PreProc       guifg=#d38d97 gui=NONE cterm=NONE
hi Include       guifg=#ff9664 gui=NONE cterm=NONE
hi Define        guifg=#d38d97 gui=NONE cterm=NONE
hi Macro         guifg=#d38d97 gui=NONE cterm=NONE
hi PreCondit     guifg=#d38d97 gui=NONE cterm=NONE
hi Type          guifg=#fda47f gui=NONE cterm=NONE
hi StorageClass  guifg=#fda47f gui=NONE cterm=NONE
hi Structure     guifg=#fda47f gui=NONE cterm=NONE
hi Typedef       guifg=#fda47f gui=NONE cterm=NONE
hi Special       guifg=#ff8349 gui=NONE cterm=NONE
hi SpecialChar   guifg=#ff8349 gui=NONE cterm=NONE
hi Delimiter     guifg=#cbd9d8 gui=NONE cterm=NONE
hi SpecialComment guifg=#a1cdd8 gui=NONE cterm=NONE
hi Tag           guifg=#5a93aa gui=NONE cterm=NONE
hi Debug         guifg=#e85c51 gui=NONE cterm=NONE

" ── Diff ─────────────────────────────────────────────────────────────────
" These matter most in `vimdiff` / `git mergetool`, where the whole screen is
" diff. Backgrounds only, so the syntax colours above still read through.
hi DiffAdd       guibg=#293e40 gui=NONE cterm=NONE
hi DiffDelete    guibg=#4a3332 gui=NONE cterm=NONE
hi DiffChange    guibg=#31474b gui=NONE cterm=NONE
hi DiffText      guibg=#466066 gui=NONE cterm=NONE
hi diffAdded     guifg=#7aa4a1 gui=NONE cterm=NONE
hi diffRemoved   guifg=#e85c51 gui=NONE cterm=NONE
hi diffChanged   guifg=#fda47f gui=NONE cterm=NONE
hi diffFile      guifg=#73a3b7 gui=bold cterm=bold
hi diffLine      guifg=#6d7f8b gui=NONE cterm=NONE

" ── Spelling ─────────────────────────────────────────────────────────────
hi SpellBad      guisp=#e85c51 gui=undercurl cterm=undercurl
hi SpellCap      guisp=#fda47f gui=undercurl cterm=undercurl
hi SpellRare     guisp=#ad5c7c gui=undercurl cterm=undercurl
hi SpellLocal    guisp=#5a93aa gui=undercurl cterm=undercurl
