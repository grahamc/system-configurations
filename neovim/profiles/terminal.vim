" Exit if we are not running in a terminal
if index(v:argv, '--embed') != -1 || index(v:argv, '--headless') != -1
  finish
endif

""" Section: General
set confirm
set mouse=a
set sessionoptions-=blank sessionoptions-=options sessionoptions+=tabpages sessionoptions+=folds
set display+=lastline
set nofoldenable
set wildoptions=pum
set nohlsearch
let &clipboard = has('nvim') ? 'unnamedplus' : 'unnamed'
set scrolloff=10

" persist undo history to disk
set undofile

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
    autocmd FileType * setlocal textwidth=0
    autocmd FileType * setlocal wrapmargin=0
    autocmd FileType * setlocal formatoptions-=t formatoptions-=l
  augroup END
endfunction

augroup Miscellaneous
  autocmd!
  autocmd BufEnter *
        \ if &ft ==# 'help' && (&columns * 10) / &lines > 31 | wincmd L | endif
  autocmd FileType sh setlocal keywordprg=man
  autocmd VimEnter * call OverrideVimsDefaultFiletypePlugins()
  autocmd CursorHold * execute printf('silent! 2match WordUnderCursor /\V\<%s\>/', escape(expand('<cword>'), '/\'))
  " After a quickfix command is run, open the quickfix window , if there are results
  autocmd QuickFixCmdPost [^l]* cwindow
  autocmd QuickFixCmdPost l*    lwindow
  " Put focus back in quickfix window after opening an entry
  autocmd FileType qf nnoremap <buffer> <CR> <CR><C-W>p
  " highlight trailing whitespace
  autocmd ColorScheme * highlight ExtraWhitespace ctermbg=1 ctermfg=1 | execute '2match ExtraWhitespace /\s\+$/'
  " Automatically resize all splits to make them equal when the vim window is
  " resized or a new window is created/closed
  autocmd VimResized,WinNew,WinClosed,TabEnter * wincmd =
  " Start syntax highlighting from the beginning of the file. Unless it's a large file, in which case start
  " don't highlight at all.
  autocmd BufWinEnter * if line2byte(line("$") + 1) > 1000000 | syntax clear | else | syntax sync fromstart | endif
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

" TODO: When tmux is able to differentiate between tab/ctrl+i and enter/ctrl+m these mappings
" should be updated.
" tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
"
" maximize a window by opening it in a new tab
nnoremap <silent><Leader>m <Cmd>tab sp<CR>
" move forward in the jumplist
nnoremap <C-p> <C-i>

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
augroup LastTab
  autocmd!
  autocmd TabLeave * let g:lasttab = tabpagenr()
augroup END

""" Section: Autocomplete
" show the completion menu even if there is only one suggestion
" when autocomplete gets triggered, no suggestion is selected
" Use popup instead of preview window
set completeopt=menuone,noselect
if has('nvim')
  " TODO: not working
  " set completeopt+=preview
  " " Automatically close the preview window when autocomplete is done
  " augroup ClosePreview
  "   autocmd!
  "   autocmd CompleteDone * if pumvisible() == 0 | pclose | endif
  " augroup END
else
  set completeopt+=popup
endif
set complete=.,w,b,u

""" Section: Command line settings
" on first wildchar press (<Tab>), show all matches and complete the longest common substring among them.
" on subsequent wildchar presses, cycle through matches
set wildmode=longest:full,full
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
      let s:session_full_path = s:session_dir . '/' . s:session_name
      let s:session_cmd = filereadable(s:session_full_path) ? "source " : "mksession! "
      execute s:session_cmd . fnameescape(s:session_full_path)
    endif
  endfunction
  autocmd VimEnter * ++nested call RestoreOrCreateSession()
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
set showtabline=1
set wrap
set listchars=tab:¬-,space:· " chars to represent tabs and spaces when 'setlist' is enabled
set signcolumn=yes " always show the sign column
augroup SetColorscheme
  autocmd!
  " use nested so my colorscheme changes are loaded
  autocmd VimEnter * ++nested colorscheme nord
augroup END

" Statusline
let g:statusline_separator = "%#TabLineFill# %#StatusLineRightSeparator#/ %#StatusLineRightText#"
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

  let l:warning = ''
  let l:error = ''
  let l:info = ''
  try
    let l:ale_count = ale#statusline#Count(bufnr('%'))
  catch
    let l:ale_count = {'warning': 0, 'error': 0, 'info': 0}
  endtry
  let l:error_count = l:ale_count.error
  let l:warning_count = l:ale_count.warning
  let l:info_count = l:ale_count.info
  if (l:error_count > 0)
    let l:error = '%#StatusLineRightText#' . g:statusline_separator . '%#StatusLineErrorText#' . l:error_count . ' ' . '⨂ '
  endif
  if (l:warning_count > 0)
    let l:warning = '%#StatusLineRightText#' . g:statusline_separator . '%#StatusLineWarningText#' . l:warning_count . ' ' . '⚠ '
  endif
  if (l:info_count > 0)
    let l:info = '%#StatusLineRightText#' . g:statusline_separator . '%#StatusLineInfoText#' . l:info_count . ' 🛈 '
  endif

  return l:highlight_text . (exists('l:special_statusline') ? l:special_statusline : ' %y %h%w%q%t%m%r ') . l:highlight . '%=' . l:highlight_right_text . 'Ln %l/%L' . g:statusline_separator . 'Col %c/%{execute("echon col(\"$\") - 1")}' . l:info . l:warning . l:error . ' '
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

set fillchars=vert:┃

" Tabline
function! Tabline()
  let tab_count = tabpagenr('$')
  let tabline = '%#StatusLineText# 🗐  %#TabLineFill#%='

  for i in range(tab_count)
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
    let highlight = (tab == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#')
    let highlight_button = (tab == tabpagenr() ? '%#TabLineButtonSel#' : '%#TabLineButton#')
    let tabline .= highlight_button . '%' . tab . 'X✕%X' . highlight . ' ' . bufname
    if i < tab_count - 1
      let tabline .= g:statusline_separator
    endif
  endfor
  let tabline .= '%='

  return tabline
endfunction
set tabline=%!Tabline()

" Write to file with sudo. For when I forget to use sudoedit.
" tee streams its input to stdout as well as the specified file so I suppress the output
command! SudoWrite w !sudo tee % >/dev/null

" Delete buffers that aren't referencing a file
function s:WipeBuffersWithoutFiles()
    let bufs=filter(range(1, bufnr('$')), 'bufexists(v:val) && '.
                                          \'empty(getbufvar(v:val, "&buftype")) && '.
                                          \'!filereadable(bufname(v:val))')
    if !empty(bufs)
        execute 'bwipeout' join(bufs)
    endif
endfunction
command CleanBuffers call s:WipeBuffersWithoutFiles()

" Plugins
""""""""""""""""""""""""""""""""""""""""
Plug 'junegunn/vim-peekaboo'
  let g:peekaboo_delay = 500 " measured in milliseconds

Plug 'inkarkat/vim-CursorLineCurrentWindow'

Plug 'farmergreg/vim-lastplace'

Plug 'tmux-plugins/vim-tmux'

Plug 'tweekmonster/startuptime.vim'

" Autocomplete
Plug 'prabirshrestha/asyncomplete.vim'
  let g:asyncomplete_auto_completeopt = 0
  let g:asyncomplete_auto_popup = 1
  let g:asyncomplete_min_chars = 1
  let g:asyncomplete_matchfuzzy = 0
  inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
  function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~ '\s'
  endfunction
  inoremap <silent><expr> <TAB>
    \ pumvisible() ? "\<C-n>" :
    \ <SID>check_back_space() ? "\<TAB>" :
    \ asyncomplete#force_refresh()
  imap <C-a> <Plug>(asyncomplete_force_refresh)
  Plug 'prabirshrestha/asyncomplete-buffer.vim'
    let g:asyncomplete_buffer_clear_cache = 1
    autocmd User asyncomplete_setup
      \ call asyncomplete#register_source(asyncomplete#sources#buffer#get_source_options({
      \ 'name': 'buffer',
      \ 'allowlist': ['*'],
      \ 'events': ['InsertLeave','BufWinEnter','BufWritePost'],
      \ 'completor': function('asyncomplete#sources#buffer#completor'),
      \ }))
  Plug 'prabirshrestha/asyncomplete-file.vim'
    autocmd User asyncomplete_setup
        \ call asyncomplete#register_source(asyncomplete#sources#file#get_source_options({
        \ 'name': 'file',
        \ 'allowlist': ['*'],
        \ 'priority': 10,
        \ 'completor': function('asyncomplete#sources#file#completor')
        \ }))
  Plug 'yami-beta/asyncomplete-omni.vim'
    autocmd User asyncomplete_setup
        \ call asyncomplete#register_source(asyncomplete#sources#omni#get_source_options({
        \ 'name': 'omni',
        \ 'allowlist': ['*'],
        \ 'completor': function('asyncomplete#sources#omni#completor'),
        \ 'config': {
        \   'show_source_kind': 1,
        \ },
        \ }))
  Plug 'Shougo/neco-vim'
    Plug 'prabirshrestha/asyncomplete-necovim.vim'
      autocmd User asyncomplete_setup
          \ call asyncomplete#register_source(asyncomplete#sources#necovim#get_source_options({
          \ 'name': 'necovim',
          \ 'allowlist': ['vim'],
          \ 'completor': function('asyncomplete#sources#necovim#completor'),
          \ }))
  Plug 'prabirshrestha/async.vim'
    Plug 'wellle/tmux-complete.vim'
  " Language Server Protocol client that provides IDE like features
  " e.g. autocomplete, autoimport, smart renaming, go to definition, etc.
  Plug 'prabirshrestha/vim-lsp'
    " for debugging
    let g:lsp_log_file = has('nvim') ? stdpath('data') . '/vim-lsp-log' : $HOME.'/.vim/vim-lsp-log'
    let g:lsp_fold_enabled = 0
    let g:lsp_document_code_action_signs_enabled = 0
    let g:lsp_document_highlight_enabled = 0
    " An easy way to install/manage language servers for vim-lsp.
    Plug 'mattn/vim-lsp-settings'
      " where the language servers are stored
      let g:lsp_settings_servers_dir = has('nvim') ? stdpath('data') . '/lsp-servers' : $HOME.'/.vim/lsp-servers'
      call mkdir(g:lsp_settings_servers_dir, "p")
      let g:lsp_settings = {
        \ 'efm-langserver': {'disabled': v:true},
        \ 'bash-language-server': {'disabled': v:true}
        \ }
    Plug 'prabirshrestha/asyncomplete-lsp.vim'

" Asynchronous linting
Plug 'dense-analysis/ale'
  " If a linter is not found don't continue to check on subsequent linting operations.
  let g:ale_cache_executable_check_failures = 1
  " Don't show popup when the mouse if over a symbol, vim-lsp
  " should be responsible for that.
  let g:ale_set_balloons = 0
  " Don't show variable information in the status line,
  " vim-lsp should be responsible for that.
  let g:ale_hover_cursor = 0
  " Only display diagnostics with a warning level or above
  " i.e. warning,error
  let g:ale_lsp_show_message_severity = "information"
  let g:ale_lint_on_enter = 1 " lint when a buffer opens
  let g:ale_lint_on_text_changed = "always"
  let g:ale_lint_delay = 1000
  let g:ale_lint_on_insert_leave = 0
  let g:ale_lint_on_filetype_changed = 0
  let g:ale_lint_on_save = 0
  let g:ale_sign_error = '•'
  let g:ale_sign_warning = '•'
  let g:ale_sign_info = '•'
  let g:ale_sign_priority = 100

" A bridge between vim-lsp and ale. This works by
" sending diagnostics (e.g. errors, warning) from vim-lsp to ale.
" This way, vim-lsp will only provide LSP features
" and ALE will only provide realtime diagnostics.
Plug 'rhysd/vim-lsp-ale'
  " Only report diagnostics with a level of 'warning' or above
  " i.e. warning,error
  let g:lsp_ale_diagnostics_severity = "information"

" Expands Emmet abbreviations to write HTML more quickly
Plug 'mattn/emmet-vim'
  let g:user_emmet_expandabbr_key = '<Leader>e'
  let g:user_emmet_mode='n'

" Seamless movement between vim windows and tmux panes.
Plug 'christoomey/vim-tmux-navigator'
  let g:tmux_navigator_no_mappings = 1
  noremap <silent> <M-h> :TmuxNavigateLeft<cr>
  noremap <silent> <M-l> :TmuxNavigateRight<cr>
  noremap <silent> <M-j> :TmuxNavigateDown<cr>
  noremap <silent> <M-k> :TmuxNavigateUp<cr>

" Add icons to the gutter to signify version control changes (e.g. new lines, modified lines, etc.)
Plug 'mhinz/vim-signify'
  nnoremap <Leader>vk <Cmd>SignifyHunkDiff<CR>

" fzf integration
"
" TODO: Until vim gets support for dim text in its terminals, it will be hard to see which item is
" active.
" issue: https://github.com/vim/vim/issues/8269
Plug 'junegunn/fzf'
  let g:fzf_layout = { 'window': 'tabnew' }
  augroup Fzf
    autocmd!
    " Hide all ui elements when fzf is active
    " TODO: Once neovim v0.8 is released, I can hide the command window with `set cmdheight=0`
    " v0.8 milestone: https://github.com/neovim/neovim/milestone/28
    autocmd  FileType fzf set laststatus=0 noshowmode noruler nonumber norelativenumber showtabline=0
      \| autocmd BufLeave <buffer> set laststatus=2 showmode number relativenumber showtabline=1
    " In terminals you have to press <C-\> twice to send it to the terminal.
    " This mapping makes it so that I only have to press it once.
    " This way, I can use a <C-\> keybind in fzf more easily.
    autocmd  FileType fzf tnoremap <buffer> <C-\> <C-\><C-\>
  augroup END
  " Collection of fzf-based commands
  Plug 'junegunn/fzf.vim'
    nnoremap <silent> <Leader>h <Cmd>History:<CR>
    nnoremap <silent> <Leader>/ <Cmd>Commands<CR>
    nnoremap <silent> <Leader>b <Cmd>Buffers<CR>
    " recursive grep
    function! RipgrepFzf(query, fullscreen)
      let command_fmt = 'rg --hidden --column --line-number --fixed-strings --no-heading --color=always --smart-case -- %s || true'
      let initial_command = printf(command_fmt, shellescape(a:query))
      let reload_command = printf(command_fmt, '{q}')
      let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:first+reload:'.reload_command, '--prompt', 'lines: ', '--preview', 'bat --paging=never --terminal-width (math $FZF_PREVIEW_COLUMNS - 2) {1} --highlight-line {2} | tail -n +2 | head -n -1']}
      call fzf#vim#grep(initial_command, 1, spec, a:fullscreen)
    endfunction
    command! -nargs=* -bang FindLine call RipgrepFzf(<q-args>, <bang>0)
    nnoremap <Leader>g <Cmd>FindLine<CR>
    " recursive file search
    command! -bang -nargs=* FindFile call
        \ fzf#run(fzf#wrap({
        \ 'source': 'fd --hidden --strip-cwd-prefix --type file --type symlink | tr -d "\017"',
        \ 'sink': 'edit',
        \ 'options': '--ansi --preview "bat --style=numbers,grid --paging=never --terminal-width (math \$FZF_PREVIEW_COLUMNS - 2) {} | tail -n +2 | head -n -1" --prompt="' . substitute(getcwd(), $HOME, '~', "") .'/" --keep-right'}))
    nnoremap <Leader>f <Cmd>FindFile<CR>

" Colors
" Opens the OS color picker and inserts the chosen color into the buffer.
Plug 'KabbAmine/vCoolor.vim'
  " Make an alias for the 'VCoolor' command with a name that is easier to remember
  command! ColorPicker VCoolor

" File explorer
Plug 'preservim/nerdtree', {'on': 'NERDTreeFind'}
  function! NerdTreeToggle()
    " NERDTree is open so close it.
    if exists('g:NERDTree') && g:NERDTree.IsOpen()
      silent execute 'NERDTreeToggle'
      return
    endif

    " If NERDTree can't find the current file, it prints an error and doesn't open NERDTree.
    " In which case, I call 'NERDTree' which opens NERDTree to the current directory.
    silent execute 'NERDTreeFind'
    if !g:NERDTree.IsOpen()
      silent execute 'NERDTree'
    endif
  endfunction
  nnoremap <silent> <M-e> <Cmd>call NerdTreeToggle()<CR>
  augroup NerdTree
    autocmd!
    " open/close directories with 'h' and 'l'
    autocmd FileType nerdtree nmap <buffer> l o
    autocmd FileType nerdtree nmap <buffer> h o
  augroup END
  let g:NERDTreeMouseMode = 2
  let g:NERDTreeShowHidden = 1
  let g:NERDTreeStatusline = -1
  let g:NERDTreeWinPos = "right"

" Colorscheme
Plug 'arcticicestudio/nord-vim'
  let g:nord_bold = 1
  let g:nord_italic = 1
  let g:nord_italic_comments = 1
  let g:nord_underline = 1
  " Overrides
  augroup NordColorschemeOverrides
    autocmd!
    " MatchParen
    autocmd ColorScheme nord highlight MatchParen ctermfg=blue cterm=underline ctermbg=NONE
    " Transparent SignColumn
    autocmd ColorScheme nord highlight clear SignColumn
    " Transparent vertical split
    autocmd ColorScheme nord highlight VertSplit ctermbg=NONE ctermfg=8
    " statusline colors
    autocmd ColorScheme nord highlight StatusLine ctermbg=8
    autocmd ColorScheme nord highlight StatusLineText ctermfg=14 ctermbg=NONE cterm=reverse
    autocmd ColorScheme nord highlight StatusLineNC ctermbg=8
    autocmd ColorScheme nord highlight StatusLineNCText ctermfg=15 ctermbg=NONE cterm=reverse
    autocmd ColorScheme nord highlight StatusLineRightText ctermfg=15 ctermbg=8
    autocmd ColorScheme nord highlight StatusLineRightSeparator ctermfg=8 ctermbg=NONE cterm=reverse,bold
    autocmd ColorScheme nord highlight StatusLineErrorText ctermfg=1 ctermbg=8
    autocmd ColorScheme nord highlight StatusLineWarningText ctermfg=3 ctermbg=8
    autocmd ColorScheme nord highlight StatusLineInfoText ctermfg=7 ctermbg=8
    " autocomplete popupmenu
    autocmd ColorScheme nord highlight PmenuSel ctermfg=11 ctermbg=8
    autocmd ColorScheme nord highlight Pmenu ctermfg=NONE ctermbg=8
    autocmd ColorScheme nord highlight CursorLine ctermfg=NONE ctermbg=NONE cterm=underline
    " transparent background
    autocmd ColorScheme nord highlight Normal ctermbg=NONE
    autocmd ColorScheme nord highlight NonText ctermbg=NONE
    autocmd ColorScheme nord highlight! link EndOfBuffer NonText
    " relative line numbers
    autocmd ColorScheme nord highlight LineNr ctermfg=NONE
    autocmd ColorScheme nord highlight LineNrAbove ctermfg=15
    autocmd ColorScheme nord highlight! link LineNrBelow LineNrAbove
    autocmd ColorScheme nord highlight WordUnderCursor cterm=underline,bold
    autocmd ColorScheme nord highlight! link IncSearch Search
    autocmd ColorScheme nord highlight TabLine ctermbg=8 ctermfg=15
    autocmd ColorScheme nord highlight TabLineSel ctermbg=8 ctermfg=14 cterm=bold
    autocmd ColorScheme nord highlight TabLineFill ctermbg=8
    autocmd ColorScheme nord highlight TabLineButton ctermfg=15 ctermbg=8 cterm=bold
    autocmd ColorScheme nord highlight TabLineButtonSel ctermfg=14 ctermbg=8 cterm=bold
    autocmd ColorScheme nord highlight WildMenu ctermfg=14 ctermbg=NONE cterm=underline
    autocmd ColorScheme nord highlight Comment ctermfg=15 ctermbg=NONE
    " This variable contains a list of 16 colors that should be used as the color palette for terminals opened in vim.
    " By unsetting this, I ensure that terminals opened in vim will use the colors from the color palette of the
    " terminal emulator in which vim is running
    autocmd ColorScheme nord if exists('g:terminal_ansi_colors') | unlet g:terminal_ansi_colors | endif
    " Have vim only use the colors from the 16 color palette of the terminal emulator in which it runs
    autocmd ColorScheme nord set t_Co=16
    autocmd ColorScheme nord highlight Visual ctermbg=8
    " Search hit
    autocmd ColorScheme nord highlight Search ctermfg=DarkYellow ctermbg=NONE cterm=reverse
    " Parentheses
    autocmd ColorScheme nord highlight Delimiter ctermfg=NONE ctermbg=NONE
    autocmd ColorScheme nord highlight ErrorMsg ctermfg=1 ctermbg=NONE cterm=bold
    autocmd ColorScheme nord highlight Error ctermfg=1 ctermbg=NONE cterm=undercurl
    autocmd ColorScheme nord highlight! link SpellBad Error
    autocmd ColorScheme nord highlight! link NvimInternalError ErrorMsg
    autocmd ColorScheme nord highlight! link ALEError Error
    autocmd ColorScheme nord highlight ALEWarning ctermfg=3 ctermbg=NONE cterm=undercurl
  augroup END

Plug 'junegunn/goyo.vim'
  let g:goyo_width = '85%'
  " Make an alias for the 'Goyo' command with a name that is easier to remember
  command! Focus Goyo

" Install plugins if not found. Must be done after plugins are registered
function! InstallMissingPlugins()
  let missing_plugins = filter(deepcopy(get(g:, 'plugs', {})), '!isdirectory(v:val.dir)')
  if empty(missing_plugins)
    return
  endif

  let install_prompt = "The following plugins are not installed:\n" . join(keys(missing_plugins), ", ") . "\nWould you like to install them?"
  let should_install = confirm(install_prompt, "yes\nno") == 1
  if should_install
    let snapshot_file = stdpath('data') . '/vim-plug-snapshot.vim'
    if filereadable(snapshot_file)
      " Sourcing the snapshot will set plugins to the commit specified in the snapshot
      " and install any missing ones.
      execute printf('source %s', snapshot_file)

      " Take a new snapshot in case we've installed any plugins that aren't in the current snapshot.
      execute printf('PlugSnapshot! %s', snapshot_file)

      " Edit the snapshot file so that it updates plugins synchronously
      execute "silent! !sed --in-place --follow-symlinks 's/PlugUpdate\\!/PlugUpdate\\! --sync/g' " . snapshot_file
    else
      PlugInstall --sync
    endif
  endif
endfunction

" If it's been more than a month, update plugins
function! MonthlyPluginUpdate()
  let snapshot_file = stdpath('data') . '/vim-plug-snapshot.vim'
  if !filereadable(snapshot_file)
    return
  endif

  " Make this a command so it can be called manually if needed
  execute "command! PlugUpdateAndSnapshot PlugUpdate --sync | PlugSnapshot! " . snapshot_file

  let last_modified_time = system(printf('date --reference %s +%%s', snapshot_file))
  let current_time = system('date +%s')
  let time_since_last_update = current_time - last_modified_time
  if time_since_last_update > 2592000
    let update_prompt = "You haven't updated your plugins in over a month, would you like to update them now?"
    let should_update = confirm(update_prompt, "yes\nno") == 1
    if should_update
      PlugUpgrade
      PlugUpdateAndSnapshot

      " Edit the snapshot file so that it updates plugins synchronously
      execute "silent! !sed --in-place --follow-symlinks 's/PlugUpdate\\!/PlugUpdate\\! --sync/g' " . snapshot_file
    endif
  endif
endfunction

augroup PostPluginLoadOperations
  autocmd VimEnter * call InstallMissingPlugins() | call MonthlyPluginUpdate()
augroup END
