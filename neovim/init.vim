""" Section: This Stuff Should Stay at the Top
let g:mapleader = "\<Space>"

""" Section: General
set backspace=indent,eol,start
set hidden
set nrformats-=octal
set ttimeout ttimeoutlen=100
set updatetime=500
let &clipboard = has('nvim') ? 'unnamedplus' : 'unnamed'
set autoread " Re-read file if it is changed by an external program
set scrolloff=10

" persist undo history to disk
set undofile

augroup Miscellaneous
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
"""" Misc.
" While typing the search query, highlight where the first match would be.
set incsearch
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

""" Section: Plugins

" Install vim-plug if not found
let data_dir = has('nvim') ? stdpath('data') . '/site' : $HOME.'/.vim'
let vim_plug_plugin_file = data_dir . '/autoload/plug.vim'
let plug_is_installed = v:true
if empty(glob(vim_plug_plugin_file))
  let should_install = confirm('vim-plug is not installed, would you like to install it?', "yes\nno") == 1
  if should_install
    silent execute '!curl -fLo '.vim_plug_plugin_file.' --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  else
    let plug_is_installed = v:false
  endif
endif

"""" Start Plugin Manager
call plug#begin()

" To get the vim help pages for vim-plug itself, you need to add it as a plugin
Plug 'junegunn/vim-plug'

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
" Determine the filetype based on the interpreter specified in a shebang
Plug 'vitalk/vim-shebang'
Plug 'bkad/CamelCaseMotion'
  let g:camelcasemotion_key = ','

" Combine enter key (<CR>) mappings from the delimitmate and vim-endwise plugins.
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
Plug 'tpope/vim-commentary'

" These plugins only apply when vim is being used in a terminal. I'd like to
" put this in the vim config that contains all my terminal specific settings,
" <config_directory>/plugin/terminal.vim, but since vim-plug doesn't allow
" declaring plugins in separate files, I had to put them here.
if index(v:argv, '--embed') == -1 && index(v:argv, '--headless') == -1
  """" General
  Plug 'junegunn/vim-peekaboo'
    let g:peekaboo_delay = 500 " measured in milliseconds
  Plug 'inkarkat/vim-CursorLineCurrentWindow'
  Plug 'farmergreg/vim-lastplace'
  Plug 'tmux-plugins/vim-tmux'
  Plug 'tweekmonster/startuptime.vim'

  """" Autocomplete
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
    let g:ale_lsp_show_message_severity = "warning"
    let g:ale_lint_on_enter = 1 " lint when a buffer opens
    let g:ale_lint_on_text_changed = "always"
    let g:ale_lint_delay = 1000
    let g:ale_lint_on_insert_leave = 0
    let g:ale_lint_on_filetype_changed = 0
    let g:ale_lint_on_save = 0

  " A bridge between vim-lsp and ale. This works by
  " sending diagnostics (e.g. errors, warning) from vim-lsp to ale.
  " This way, vim-lsp will only provide LSP features
  " and ALE will only provide realtime diagnostics.
  Plug 'rhysd/vim-lsp-ale'
    " Only report diagnostics with a level of 'warning' or above
    " i.e. warning,error
    let g:lsp_ale_diagnostics_severity = "warning"

  """" Editing
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
      " Hide statusline when fzf is active
      autocmd  FileType fzf set laststatus=0 noshowmode noruler nonumber norelativenumber | let t:fzf_active = 1
        \| autocmd BufLeave <buffer> set laststatus=2 showmode number relativenumber
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

  """" Colors
  " Opens the OS color picker and inserts the chosen color into the buffer.
  Plug 'KabbAmine/vCoolor.vim'
    " Make an alias for the 'VCoolor' command with a name that is easier to remember
    command! ColorPicker VCoolor

  """" File explorer
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

  """" Colorscheme
  Plug 'arcticicestudio/nord-vim'
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
      autocmd ColorScheme nord highlight StatusLineNC ctermbg=8
      autocmd ColorScheme nord highlight StatusLineText ctermfg=14 ctermbg=NONE cterm=reverse
      autocmd ColorScheme nord highlight StatusLineRightText ctermfg=14 ctermbg=8
      autocmd ColorScheme nord highlight StatusLineRightSeparator ctermfg=8 ctermbg=NONE cterm=reverse
      autocmd ColorScheme nord highlight StatusLineErrorText ctermfg=1 ctermbg=8
      autocmd ColorScheme nord highlight StatusLineWarningText ctermfg=3 ctermbg=8
      autocmd ColorScheme nord highlight StatusLineNCText ctermfg=0 ctermbg=NONE cterm=reverse
      autocmd ColorScheme nord highlight StatusLineStandout ctermfg=0 ctermbg=NONE
      autocmd ColorScheme nord highlight StatusLineStandoutText ctermfg=DarkYellow ctermbg=NONE cterm=reverse
      " autocomplete popupmenu
      autocmd ColorScheme nord highlight PmenuSel ctermfg=14 ctermbg=NONE cterm=reverse
      autocmd ColorScheme nord highlight Pmenu ctermfg=black ctermbg=NONE cterm=reverse
      autocmd ColorScheme nord highlight CursorLine ctermfg=NONE ctermbg=NONE cterm=underline
      " transparent background
      autocmd ColorScheme nord highlight Normal ctermbg=NONE
      autocmd ColorScheme nord highlight NonText ctermbg=NONE
      autocmd ColorScheme nord highlight! link EndOfBuffer NonText
      " relative line numbers
      autocmd ColorScheme nord highlight LineNr ctermfg=NONE
      autocmd ColorScheme nord highlight LineNrAbove ctermfg=0
      autocmd ColorScheme nord highlight! link LineNrBelow LineNrAbove
      autocmd ColorScheme nord highlight WordUnderCursor cterm=bold
      autocmd ColorScheme nord highlight IncSearch ctermbg=8 cterm=NONE
      autocmd ColorScheme nord highlight TabLine ctermbg=NONE ctermfg=black cterm=reverse
      autocmd ColorScheme nord highlight TabLineSel ctermbg=NONE ctermfg=14 cterm=reverse
      autocmd ColorScheme nord highlight TabLineFill ctermbg=8
      autocmd ColorScheme nord highlight WildMenu ctermfg=14 ctermbg=NONE cterm=underline
      autocmd ColorScheme nord highlight Comment ctermfg=Black ctermbg=NONE
      " This variable contains a list of 16 colors that should be used as the color palette for terminals opened in vim.
      " By unsetting this, I ensure that terminals opened in vim will use the colors from the color palette of the
      " terminal emulator in which vim is running
      autocmd ColorScheme nord if exists('g:terminal_ansi_colors') | unlet g:terminal_ansi_colors | endif
      " Have vim only use the colors from the 16 color palette of the terminal emulator in which it runs
      autocmd ColorScheme nord set t_Co=16
      autocmd ColorScheme nord highlight Visual ctermbg=8
      " Search hit
      autocmd ColorScheme nord highlight Search ctermfg=DarkYellow ctermbg=NONE cterm=reverse
    augroup END
endif

"""" End Plugin Manager
call plug#end()

" Install plugins if not found. Must be done after plugins are registered
function! InstallMissingPlugins()
  let l:missing_plugins = filter(deepcopy(get(g:, 'plugs', {})), '!isdirectory(v:val.dir)')
  if !empty(l:missing_plugins)
    let install_prompt = "The following plugins are not installed:\n" . join(keys(l:missing_plugins), ", ") . "\nWould you like to install them?"
    let should_install = confirm(install_prompt, "yes\nno") == 1
    if should_install
      PlugInstall --sync
    endif
  endif
endfunction
if plug_is_installed
  call InstallMissingPlugins()
endif
