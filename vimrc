""" Section: This Stuff Should Stay at the Top
set nocompatible
let $VIMHOME = $HOME . '/.vim/'
let g:mapleader = "\<Space>"
" if 'encoding' is set, 'scriptencoding' must be set after it
set encoding=utf8 | scriptencoding utf-8

""" Section: Plugins
"""" Plugin Manager Settings
" Install vim-plug if not found
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
  \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

"""" Start Plugin Manager
call plug#begin('~/.vim/plugged')

"""" General
" Syntax plugins for practically any language
Plug 'sheerun/vim-polyglot'
" Split/join lines, adding/removing language-specific continuation characters as necessary
Plug 'AndrewRadev/splitjoin.vim'
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
" Applies editorconfig settings to vim
Plug 'editorconfig/editorconfig-vim'
" Dim inactive windows
Plug 'TaDaa/vimade'
  " Enabling this so that 'incsearch' highlighting works
  let g:vimade = {'usecursorhold': 1}
  " Quickpick windows should never be dimmed
  augroup Vimade
    autocmd!
    autocmd FileType quickpick :VimadeWinDisable
    autocmd FileType quickpick-filter :VimadeWinDisable
  augroup END

"""" Coordination between plugins
""""" asyncomplete, delimitmate, vim-endwise
" Combine enter key (<CR>) mappings from my plugins
imap <expr> <CR>
  \ pumvisible() ?
    \ asyncomplete#close_popup() :
    \ delimitMate#WithinEmptyPair() ?
      \ "\<C-R>=delimitMate#ExpandReturn()\<CR>" :
      \ "\<CR>\<Plug>DiscretionaryEnd"

"""" Autocomplete
Plug 'prabirshrestha/asyncomplete.vim'
  let g:asyncomplete_auto_completeopt = 0
  let g:asyncomplete_auto_popup = 0
  let g:asyncomplete_min_chars = 4
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
  Plug 'prabirshrestha/asyncomplete-buffer.vim'
    let g:asyncomplete_buffer_clear_cache = 0
    autocmd User asyncomplete_setup
      \ call asyncomplete#register_source(asyncomplete#sources#buffer#get_source_options({
      \ 'name': 'buffer',
      \ 'allowlist': ['*'],
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
  " TODO this doesn't insert correctly, at least in python, need to fix
  " Plug 'yami-beta/asyncomplete-omni.vim'
  " autocmd User asyncomplete_setup
  "     \ call asyncomplete#register_source(asyncomplete#sources#omni#get_source_options({
  "     \ 'name': 'omni',
  "     \ 'allowlist': ['*'],
  "     \ 'completor': function('asyncomplete#sources#omni#completor'),
  "     \ 'config': {
  "     \   'show_source_kind': 1,
  "     \ },
  "     \ }))
  Plug 'Shougo/neco-vim'
    Plug 'prabirshrestha/asyncomplete-necovim.vim'
    autocmd User asyncomplete_setup
        \ call asyncomplete#register_source(asyncomplete#sources#necovim#get_source_options({
        \ 'name': 'necovim',
        \ 'allowlist': ['vim'],
        \ 'completor': function('asyncomplete#sources#necovim#completor'),
        \ }))

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
" Swap a piece of text for one of its specified replacements. For example, calling swap on
" the logical operator '&&' would change it to '||'.
Plug 'AndrewRadev/switch.vim'
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
  noremap <silent> <C-Left> :TmuxNavigateLeft<cr>
  noremap <silent> <C-Right> :TmuxNavigateRight<cr>
  noremap <silent> <C-Down> :TmuxNavigateDown<cr>
  noremap <silent> <C-Up> :TmuxNavigateUp<cr>
" Visualizes indentation. Useful for fixing incorrectly indented lines.
Plug 'Yggdroot/indentLine'
  let g:indentLine_char = '▏'
  let g:indentLine_setColors = 0
  let g:indentLine_enabled = 0
" Add icons to the gutter to signify version control changes (e.g. new lines, modified lines, etc.)
Plug 'mhinz/vim-signify'
  nnoremap <Leader>vk :SignifyHunkDiff<CR>
" The author said this is experimental so I'll pin a commit to avoid breaking changes
Plug 'prabirshrestha/quickpick.vim', {'commit': '3d4d574d16d2a6629f32e11e9d33b0134aa1e2d9'}
  function! QuickpickMappings()
    " move next
    imap <silent> <buffer> <Down> <Plug>(quickpick-move-next)
    nmap <silent> <buffer> <Down> <Plug>(quickpick-move-next)
    imap <silent> <buffer> <Tab> <Plug>(quickpick-move-next)
    nmap <silent> <buffer> <Tab> <Plug>(quickpick-move-next)
    " move previous
    imap <silent> <buffer> <Up> <Plug>(quickpick-move-previous)
    nmap <silent> <buffer> <Up> <Plug>(quickpick-move-previous)
    imap <silent> <buffer> <S-Tab> <Plug>(quickpick-move-previous)
    nmap <silent> <buffer> <S-Tab> <Plug>(quickpick-move-previous)
  endfunction
  call sign_define("quickpick_cursor", {'text': '> ', 'texthl': 'Normal'})
  augroup Quickpick
    autocmd!
    autocmd ColorScheme *
          \ highlight QuickpickInvisibleStatusLine ctermbg=NONE ctermfg=8
    autocmd FileType quickpick
          \ setlocal cursorline |
          \ setlocal cursorlineopt=line |
          \ setlocal statusline=%#QuickpickInvisibleStatusLine#
    autocmd FileType quickpick-filter
          \ call QuickpickMappings() |
          \ call sign_place(0, '', 'quickpick_cursor', 'quickpick-filter', {'lnum': 1})
  augroup END

"""" Colors
" Detects color strings (e.g. hex, rgba) and changes the background of the characters
" in that string to match the color. For example, in the following sample line of CSS:
"   p {color: red}
" The background color of the string "red" would be the color red.
Plug 'ap/vim-css-color'
" Opens the OS color picker and inserts the chosen color into the buffer.
Plug 'KabbAmine/vCoolor.vim'

"""" File explorer
Plug 'preservim/nerdtree', {'on': 'NERDTreeTabsToggle'}
  let g:NERDTreeMouseMode = 2
  let g:NERDTreeWinPos = "right"
  let g:NERDTreeShowHidden = 1
  let g:NERDTreeStatusline = -1
  " Syncs nerdtree across tabs, but I'm really only using this
  " since it has an option for auto-focusing on the current file
  Plug 'jistr/vim-nerdtree-tabs', {'on': 'NERDTreeTabsToggle'}
    let g:nerdtree_tabs_autofind = 1
    nnoremap <silent> <Leader>n :NERDTreeTabsToggle<CR>

"""" Colorscheme
Plug 'arcticicestudio/nord-vim'
  " Overrides
  augroup ColorschemeOverrides
    autocmd!
    " MatchParen
    autocmd Colorscheme * hi MatchParen ctermfg=blue cterm=underline ctermbg=NONE
    " Transparent SignColumn
    autocmd Colorscheme nord hi clear SignColumn
    " Transparent vertical split
    autocmd Colorscheme nord highlight VertSplit ctermbg=NONE ctermfg=0
    " statusline colors
    autocmd ColorScheme nord hi StatusLine ctermfg=6 ctermbg=NONE
    autocmd ColorScheme nord hi StatusLineNC ctermfg=8 ctermbg=NONE
    " autocomplete popupmenu
    autocmd ColorScheme * highlight PmenuSel ctermfg=1 ctermbg=3
    autocmd ColorScheme * highlight Pmenu ctermbg=12E3440 ctermfg=81 ctermbg=3
    " cursorline for quickpick
    autocmd ColorScheme * highlight! link CursorLine PmenuSel
    " transparent background
    autocmd ColorScheme * highlight Normal ctermbg=NONE
    autocmd ColorScheme * highlight NonText ctermbg=NONE
    autocmd ColorScheme * highlight! link EndOfBuffer NonText
  augroup END

"""" End Plugin Manager
call plug#end()

""" Section: General
set confirm
set mouse=a
" enable mouse mode while in tmux
let &ttymouse = has('mouse_sgr') ? 'sgr' : 'xterm2'
set backspace=indent,eol,start
set hidden
set nrformats-=octal
set ttimeout ttimeoutlen=100
set updatetime=500
set clipboard=unnamed
set autoread " Re-read file if it is changed by an external program
set scrolloff=10
set sessionoptions-=blank sessionoptions-=options sessionoptions+=tabpages sessionoptions-=folds
augroup Miscellaneous
  autocmd!
  " for some reason there is an ftplugin that is bundled with vim that
  " sets the textwidth to 78 if it is currently 0. This sets it back to 0
  autocmd VimEnter * :set tw=0
  " Set a default omnifunc
  autocmd FileType * if &omnifunc == "" | setlocal omnifunc=syntaxcomplete#Complete | endif
  " Extend iskeyword for filetypes that can reference CSS classes
  autocmd FileType
    \ css,scss,javascriptreact,typescriptreact,javascript,typescript,sass,postcss
    \ setlocal iskeyword+=-,?,!
  autocmd FileType vim setlocal iskeyword+=:,#,-
  autocmd BufEnter *
        \ if &ft ==# 'help' && &columns > 150 | wincmd L | endif
  " Use vim help pages for keywordprg in vim files
  autocmd FileType vim setlocal keywordprg=:help
  autocmd FileType sh setlocal keywordprg=man
  augroup HighlightWordUnderCursor
    autocmd!
    autocmd CursorMoved * exe printf('match CursorColumn /\V\<%s\>/', escape(expand('<cword>'), '/\'))
  augroup END
  " After a quickfix command is run, open the quickfix window , if there are results
  autocmd QuickFixCmdPost [^l]* cwindow
  autocmd QuickFixCmdPost l*    lwindow
  " Put focus back in quickfix window after opening an entry
  autocmd FileType qf nnoremap <buffer> <CR> <CR><C-W>p
  " highlight trailing whitespace
  autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red | exe '2match ErrorMsg /\s\+$/'
augroup END

" set swapfile directory
let &directory = $VIMHOME . 'swapfile_dir/'
call mkdir(&directory, "p")

" persist undo history to disk
let &undodir = $VIMHOME . 'undo_dir/'
call mkdir(&undodir, "p")
set undofile

" set backup directory
let &backupdir = $VIMHOME . 'backup_dir/'
call mkdir(&backupdir, "p")
set backup

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

inoremap jk <Esc>
nnoremap <silent> <Leader>w :wa<CR>
nnoremap <Leader>x :wqa<CR>
nnoremap <Leader>r :source $MYVIMRC<CR>
nnoremap <silent> <Leader>i :IndentLinesToggle<CR>

" open new horizontal and vertical panes to the right and bottom respectively
set splitright splitbelow
nnoremap <Leader>" :vsplit<CR>
nnoremap <Leader>% :split<CR>
" close a window, quit if last window
nnoremap <silent> <expr> <leader>q  winnr('$') == 1 ? ':q<CR>' : ':close<CR>'

""" Section: Autocomplete
" show the completion menu even if there is only one suggestion
" when autocomplete gets triggered, no suggestion is selected
" Use popup instead of preview window
set completeopt+=menuone,noselect,popup completeopt-=preview
set complete=.,w,b,u

""" Section: Command line settings
" on first wildchar press (<Tab>), show all matches and complete the longest common substring among them.
" on subsequent wildchar presses, cycle through matches
set wildmenu wildmode=longest:full,full
" move to beginning of line
cnoremap <C-a> <C-b>
set cmdheight=2

""" Section: System Mappings
" Map the output of these key combinations to their actual names
map l <M-l>
map h <M-h>
map j <M-j>
map k <M-k>
imap OB <Down>
imap OA <Up>

""" Section: Line folding / splitting
" Prevents inserting two spaces after punctuation on a join (J)
set nojoinspaces
" Delete comment character when joining commented lines
set formatoptions+=j
" Remap the builtin shift-j to try using splitjoin first
function! s:try(cmd, default)
  if exists(':' . a:cmd) && !v:count
    let tick = b:changedtick
    execute a:cmd
    if tick == b:changedtick
      execute join(['normal!', a:default])
    endif
  else
    execute join(['normal! ', v:count, a:default], '')
  endif
endfunction
nnoremap <silent> J :<C-u>call <SID>try('SplitjoinJoin',  'J')<CR>
nnoremap <silent> sj :<C-u>call <SID>try('SplitjoinSplit', "r\015")<CR>

""" Section: Motions / Text Objects
set matchpairs+=<:>
" Go to start/end of text object
function! GoStart(type) abort
  normal! `[
endfunction
function! GoEnd(type) abort
  normal! `]
endfunction
nnoremap <silent> gb :set opfunc=GoStart<CR>g@
nnoremap <silent> ge :set opfunc=GoEnd<CR>g@
" move ten lines/columns at a time by holding ctrl and a directional key
noremap <C-h> 10h
noremap <C-j> 10j
noremap <C-k> 10k
noremap <C-l> 10l
noremap <C-e> 10<C-e>
noremap <C-y> 10<C-y>

""" Section: Search
"""" Misc.
" While typing the search query, highlight where the first match would be.
set incsearch
" searching is only case sensitive when the query contains an uppercase letter
set ignorecase smartcase
" show match position in command window, don't show 'Search hit BOTTOM/TOP'
set shortmess-=S shortmess+=s
" Use ripgrep as the grep program, if it's available. Otherwise use the internal
" grep implementation since it's cross-platform
let &grepprg = executable('rg') ? 'rg --vimgrep --smart-case --follow' : 'internal'
" toggle search highlighting
nnoremap <silent> <Leader>/ :set hlsearch!<CR>

"""" Use '/' and '?' search in visual mode
vnoremap <silent> * :<C-U>
  \let old_reg=getreg('y')<Bar>let old_regtype=getregtype('y')<CR>
  \gv"yy/<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(
  \escape(@y, '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gVzv:call setreg('y', old_reg, old_regtype)<CR>
vnoremap <silent> # :<C-U>
  \let old_reg=getreg('y')<Bar>let old_regtype=getregtype('y')<CR>
  \gv"yy?<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(
  \escape(@y, '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gVzv:call setreg('y', old_reg, old_regtype)<CR>

"""" File search
function! QuickpickFiles() abort
  call quickpick#open({
    \ 'items': [],
    \ 'on_accept': function('s:quickpick_files_on_accept'),
    \ 'on_selection': function('s:quickpick_files_on_selection'),
    \ 'on_change': function('s:quickpick_files_on_change'),
    \ 'maxheight': 5,
    \ })
endfunction
function! s:quickpick_files_on_accept(data, ...) abort
  call quickpick#close()
  exe 'edit ' . a:data['items'][0]
endfunction
function! s:quickpick_files_on_selection(data, ...) abort
  return
endfunction
function! s:quickpick_files_on_change(data, ...) abort
  call quickpick#items(systemlist('rg --vimgrep --files ' . $RG_DEFAULT_OPTIONS . ' | fzf --filter ' . shellescape(a:data['input'])))
endfunction
nnoremap <silent> <Leader>f :silent! call QuickpickFiles()<CR>
"""" Line search
function! QuickpickLines() abort
  let s:quickpick_current_buffer = bufnr()
  let s:quickpick_current_line = line(".")
  let s:quickpick_popup = v:none
  call quickpick#open({
    \ 'on_accept': function('s:quickpick_lines_on_accept'),
    \ 'on_selection': function('s:quickpick_lines_on_selection'),
    \ 'on_change': function('s:quickpick_lines_on_change'),
    \ 'on_cancel': function('s:quickpick_lines_on_cancel'),
    \ 'maxheight': 5,
    \ })
endfunction
function! s:quickpick_lines_on_accept(data, ...) abort
  call quickpick#close()
  if s:quickpick_popup != v:none
    call popup_close(s:quickpick_popup)
    let s:quickpick_popup = v:none
  endif
  let [l:file, l:line; rest] = a:data['items'][0]->split(':')
  exe 'edit +' . l:line . ' ' . l:file
endfunction
function! s:quickpick_lines_on_cancel(data, ...) abort
  call quickpick#close()
  if s:quickpick_popup != v:none
    call popup_close(s:quickpick_popup)
    let s:quickpick_popup = v:none
  endif
endfunction
function! s:quickpick_lines_on_selection(data, ...) abort
  if empty(a:data['items'])
    if s:quickpick_popup != v:none
      call popup_close(s:quickpick_popup)
      let s:quickpick_popup = v:none
    endif
    return
  endif
  let [l:file, l:line; rest] = a:data['items'][0]->split(':')
  let l:wininfo = getwininfo(bufwinid('quickpick-filter'))[0]

  if s:quickpick_popup != v:none
    call popup_close(s:quickpick_popup)
    let s:quickpick_popup = v:none
  endif

  " open buffer for file if it isn't already open
  let l:buffer_number = bufadd(l:file)

  let s:quickpick_popup_options = {
        \ 'pos':    'botleft',
        \ 'borderchars': ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
        \ 'border': [1,1,1,1],
        \ 'title':  "Preview",
        \ 'maxheight': 9,
        \ 'minwidth':  l:wininfo.width - 3,
        \ 'maxwidth':  l:wininfo.width - 3,
        \ 'col':       l:wininfo.wincol,
        \ 'line':      l:wininfo.winrow - 9,
        \ }
  silent let s:quickpick_popup = popup_create(l:buffer_number, s:quickpick_popup_options)
  call win_execute(s:quickpick_popup, ['normal! '. l:line .'Gzz', 'setlocal cursorline cursorlineopt=line'])
endfunction
function! s:quickpick_lines_on_change(data, ...) abort
  call quickpick#items(systemlist('rg '.$RG_DEFAULT_OPTIONS.' ' . shellescape(a:data['input'])))
endfunction
nnoremap <silent> <Leader>g :silent! call QuickpickLines()<CR>
"""" Buffer search
function! QuickpickBuffers() abort
  let s:quickpick_current_buffer = bufnr()
  let s:quickpick_buffers = s:quickpick_get_buffers()
  let s:quickpick_buffers_string = s:quickpick_buffers->join("\n")
  call quickpick#open({
    \ 'items': s:quickpick_buffers,
    \ 'on_accept': function('s:quickpick_buffers_on_accept'),
    \ 'on_change': function('s:quickpick_buffers_on_change'),
    \ 'maxheight': 5,
    \ })
endfunction
function! s:quickpick_get_buffers() abort
  let l:buffer_numbers = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&filetype") != "qf" && v:val != s:quickpick_current_buffer')

  if empty(l:buffer_numbers)
    return l:buffer_numbers
  endif

  " previous buffer gets listed first
  let l:previous_buffer = bufnr('#')
  let l:previous_buffer_index = index(l:buffer_numbers, l:previous_buffer)
  if l:previous_buffer_index != -1
    let [l:buffer_numbers[0], l:buffer_numbers[l:previous_buffer_index]] = [l:buffer_numbers[l:previous_buffer_index], l:buffer_numbers[0]]
  endif

  let l:formatted_buffer_numbers = mapnew(l:buffer_numbers, { index, buf -> '[' . buf . '] ' . bufname(buf) })

  return l:formatted_buffer_numbers
endfunction
function! s:quickpick_buffers_on_accept(data, ...) abort
  call quickpick#close()
  " go to the buffer specified by the number in between braces
  let l:left_or_right_brace_pattern = '[\[|\]]'
  let l:keep_empty_strings = 0
  exe 'b' . a:data['items'][0]->split(l:left_or_right_brace_pattern, l:keep_empty_strings)[0]
endfunction
function! s:quickpick_buffers_on_change(data, ...) abort
  call quickpick#items(systemlist('fzf --filter ' . shellescape(a:data['input']), s:quickpick_buffers_string))
endfunction
nnoremap <silent> <Leader>b :silent! call QuickpickBuffers()<CR>

""" Section: Restore Settings
augroup RestoreSettings
  autocmd!
  function! HasMissingPlugins()
    return len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  endfunction
  " Restore session after vim starts. The 'nested' keyword tells vim to fire events
  " normally while this autocmd is executing. By default, no events are fired
  " during the execution of an autocmd to prevent infinite loops.
  let s:session_dir = $VIMHOME . 'sessions/'
  function! RestoreOrCreateSession()
    if argc() == 0 |
      call mkdir(s:session_dir, "p") |
      let s:session_name =  substitute($PWD, '/', '%', 'g') . '%vim' |
      let s:session_full_path = s:session_dir . s:session_name |
      let s:session_cmd = filereadable(s:session_full_path) ? "source " : "mksession! " |
      exe s:session_cmd . fnameescape(s:session_full_path) |
    endif
  endfunction
  autocmd VimEnter * nested
    \ call RestoreOrCreateSession() |
    \ if HasMissingPlugins() |
      \ PlugInstall --sync |
      \ source $MYVIMRC |
    \ endif
  " save session before vim exits
  autocmd VimLeavePre *
        \ if !empty(v:this_session) |
          \ exe 'mksession! ' . fnameescape(v:this_session) |
        \ endif
  " restore last cursor position after opening a file
  autocmd BufReadPost *
        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
          \ exe "normal! g'\"" |
        \ endif
augroup END

""" Section: Aesthetics
"""" Misc.
colorscheme nord
set linebreak
set number relativenumber
set cursorline cursorlineopt=number
set laststatus=2
set wrap
set listchars=tab:¬-,space:· " chars to represent tabs and spaces when 'setlist' is enabled
set signcolumn=yes " always show the sign column
set fillchars+=foldopen:\ ,fold:\ ,vert:│

"""" Block cursor in normal mode, thin line in insert mode, and underline in replace mode
let &t_SI.="\e[5 q" "SI = INSERT mode
let &t_SR.="\e[3 q" "SR = REPLACE mode
let &t_EI.="\e[1 q" "EI = NORMAL mode (ELSE)
" When vim exits, reset terminal cursor to blinking bar
augroup ResetCursor
  autocmd!
  autocmd VimLeave * silent exe "!echo -ne '\e[5 q'"
augroup END

"""" Statusline
set fillchars+=stl:─,stlnc:─
let s:GREY_HIGHLIGHT = "%#VertSplit#"
let s:STATUSLINE_HIGHLIGHT = "%{%g:actual_curwin==win_getid()?'%#StatusLine#':'%#StatusLineNC#'%}"
let s:STATUSLINE_SEPARATOR = s:GREY_HIGHLIGHT.'%='
let s:GROUP_SEPARATOR = s:GREY_HIGHLIGHT.'╾─╼'
let g:FormatGroup = { group -> s:GREY_HIGHLIGHT.'['.s:STATUSLINE_HIGHLIGHT.group.s:GREY_HIGHLIGHT.']' }
function! MyStatusLine()
  if &ft ==# 'help'
    return g:FormatGroup('HELP').s:STATUSLINE_SEPARATOR
  elseif exists('b:NERDTree')
    return g:FormatGroup('NERDTree').s:STATUSLINE_SEPARATOR
  elseif &ft ==# 'vim-plug'
    return g:FormatGroup('VIM_PLUG').s:STATUSLINE_SEPARATOR
  endif
  return g:FormatGroup('%h%w%q%t%m%r').s:STATUSLINE_SEPARATOR.g:FormatGroup('Ln:%l:%L').s:GROUP_SEPARATOR.g:FormatGroup('Col:%c')
endfunction
set statusline=%{%MyStatusLine()%}
