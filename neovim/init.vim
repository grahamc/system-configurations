set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
""" Section: Plugins
"""" Plugin Manager Settings
" Install vim-plug if not found
let data_dir = '~/.vim'
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
" Automatically close html tags
Plug 'alvan/vim-closetag'
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

set clipboard=unnamedplus
let g:mapleader = "\<Space>"
xmap <C-Space> <C-S-P>
nnoremap <Leader>x :Wqall<CR>
nnoremap <silent> <Leader>w :Wall<CR>
nnoremap <silent> <Leader>q :Quit<CR>
nmap <Leader>\| <C-w>v
nmap <Leader>- <C-w>s
nnoremap <silent> <Leader>f :Find<CR>
nnoremap <silent> <Leader>g :call VSCodeNotify("workbench.action.findInFiles")<CR>
noremap <C-j> 10j
noremap <C-k> 10k
nnoremap <Leader>e :call VSCodeNotify("workbench.action.toggleSidebarVisibility")<CR>
xmap gc  <Plug>VSCodeCommentary
