""" Section: This Stuff Should Stay at the Top
let g:mapleader = "\<Space>"

""" Section: General
set nrformats-=octal
set ttimeout ttimeoutlen=100
set updatetime=500
set scrolloff=10
set noswapfile

augroup ExtendIskeyword
  autocmd!
  " Extend iskeyword for filetypes that can reference CSS classes
  autocmd FileType
    \ css,scss,javascriptreact,typescriptreact,javascript,typescript,sass,postcss
    \ setlocal iskeyword+=-,?,!
  autocmd FileType vim setlocal iskeyword+=:,#
  autocmd FileType tmux setlocal iskeyword+=-
augroup END

inoremap jk <Esc>

" automatically go to the end of pasted text
vnoremap <silent> p p`]
nnoremap <silent> p p`]

" select the text that was just pasted
noremap gV `[v`]

" pasting doesn't replace clipboard
vnoremap p "_dP

""" Section: Line folding / splitting
" Prevents inserting two spaces after punctuation on a join (J)
set nojoinspaces
" Delete comment character when joining commented lines
set formatoptions+=j

""" Section: Motions / Text Objects
set matchpairs+=<:>
" move ten lines at a time by holding ctrl and a directional key
noremap <C-j> 10j
noremap <C-k> 10k
nnoremap Y yg_

" Using the paragraph motions won't add to the jump stack
nnoremap } <Cmd>keepjumps normal! }<CR>
nnoremap { <Cmd>keepjumps normal! {<CR>

""" Section: Search
" searching is only case sensitive when the query contains an uppercase letter
set ignorecase smartcase
" Use ripgrep as the grep program, if it's available. Otherwise use the internal
" grep implementation since it's cross-platform
let &grepprg = executable('rg') ? 'rg --vimgrep --smart-case --follow' : 'internal'

" Search for selected text, forwards or backwards.
vnoremap <silent> * :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy/<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gVzv:call setreg('"', old_reg, old_regtype)<CR>
vnoremap <silent> # :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy?<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(
  \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gVzv:call setreg('"', old_reg, old_regtype)<CR>

" Combine enter key (<CR>) mappings from the delimitmate and vim-endwise plugins.
" Also, if the popupmenu is visible, but no items are selected, close the
" popup and insert a newline.
imap <expr> <CR>
  \ pumvisible() ?
    \ (complete_info().selected == -1 ? '<C-y><CR>' : '<C-y>') :
    \ delimitMate#WithinEmptyPair() ?
      \ "\<C-R>=delimitMate#ExpandReturn()\<CR>" :
      \ "\<CR>\<Plug>DiscretionaryEnd"

" Plugins
""""""""""""""""""""""""""""""""""""""""
" Install vim-plug if not found
let data_dir = has('nvim') ? stdpath('data') . '/site' : $HOME.'/.vim'
let vim_plug_plugin_file = data_dir . '/autoload/plug.vim'
if empty(glob(vim_plug_plugin_file))
  silent execute '!curl -fLo '.vim_plug_plugin_file.' --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

" Start vim-plug
call plug#begin()

" Set vim-plug to end at VimEnter. By running this at VimEnter, I am able to add plugins in my other config files as well.
" Since some plugins, like vim-lsp, have autocmds for VimEnter, I fire VimEnter again after loading plugins.
" To prevent infinitely firing VimEnter, I use '++once'. Downside to this is that anything that runs at VimEnter
" needs to be idempotent because it might get run twice since VimEnter gets fired twice now.
augroup VimPlug
  autocmd!
  autocmd VimEnter * ++nested ++once call plug#end() | doautocmd VimEnter
augroup END

" To get the vim help pages for vim-plug itself, you need to add it as a plugin
Plug 'junegunn/vim-plug'

" Syntax plugins for practically any language
Plug 'sheerun/vim-polyglot'

" Motions for levels of indentation
Plug 'jeetsukumaran/vim-indentwise'
  map [<Tab> <Plug>(IndentWiseBlockScopeBoundaryBegin)
  map ]<Tab> <Plug>(IndentWiseBlockScopeBoundaryEnd)

" replacement for matchit since matchit wasn't working for me
Plug 'andymass/vim-matchup'
  " Don't display offscreen matches in my statusline or a popup window
  let g:matchup_matchparen_offscreen = {}

" Additional text objects and motions
Plug 'wellle/targets.vim'

" Determine the filetype based on the interpreter specified in a shebang
Plug 'vitalk/vim-shebang'

Plug 'bkad/CamelCaseMotion'
  let g:camelcasemotion_key = ','

" Automatically add closing keywords (e.g. function/endfunction in vimscript)
Plug 'tpope/vim-endwise'
  let g:endwise_no_mappings = 1
  " this way endwise triggers on 'o'
  nmap o A<CR>

" Automatically close html tags
Plug 'alvan/vim-closetag'

" Automatically insert closing braces/quotes
Plug 'Raimondi/delimitMate'
  " Given the following line (where | represents the cursor):
  "   function foo(bar) {|}
  " Pressing enter will result in:
  " function foo(bar) {
  "   |
  " }
  let g:delimitMate_expand_cr = 0

" Makes it easier to manipulate brace/bracket/quote pairs by providing commands to do common
" operations like change pair, remove pair, etc.
Plug 'tpope/vim-surround'

" For swapping two pieces of text
Plug 'tommcdo/vim-exchange'

" Commands/mappings for working with variants of words:
" - A command for performing substitutions. More features than vim's builtin :substitution
" - A command for creating abbreviations. More features than vim's builtin :iabbrev
" - Mappings for case switching e.g. mixed-case, title-case, etc.
Plug 'tpope/vim-abolish'
  " TODO: Using this so that substitutions made by vim-abolish get highlighted as I type them.
  " Won't be necessary if vim-abolish adds support for neovim's `inccommand`.
  " issue for `inccommand` support: https://github.com/tpope/vim-abolish/issues/107
  Plug 'markonm/traces.vim'
    let g:traces_abolish_integration = 1

Plug 'airblade/vim-matchquote'

Plug 'tpope/vim-commentary'
