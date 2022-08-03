" vim:foldmethod=marker

" Exit if vim is not running in a terminal. I detect this by checking if the input
" to vim is coming from a terminal (also referred to as a tty).
if !has('ttyin')
  finish
endif

" Miscellaneous {{{
set confirm
set mouse=a
set display+=lastline
let &clipboard = 'unnamedplus'
set scrolloff=10
set jumpoptions=stack

" persist undo history to disk
set undofile

augroup Miscellaneous
  autocmd!
  autocmd BufEnter *
        \ if &ft ==# 'help' && (&columns * 10) / &lines > 31 | wincmd L | endif
  autocmd FileType sh setlocal keywordprg=man
  autocmd CursorHold * execute printf('silent! 2match WordUnderCursor /\V\<%s\>/', escape(expand('<cword>'), '/\'))
  " After a quickfix command is run, open the quickfix window , if there are results
  autocmd QuickFixCmdPost [^l]* cwindow
  autocmd QuickFixCmdPost l*    lwindow
  " Put focus back in quickfix window after opening an entry
  autocmd FileType qf nnoremap <buffer> <CR> <CR><C-W>p
  " highlight trailing whitespace
  autocmd ColorScheme * highlight! link ExtraWhitespace Warning | execute 'match ExtraWhitespace /\s\+$/'
  " Start syntax highlighting from the beginning of the file. Unless it's a large file, in which case
  " don't highlight at all.
  autocmd BufWinEnter * if line2byte(line("$") + 1) > 1000000 | syntax clear | else | syntax sync fromstart | endif
  autocmd OptionSet readonly if v:option_new | setlocal colorcolumn= | endif
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

" Decide which actions to take when the enter key is pressed.
function! GetEnterKeyActions()
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

set colorcolumn=120
" }}}

" Autoreload {{{
" neovim config files
let config_files = ['init.vim']
for profile in g:profiles
  let last_filename_segment = profile->split('/', 0)[-1]
  call add(config_files, last_filename_segment)
endfor

let config_file_pattern = config_files->join(',')
execute printf(
      \ 'autocmd! bufwritepost %s ++nested source $MYVIMRC | execute "colorscheme " . trim(execute("colorscheme"))',
      \ config_file_pattern
      \ )
" }}}

" Option overrides {{{
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

function! OverridePolyglot()
  setlocal textwidth=0
endfunction

augroup Overrides
  autocmd!
  autocmd VimEnter * call OverrideVimsDefaultFiletypePlugins()
  autocmd VimEnter * call OverridePolyglot()
augroup END
" }}}

" Utilities {{{
" Display all highlight groups in a new window
command! HighlightTest so $VIMRUNTIME/syntax/hitest.vim

" Sets options to the specified new values and returns their old values.
" Useful for when you want to change an option and then restore its old value later on.
function! SetOptions(new_option_values)
  let old_option_values = {}

  for item in items(a:new_option_values)
    let option_name = item[0]
    let new_option_value = item[1]

    " store old value
    execute 'let old_option_value = ' . option_name
    let old_option_values[option_name] = old_option_value

    " set new value
    if type(new_option_value) == type("")
      " quote string values
      execute printf('let %s = "%s"', option_name, new_option_value)
    else
      execute printf('let %s = %s', option_name, new_option_value)
    endif
  endfor

  return old_option_values
endfunction
" }}}

" Windows {{{
" open new horizontal and vertical panes to the right and bottom respectively
set splitright splitbelow
nnoremap <Leader><Bar> <Cmd>vsplit<CR>
nnoremap <Leader>- <Cmd>split<CR>

" close a window, quit if last window
" also when closing a tab, go to the previously opened tab
nnoremap <silent> <expr> <leader>q  winnr('$') == 1 ? ':exe "q" <Bar> silent! tabn '.g:lasttab.'<CR>' : ':close<CR>'

" TODO: When tmux is able to differentiate between enter and ctrl+m this mapping should be updated.
" tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
"
" maximize a window by opening it in a new tab
nnoremap <silent><Leader>m <Cmd>if winnr('$') > 1 <Bar> tab sp <Bar> endif<CR>

augroup Window
  autocmd!

  " Automatically resize all splits to make them equal when the vim window is
  " resized or a new window is created/closed
  autocmd VimResized,WinNew,WinClosed,TabEnter * wincmd =
augroup END
" }}}

" Tab pages {{{
nnoremap <silent> <Leader>t <Cmd>$tabnew<CR>
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
" }}}

" Indentation {{{
set expandtab
set autoindent smartindent
set smarttab
set shiftround " Round indent to multiple of shiftwidth (applies to < and >)
let s:tab_width = 2
let &tabstop = s:tab_width
let &shiftwidth = s:tab_width
let &softtabstop = s:tab_width
" }}}

" Folds {{{
set fillchars+=foldsep:\ ,foldclose:›,foldopen:⌄,fold:\ 
" Setting this so that the fold column gets displayed
set foldenable
" When a file is opened, all folds should be open.
" Only set the foldlevel once when vim starts up
if !exists('g:foldlevel_set')
  set foldlevel=999
  let g:foldlevel_set = 1
endif
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
  autocmd FileType * setlocal foldmethod=indent
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

  let separator_text = '⋯ '
  let separator_text_length = 2

  let line_text = getline(v:foldstart)
  " indent the line relative to the foldlevel if it isn't already indented
  if line_text !~# '\v^\s+'
    let indent_count = max([0, v:foldlevel - 1])
    let indent = repeat(' ', &tabstop)
    let indent = repeat(indent, indent_count)
    let line_text = indent . line_text
  endif
  " truncate if there isn't space for the fold description and separator text
  let max_line_text_length = line_width - (fold_description_length + separator_text_length)
  if strdisplaywidth(line_text) > max_line_text_length
    let line_text = line_text[: max_line_text_length - 1]
  endif
  let line_text_length = strdisplaywidth(line_text)

  return line_text . separator_text . fold_description
endfunction
" }}}

" Autocomplete {{{
set complete=.,w,b,u
" - show the completion menu even if there is only one suggestion
" - when autocomplete gets triggered, no suggestion is selected
set completeopt=menu,menuone,noselect
" }}}

" Command line {{{
" on first wildchar press (<Tab>), show all matches and complete the longest common substring among them.
" on subsequent wildchar presses, cycle through matches
set wildmode=longest:full,full
set wildoptions=pum
set cmdheight=2
cnoreabbrev <expr> h getcmdtype() == ":" && getcmdline() == 'h' ? 'tab help' : 'h'
" }}}

" Search {{{
set nohlsearch
" show match position in command window, don't show 'Search hit BOTTOM/TOP'
set shortmess-=S shortmess+=s
" toggle search highlighting
nnoremap <silent> <Leader>\ <Cmd>set hlsearch!<CR>
" }}}

" Sessions {{{
set sessionoptions-=blank sessionoptions-=options sessionoptions+=tabpages sessionoptions+=folds
let s:session_dir = g:data_path . '/sessions'
call mkdir(s:session_dir, "p")

function! RestoreOrCreateSession()
  " We omit the first element in the list since that will always be the path to the vim executable
  if v:argv[1:]->empty()
    let session_name =  substitute($PWD, '/', '%', 'g') . '%vim'
    let session_full_path = s:session_dir . '/' . session_name
    let session_cmd = filereadable(session_full_path) ? "source " : "mksession! "
    execute session_cmd . fnameescape(session_full_path)
    let s:session_active = 1
  endif
endfunction

function! SaveSession()
  if exists("s:session_active") && !empty(v:this_session)
    execute 'mksession! ' . fnameescape(v:this_session)
  endif
endfunction

augroup SaveAndRestoreSettings
  autocmd!
  " Restore session after vim starts. The 'nested' keyword tells vim to fire events
  " normally while this autocmd is executing. By default, no events are fired
  " during the execution of an autocmd to prevent infinite loops.
  autocmd VimEnter * ++nested call RestoreOrCreateSession()
  " save session before vim exits
  autocmd VimLeavePre * call SaveSession()
augroup END
" }}}

" Aesthetics {{{

" Miscellaneous {{{
set linebreak
set number relativenumber
set cursorline cursorlineopt=number,screenline
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
" }}}

" Statusline {{{
set laststatus=3

function! MyStatusLine()
  let item_separator = '%#StatusLineSeparator# ∙ '

  let line = '%#StatusLine#Ln %l/%L'
  let column = '%#StatusLine#Col %c/%{execute("echon col(\"$\") - 1")}'
  let position = line . ', ' . column

  if getbufvar(bufnr('%'), "&mod")
    let modified_indicator = '*'
  else
    let modified_indicator = ''
  endif
  let file_info = '%#StatusLine#%y %t' . modified_indicator . '%w%q'

  if &fileformat !=# 'unix'
    let fileformat = printf('%%#StatusLineStandoutText#[%s]', &fileformat)
  endif

  if &readonly
    let readonly = '%#StatusLineStandoutText#[RO]'
  endif

  function! OpenDiagnosticWindow(minimum_width, mouse_click_count, mouse_button, modifiers)
    if exists(':TroubleToggle')
      TroubleToggle
    endif
  endfunction
  function! GetDiagnosticCountForSeverity(severity)
    return v:lua.vim.diagnostic.get(0, {'severity': a:severity})->len()
  endfunction
  let diagnostic_count = {
        \ 'warning': GetDiagnosticCountForSeverity('warn'),
        \ 'error': GetDiagnosticCountForSeverity('error'),
        \ 'info': GetDiagnosticCountForSeverity('info'),
        \ 'hint': GetDiagnosticCountForSeverity('hint')
        \ }
  let diagnostic_list = []
  let error_count = diagnostic_count.error
  if (error_count > 0)
    let error = '%#StatusLineErrorText#' . 'ⓧ '. error_count
    call add(diagnostic_list, error)
  endif
  let warning_count = diagnostic_count.warning
  if (warning_count > 0)
    let warning = '%#StatusLineWarningText#' . '⚠ ' . warning_count
    call add(diagnostic_list, warning)
  endif
  let info_count = diagnostic_count.info
  if (info_count > 0)
    let info = '%#StatusLineInfoText#' . 'ⓘ ' . info_count
    call add(diagnostic_list, info)
  endif
  let hint_count = diagnostic_count.hint
  if (hint_count > 0)
    let hint = '%#StatusLineHintText#' . 'ⓗ ' . hint_count
    call add(diagnostic_list, hint)
  endif
  if !empty(diagnostic_list)
    let diagnostics = diagnostic_list->join(' ')
    let diagnostics = '%@OpenDiagnosticWindow@' . diagnostics . '%X'
  endif

  let left_side_items = [file_info]
  if exists('fileformat')
    call add(left_side_items, fileformat)
  endif
  if exists('readonly')
    call add(left_side_items, readonly)
  endif
  let left_side = left_side_items->join(' ')

  let right_side_items = [position]
  if exists('diagnostics')
    call add(right_side_items, diagnostics)
  endif
  let right_side = right_side_items->join(item_separator)

  let statusline_separator = '%#StatusLine#%='
  let padding = '%#StatusLine# '

  return padding . left_side . statusline_separator . right_side . padding
endfunction
set statusline=%{%MyStatusLine()%}
" }}}

" Tabline {{{
function! Tabline()
  let tab_count = tabpagenr('$')
  let tabline = ''
  let left_divider_char = '▎'
  let right_divider_char = '🮇'

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
    let separator_highlight = (tab == tabpagenr() ? '%#TabLineSeparator#' : '%#TabLineSeparatorNC#')
    let tabline .= separator_highlight . left_divider_char . '  ' . highlight . bufname . '  '
    if i < tab_count - 1
      let tabline .= ' %#StatusLineSeparator#' . highlight
    endif
  endfor
  let last_tab_number = tab_count
  let last_separator_highlight = (last_tab_number == tabpagenr() ? '%#TabLineLastSeparator#' : '%#TabLineLastSeparatorNC#')
  let tabline .= last_separator_highlight . right_divider_char . '%#TabLineFill#'

  return tabline
endfunction
set tabline=%!Tabline()
" }}}

" Cursor {{{
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
" }}}

" }}}

" Diagnostics {{{
lua << EOF
vim.diagnostic.config({
  virtual_text = false,
  signs = {
    -- Make it high enough to have priority over vim-signify
    priority = 11,
  },
  update_in_insert = true,
  severity_sort = true,
  float = {
    source = "if_many",
  },
})

local bullet = '•'
local signs = { Error = bullet, Warn = bullet, Hint = bullet, Info = bullet }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

function PrintDiagnostics(opts, bufnr, line_nr, client_id)
  bufnr = bufnr or 0
  line_nr = line_nr or (vim.api.nvim_win_get_cursor(0)[1] - 1)
  opts = opts or {['lnum'] = line_nr}

  local line_diagnostics = vim.diagnostic.get(bufnr, opts)
  if vim.tbl_isempty(line_diagnostics) then
    return
  end

  local line_limit = vim.o.columns * vim.o.cmdheight
  local diagnostic_message = ""
  for i, diagnostic in ipairs(line_diagnostics) do
    current_message = string.format("%d: %s (%s)", i, diagnostic.message or "", diagnostic.code or "")
    -- prevent the 'press enter to continue' message by making sure the message fits
    current_message = string.sub(current_message, 1, line_limit)

    diagnostic_message = diagnostic_message .. current_message
    print(diagnostic_message)

    -- only use the first item
    break
  end

  vim.api.nvim_echo({{diagnostic_message, "Normal"}}, false, {})
end
vim.cmd [[ autocmd! CursorHold * lua PrintDiagnostics() ]]
EOF
" }}}

" Plugins {{{

" Miscellaneous {{{
Plug 'junegunn/vim-peekaboo'
  let g:peekaboo_delay = 500 " measured in milliseconds

Plug 'inkarkat/vim-CursorLineCurrentWindow'

Plug 'farmergreg/vim-lastplace'

Plug 'tmux-plugins/vim-tmux'

Plug 'tweekmonster/startuptime.vim'

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
  let g:signify_sign_add               = '│'
  let g:signify_sign_change            = '│'
  let g:signify_sign_show_count = 0

" Colors
" Opens the OS color picker and inserts the chosen color into the buffer.
Plug 'KabbAmine/vCoolor.vim'
  let g:vcoolor_disable_mappings = 1

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

" Use the ANSI OSC52 sequence to copy text to the system clipboard
Plug 'ojroques/vim-oscyank', {'branch': 'main'}
  let g:oscyank_silent = 1
  augroup VimOscyank
    autocmd!
    autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '+' && (!empty($SSH_CLIENT) || !empty($SSH_TTY)) | execute 'OSCYankReg +' | endif
  augroup END

Plug 'lukas-reineke/virt-column.nvim'
  function! SetupVirtColumn()
    lua << EOF
    require("virt-column").setup { char = "│" }
EOF

    execute 'VirtColumnRefresh!'
    autocmd WinEnter,VimResized * VirtColumnRefresh!
  endfunction
  autocmd VimEnter * call SetupVirtColumn()

" lua library specfically for use in neovim
" DEPENDED_ON_BY: null-ls.nvim, telescope.nvim
Plug 'nvim-lua/plenary.nvim'

Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }

Plug 'nvim-telescope/telescope.nvim', { 'branch': '0.1.x' }
  function! SetupTelescope()
    lua << EOF
    telescope = require('telescope')
    actions = require('telescope.actions')

    telescope.setup({
      defaults = {
        mappings = {
          i = {
            ["<Esc>"] = actions.close,
            ["<Tab>"] = actions.move_selection_next,
            ["<S-Tab>"] = actions.move_selection_previous,
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-n>"] = actions.cycle_history_next,
          },
        },
      },
    })
EOF
  endfunction
  autocmd VimEnter * call SetupTelescope()

" RECOMMENDED_BY: mason.nvim (for the language filter)
Plug 'stevearc/dressing.nvim'
  function! SetupDressing()
    lua << EOF
    require('dressing').setup({
      select = {
        telescope = {
          layout_config = {
            width = 0.6,
            height = 0.6,
          },
          layout_strategy = 'center',
          sorting_strategy = 'ascending'
        },
      },
    })
EOF
  endfunction
  autocmd VimEnter * call SetupDressing()
" }}}

" Prose {{{
Plug 'junegunn/goyo.vim'
  let g:goyo_width = '90%'

  function! s:goyo_enter()
    if executable('tmux') && strlen($TMUX)
      silent !tmux set status off
    endif
    let g:goyo_old_option_values = SetOptions({
          \ '&showmode': 0,
          \ '&showcmd': 0,
          \ '&cmdheight': 0,
          \ '&winbar': '',
            \})
    function! GoyoSetHighlights()
      highlight clear WordUnderCursor
      highlight CursorLine cterm=NONE
      highlight clear MatchParen
      highlight FoldColumn ctermbg=NONE ctermfg=15
    endfunction
    call GoyoSetHighlights()
    " In case the colorscheme gets set after I set highlights this will set them again
    autocmd Colorscheme <buffer> call GoyoSetHighlights()
    silent! DelimitMateSwitch
    setlocal scrolloff=0
    setlocal conceallevel=2
    setlocal concealcursor=nvic
    syn match listItem "^\s*[-*]\s\+" contains=listBullet
    syn match listBullet "[-*]" contained conceal cchar=•
    syn match headerUnderline "[-=][-=][-=][-=][-=][-=]*" contains=headerUnderlineDash
    syn match headerUnderlineDash "[-=]" contained conceal cchar=―
    syn match emDash "\s\+--\s\+" contains=emDashSingleDash
    syn match emDashSingleDash "-" contained conceal cchar=―
    nnoremap <buffer> <silent> p p
    vnoremap <buffer> <silent> p p
    setlocal breakindent
    let &breakindentopt = 'shift:' . &tabstop
    function! GetBulletAction()
      let line = getline('.')

      " Insert a newline before the bullet
      if line =~# '^\s*[-*]\s\+$'
        return "\<Esc>\<S-o>\<Esc>j\<S-a>"
      endif

      " Create a bullet on the next line
      if line =~# '^\s*[-*]\s\+.*'
        let bullet_character = line->stridx('-') != -1 ? "-" : "*"
        return "\<CR>" . bullet_character . "\<Space>"
      endif

      return "\<CR>"
    endfunction
    inoremap <buffer> <expr> <CR> GetBulletAction()
    setlocal foldlevel=0
    setlocal foldmethod=marker
    inoremap <buffer> <Tab> <C-t>
    inoremap <buffer> <S-Tab> <C-d>
  endfunction

  function! s:goyo_leave()
    if executable('tmux') && strlen($TMUX)
      silent !tmux set status on
    endif
    call SetOptions(g:goyo_old_option_values)
    silent! DelimitMateSwitch
    silent! SignifyEnableAll
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

    " Auto activate for files ending in '.txt'
    autocmd VimEnter * if @% =~# '.txt$' | execute 'Goyo' | endif
  augroup END
" }}}

" Fzf integration {{{
Plug 'junegunn/fzf'
  let g:fzf_layout = { 'window': 'tabnew' }
  function! IsFloatingWindow()
    let window_config = nvim_win_get_config(0)
    return !empty(window_config.relative) || window_config.external
  endfunction
  function! LoadFzfConfig()
    " In terminals you have to press <C-\> twice to send it to the terminal.
    " This mapping makes it so that I only have to press it once.
    " This way, I can use a <C-\> keybind more easily.
    tnoremap <buffer> <C-\> <C-\><C-\>

    " Prevent entering normal mode in the terminal
    autocmd ModeChanged <buffer> if mode(1) =~# '\v^nt' | startinsert | endif

    " If fzf is the only window in the current tab, hide all ui elements, otherwise customize them.
    if tabpagewinnr(tabpagenr(), '$') == 1
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
            \ '&colorcolumn': '',
            \ })

      " Restore old option values after leaving fzf
      autocmd BufLeave <buffer> call SetOptions(g:fzf_old_option_values)
    else
      autocmd! User FzfStatusLine setlocal statusline=%#StatusLine#\ fzf
    endif
  endfunction
  augroup Fzf
    autocmd!
    autocmd FileType fzf call LoadFzfConfig()
  augroup END
  " Collection of fzf-based commands
  Plug 'junegunn/fzf.vim'
    nnoremap <silent> <Leader>h <Cmd>History:<CR>
    nnoremap <silent> <Leader>b <Cmd>Buffers<CR>
    nnoremap <silent> <Leader>/ <Cmd>Commands<CR>
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
" }}}

" File explorer {{{
Plug 'preservim/nerdtree'
  let g:NERDTreeMouseMode = 2
  let g:NERDTreeShowHidden = 1
  let g:NERDTreeStatusline = -1
  let g:NERDTreeMinimalUI=1
  let g:NERDTreeAutoDeleteBuffer=0
  let g:NERDTreeHijackNetrw=1
  function! NerdTreeToggle()
    " NERDTree is open so close it.
    if g:NERDTree.IsOpen()
      silent execute 'NERDTreeToggle'
      return
    endif

    " If NERDTree can't find the current file, it prints an error and doesn't open NERDTree.
    " In which case, I'll call 'NERDTree' which opens NERDTree to the current directory.
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
    autocmd FileType nerdtree setlocal winbar=%#NerdTreeWinBar#%=Press\ ?\ for\ help%=
    autocmd BufEnter * call CloseIfOnlyNerdtreeLeft()
  augroup END
" }}}

" Autocomplete {{{
Plug 'hrsh7th/nvim-cmp'
  function! SetupNvimCmp()
    lua << EOF
    local cmp = require("cmp")

    -- sources
    local buffer = {
      name = 'buffer',
      option = {
        keyword_length = 2,
        get_bufnrs = function()
          local buf = vim.api.nvim_get_current_buf()
          local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
          if byte_size > 1024 * 1024 then -- 1 Megabyte max
            return {}
          end

          return { buf }
        end,
      },
    }
    local nvim_lsp = { name = 'nvim_lsp' }
    local omni = { name = 'omni' }
    local path = {
      name = 'path',
      option = {
        get_cwd = function(params)
          return vim.fn.getcwd()
        end,
      },
    }
    local nvim_lua = { name = 'nvim_lua' }
    local tmux = {
      name = 'tmux',
      option = { all_panes = true },
    }
    local cmdline = { name = 'cmdline' }
    local cmdline_history = { name = 'cmdline_history' }

    -- views
    local wildmenu = {
      entries = {
        name = 'wildmenu',
        separator = '|',
      },
    }

    -- helpers
    local is_cursor_preceded_by_nonblank_character = function()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
    end

    cmp.setup({
      mapping = cmp.mapping.preset.insert({
        ['<C-a>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif is_cursor_preceded_by_nonblank_character() then
            cmp.complete()
          else
            fallback()
          end
        end, { 'i', 's' }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end, { 'i', 's' }),
      }),
      sources = cmp.config.sources(
        {
          nvim_lsp,
          buffer,
          omni,
          path,
          nvim_lua,
          tmux,
        }
      )
    })

    -- TODO: Until I can reposition the completion window vertically, it will cover my cmdline
    -- issue: https://github.com/hrsh7th/nvim-cmp/issues/908
    -- cmp.setup.cmdline(
    --   '/',
    --   {
    --     view = wildmenu,
    --     mapping = cmp.mapping.preset.cmdline(),
    --     sources = {
    --       buffer,
    --       cmdline_history,
    --     }
    --   }
    -- )
    -- cmp.setup.cmdline(
    --   ':',
    --   {
    --     view = wildmenu,
    --     mapping = cmp.mapping.preset.cmdline(),
    --     sources = cmp.config.sources(
    --       {
    --         path,
    --         cmdline,
    --         buffer,
    --         cmdline_history,
    --       }
    --     )
    --   }
    -- )
    -- cmp.setup.cmdline(
    --   '?',
    --   {
    --     view = wildmenu,
    --     mapping = cmp.mapping.preset.cmdline(),
    --     sources = cmp.config.sources(
    --       {
    --         buffer,
    --         cmdline_history,
    --       }
    --     )
    --   }
    -- )
EOF
  endfunction
  autocmd VimEnter * call SetupNvimCmp()

Plug 'hrsh7th/cmp-omni'

Plug 'hrsh7th/cmp-cmdline'

Plug 'dmitmel/cmp-cmdline-history'

Plug 'andersevenrud/cmp-tmux'

Plug 'hrsh7th/cmp-nvim-lua'

Plug 'hrsh7th/cmp-buffer'

Plug 'hrsh7th/cmp-nvim-lsp'

Plug 'hrsh7th/cmp-path'
" }}}

" Tool Manager {{{
Plug 'williamboman/mason.nvim'
  function! SetupMason()
    lua << EOF
    require("mason").setup({
      ui = {
        icons = {
          package_installed = "●",
          package_pending = "⧖",
          package_uninstalled = "○"
        }
      },
      log_level = vim.log.levels.DEBUG,
    })
EOF
  endfunction
  autocmd VimEnter * call SetupMason()

Plug 'williamboman/mason-lspconfig.nvim'
  function! SetupMasonLspConfig()
    lua << EOF
    require("mason-lspconfig").setup()

    local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
    require("mason-lspconfig").setup_handlers({
      -- Default handler to be called for each installed server that doesn't have a dedicated handler.
      function (server_name)
        require("lspconfig")[server_name].setup({
          capabilities = capabilities,
        })
      end,
      ["jsonls"] = function()
        require("lspconfig").jsonls.setup({
          capabilities = capabilities,
          settings = {
            json = {
              schemas = require('schemastore').json.schemas(),
              validate = { enable = true },
            },
          },
        })
      end,
    })
EOF
  endfunction
  autocmd VimEnter * call SetupMasonLspConfig()

Plug 'neovim/nvim-lspconfig'
  function! SetupNvimLspconfig()
    LspStart
    autocmd WinEnter * LspStart
  endfunction
  autocmd VimEnter * call SetupNvimLspconfig()

Plug 'b0o/schemastore.nvim'
" }}}

" Diagnostics {{{
Plug 'folke/trouble.nvim'
  function! SetupTrouble()
    lua << EOF
    require("trouble").setup({
      icons = false,
      mode = "document_diagnostics",
      fold_open = "⌄",
      fold_closed = "›",
      indent_lines = false,
      auto_close = true,
      auto_preview = false,
      signs = {
        error = "error:",
        warning = "warning:",
        hint = "hint:",
        information = "info:",
        other = "other:"
      },
      use_diagnostic_signs = false
    })
EOF
  endfunction
  autocmd VimEnter * call SetupTrouble()
" }}}

" CLI -> LSP {{{
" A language server that acts as a bridge between neovim's language server client and commandline tools that don't
" support the language server protocol. It does this by transforming the output of a commandline tool into the
" format specified by the language server protocol.
Plug 'jose-elias-alvarez/null-ls.nvim'
  function! SetupNullLs()
    lua << EOF
    local null_ls = require('null-ls')
    local builtins = null_ls.builtins
    null_ls.setup({
      sources = {
        builtins.diagnostics.shellcheck.with({
          filetypes = { 'sh', 'bash' }
        }),
        builtins.diagnostics.fish,
        builtins.diagnostics.markdownlint,
      }
    })
EOF
  endfunction
  autocmd VimEnter * call SetupNullLs()
" }}}

" Colorscheme {{{
Plug 'arcticicestudio/nord-vim'
  let g:nord_bold = 1
  let g:nord_italic = 1
  let g:nord_italic_comments = 1
  let g:nord_underline = 1
  augroup NordColorschemeOverrides
    autocmd!
    autocmd ColorScheme nord highlight MatchParen ctermfg=blue cterm=underline ctermbg=NONE
    " Transparent vertical split
    autocmd ColorScheme nord highlight VertSplit ctermbg=NONE ctermfg=8
    " statusline colors
    autocmd ColorScheme nord highlight StatusLine ctermbg=8 ctermfg=NONE
    autocmd ColorScheme nord highlight StatusLineSeparator ctermfg=8 ctermbg=NONE cterm=reverse,bold
    autocmd ColorScheme nord highlight StatusLineErrorText ctermfg=1 ctermbg=8
    autocmd ColorScheme nord highlight StatusLineWarningText ctermfg=3 ctermbg=8
    autocmd ColorScheme nord highlight StatusLineInfoText ctermfg=4 ctermbg=8
    autocmd ColorScheme nord highlight StatusLineHintText ctermfg=5 ctermbg=8
    autocmd ColorScheme nord highlight StatusLineStandoutText ctermfg=3 ctermbg=8
    " autocomplete popupmenu
    autocmd ColorScheme nord highlight PmenuSel ctermfg=14 ctermbg=NONE cterm=reverse
    autocmd ColorScheme nord highlight Pmenu ctermfg=NONE ctermbg=8
    autocmd ColorScheme nord highlight PmenuThumb ctermfg=NONE ctermbg=15
    autocmd ColorScheme nord highlight PmenuSbar ctermbg=8
    autocmd ColorScheme nord highlight CursorLine ctermfg=NONE ctermbg=NONE cterm=underline
    " transparent background
    autocmd ColorScheme nord highlight Normal ctermbg=NONE
    autocmd ColorScheme nord highlight EndOfBuffer ctermbg=NONE
    " relative line numbers
    autocmd ColorScheme nord highlight LineNr ctermfg=15
    autocmd ColorScheme nord highlight LineNrAbove ctermfg=15
    autocmd ColorScheme nord highlight! link LineNrBelow LineNrAbove
    autocmd ColorScheme nord highlight WordUnderCursor ctermbg=8
    " The highlight I use for the word under the cursor and text selected in visual mode is the same.
    " This will disable the highlighting for the word under the cursor while I'm in visual mode.
    function! DisableWordUnderCursorHighlight()
      if mode(1) =~# '\v^(v|)'
        highlight WordUnderCursor ctermbg=NONE
        " When I leave visual mode, enable WordUnderCursor highlighting
        autocmd ModeChanged * ++once if mode(1) !~# '\v^(v|)' | highlight WordUnderCursor ctermbg=8 | endif
      endif
    endfunction
    autocmd ModeChanged * call DisableWordUnderCursorHighlight()
    autocmd ColorScheme nord highlight! link IncSearch Search
    autocmd ColorScheme nord highlight TabLine ctermbg=8 ctermfg=7
    autocmd ColorScheme nord highlight TabLineSel ctermbg=NONE ctermfg=7
    autocmd ColorScheme nord highlight TabLineFill ctermbg=8
    autocmd ColorScheme nord highlight TabLineSeparator ctermbg=NONE ctermfg=14
    autocmd ColorScheme nord highlight TabLineSeparatorNC ctermbg=8 ctermfg=15
    autocmd ColorScheme nord highlight TabLineLastSeparator ctermbg=NONE ctermfg=15
    autocmd ColorScheme nord highlight TabLineLastSeparatorNC ctermbg=8 ctermfg=15
    autocmd ColorScheme nord highlight Comment ctermfg=15 ctermbg=NONE
    " This variable contains a list of 16 colors that should be used as the color palette for terminals opened in vim.
    " By unsetting this, I ensure that terminals opened in vim will use the colors from the color palette of the
    " terminal in which vim is running
    autocmd ColorScheme nord if exists('g:terminal_ansi_colors') | unlet g:terminal_ansi_colors | endif
    " Have vim only use the colors from the 16 color palette of the terminal in which it runs
    autocmd ColorScheme nord set t_Co=256
    autocmd ColorScheme nord highlight Visual ctermbg=8
    " Search hit
    autocmd ColorScheme nord highlight Search ctermfg=DarkYellow ctermbg=NONE cterm=reverse
    " Parentheses
    autocmd ColorScheme nord highlight Delimiter ctermfg=NONE ctermbg=NONE
    autocmd ColorScheme nord highlight ErrorMsg ctermfg=1 ctermbg=NONE cterm=bold
    autocmd ColorScheme nord highlight WarningMsg ctermfg=3 ctermbg=NONE cterm=bold
    autocmd ColorScheme nord highlight Error ctermfg=1 ctermbg=NONE cterm=undercurl
    autocmd ColorScheme nord highlight Warning ctermfg=3 ctermbg=NONE cterm=undercurl
    autocmd ColorScheme nord highlight! link SpellBad Error
    autocmd ColorScheme nord highlight! link NvimInternalError ErrorMsg
    autocmd ColorScheme nord highlight Folded ctermfg=15 ctermbg=8 cterm=NONE
    autocmd ColorScheme nord highlight FoldColumn ctermfg=15 ctermbg=NONE
    autocmd ColorScheme nord highlight SpecialKey ctermfg=13 ctermbg=NONE
    autocmd ColorScheme nord highlight NonText ctermfg=15 ctermbg=NONE
    autocmd ColorScheme nord highlight NerdTreeWinBar ctermfg=15 ctermbg=NONE cterm=italic
    autocmd ColorScheme nord highlight! link VirtColumn VertSplit
    autocmd ColorScheme nord highlight DiagnosticSignError ctermfg=1 ctermbg=NONE
    autocmd ColorScheme nord highlight DiagnosticSignWarn ctermfg=3 ctermbg=NONE
    autocmd ColorScheme nord highlight DiagnosticSignInfo ctermfg=1 ctermbg=NONE
    autocmd ColorScheme nord highlight DiagnosticSignHint ctermfg=5 ctermbg=NONE
    autocmd ColorScheme nord highlight! link DiagnosticUnderlineError Error
    autocmd ColorScheme nord highlight! link DiagnosticUnderlineWarn Warning
    autocmd ColorScheme nord highlight DiagnosticUnderlineInfo ctermfg=1 ctermbg=NONE cterm=undercurl
    autocmd ColorScheme nord highlight DiagnosticUnderlineHint ctermfg=5 ctermbg=NONE cterm=undercurl
    autocmd ColorScheme nord highlight! CmpItemAbbrMatch ctermbg=NONE ctermfg=6
    autocmd ColorScheme nord highlight! link CmpItemAbbrMatchFuzzy CmpItemAbbrMatch
    autocmd ColorScheme nord highlight! CmpItemKindVariable ctermbg=NONE ctermfg=15
    autocmd ColorScheme nord highlight! link CmpItemKindInterface CmpItemKindVariable
    autocmd ColorScheme nord highlight! link CmpItemKindText CmpItemKindVariable
    autocmd ColorScheme nord highlight! link CmpItemKindFunction CmpItemKindVariable
    autocmd ColorScheme nord highlight! link CmpItemKindMethod CmpItemKindVariable
    autocmd ColorScheme nord highlight! link CmpItemKindKeyword CmpItemKindVariable
    autocmd ColorScheme nord highlight! link CmpItemKindProperty CmpItemKindVariable
    autocmd ColorScheme nord highlight! link CmpItemKindUnit CmpItemKindVariable
    autocmd ColorScheme nord highlight! link CmpItemKindSnippet CmpItemKindVariable
    autocmd ColorScheme nord highlight! link CmpItemKindOperator CmpItemKindVariable
    autocmd ColorScheme nord highlight! TelescopeBorder ctermbg=NONE ctermfg=0
    autocmd ColorScheme nord highlight! TelescopePromptTitle ctermbg=NONE ctermfg=5 cterm=reverse
    autocmd ColorScheme nord highlight! TelescopeMatching ctermbg=NONE ctermfg=6
    autocmd ColorScheme nord highlight! TelescopeSelectionCaret ctermbg=8 ctermfg=8
  augroup END
" }}}

" Plugin Management {{{
" Helpers
let g:snapshot_file = g:data_path . '/vim-plug-snapshot.vim'
function! CreateSnapshotSync()
  execute printf('PlugSnapshot! %s', g:snapshot_file)

  " Edit the snapshot file so that it updates plugins synchronously
  execute "silent! !sed --in-place --follow-symlinks 's/PlugUpdate\\!/PlugUpdate\\! --sync/g' " . g:snapshot_file
endfunction
function! UpdateAndSnapshotSync()
  PlugUpdate --sync
  call CreateSnapshotSync()
endfunction
command! PlugUpdateAndSnapshot call UpdateAndSnapshotSync()
function! PlugRestore()
  if !filereadable(g:snapshot_file)
    echoerr printf("Restore failed. Unable to read the snapshot file '%s'", g:snapshot_file)
    return
  endif
  execute printf('source %s', g:snapshot_file)
endfunction
command! PlugRestore call PlugRestore()

" Install any plugins that have been registered, but aren't installed
function! InstallMissingPlugins()
  let plugs = get(g:, 'plugs', {})
  let missing_plugins = filter(deepcopy(plugs), {plugin_name, plugin_info -> !isdirectory(plugin_info.dir)})
  if empty(missing_plugins)
    return
  endif

  let install_prompt = "The following plugins are not installed:\n" . join(keys(missing_plugins), ", ") . "\nWould you like to install them?"
  let should_install = confirm(install_prompt, "yes\nno") == 1
  if should_install
    if filereadable(g:snapshot_file)
      " Sourcing the snapshot will set plugins to the commit specified in the snapshot
      " and install any missing ones.
      execute printf('source %s', g:snapshot_file)

      " Any plugins that don't have a commit specified must not be in the snapshot.
      " In which case, we'll make a new snapshot.
      let plugins_without_commit = filter(deepcopy(plugs), {plugin_name, plugin_info -> !has_key(plugin_info, 'commit')})
      if !empty(plugins_without_commit)
        call CreateSnapshotSync()
      endif
    else
      PlugInstall --sync
    endif
  endif
endfunction

" If it's been more than a month, update plugins
function! MonthlyPluginUpdate()
  if !filereadable(g:snapshot_file)
    return
  endif

  let last_modified_time = system(printf('date --reference %s +%%s', g:snapshot_file))
  let current_time = system('date +%s')
  let time_since_last_update = current_time - last_modified_time
  if time_since_last_update < 2592000
    return
  endif

  let update_prompt = "You haven't updated your plugins in over a month, would you like to update them now?"
  let should_update = confirm(update_prompt, "yes\nno") == 1
  if should_update
    PlugUpgrade
    call UpdateAndSnapshotSync()
  endif
endfunction

augroup PostPluginLoadOperations
  autocmd!
  autocmd User PlugEndPost call InstallMissingPlugins() | call MonthlyPluginUpdate()
augroup END
" }}}

" }}}
