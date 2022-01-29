set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
""" Section: Plugins
"""" Plugin Manager Settings
" Install vim-plug if not found
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
" Install plugins if not found
function! InstallMissingPlugins()
  let l:has_missing_plugins = len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  if l:has_missing_plugins
    PlugInstall --sync
  endif
endfunction
autocmd VimEnter * nested call InstallMissingPlugins()

"""" Start Plugin Manager
call plug#begin('~/.vim/plugged')

"""" General
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

"""" Coordination between plugins
""""" delimitmate, vim-endwise
" Combine enter key (<CR>) mappings from the plugins above.
" Also, if the popupmenu is visible, but no items are selected, close the
" popup and insert a newline.
imap <expr> <CR>
  \ pumvisible() ?
    \ (complete_info().selected == -1 ? '<C-y><CR>' : '<C-y>') :
    \ delimitMate#WithinEmptyPair() ?
      \ "\<C-R>=delimitMate#ExpandReturn()\<CR>" :
      \ "\<CR>\<Plug>DiscretionaryEnd"

"""" Editing
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
" I use it for more robust substitutions, but it does alot more
Plug 'tpope/vim-abolish'
Plug 'airblade/vim-matchquote'
"""" End Plugin Manager
call plug#end()
