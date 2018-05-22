set background=light
hi clear
syntax reset

let g:ale_sign_error = '●'
let g:ale_sign_warning = '●'
let g:colors_name = "test"

hi Normal           ctermfg=239 ctermbg=NONE cterm=NONE
hi LineNr           ctermfg=254 ctermbg=NONE cterm=NONE
hi TabLineFill      ctermfg=0 ctermbg=NONE cterm=NONE
hi TabLine          ctermfg=0 ctermbg=NONE cterm=NONE
hi TabLineSel       ctermfg=0 ctermbg=NONE cterm=NONE
hi NonText          ctermfg=255 ctermbg=NONE cterm=NONE
hi SpecialKey       ctermfg=NONE ctermbg=228 cterm=NONE
hi Search           ctermfg=0 ctermbg=222 cterm=NONE
hi TabLine          ctermfg=0 ctermbg=NONE cterm=NONE
hi StatusLine       ctermfg=238 ctermbg=254 cterm=NONE
hi StatusLineNC     ctermfg=238 ctermbg=255 cterm=NONE
hi VertSplit        ctermfg=0 ctermbg=NONE cterm=NONE
hi Visual           ctermfg=NONE ctermbg=228 cterm=NONE
hi Directory        ctermfg=0 ctermbg=NONE cterm=NONE
hi ModeMsg          ctermfg=0 ctermbg=NONE cterm=NONE
hi MoreMsg          ctermfg=0 ctermbg=NONE cterm=NONE
hi Question         ctermfg=0 ctermbg=NONE cterm=NONE
hi WarningMsg       ctermfg=0 ctermbg=NONE cterm=NONE
hi MatchParen       ctermfg=NONE ctermbg=228 cterm=NONE
hi Folded           ctermfg=0 ctermbg=NONE cterm=NONE
hi FoldColumn       ctermfg=0 ctermbg=NONE cterm=NONE
hi CursorLine       ctermfg=NONE ctermbg=255 cterm=NONE
hi CursorLineNr     ctermfg=242 ctermbg=255 cterm=NONE
hi CursorColumn     ctermfg=0 ctermbg=NONE cterm=NONE
hi PMenu            ctermfg=0 ctermbg=NONE cterm=NONE
hi PMenuSel         ctermfg=0 ctermbg=NONE cterm=NONE
hi SignColumn       ctermfg=0 ctermbg=NONE cterm=NONE
hi ColorColumn      ctermfg=0 ctermbg=NONE cterm=NONE
hi Comment          ctermfg=102 ctermbg=NONE cterm=NONE
hi Todo             ctermfg=0 ctermbg=NONE cterm=NONE
hi Title            ctermfg=0 ctermbg=NONE cterm=NONE
hi Identifier       ctermfg=167 ctermbg=NONE cterm=NONE
hi Statement        ctermfg=0 ctermbg=NONE cterm=NONE
hi Conditional      ctermfg=0 ctermbg=NONE cterm=NONE
hi Repeat           ctermfg=0 ctermbg=NONE cterm=NONE
hi Structure        ctermfg=0 ctermbg=NONE cterm=NONE
hi Function         ctermfg=167 ctermbg=NONE cterm=NONE
hi Constant         ctermfg=0 ctermbg=NONE cterm=NONE
hi String           ctermfg=31 ctermbg=NONE cterm=NONE
hi Special          ctermfg=59 ctermbg=NONE cterm=NONE
hi PreProc          ctermfg=0 ctermbg=NONE cterm=NONE
hi Operator         ctermfg=0 ctermbg=NONE cterm=NONE
hi Type             ctermfg=0 ctermbg=NONE cterm=NONE
hi Define           ctermfg=0 ctermbg=NONE cterm=NONE
hi Include          ctermfg=0 ctermbg=NONE cterm=NONE
hi Ignore           ctermfg=0 ctermbg=NONE cterm=NONE

" JavaScript Highlighting
hi javaScriptBraces       ctermfg=0 ctermbg=NONE cterm=NONE
hi javaScriptConditional  ctermfg=0 ctermbg=NONE cterm=NONE
hi javaScriptExceptions   ctermfg=0 ctermbg=NONE cterm=NONE
hi javaScriptFunctionKey  ctermfg=0 ctermbg=NONE cterm=NONE
hi javaScriptRepeat       ctermfg=0 ctermbg=NONE cterm=NONE
hi javaScriptNumber       ctermfg=215 ctermbg=NONE cterm=NONE
hi javaScriptMember       ctermfg=0 ctermbg=NONE cterm=NONE
hi javaScriptEndColons    ctermfg=239 ctermbg=NONE cterm=NONE

" Git Gutter Highlighting
hi GitGutterAdd           ctermfg=76 ctermbg=NONE cterm=NONE
hi GitGutterChange        ctermfg=33 ctermbg=NONE cterm=NONE
hi GitGutterDelete        ctermfg=160 ctermbg=NONE cterm=NONE
hi GitGutterChangeDelete  ctermfg=160 ctermbg=NONE cterm=NONE

hi ALEError               ctermfg=255 ctermbg=167 cterm=NONE
hi ALEWarning             ctermfg=255 ctermbg=167 cterm=NONE
hi ALEErrorSign           ctermfg=0 ctermbg=NONE cterm=NONE
hi ALEWarningSign         ctermfg=0 ctermbg=NONE cterm=NONE
