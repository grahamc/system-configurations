" vim:foldmethod=marker

" Exit if we are not running in a terminal
if index(v:argv, '--embed') != -1 || index(v:argv, '--headless') != -1
  finish
endif

" Miscellaneous {{{1
set confirm
set mouse=a
set display+=lastline
let &clipboard = has('nvim') ? 'unnamedplus' : 'unnamed'
set scrolloff=10
set jumpoptions=stack

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
  autocmd ColorScheme * highlight! link ExtraWhitespace Warning | execute 'match ExtraWhitespace /\s\+$/'
  " Start syntax highlighting from the beginning of the file. Unless it's a large file, in which case start
  " don't highlight at all.
  autocmd BufWinEnter * if line2byte(line("$") + 1) > 1000000 | syntax clear | else | syntax sync fromstart | endif
augroup END

nnoremap <silent> <Leader>w <Cmd>wa<CR>
nnoremap <Leader>x <Cmd>wqa<CR>

" TODO: When tmux is able to differentiate between tab and ctrl+i this mapping should be updated.
" tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
"
" move forward in the jumplist
nnoremap <C-p> <C-i>

" suspend vim and start a new shell
nnoremap <C-z> <Cmd>suspend<CR>
inoremap <C-z> <Cmd>suspend<CR>
xnoremap <C-z> <Cmd>suspend<CR>

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

" Utilities {{{1
" Delete buffers that aren't referencing a file
function s:WipeBuffersWithoutFiles()
    let bufs=filter(range(1, bufnr('$')), 'bufexists(v:val) && '.
                                          \'empty(getbufvar(v:val, "&buftype")) && '.
                                          \'!filereadable(bufname(v:val))')
    if !empty(bufs)
        execute 'bwipeout!' join(bufs)
    endif
endfunction
command CleanBuffers call s:WipeBuffersWithoutFiles()

" Write to file with sudo. For when I forget to use sudoedit.
" tee streams its input to stdout as well as the specified file so I suppress the output
command! SudoWrite w !sudo tee % >/dev/null

" Display all highlight groups in a new window
command! HighlightTest so $VIMRUNTIME/syntax/hitest.vim

" Sets options to the specified new values and returns their old values.
" Useful for when you want to change an option temporarily and then restore its old value.
function! SetOptions(new_option_values)
  let old_option_values = {}

  for item in items(a:new_option_values)
    let option_name = item[0]
    let new_option_value = item[1]

    " store old value
    let old_option_value = execute('echon ' . option_name)
    let old_option_values[option_name] = old_option_value

    " set new value
    if execute(printf('echon type(%s) == type("")', option_name))
      " quote string values
      execute printf('let %s = "%s"', option_name, new_option_value)
    else
      execute printf('let %s = %s', option_name, new_option_value)
    endif
  endfor

  return old_option_values
endfunction

" Windows {{{1
" open new horizontal and vertical panes to the right and bottom respectively
set splitright splitbelow
nnoremap <Leader>\| <Cmd>vsplit<CR>
nnoremap <Leader>- <Cmd>split<CR>

" close a window, quit if last window
" also when closing a tab, go to the previously opened tab
nnoremap <silent> <expr> <leader>q  winnr('$') == 1 ? ':exe "q" \| silent! tabn '.g:lasttab.'<CR>' : ':close<CR>'

" TODO: When tmux is able to differentiate between enter and ctrl+m this mapping should be updated.
" tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
"
" maximize a window by opening it in a new tab
nnoremap <silent><Leader>m <Cmd>if winnr('$') > 1 \| tab sp \| endif<CR>

augroup Window
  autocmd!

  " Automatically resize all splits to make them equal when the vim window is
  " resized or a new window is created/closed
  autocmd VimResized,WinNew,WinClosed,TabEnter * wincmd =
augroup END

" Tab windows {{{1
nnoremap <silent> <Leader>c <Cmd>$tabnew<CR>
nnoremap <silent> <C-h> <Cmd>tabprevious<CR>
nnoremap <silent> <C-l> <Cmd>tabnext<CR>
inoremap <silent> <C-h> <Cmd>tabprevious<CR>
inoremap <silent> <C-l> <Cmd>tabnext<CR>
" track which tab last opened
if !exists('g:lasttab')
  let g:lasttab = 1
endif
augroup LastTab
  autocmd!
  autocmd TabLeave * let g:lasttab = tabpagenr()
augroup END

" Indentation {{{1
set expandtab
set autoindent smartindent
set smarttab
set shiftround " Round indent to multiple of shiftwidth (applies to < and >)
let s:tab_width = 2
let &tabstop = s:tab_width
let &shiftwidth = s:tab_width
let &softtabstop = s:tab_width

" Folds {{{1
set fillchars+=foldsep:\ ,foldclose:>,foldopen:ݍ
" Setting this so that the fold column gets displayed
set foldenable
" When a file is opened, all folds should be open
set foldlevel=999
" Set max number of nested folds when 'foldmethod' is 'syntax' or 'indent'
set foldnestmax=2
" Minimum number of lines a fold must have to be able to be closed
set foldminlines=1
" Fold visually selected lines. 'foldmethod' must be set to 'manual' for this work.
vnoremap <Tab> zf
" Toggle opening and closing all folds
nnoremap <silent> <expr> <S-Tab> &foldlevel ? 'zM' : 'zR'
" auto-resize the fold column
set foldcolumn=auto:9
" Jump to the top and bottom of the current fold, without adding to the jump list
nnoremap [<Tab> <Cmd>keepjumps normal! [z<CR>
nnoremap ]<Tab> <Cmd>keepjumps normal! ]z<CR>
xnoremap [<Tab> <Cmd>keepjumps normal! [z<CR>
xnoremap ]<Tab> <Cmd>keepjumps normal! ]z<CR>
augroup Fold
  autocmd!
  autocmd FileType python,yaml,java,c,sh,bash,zsh,fish,ruby,toml,gitconfig setlocal foldmethod=indent

  " So we don't fold the contents of the class
  autocmd FileType java setlocal foldlevel=1
augroup END

" Toggle the fold at the current line, if there is one. If the previous line we were on was
" below the current line, then start at the end of the fold.
function! TrackPreviousMove(char)
  let g:previous_move = a:char
  return a:char
endfunction
nnoremap <expr> j TrackPreviousMove('j')
nnoremap <expr> k TrackPreviousMove('k')
function! FoldToggle()
  if !foldlevel('.')
    return
  endif

  let action = 'za'

  " If we are opening a fold, and the last line we were on was below the fold,
  " open to the end of the fold.
  if exists('g:previous_move') && g:previous_move ==# 'k' && foldclosed('.') != -1
    let action .= ']z'
  endif

  " This way if we close a fold and reopen it with moving lines, it takes us back to where we were
  if foldclosed('.') == -1
    let g:previous_move = ''
  endif

  execute 'keepjumps normal ' . action
endfunction
nnoremap <silent> <Tab> <Cmd>call FoldToggle()<CR>

set foldtext=FoldText()
function! FoldText()
  let window_width = winwidth(0)
  let gutter_width = getwininfo(win_getid())[0].textoff
  let line_width = window_width - gutter_width

  let fold_line_count = (v:foldend - v:foldstart) + 1
  let fold_description = fold_line_count . ' lines'
  let fold_description = printf('(%s)', fold_description)
  let fold_description_length = strdisplaywidth(fold_description)

  let line_text = getline(v:foldstart)
  " indent the line relative to the foldlevel if it isn't already indented
  if line_text[0] !=# ' ' && line_text[0] !=# '\t'
    let indent_count = max([0, v:foldlevel - 1])
    let indent = repeat(' ', &tabstop)
    let indent = repeat(indent, indent_count)
    let line_text = indent . line_text
  endif
  " truncate if there isn't space for the fold description and some separator text
  let min_separator_text_length = 7
  let max_line_text_length = line_width - (fold_description_length + min_separator_text_length)
  if strdisplaywidth(line_text) > max_line_text_length
    " truncate 1 more than we need so we can add an ellipsis
    let line_text = line_text[:max_line_text_length-2] . '…'
  endif
  let line_text_length = strdisplaywidth(line_text)

  let separator_text_length = line_width - line_text_length - fold_description_length
  let separator_text = ' ' . repeat('·', separator_text_length - 2) . ' '

  return line_text . separator_text . fold_description
endfunction

" Autocomplete {{{1
set complete=.,w,b,u
" - show the completion menu even if there is only one suggestion
" - when autocomplete gets triggered, no suggestion is selected
set completeopt=menuone,noselect

" Command line settings {{{1
" on first wildchar press (<Tab>), show all matches and complete the longest common substring among them.
" on subsequent wildchar presses, cycle through matches
set wildmode=longest:full,full
set wildoptions=pum
set cmdheight=2
cnoreabbrev <expr> h getcmdtype() == ":" && getcmdline() == 'h' ? 'tab help' : 'h'

" Search {{{1
set nohlsearch
" show match position in command window, don't show 'Search hit BOTTOM/TOP'
set shortmess-=S shortmess+=s
" toggle search highlighting
nnoremap <silent> <Leader>\ <Cmd>set hlsearch!<CR>

" Sessions {{{1
set sessionoptions-=blank sessionoptions-=options sessionoptions+=tabpages sessionoptions+=folds
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

" Aesthetics {{{1
" Miscellaneous {{{2
set linebreak
set number relativenumber
set cursorline cursorlineopt=number,line
set showtabline=1
set wrap
set listchars=tab:¬-,space:· " chars to represent tabs and spaces when 'setlist' is enabled
set signcolumn=yes " always show the sign column
set fillchars+=vert:┃,eob:\ ,horiz:━,horizup:┻,horizdown:┳,vertleft:┫,vertright:┣,verthoriz:╋
augroup SetColorscheme
  autocmd!
  " use nested so my colorscheme changes are loaded
  autocmd VimEnter * ++nested colorscheme nord
augroup END

" Statusline {{{2
let &laststatus = has('nvim') ? 3 : 2

let g:statusline_separator = "%#TabLineFill# %#StatusLineRightSeparator#/ %#StatusLine#"
function! MyStatusLine()
  let l:highlight = '%#StatusLine#'

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
    let l:error = l:highlight . g:statusline_separator . '%#StatusLineErrorText#' . l:error_count . ' •'
  endif
  if (l:warning_count > 0)
    let l:warning = l:highlight . g:statusline_separator . '%#StatusLineWarningText#' . l:warning_count . ' •'
  endif
  if (l:info_count > 0)
    let l:info = l:highlight. g:statusline_separator . '%#StatusLineInfoText#' . l:info_count . ' •'
  endif

  return l:highlight . ' %y%w%q%r%=' . '%=' . 'Ln %l/%L' . g:statusline_separator . 'Col %c/%{execute("echon col(\"$\") - 1")}' . l:info . l:warning . l:error . ' '
endfunction
set statusline=%{%MyStatusLine()%}

" Tabline {{{2
function! Tabline()
  let tab_count = tabpagenr('$')
  let tabline = ''

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

  " center it
  let tabline = '%=' . tabline . '%='

  return tabline
endfunction
set tabline=%!Tabline()

" Window bar {{{2
if has('nvim')
  function! CloseWindow(window_id, click_count, mouse_button, modifiers)
    " If there's more than one window open, just close the window
    if winnr('$') > 1
      let window_number = win_id2win(a:window_id)
      if (window_number > 0)
        execute printf('%dwincmd c', window_number)
      endif
      return
    endif

    " close the window and close vim if it was the last window
    q

    " go to the previous tab
    execute printf('silent! tabn %d', g:lasttab)
  endfunction

  function! WindowBar()
    let winbar_highlight = (g:actual_curwin == win_getid()) ? 'WinBar' : 'WinBarNC'
    let winbar_highlight = '%#' . winbar_highlight . '#'
    let content = ''

    " Add button to close the window
    "
    " TODO: Not sure how to get the id of the window that contains the winbar that triggered
    " a click handler from the click handler itself so I'm setting the 'minwid' section of the
    " click item to the window id. This way, the window id will be passed to the click handler
    " as the 'minwid'.
    let content .= '%' . win_getid() . '@CloseWindow@✕%X'

    let content .= ' %f'

    " Indicate file has unsaved changes
    if getbufvar(winbufnr(0), "&mod")
      let content .= '*'
    endif

    " padding
    let content = printf(' %s ', content)

    return winbar_highlight . content . '%#WinBarFill#'
  endfunction

  set winbar=%{%WindowBar()%}
endif

" Cursor {{{2
function! SetCursor()
  " Block cursor in normal mode, thin line in insert mode, and underline in replace mode
  set guicursor=n-v:block-blinkon0,o:block-blinkwait0-blinkon200-blinkoff200,i-c:ver25-blinkwait0-blinkon200-blinkoff200,r:hor20-blinkwait0-blinkon200-blinkoff200
endfunction
call SetCursor()

function! ResetCursor()
  " reset terminal cursor to blinking bar
  set guicursor=a:ver25-blinkwait0-blinkon200-blinkoff200
endfunction

augroup Cursor
  autocmd!
  autocmd VimLeave * call ResetCursor()
  autocmd VimSuspend * call ResetCursor()
  autocmd VimResume * call SetCursor()
augroup END

" Plugins {{{1
" General {{{2
Plug 'junegunn/vim-peekaboo'
  let g:peekaboo_delay = 500 " measured in milliseconds

Plug 'inkarkat/vim-CursorLineCurrentWindow'

Plug 'farmergreg/vim-lastplace'

Plug 'tmux-plugins/vim-tmux'

Plug 'tweekmonster/startuptime.vim'

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

" Colors
" Opens the OS color picker and inserts the chosen color into the buffer.
Plug 'KabbAmine/vCoolor.vim'
  " Make an alias for the 'VCoolor' command with a name that is easier to remember
  command! ColorPicker VCoolor

Plug 'junegunn/goyo.vim'
  let g:goyo_width = '90%'
  " Make an alias for the 'Goyo' command with a name that is easier to remember
  command! Prose Goyo

  function! s:goyo_enter()
    if executable('tmux') && strlen($TMUX)
      silent !tmux set status off
    endif
    set noshowmode
    set noshowcmd
    let g:asyncomplete_auto_popup = 0
    highlight clear WordUnderCursor
    highlight CursorLine cterm=NONE
    set cmdheight=0
    set winbar=
    DelimitMateSwitch
    set scrolloff=0
    imap <buffer> <CR> <CR>
    highlight clear MatchParen
  endfunction

  function! s:goyo_leave()
    if executable('tmux') && strlen($TMUX)
      silent !tmux set status on
    endif
    set showmode
    set showcmd
    let g:asyncomplete_auto_popup = 1
    set cmdheight=2
    set winbar=%{%WindowBar()%}
    DelimitMateSwitch
    set scrolloff=10
  endfunction

  augroup Goyo
    autocmd!

    autocmd User GoyoEnter ++nested call <SID>goyo_enter()
    autocmd User GoyoLeave ++nested call <SID>goyo_leave()

    " If I'm about to exit vim without turning off goyo, then turn it off now.
    " 'nested' is used so that the 'GoyoLeave' event fires
    autocmd VimLeavePre * ++nested if exists('#goyo') | Goyo | endif

    " On window resize, if goyo is active, resize the window
    autocmd VimResized * if exists('#goyo') | exe "normal \<c-w>=" | endif
  augroup END

" To get the vim help pages for vim-plug itself, you need to add it as a plugin
Plug 'junegunn/vim-plug'

" Syntax plugins for practically any language
Plug 'sheerun/vim-polyglot'

" Automatically close html tags
Plug 'alvan/vim-closetag'

" TODO: Using this so that substitutions made by vim-abolish get highlighted as I type them.
" Won't be necessary if vim-abolish adds support for neovim's `inccommand`.
" issue for `inccommand` support: https://github.com/tpope/vim-abolish/issues/107
Plug 'markonm/traces.vim'
  let g:traces_abolish_integration = 1

" Automatically insert closing braces/quotes
Plug 'Raimondi/delimitMate'
  " Given the following line (where | represents the cursor):
  "   function foo(bar) {|}
  " Pressing enter will result in:
  " function foo(bar) {
  "   |
  " }
  let g:delimitMate_expand_cr = 0

" Automatically add closing keywords (e.g. function/endfunction in vimscript)
Plug 'tpope/vim-endwise'
  let g:endwise_no_mappings = 1
  " this way endwise triggers on 'o'
  nmap o A<CR>

Plug 'tpope/vim-commentary'

" Asynchronous linting {{{2
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

" Fzf integration {{{2
Plug 'junegunn/fzf'
  let g:fzf_layout = { 'window': 'tabnew' }
  function! LoadFzfConfig()
    " In terminals you have to press <C-\> twice to send it to the terminal.
    " This mapping makes it so that I only have to press it once.
    " This way, I can use a <C-\> keybind more easily.
    tnoremap <buffer> <C-\> <C-\><C-\>

    " Hide all ui elements
    let g:fzf_old_option_values = SetOptions({
          \ '&laststatus': 0,
          \ '&showmode': 0,
          \ '&ruler': 0,
          \ '&number': 0,
          \ '&relativenumber': 0,
          \ '&showtabline': 0,
          \ '&cmdheight': 0,
          \ '&winbar': '',
          \})
    autocmd BufLeave <buffer> call SetOptions(g:fzf_old_option_values)
  endfunction
  augroup Fzf
    autocmd!
    autocmd FileType fzf call LoadFzfConfig()
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

" File explorer {{{2
Plug 'preservim/nerdtree', {'on': 'NERDTreeFind'}
  let g:NERDTreeMouseMode = 2
  let g:NERDTreeShowHidden = 1
  let g:NERDTreeStatusline = -1
  let g:NERDTreeWinPos = "right"
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
  function! CloseIfOnlyNerdtreeLeft()
    if !exists('b:NERDTree')
      return
    endif
    if tabpagewinnr(tabpagenr(), '$') != 1
      return
    endif

    if tabpagenr('$') > 1
      tabclose
    else
      execute 'q'
    endif
  endfunction
  augroup NerdTree
    autocmd!
    " open/close directories with 'h' and 'l'
    autocmd FileType nerdtree nmap <buffer> l o
    autocmd FileType nerdtree nmap <buffer> h o
    autocmd BufEnter * call CloseIfOnlyNerdtreeLeft()
  augroup END

" Autocomplete {{{2
" async autocomplete
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

" Colorscheme {{{2
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
    autocmd ColorScheme nord highlight StatusLine ctermbg=8 ctermfg=15
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
    autocmd ColorScheme nord highlight WordUnderCursor cterm=bold
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
    autocmd ColorScheme nord highlight Warning ctermfg=3 ctermbg=NONE cterm=undercurl
    autocmd ColorScheme nord highlight! link SpellBad Error
    autocmd ColorScheme nord highlight! link NvimInternalError ErrorMsg
    autocmd ColorScheme nord highlight! link ALEError Error
    autocmd ColorScheme nord highlight! link ALEWarning Warning
    autocmd ColorScheme nord highlight Folded ctermfg=15 ctermbg=NONE cterm=NONE
    autocmd ColorScheme nord highlight FoldColumn ctermfg=15 ctermbg=NONE
    autocmd ColorScheme nord highlight WinBar ctermfg=14 ctermbg=NONE cterm=reverse
    autocmd ColorScheme nord highlight WinBarNC ctermfg=15 ctermbg=NONE cterm=reverse
    autocmd ColorScheme nord highlight WinBarFill ctermfg=NONE ctermbg=NONE
  augroup END

" Post Plugin Load Operations {{{2
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
