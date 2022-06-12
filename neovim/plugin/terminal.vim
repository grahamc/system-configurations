if index(v:argv, '--embed') != -1 || index(v:argv, '--headless') != -1
  finish
endif

""" Section: General
set confirm
set mouse=a
set sessionoptions-=blank sessionoptions-=options sessionoptions+=tabpages sessionoptions-=folds
set showcmd
set display+=lastline
set nofoldenable
set wildoptions=pum
set nohlsearch

function! OverrideVimsDefaultFiletypePlugins()
  " Vim's default filetype plugins get run after filetype detection is
  " performed (i.e. ':filetype plugin on'). So in order to override
  " settings from vim's filetype plugins, the FileType autocommands
  " need to be registered after filetype detection.
  " Since this function gets called on the VimEnter event, we're
  " certain that filetype detection has already
  " happened because filetype detection gets triggered when the
  " plugin manager, vim-plug, finishes loading plugins.
  augroup OverrideFiletypePlugins
    autocmd!
    " Use vim help pages for keywordprg in vim files
    autocmd FileType vim setlocal keywordprg=:tab\ help
    " Set a default omnifunc
    autocmd FileType * if &omnifunc == "" | setlocal omnifunc=syntaxcomplete#Complete | endif
    autocmd FileType * set textwidth=0
    autocmd FileType * set wrapmargin=0
  augroup END
endfunction

augroup Miscellaneous
  autocmd!
  autocmd BufEnter *
        \ if &ft ==# 'help' && (&columns * 10) / &lines > 31 | wincmd L | endif
  autocmd FileType sh setlocal keywordprg=man
  autocmd VimEnter * call OverrideVimsDefaultFiletypePlugins()
  autocmd CursorHold * execute printf('silent! 3match WordUnderCursor /\V\<%s\>/', escape(expand('<cword>'), '/\'))
  " After a quickfix command is run, open the quickfix window , if there are results
  autocmd QuickFixCmdPost [^l]* cwindow
  autocmd QuickFixCmdPost l*    lwindow
  " Put focus back in quickfix window after opening an entry
  autocmd FileType qf nnoremap <buffer> <CR> <CR><C-W>p
  " highlight trailing whitespace
  autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red | execute '2match ErrorMsg /\s\+$/'
  " Automatically resize all splits to make them equal when the vim window is
  " resized or a new window is created/closed
  autocmd VimResized,WinNew,WinClosed * wincmd =
  " TODO: update for neovim
  autocmd! bufwritepost .vimrc,vimrc nested source $MYVIMRC | execute 'colorscheme ' . trim(execute('colorscheme'))
augroup END

cnoreabbrev <expr> h getcmdtype() == ":" && getcmdline() == 'h' ? 'tab help' : 'h'

" tab setup
set expandtab
set autoindent smartindent
set smarttab
set shiftround " Round indent to multiple of shiftwidth (applies to < and >)
let s:tab_width = 2
let &tabstop = s:tab_width
let &shiftwidth = s:tab_width
let &softtabstop = s:tab_width

" Display all highlight groups in a new window
command! HighlightTest so $VIMRUNTIME/syntax/hitest.vim

" tabs
nnoremap <silent> <Leader>c <Cmd>tabnew<CR>
nnoremap <silent> <C-h> <Cmd>tabprevious<CR>
nnoremap <silent> <C-l> <Cmd>tabnext<CR>

nnoremap <silent> <Leader>w <Cmd>wa<CR>
nnoremap <Leader>x <Cmd>wqa<CR>

" maximize a window by opening it in a new tab
nnoremap <silent><Leader>m <Cmd>tab sp<CR>

" open new horizontal and vertical panes to the right and bottom respectively
set splitright splitbelow
nnoremap <Leader>\| <Cmd>vsplit<CR>
nnoremap <Leader>- <Cmd>split<CR>
" close a window, quit if last window
" also when closing a tab, go to the previously opened tab
nnoremap <silent> <expr> <leader>q  winnr('$') == 1 ? ':exe "q" \| silent! tabn '.g:lasttab.'<CR>' : ':close<CR>'
" track which tab last opened
if !exists('g:lasttab')
  let g:lasttab = 1
endif
autocmd TabLeave * let g:lasttab = tabpagenr()

""" Section: Autocomplete
" show the completion menu even if there is only one suggestion
" when autocomplete gets triggered, no suggestion is selected
" Use popup instead of preview window
set completeopt+=menu,menuone,noselect
if has('nvim')
  set completeopt+=preview
  " Automatically close the preview window when autocomplete is done
  autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif
else
  set completeopt+=popup
endif
set complete=.,w,b,u

""" Section: Command line settings
" on first wildchar press (<Tab>), show all matches and complete the longest common substring among them.
" on subsequent wildchar presses, cycle through matches
set wildmenu wildmode=longest:full,full
set cmdheight=2

" suspend vim and start a new shell
nnoremap <C-z> <Cmd>suspend<CR>
inoremap <C-z> <Cmd>suspend<CR>
xnoremap <C-z> <Cmd>suspend<CR>

""" Section: Search
" show match position in command window, don't show 'Search hit BOTTOM/TOP'
set shortmess-=S shortmess+=s
" toggle search highlighting
nnoremap <silent> <Leader>\ <Cmd>set hlsearch!<CR>

""" Section: Restore Settings
augroup SaveAndRestoreSettings
  autocmd!
  " Restore session after vim starts. The 'nested' keyword tells vim to fire events
  " normally while this autocmd is executing. By default, no events are fired
  " during the execution of an autocmd to prevent infinite loops.
  let s:session_dir = has('nvim') ? stdpath('data') . '/sessions' : $HOME.'/.vim/sessions'
  function! RestoreOrCreateSession()
    " We omit the first element in the list since that will always be the path
    " to the vim binary e.g. /usr/local/bin/vim
    if v:argv[1:]->empty()
      call mkdir(s:session_dir, "p")
      let s:session_name =  substitute($PWD, '/', '%', 'g') . '%vim'
      let s:session_full_path = s:session_dir . s:session_name
      let s:session_cmd = filereadable(s:session_full_path) ? "source " : "mksession! "
      execute s:session_cmd . fnameescape(s:session_full_path)
    endif
  endfunction
  autocmd VimEnter * nested call RestoreOrCreateSession()
  " save session before vim exits
  function! SaveSession()
    if !empty(v:this_session)
      execute 'mksession! ' . fnameescape(v:this_session)
    endif
  endfunction
  autocmd VimLeavePre * call SaveSession()
augroup END

""" Section: Aesthetics
"""" Misc.
set linebreak
set number relativenumber
set cursorline cursorlineopt=number,line
set laststatus=2
set showtabline=1
set wrap
set listchars=tab:¬-,space:· " chars to represent tabs and spaces when 'setlist' is enabled
set signcolumn=yes " always show the sign column
let &fillchars = "foldopen: ,fold: ,vert:\u2502,stl:\ ,stlnc:\ "

" Statusline
let g:statusline_separator = "%#StatusLineRightSeparator# \u2759 %#StatusLineRightText#"
function! MyStatusLine()
  if g:actual_curwin == win_getid()
    let l:highlight = 'StatusLine'
  else
    let l:highlight = 'StatusLineNC'
  endif
  let l:highlight_text = l:highlight . 'Text'
  let l:highlight = '%#' . l:highlight . '#'
  let l:highlight_text = '%#' . l:highlight_text . '#'
  let l:highlight_right_text = '%#StatusLineRightText#'

  if &ft ==# 'help'
    let l:special_statusline = '[Help] %t'
  elseif &ft ==# 'vim-plug'
    let l:special_statusline = 'Vim Plug'
  elseif g:actual_curwin != win_getid()
    let l:special_statusline = '%t'
  elseif exists('b:NERDTree')
    let l:special_statusline = '%t'
  endif
  if exists('l:special_statusline')
    let l:special_statusline = ' ' . l:special_statusline . ' '
    return l:highlight_text . l:special_statusline . l:highlight
  endif

  let l:ale_count = ale#statusline#Count(bufnr('%'))
  let l:error_count = l:ale_count.error
  let l:warning_count = l:ale_count.warning
  let l:error = (l:error_count > 0) ? '%#StatusLineRightText#' . g:statusline_separator . '%#StatusLineErrorText#' . l:error_count . ' ' . '⨂' : ''
  let l:warning = (l:warning_count > 0) ? '%#StatusLineRightText#' . g:statusline_separator . '%#StatusLineWarningText#' . l:warning_count . ' ' . '⚠' : ''

  return l:highlight_text . (exists('l:special_statusline') ? l:special_statusline : ' %y %h%w%q%t%m%r ') . l:highlight . '%=' . l:highlight_right_text . 'Ln %l/%L' . g:statusline_separator . 'Col %c/%{execute("echon col(\"$\") - 1")}' . l:warning . l:error . ' '
endfunction
set statusline=%{%MyStatusLine()%}

"""" Block cursor in normal mode, thin line in insert mode, and underline in replace mode
let &t_SI.="\e[5 q" "SI = INSERT mode
let &t_SR.="\e[3 q" "SR = REPLACE mode
let &t_EI.="\e[1 q" "EI = NORMAL mode (ELSE)
function! RestoreCursor()
  " set cursor back to block
  silent execute "!echo -ne '\e[1 q'"
endfunction
function! ResetCursor()
  " reset terminal cursor to blinking bar
  silent execute "!echo -ne '\e[5 q'"
endfunction
augroup Cursor
  autocmd!
  autocmd VimLeave * call ResetCursor()
  autocmd VimSuspend * call ResetCursor()
  autocmd VimResume * call RestoreCursor()
augroup END

" Tabline
function! Tabline()
  let tabline = ''

  for i in range(tabpagenr('$'))
    let tab = i + 1
    let winnr = tabpagewinnr(tab)
    let buflist = tabpagebuflist(tab)
    let bufnr = buflist[winnr - 1]

    let bufname = bufname(bufnr)
    if bufname != ''
      let bufname = fnamemodify(bufname, ':t')
    else
      let bufname = '[No Name]'
    endif

    let tabline .= '%' . tab . 'T'
    let tabline .= (tab == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#')
    let tabline .= ' %' . tab . 'X✕%X '
    let tabline .= empty(gettabvar(tab, 'fzf_active')) ? bufname : 'fzf'
    let tabline .= ' '
  endfor

  let tabline .= '%T%#TabLineFill#'

  return tabline
endfunction
set tabline=%!Tabline()

" Write to file with sudo. For when I forget to use sudoedit.
" tee streams its input to stdout as well as the specified file so I suppress the output
command! SudoWrite w !sudo tee % >/dev/null

" Must be after plugins are loaded since this colorscheme comes from a plugin
colorscheme nord

