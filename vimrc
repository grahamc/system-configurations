" Section: Settings
" ----------------------
" env variables
let $VIMHOME = $HOME . '/.vim/'

" misc.
set confirm
set encoding=utf8
scriptencoding utf-8
syntax enable
set mouse=a
set backspace=indent,eol,start
set linebreak
set cursorline
set pastetoggle=<F2>
set laststatus=2
set number relativenumber
set incsearch
set termguicolors
set hidden
set autoindent
set smartindent
set complete=.,w,b,u
set smarttab
set nrformats-=octal
set ttimeout
set ttimeoutlen=100
set display=lastline
set clipboard=unnamed
set nocompatible
set wildmenu
set wildmode=list:longest
set nojoinspaces " Prevents inserting two spaces after punctuation on a join (J)
set shiftround " Round indent to multiple of shiftwidth (applies to < and >)
set autoread " Re-read file if it is changed by an external program
set nolazyredraw
set foldmethod=syntax
set foldopen=all
set dictionary+=/usr/share/dict/words
set foldlevel=20
set scrolloff=10
set wrap
set updatetime=500
set cmdheight=3

" autocomplete
let g:Emmet_completer_with_menu =
            \ { findstart, base -> findstart ?
            \ emmet#completeTag(findstart, base) :
            \ map(
                \ emmet#completeTag(findstart, base),
                \ "{'word': v:val, 'menu': repeat(' ', &l:pumwidth - 13) . '[emmet]'}"
            \ )}
let g:multicomplete_completers = [function('lsp#complete')]
if exists('$TMUX')
    call add(g:multicomplete_completers, function('tmuxcomplete#complete'))
endif
set completefunc=MultiComplete

set belloff+=all " turn off bell sounds

" show the completion [menu] even if there is only [one] suggestion
" by default, [no] suggestion is [select]ed
" Use [popup] instead of [preview] window
set completeopt+=menuone,noselect,popup
set completeopt-=preview

set shortmess+=Icm " don't display messages related to completion

set formatoptions+=j " Delete comment character when joining commented lines

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
let g:tab_width = 2
let &tabstop = g:tab_width
let &shiftwidth = g:tab_width
let &softtabstop = g:tab_width

set ignorecase smartcase " searching is only case sensitive when the query contains an uppercase letter

set splitright splitbelow " open new horizontal and vertical panes to the right and bottom respectively

let &ttymouse = has('mouse_sgr') ? 'sgr' : 'xterm2' " enable mouse mode while in tmux

" Section: Mappings
" NOTE: "<C-U>" is added to a lot of mappings to clear the visual selection
" that is being added automatically. Without it, trying to run a command
" through :Cheatsheet won't work.
" see: https://stackoverflow.com/questions/13830874/why-do-some-vim-mappings-include-c-u-after-a-colon
" -----------------
" Map the output of these key combinations to their actual names
" to make mappings that use these key combinations easier to understand
" WARNING: When doing this you should turn off any plugin that
" automatically adds closing braces since it might accidentally
" add a closing brace to an escape sequence
" TODO: map function row
nmap ¬ <A-l>
nmap ˙ <A-h>
nmap ∆ <A-j>
nmap ˚ <A-k>
vmap ¬ <A-l>
vmap ˙ <A-h>
vmap ∆ <A-j>
vmap ˚ <A-k>
nmap [1;2D <S-Left>
nmap [1;2C <S-Right>
nmap [1;2B <S-Down>
nmap [1;2A <S-Up>
nmap [1;5D <C-Left>
nmap [1;5C <C-Right>
nmap [1;5B <C-Down>
nmap [1;5A <C-Up>
nmap <C-@> <C-Space>
vmap <C-@> <C-Space>
imap <C-@> <C-Space>

let g:mapleader = "\<Space>"
inoremap jk <Esc>
nnoremap <silent> <Leader>\ :nohl<CR>
nnoremap <silent> <Leader>w :wa<CR>
nnoremap <Leader>r :source $MYVIMRC<CR>
nnoremap <Leader>x :wqa<CR>
nnoremap <silent> <Leader>i :IndentLinesToggle<CR>

" LSP
nnoremap <Leader>lis :<C-U>LspInstallServer<CR>
nnoremap <Leader>lh :<C-U>LspHover<CR>
nnoremap <Leader>ls :<C-U>LspStatus<CR>
nnoremap <Leader>ld :<C-U>LspDefinition<CR>
nnoremap <Leader>lrn :<C-U>LspRename<CR>
nnoremap <Leader>lrf :<C-U>LspReferences<CR>
nnoremap <Leader>lca :<C-U>LspCodeActionSync<CR>
nnoremap <Leader>lo :<C-U>LspCodeActionSync source.organizeImports<CR>

" buffer navigation
noremap <silent> <S-h> :bp<CR>
noremap <silent> <S-l> :bn<CR>

" tab navigation
nnoremap <silent> <S-Down> :tabprevious<CR>
nnoremap <silent> <S-Up> :tabnext<CR>

" wrap a function call in another function call.
" this is done by looking for a function call under the cursor and if found,
" wrapping it with parentheses and then going into
" insert mode so the wrapper function name can be typed
let @w='vicS)i'

" remove all trailing whitespace
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" Shift line up or down
nnoremap <C-Down> :m .+1<CR>==
nnoremap <C-Up> :m .-2<CR>==
vnoremap <C-Down> :m '>+1<CR>gv=gv
vnoremap <C-Up> :m '<-2<CR>gv=gv

" move ten lines at a time by holding ctrl and a directional key
nnoremap <A-h> 10h
nnoremap <A-j> 10j
nnoremap <A-k> 10k
nnoremap <A-l> 10l
vnoremap <A-j> 10j
vnoremap <A-h> 10h
vnoremap <A-k> 10k
vnoremap <A-l> 10l

" toggle folds
let $unrol=1
function UnrolMe()
    if $unrol==0
        :exe "normal zR"
        let $unrol=1
    else
        :exe "normal zM"
        let $unrol=0
    endif
endfunction
nnoremap <silent> <Leader>z :call UnrolMe()<CR>

nnoremap \| :vsplit<CR>
nnoremap _ :split<CR>

function! CloseBufferAndPossiblyWindow()
    " If the current buffer is a help or preview page or there is only one window and one buffer
    " left, then close the window and buffer.
    " Otherwise close the buffer and preserve the window
    if &l:filetype ==? "help"
                \ || (len(getbufinfo({'buflisted':1})) == 1 && winnr('$') == 1)
                \ || getwinvar('.', '&previewwindow') == 1
        execute "silent Sayonara"
    else
        execute "silent Sayonara!"
    endif
endfunction

nnoremap <silent> <leader>q :call CloseBufferAndPossiblyWindow()<CR>
" close window
nnoremap <silent> <leader>Q :q<CR>

function! CleanNoNameEmptyBuffers()
    let buffers = filter(
                \ range(1, bufnr('$')),
                \ 'buflisted(v:val) && empty(bufname(v:val)) && bufwinnr(v:val) < 0 && (getbufline(v:val, 1, "$") == [""])'
                \ )
    if !empty(buffers)
        exe 'bd '.join(buffers, ' ')
    endif
endfunction
nnoremap <silent> <Leader>c :call CleanNoNameEmptyBuffers()<CR>

" Keybind cheatsheet
let g:command_list = [
            \ "Show references [<Leader>lrf]",
            \ "Rename symbol [<Leader>lrn]",
            \ "Next buffer [<S-l>]",
            \ "Previous buffer [<S-h>]",
            \ "Next tab [<S-Up>]",
            \ "Previous tab [<S-Down>]",
            \ "Remove trailing whitespace [<F5>]",
            \ "Shift line(s) up [<C-Up>]",
            \ "Shift line(s) down [<C-Down>]",
            \ "Toggle folds [<Leader>z]",
            \ "Vertical split [|]",
            \ "Horizontal split [_]",
            \ "Close buffer [<Leader>q]",
            \ "Close window [<Leader>Q]",
            \ ]
function! CheatsheetSink(result)
    " Extract the keybinding which is always between brackets at the end
    let l:keybind = a:result[ match(a:result, '\[.*\]$') + 1 : -2 ]
    " Replace '<leader>' with mapleader
    let l:keybind = substitute(l:keybind, '<leader>', '\<Space>', 'g')
    " If the command starts with space, put a 1 before it (:h normal)
    if l:keybind =~? '^<space>'
        let l:keybind = 1 . l:keybind
    endif
    " Escape angle bracket sequences, like <C-h>, by prepending a '\'
    let l:keybind = substitute(l:keybind, '<[a-z,0-9,-]*>', '\="\\" . submatch(0)', 'g')
    " Escape sequences will only be parsed by vim if the string is in
    " double quotes so this line will make it a double quoted string,
    " see: https://vi.stackexchange.com/questions/10916/execute-normal-command-doesnt-work
    let l:keybind = eval('"' . l:keybind . '"')

    exe "normal " . l:keybind
endfunction
command! -bang -nargs=* Cheatsheet call
            \ fzf#run(fzf#wrap({
            \ 'source': g:command_list,
            \ 'sink': function('CheatsheetSink')}))
nnoremap <C-Space> :Cheatsheet<CR>
vnoremap <C-Space> :<C-U>Cheatsheet<CR>
inoremap <C-Space> <Esc>:Cheatsheet<CR>

" Section: Plugins
" ------------------------------------
call plug#begin('~/.vim/plugged')

" Colorschemes
""""""""""""""""""""""""""""""""""""
" light and dark
Plug 'lifepillar/vim-solarized8' | Plug 'arcticicestudio/nord-vim'

" Text objects (:h text-objects)
""""""""""""""""""""""""""""""""""""
" Select a function call. This can be used to wrap a function call in another call, for example.
Plug 'machakann/vim-textobj-functioncall'
    let g:textobj_functioncall_no_default_key_mappings = 1
    xmap ic <Plug>(textobj-functioncall-i)
    omap ic <Plug>(textobj-functioncall-i)
    xmap ac <Plug>(textobj-functioncall-a)
    omap ac <Plug>(textobj-functioncall-a)

" Manipulating Surroundings (e.g. braces, brackets, quotes)
""""""""""""""""""""""""""""""""""""
" Automatically add closing keyowrds (e.g. function/endfunction in vimscript)
Plug 'tpope/vim-endwise', {'for': ['vim', 'ruby']}
" Automatically close html tags
Plug 'alvan/vim-closetag'
" Automatically insert closing braces/quotes
Plug 'Raimondi/delimitMate'
    let g:delimitMate_expand_cr = 1
" Makes it easier to manipulate surroundings by providing commands to do common
" operations like change surrounding, remove surrounding, etc.
Plug 'tpope/vim-surround'

" Color stuff
""""""""""""""""""""""""""""""""""""
" Detects color strings (e.g. hex, rgba) and changes the background of the characters
" in that string to match the color. For example, in the following sample line of CSS:
"   p {color: red}
" The background color of the string "red" would be the color red.
Plug 'ap/vim-css-color'
" Opens the OS color picker and inserts the chosen color into the buffer.
Plug 'KabbAmine/vCoolor.vim'

" Buffer/tab/window management
""""""""""""""""""""""""""""""""""""
" Commands for closing buffers while keeping/destroying the window it was displayed in.
Plug 'mhinz/vim-sayonara'
" Easy movement between vim windows and tmux panes.
Plug 'christoomey/vim-tmux-navigator'
    let g:tmux_navigator_no_mappings = 1
    nnoremap <C-h> :TmuxNavigateLeft<cr>
    nnoremap <C-l> :TmuxNavigateRight<cr>
    nnoremap <C-j> :TmuxNavigateDown<cr>
    nnoremap <C-k> :TmuxNavigateUp<cr>

" Version control
""""""""""""""""""""""""""""""""""""
" Add icons to the gutter to signify version control changes (e.g. new lines, modified lines, etc.)
Plug 'mhinz/vim-signify'
" Run Git commands from vim
Plug 'tpope/vim-fugitive'

" Misc.
""""""""""""""""""""""""""""""""""""
" Statusbar and tabline
Plug 'vim-airline/vim-airline' | Plug 'vim-airline/vim-airline-themes'
    let g:airline#extensions#tabline#enabled = 1
    let g:airline#extensions#tabline#formatter = 'unique_tail'
" File explorer
Plug 'preservim/nerdtree', {'on': ['NERDTreeTabsToggle']}
    let g:NERDTreeMouseMode=2
    let g:NERDTreeWinPos="right"
    let g:NERDTreeShowHidden=1
Plug 'jistr/vim-nerdtree-tabs', {'on': 'NERDTreeTabsToggle'}
    let g:nerdtree_tabs_autofind = 1
    nnoremap <silent> <Leader>n :NERDTreeTabsToggle<CR>
" Highlight the current word and other occurences of it.
Plug 'dominikduda/vim_current_word'
" A tool for profiling vim's startup time. Useful for finding slow plugins.
Plug 'tweekmonster/startuptime.vim'
Plug 'AndrewRadev/splitjoin.vim'
    let g:splitjoin_split_mapping = ''
    let g:splitjoin_join_mapping = ''
    nnoremap sj :SplitjoinSplit<cr>
    nnoremap sk :SplitjoinJoin<cr>
" Visualizes indentation in the buffer. Useful for fixing incorrectly indented lines.
Plug 'Yggdroot/indentLine'
    let g:indentLine_char = '▏'
    let g:indentLine_setColors = 0
    let g:indentLine_enabled = 0
" Run a shell command asynchronously and put the results in the quickfix window.
" Useful for running test suites.
Plug 'tpope/vim-dispatch'
" Provides a collection of language packs, which provide syntax highlighting,
" and selects the correct one for the current buffer. Also detects indentation.
Plug 'sheerun/vim-polyglot'
" Easier management of vim sessions
Plug 'tpope/vim-obsession'
" Fuzzy finder
" TODO: Find a more portable replacement
Plug 'junegunn/fzf.vim'
    set runtimepath+=/usr/local/opt/fzf
    let g:fzfFindLineCommand = 'rg '.$FZF_RG_OPTIONS
    let g:fzfFindFileCommand = 'rg '.$FZF_RG_OPTIONS.' --files'
" recursive grep
function! FindLineResultHandler(result)
    let l:resultTokens = split(a:result, ':')
    let l:filename = l:resultTokens[0]
    let l:lineNumber = l:resultTokens[1]
    execute 'silent edit '.l:filename
    execute l:lineNumber
endfunction
command! -bang -nargs=* FindLine call
            \ fzf#vim#grep(
            \ g:fzfFindLineCommand.' '.shellescape(<q-args>).' | tr -d "\017"',
            \ 1,
            \ {'sink': function('FindLineResultHandler'), 'options': '--delimiter : --nth 4..'},
            \ <bang>0)
nnoremap <Leader>g :FindLine<CR>
" recursive file search
command! -bang -nargs=* FindFile call
            \ fzf#run(fzf#wrap({
            \ 'source': g:fzfFindFileCommand.' | tr -d "\017"',
            \ 'sink': 'edit'}))
nnoremap <Leader>f :FindFile<CR>

" IDE features (e.g. autocomplete, smart refactoring, goto definition, etc.)
""""""""""""""""""""""""""""""""""""
" An autocompleter that can chain various built-in and custom completion sources.
" If one source does not return any results, mucomplete will automatically try the next
" source in the chain. This way:
" - You can put the faster completion sources in the front of the chain,
" deferring to the slower ones only if necessary. (e.g. search
" keywords in the current buffer first before searching tags)
" - You don't have to remember all the various keybinds for the built-in
" and custom completion sources.
Plug 'lifepillar/vim-mucomplete'
    let g:mucomplete#reopen_immediately = 1
    let g:mucomplete#always_use_completeopt = 1
    " minimum chars before autocompletion starts
    let g:mucomplete#minimum_prefix_length = 3
    " NOTE: 'user' is whatever is assigned to the setting 'completefunc'
    let g:mucomplete#chains = {
                \ 'default': ['path', 'user', 'c-n', 'incl', 'omni', 'line'],
                \ 'vim': ['path', 'c-n', 'incl', 'cmd', 'user', 'omni', 'line'],
                \ }
    inoremap <silent> <plug>(MUcompleteFwdKey) <right>
    imap <right> <plug>(MUcompleteCycFwd)
    inoremap <silent> <plug>(MUcompleteBwdKey) <left>
    imap <left> <plug>(MUcompleteCycBwd)
" Language Server Protocol client that provides IDE like features
" e.g. autocomplete, autoimport, smart renaming, go to definition, etc.
Plug 'bigolu/vim-lsp'
    " for debugging
    " let g:lsp_log_file = expand('~/vim-lsp.log')
    let g:lsp_fold_enabled = 0
    let g:lsp_document_code_action_signs_enabled = 0
    let g:lsp_document_highlight_enabled = 0
" An easy way to install/manage language servers for vim-lsp.
Plug 'mattn/vim-lsp-settings'
    " where the language servers are stored
    let g:lsp_settings_servers_dir = $VIMHOME . "vim-lsp-servers"
    call mkdir(g:lsp_settings_servers_dir, "p")
" A bridge between vim-lsp and ale. This works by
" sending diagnostics (e.g. errors, warning) from vim-lsp to ale.
" This way, vim-lsp will only provide LSP features
" and ALE will only provide realtime diagnostics.
" Now if something goes wrong its easier to determine which plugin
" has the issue. Plus it allows ALE and vim-lsp to focus on their
" strengths: linting and LSP respectively.
Plug 'rhysd/vim-lsp-ale'
    " Only report diagnostics with a level of 'warning' or above
    " i.e. warning,error
    let g:lsp_ale_diagnostics_severity = "warning"
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
    let g:ale_lint_on_enter = 0 " Don't lint when a buffer opens
    let g:ale_lint_on_text_changed = "always"
    let g:ale_lint_delay = 1000
    let g:ale_lint_on_insert_leave = 0
    let g:ale_lint_on_filetype_changed = 0
    let g:ale_lint_on_save = 0
    let g:ale_fix_on_save = 1
    let g:ale_fixers = {
                \ 'javascript': ['prettier'],
                \ 'javascriptreact': ['prettier'],
                \ 'typescript': ['prettier'],
                \ 'typescriptreact': ['prettier'],
                \ 'json': ['prettier'],
                \ 'html': ['prettier'],
                \ 'css': ['prettier']
                \ }
    let g:ale_linters = {
                \ 'vim': [],
                \ 'javascript': ['eslint'],
                \ 'javascriptreact': ['eslint'],
                \ 'typescript': ['eslint'],
                \ 'typescriptreact': ['eslint']
                \ }
" Expands Emmet abbreviations to write HTML more quickly
Plug 'mattn/emmet-vim'
    let g:user_emmet_leader_key='<C-e>'
" autocomplete from other tmux panes
Plug 'wellle/tmux-complete.vim'
    let g:tmuxcomplete#trigger = ''

call plug#end()

" Section: Autocommands
" ---------------------
function! RestoreOrCreateSession()
    if argc() == 0
        let l:session_name =  substitute($PWD, "/", ".", "g") . ".vim"
        let l:session_full_path = $VIMHOME . 'sessions/' . l:session_name
        let l:session_cmd = empty(glob(l:session_full_path)) ? "Obsess " : "source "
        silent! execute l:session_cmd . l:session_full_path
    endif
endfunction

augroup RestoreSettings
    autocmd!
    " restore session
    autocmd VimEnter * nested call RestoreOrCreateSession()
    " restore last cursor position
    autocmd BufReadPost *
                \ if line("'\"") > 0 && line ("'\"") <= line("$") |
                \ exe "normal! g'\"" |
                \ endif
augroup END

augroup Styles
    autocmd!
    " Increase brightness of comments in nord
    autocmd ColorScheme nord highlight Comment guifg=#6d7a96
    " Make CursorLine look like an underline
    autocmd VimEnter * execute "hi clear CursorLine"
    autocmd VimEnter * execute "hi CursorLine gui=underline cterm=underline"
    " MatchParen
    autocmd VimEnter * execute "hi MatchParen ctermbg=blue guibg=lightblue"
    " Only highlight the current line on the active window
    au WinLeave * set nocursorline
    au WinEnter * set cursorline
    " Transparent SignColumn
    autocmd Colorscheme solarized8 execute "hi clear SignColumn"
    autocmd Colorscheme solarized8 execute "hi DiffAdd ctermbg=NONE guibg=NONE"
    autocmd Colorscheme solarized8 execute "hi DiffChange ctermbg=NONE guibg=NONE"
    autocmd Colorscheme solarized8 execute "hi DiffDelete ctermbg=NONE guibg=NONE"
    autocmd Colorscheme solarized8 execute "hi SignifyLineChange ctermbg=NONE guibg=NONE"
    autocmd Colorscheme solarized8 execute "hi SignifyLineDelete ctermbg=NONE guibg=NONE"
    autocmd Colorscheme solarized8 execute "hi ALEErrorSign ctermbg=NONE guibg=NONE"
    autocmd Colorscheme solarized8 execute "hi ALEWarningSign ctermbg=NONE guibg=NONE"
    " Transparent number column
    autocmd Colorscheme solarized8 execute "hi clear CursorLineNR"
    autocmd Colorscheme solarized8 execute "hi clear LineNR"
    " Transparent vertical split (line that divides NERDTree and editor)
    autocmd Colorscheme solarized8 execute "highlight VertSplit ctermbg=NONE guibg=NONE"
augroup END

augroup Miscellaneous
    autocmd!
    " for some reason there is an ftplugin that is bundled with vim that
    " sets the textwidth to 78 if it is currently 0. This sets it back to 0
    autocmd VimEnter * :set tw=0
    " Set a default omnifunc
    autocmd Filetype *
                \	if &omnifunc == "" |
                \ setlocal omnifunc=syntaxcomplete#Complete |
                \	endif
    " allow the use of mucomplete_current_method which returns a short
    " string denoting the currently active completion method, to be
    " used in a statusline
    autocmd VimEnter * execute "MUcompleteNotify 3"
    " Set fold method for vim
    autocmd Filetype vim execute "setlocal foldmethod=indent"
    " Extend iskeyword for filetypes that can reference CSS classes
    autocmd FileType css,scss,javascriptreact,typescriptreact,javascript,typescript,sass,postcss setlocal iskeyword+=-,?,!
    autocmd FileType vim setlocal iskeyword+=:,#
    " Open help/preview/quickfix windows across the bottom of the editor
    autocmd FileType *
                \ if &filetype ==? "help" || &filetype ==? "qf" || getwinvar('.', '&previewwindow') == 1 |
                    \ wincmd J |
                \ endif
    " Use vim help pages for keywordprg in vim files
    autocmd FileType vim setlocal keywordprg=:help
    " Is LSP is enabled, assign keywordprg to its hover feature. Unless it's bash or vim
    " in which case they'll use man pages and vim help pages respectively.
    autocmd User lsp_buffer_enabled if &filetype !=? "vim" && &filetype !=? "sh" | setlocal keywordprg=:LspHover | endif
    " Add emmet snippet autocomplete for filetypes that can contain HTML
    autocmd Filetype html,javascriptreact,typescriptreact,javascript,typescript
                \ let b:multicomplete_completers = get(b:, 'multicomplete_completers', [])->add(g:Emmet_completer_with_menu)
augroup END

" Section: Aesthetics
" ----------------------
" Get the completion source currently being used by mucomplete
fun! MU()
    return get(g:mucomplete#msg#short_methods,
                \        get(g:, 'mucomplete_current_method', ''), '')
endf

" let &statusline = ' %Y %F %{MU()}%m%r%h%w%=%04l,%04v %L '
set listchars=tab:¬-,space:· " chars to represent tabs and spaces when 'setlist' is enabled
set signcolumn=yes " always show the sign column
set fillchars=vert:│ " For a nice continuous line

" Block cursor in normal mode and thin line in insert mode
if exists('$TMUX')
    let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
    let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

function! SetColorscheme(mode)
        let &background = a:mode

        let s:new_color = a:mode ==? "light" ? "solarized8" : "nord"
        silent! execute "normal! :color " . s:new_color . "\<cr>"

        let s:new_airline_theme = a:mode ==? "light" ? "solarized" : "base16_nord"
        silent! execute "normal! :AirlineTheme " . s:new_airline_theme . "\<cr>"
endfunction
" Check periodically to see if darkmode is toggled on the OS and update the vim/airline theme accordingly.
" There is a bash script running in the background of my shell that puts the current mode
" in ~/.darkmode (1=dark, 0=light)
function! SyncColorscheme(timer_id)
    if !filereadable(expand('~/.darkmode'))
        " If the file to sync with can't be read then default to dark mode and stop the sync job
        call SetColorscheme('dark')
        if a:timer_id
            call timer_stop(a:timer_id)
        endif
        return
    endif

    let l:mode = system('cat ~/.darkmode') ==? "0" ? "light" : "dark"
    let l:bg_changed_or_is_not_set = &background !=? l:mode || !exists('g:colors_name')
    if l:bg_changed_or_is_not_set
        call SetColorscheme(l:mode)
    endif
endfunction
call SyncColorscheme(v:none)
call timer_start(5000, function('SyncColorscheme'), {"repeat": -1})

" Section: Utilities
" ----------------------
function! MultiComplete(findstart, base)
    let l:completers = extendnew(
                \ get(g:, 'multicomplete_completers', []),
                \ get(b:, 'multicomplete_completers', []))

    if a:findstart
        let g:findstarts = []
        let l:result = -3
        for l:Completer in l:completers
            let l:completer_result = l:Completer(a:findstart, a:base)
            call add(g:findstarts, l:completer_result)
            " Don't care if result is -3 since that is our default return
            " value. Don't care about -2 either since I don't want the
            " completion menu to stay open if there are no results.
            if l:completer_result >= 0
                if l:result < 0
                    let l:result = l:completer_result
                else
                    let l:result = min([l:result, l:completer_result])
                endif
            endif
        endfor
        let g:findstart = l:result " 0 indexed
        let g:col = virtcol(".") " 1 indexed
        let g:line = getline('.')
        return l:result
    endif

    let l:results = []
    let l:i = 0
    let l:replaceable_chars = split(g:line, '\zs')[g:findstart:g:col - 2]
    for l:Completer in l:completers
        let l:findstart = g:findstarts->get(l:i)
        if l:findstart >= 0
            let l:completer_results = l:Completer(a:findstart, a:base)

            " If the dictionary form of results is returned, we'll just take the
            " words and ignore the 'refresh' key
            if type(l:completer_results) == type({})
                let l:completer_results = l:completer_results.words
            endif

            if l:findstart > g:findstart " we need to pad
                " coerce to dictionary
                if typename(l:completer_results) ==? "list<string>"
                    call map(l:completer_results, "{'word': v:val}")
                endif
                for l:dict in l:completer_results
                    let l:val = dict['word']
                    let dict.word = l:replaceable_chars[0:(l:findstart - g:findstart) - 1]->join("") . l:val

                    " make sure that the padded string doesn't show
                    " up in the completion menu by adding an "abbr"
                    " key if one isn't already present
                    if !l:dict->has_key("abbr")
                        let l:dict.abbr = l:val
                    endif
                endfor
            endif
            call extend(l:results, l:completer_results)
        endif
        let l:i = l:i + 1
    endfor

    return l:results
endfunction
