""" Section: This Stuff Should Stay at the Top
let g:mapleader = "\<Space>"

""" Section: General
set nrformats-=octal
set ttimeout ttimeoutlen=100
set updatetime=500
set scrolloff=10
set noswapfile

augroup InitMiscellaneous
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

" vp doesn't replace paste buffer
function! RestoreRegister()
  let @" = s:restore_reg
  return ''
endfunction
function! s:Repl()
  let s:restore_reg = @"
  return "p@=RestoreRegister()\<cr>"
endfunction
vmap <silent> <expr> p <sid>Repl()

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

let external_plugins_file = expand('<sfile>:h') . '/external-plugins.vim'
execute 'source ' . external_plugins_file
