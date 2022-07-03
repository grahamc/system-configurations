" vim:foldmethod=marker

" This should stay at the top so all mappings can reference it
let g:mapleader = "\<Space>"

" This should stay at the top so that I can register plugins anywhere in my config
" Install vim-plug if not found
let data_dir = has('nvim') ? stdpath('data') . '/site' : $HOME.'/.vim'
let vim_plug_plugin_file = data_dir . '/autoload/plug.vim'
if empty(glob(vim_plug_plugin_file))
  silent execute '!curl -fLo '.vim_plug_plugin_file.' --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif
call plug#begin()

" Miscellaneous {{{1
set nrformats-=octal
set ttimeout ttimeoutlen=100
set updatetime=500
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

" automatically go to the end of pasted text and reindent it
vnoremap <silent> p p=`]
nnoremap <silent> p p=`]

" select the text that was just pasted
noremap gV `[v`]

" pasting doesn't replace clipboard
vnoremap p "_dP

" Prevents inserting two spaces after punctuation on a join (J)
set nojoinspaces
" Delete comment character when joining commented lines
set formatoptions+=j

set matchpairs+=<:>
" move ten lines at a time by holding ctrl and a directional key
noremap <C-j> 10j
noremap <C-k> 10k

" Copy up to the end of line, not including the newline character
nnoremap Y yg_

" Using the paragraph motions won't add to the jump stack
nnoremap } <Cmd>keepjumps normal! }<CR>
nnoremap { <Cmd>keepjumps normal! {<CR>

" There are a number of actions that could be performed when the enter key is pressed.
" This function decides which ones.
function! GetEnterKeyActions()
  if pumvisible()
    " close the popup menu
    let keys = "\<C-y>"

    " If there was no item selected, enter a newline
    if complete_info().selected == -1
      let keys .= "\<CR>"
    endif

    return keys
  endif

  " The existence check ensures that the plugin delimitmate was loaded
  if exists('*delimitMate#WithinEmptyPair') && delimitMate#WithinEmptyPair()
    return "\<C-R>=delimitMate#ExpandReturn()\<CR>"
  endif

  " The existence check ensures that the plugin vim-endwise was loaded
  if exists('g:loaded_endwise')
    return "\<CR>\<Plug>DiscretionaryEnd"
  endif

  return "\<CR>"
endfunction
imap <expr> <CR> GetEnterKeyActions()

" Searching {{{1
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

" Plugins {{{1
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

Plug 'airblade/vim-matchquote'

" Profiles {{{1
let profile_directory = expand('<sfile>:h') . '/profiles' 
if isdirectory(profile_directory)
  let profiles = split(globpath(profile_directory, '*'), '\n')
  for profile in profiles
    execute 'source ' . profile
  endfor
endif
" }}}

" This should stay at the bottom so that I can register plugins anywhere in my config
call plug#end()
