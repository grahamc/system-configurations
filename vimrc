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
    set complete=.,w,b,i,u,U
    set smarttab
    set nrformats-=octal
    set ttimeout
    set ttimeoutlen=100
    set display=lastline
    set clipboard=unnamed
    set nocompatible " needed for Vundle
    filetype off " needed for Vundle 
    set cmdheight=2
    set wildmenu
    set wildmode=list:longest
    set nojoinspaces " Prevents inserting two spaces after punctuation on a join (J)
    set shiftround " Round indent to multiple of shiftwidth (applies to < and >)
    set autoread " Re-read file if it is changed by an external program
    set lazyredraw " don't redraw the page during the execution of a compound command (e.g. :bufdo), only redraw once at the end of execution
    set foldmethod=syntax
    set foldopen=all
    set dictionary+=/usr/share/dict/words
    set foldlevel=20
    set scrolloff=10
    set wrap
    set updatetime=500

    " autocomplete
    let g:Emmet_completer_with_menu =
            \ { findstart, base -> findstart ?
                \ emmet#completeTag(findstart, base) :
                \ map(
                    \ emmet#completeTag(findstart, base),
                    \ "{'word': v:val, 'menu': repeat(' ', &l:pumwidth - 13) . '[emmet]'}"
                \ )
            \ }
    let g:multicomplete_completers = [function('lsp#complete'), g:Emmet_completer_with_menu]
    set completefunc=lsp#complete

    " turn off bell sounds
    set belloff+=all

    " show the completion [menu] even if there is only [one] suggestion
    " by default, [no] suggestion is [select]ed
    set completeopt+=menuone,noselect,popup
    set completeopt-=preview

    " don't display messages related to completion
    set shortmess+=Icm

    " Delete comment character when joining commented lines
    set formatoptions+=j

    " set swapfile directory
    let &directory = $VIMHOME . 'swapfile_dir/'
    call mkdir(expand(&directory), "p")

    " persist undo history to disk
    let &undodir = $VIMHOME . 'undo_dir/'
    call mkdir(expand(&undodir), "p")
    set undofile

    " set backup directory
    let &backupdir = $VIMHOME . 'backup_dir/'
    call mkdir(expand(&backupdir), "p")
    set backup

    " tab setup
    set expandtab
    let g:tab_width = 2
    let &tabstop = g:tab_width
    let &shiftwidth = g:tab_width
    let &softtabstop = g:tab_width

    " searching is only case sensitive when the query contains an uppercase letter
    set ignorecase smartcase

    " open new horizontal and vertical panes to the right and bottom respectively
    set splitright splitbelow

    " enable mouse mode while in tmux
    let &ttymouse = has('mouse_sgr') ? 'sgr' : 'xterm2'

" Section: Mappings
" -----------------
    let g:mapleader = "\<Space>"
    inoremap jk <Esc>
    nnoremap <silent> <Leader>\ :nohl<CR>
    nnoremap <silent> <Leader>w :wa<CR>
    nnoremap <Leader>r :source $MYVIMRC<CR>
    nnoremap <Leader>x :wqa<CR>
    nnoremap <silent> <Leader>i :IndentLinesToggle<CR>

    " LSP
    nnoremap <Leader>lis :LspInstallServer<CR>
    nnoremap <Leader>ls :LspStatus<CR>
    nnoremap <Leader>lh :LspHover<CR>

    " Map the output of these key combinations to their actual names
    " to make mappings that use these key combinations easier to understand
    " WARNING: When doing this you should turn off any plugin that
    " automatically adds closing braces since it might accidentally
    " add a closing brace to an escape sequence
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
        let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val) && empty(bufname(v:val)) && bufwinnr(v:val) < 0 && (getbufline(v:val, 1, "$") == [""])')
        if !empty(buffers)
            exe 'bd '.join(buffers, ' ')
        endif
    endfunction
    nnoremap <silent> <Leader>c :call CleanNoNameEmptyBuffers()<CR>

" Section: Plugins
" ------------------------------------
    " set the runtime path to include Vundle and initialize
    set rtp+=~/.vim/bundle/Vundle.vim
    " alternatively, pass a path where Vundle should install plugins
    "call vundle#begin('~/some/path/here')
    call vundle#begin()

    " let Vundle manage Vundle, required
    Plugin 'VundleVim/Vundle.vim'

    " Colorschemes
    """"""""""""""""""""""""""""""""""""
    Plugin 'lifepillar/vim-solarized8'
    Plugin 'arcticicestudio/nord-vim'

    " Text objects (:h text-objects)
    """"""""""""""""""""""""""""""""""""
    " Makes it easier to create custom text objects.
    " Most of the plugins below depend on this.
    Plugin 'kana/vim-textobj-user'
    " Select a function
    Plugin 'kana/vim-textobj-function'
    " Select all lines on the same indentation level as the cursor.
    " Useful for indentation bases languages like python.
    Plugin 'michaeljsmith/vim-indent-object'
    " Select a function call. This can be used to wrap a function call in another call, for example.
    Plugin 'machakann/vim-textobj-functioncall'
        let g:textobj_functioncall_no_default_key_mappings = 1
        xmap ic <Plug>(textobj-functioncall-i)
        omap ic <Plug>(textobj-functioncall-i)
        xmap ac <Plug>(textobj-functioncall-a)
        omap ac <Plug>(textobj-functioncall-a)
    " Selecting functions, specifically in javascript.
    Plugin 'thinca/vim-textobj-function-javascript'

    " Manipulating Surroundings (e.g. braces, brackets, quotes)
    """"""""""""""""""""""""""""""""""""
    " Automatically add closing keyowrds (e.g. function/endfunction in vimscript)
    Plugin 'tpope/vim-endwise'
    " Automatically close html tags
    Plugin 'alvan/vim-closetag'
    " Automatically insert closing braces/quotes
    Plugin 'Raimondi/delimitMate'
    " Makes it easier to manipulate surroundings by providing commands to do common
    " operations (e.g. change surrounding, remove surrounding, add surrounding)
    Plugin 'tpope/vim-surround'

    " File explorer
    Plugin 'preservim/nerdtree'
        let g:NERDTreeMouseMode=2
        let g:NERDTreeWinPos="right"
        let g:NERDTreeShowHidden=1
        Plugin 'jistr/vim-nerdtree-tabs'
            nnoremap <silent> <Leader>n :NERDTreeTabsToggle<CR>
        Plugin 'unkiwii/vim-nerdtree-sync'
            let g:nerdtree_sync_cursorline = 1

    " Color stuff
    """"""""""""""""""""""""""""""""""""
    " Detects color strings (e.g. hex, rgba) and changes the background of the characters
    " in that string to match the color. For example, in the following sample  line of CSS:
    "   p {color: red}
    " The background color of the string "red" would be the color red.
    Plugin 'ap/vim-css-color'
    " Opens the OS color picker and inserts the chosen color in the buffer.
    Plugin 'KabbAmine/vCoolor.vim'

    " Buffer/tab/window management
    """"""""""""""""""""""""""""""""""""
    " Commands for closing buffers while keeping/destroying the window it was displayed in.
    Plugin 'mhinz/vim-sayonara'
    " Easy movement between vim windows and tmux panes.
    Plugin 'christoomey/vim-tmux-navigator'
        let g:tmux_navigator_no_mappings = 1
        nnoremap <C-h> :TmuxNavigateLeft<cr>
        nnoremap <C-l> :TmuxNavigateRight<cr>
        nnoremap <C-j> :TmuxNavigateDown<cr>
        nnoremap <C-k> :TmuxNavigateUp<cr>
    " Displays a bar at the top of the editor to see buffers and tabs.
    Plugin 'bagrat/vim-buffet'

    " Misc.
    """"""""""""""""""""""""""""""""""""
    " Highlight the current word and other occurences of it.
    Plugin 'dominikduda/vim_current_word'
    " A tool for profiling vim's startup time.
    " Useful for finding slow plugins.
    Plugin 'tweekmonster/startuptime.vim'
    Plugin 'AndrewRadev/splitjoin.vim'
        let g:splitjoin_split_mapping = ''
        let g:splitjoin_join_mapping = ''
        nnoremap sj :SplitjoinSplit<cr>
        nnoremap sk :SplitjoinJoin<cr>
    " Visualizes indentation in the buffer. Useful for fixing incorrectly indented lines.
    Plugin 'Yggdroot/indentLine'
        let g:indentLine_char = '▏'
        let g:indentLine_setColors = 0
        let g:indentLine_enabled = 0
    " Run a shell command asynchronously and put the results in the quickfix window.
    " Useful for running test suites.
    Plugin 'tpope/vim-dispatch'
    " Provides a collection of language packs, which provide syntax highlighting,
    " and selects the correct one for the current buffer. Also detects indentation.
    Plugin 'sheerun/vim-polyglot'
    " Easier management of vim sessions
    Plugin 'tpope/vim-obsession'
    " Fuzzy finder
    " TODO: Find a more portable replacement like quickpick.vim
    Plugin 'junegunn/fzf.vim'
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
        nnoremap <C-@> :Commands<CR>
        inoremap <C-@> <Esc>:Commands<CR>

    " IDE features (e.g. autocomplete, smart refactoring, goto definition, etc.)
    """"""""""""""""""""""""""""""""""""
    " An autocompleter that allows for the chaining
    " of various built-in and custom completion sources. If one source does not
    " return any results, mucomplete will automatically try the next
    " source in the chain. This way:
    " - You can put the faster completion sources in the front of the chain,
    " deferring to the slower ones only if necessary. (e.g. search
    " keywords in the current buffer first before searching tags)
    " - You don't have to remember all the various keybinds for the built-in
    " and custom completion sources.
    Plugin 'lifepillar/vim-mucomplete'
        let g:mucomplete#completion_delay = 300
        let g:mucomplete#always_use_completeopt = 1
        let g:mucomplete#enable_auto_at_startup = 1
        " minimum chars before autocompletion starts
        let g:mucomplete#minimum_prefix_length = 3
        " specify different completion sources to chain together per filetype
        " NOTE: 'user' is whatever is assigned to the setting 'completefunc'
        let g:mucomplete#chains = {
                    \ 'default': ['path', 'user', 'c-n', 'omni'],
                    \ 'vim': ['path', 'user', 'c-n', 'omni']
                    \ }
        " disable default mappings
        let g:mucomplete#no_mappings = 1
        " selecting completion matches
        imap <tab> <plug>(MUcompleteFwd)
	      imap <s-tab> <plug>(MUcompleteBwd)
        " manually selecting completion sources
        inoremap <silent> <plug>(MUcompleteFwdKey) <C-j>
        imap <C-j> <plug>(MUcompleteCycFwd)
        inoremap <silent> <plug>(MUcompleteBwdKey) <C-h>
        imap <C-h> <plug>(MUcompleteCycBwd)
    " Language Server Protocol client that provides IDE like features
    " e.g. autocomplete, autoimport, smart renaming, go to definition, etc.
    Plugin 'prabirshrestha/vim-lsp'
        let g:lsp_fold_enabled = 0
    " An easy way to install/manage language servers for vim-lsp.
    Plugin 'mattn/vim-lsp-settings'
        " where the language servers are stored
        let g:lsp_settings_servers_dir = $VIMHOME . "vim-lsp-servers"
        call mkdir(g:lsp_settings_servers_dir, "p")
    " A bridge between vim-lsp and ale. This works by
    " sending diagnostics (e.g. errors, warning) from vim-lsp to ale.
    " This gives a nice separation of concerns: vim-lsp will only
    " provide LSP features and Ale will only provide realtime diagnostics.
    " Plus, ale's diagnostics are more robust than vim-lsp's
    " and vim-lsp's LSP features are more robust than ale's.
    Plugin 'rhysd/vim-lsp-ale'
        " Only report diagnostics with a warning level or above
        " i.e. warning,error
        let g:lsp_ale_diagnostics_severity = "warning"
    " Asynchronous linting
    Plugin 'dense-analysis/ale'
        " If you check for the existence of a linter and it isn't there,
        " don't continue to check on subsequent linting operations.
        let g:ale_cache_executable_check_failures = 1
        " Don't show popup when the mouse if over a symbol, vim-lsp
        " should be responsible for that.
        let g:ale_set_balloons = 0
        " Don't show variable information in the status line,
        " vim-lsp should be responsible for that.
        let g:ale_hover_cursor = 0
        " Only report diagnostics with a warning level or above
        " i.e. warning,error
        let g:ale_lsp_show_message_severity = "warning"
        " Don't lint when opening the file.
        let g:ale_lint_on_enter = 0
        let g:ale_lint_on_text_changed = "always"
        let g:ale_lint_delay = 1000
        let g:ale_lint_on_insert_leave = 0
        let g:ale_lint_on_filetype_changed = 0
        let g:ale_lint_on_save = 0
        let g:ale_fix_on_save = 1
        " These are not so much fixers as formatters
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
    " Expand emmet abbreviations
    Plugin 'mattn/emmet-vim'
        inoremap <C-e> <Esc>:call emmet#expandAbbr(0, "")<CR>
        nnoremap <C-e> :call emmet#expandAbbr(0, "")<CR>
    " Add icons to the gutter to signify version control changes (e.g. new lines, modified lines, etc.)
    Plugin 'mhinz/vim-signify'

    call vundle#end()            " required for Vundle 
    filetype plugin indent on    " required for Vundle 

" Section: Autocommands
" ---------------------
    function! StartWorkspace()
        if argc() == 0
            let l:session_name =  substitute($PWD, "/", ".", "g") . ".vim"
            let l:session_full_path = $VIMHOME . 'sessions/' . l:session_name
            let l:session_cmd = empty(glob(l:session_full_path)) ? "Obsess " : "source "
            execute l:session_cmd . l:session_full_path
        endif
    endfunction

    augroup RestoreSettings
        autocmd!
        " restore session
        autocmd VimEnter * nested call StartWorkspace()
        " restore last cursor position
        autocmd BufReadPost *
                    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
                        \ exe "normal! g'\"" | exe "normal! zz" |
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
    augroup END
    " for some reason there is an ftplugin that is bundled with vim that
    " sets the textwidth to 78 if it is currently 0. This sets it back to 0
    augroup resetTextWidth
        autocmd!
        autocmd VimEnter * :set tw=0
    augroup END
    augroup SetDefaultOmniFunc
        autocmd!
        autocmd Filetype *
            \	if &omnifunc == "" |
                \ setlocal omnifunc=syntaxcomplete#Complete |
            \	endif
    augroup END
    augroup MUCompleteConfig
        autocmd!
        " allow the use of mucomplete_current_method which returns a short
        " string denoting the currently active completion method, to be
        " used in a statusline
        autocmd VimEnter * execute "MUcompleteNotify 3"
    augroup END
    augroup SetFoldMethod
        autocmd!
        autocmd Filetype vim execute "setlocal foldmethod=indent"
    augroup END
    augroup TypescriptFunctionObject
        " "vim-textobj-function-javascript works pretty
        " well for typescript so this will enable it
        autocmd!
        autocmd FileType typescriptreact,typescript
            \ let b:textobj_function_select = function('textobj#function#javascript#select')
    augroup END
    augroup ExtendIskeyword
        autocmd!
        autocmd FileType css,scss,javascriptreact,typescriptreact,javascript,typescript,sass,postcss setlocal iskeyword+=-,?,!
        autocmd FileType vim setlocal iskeyword+=:,#
    augroup END
    augroup OpenHelpOrPreviewWindowAcrossBottom
        autocmd!
        autocmd FileType *
            \ if &filetype ==? "help" || getwinvar('.', '&previewwindow') == 1 |
                \ wincmd J |
            \ endif
    augroup END

" Section: Aesthetics
" ----------------------
    " Get the completion source currently being used by mucomplete
    fun! MU()
        return get(g:mucomplete#msg#short_methods,
        \        get(g:, 'mucomplete_current_method', ''), '')
    endf

    let &statusline = ' %Y %F %{MU()}%m%r%h%w%=%04l,%04v %L '
    set listchars=tab:¬-,space:·
    " always show the sign column
    set signcolumn=yes
    " For a nice continuous line
    set fillchars=vert:│

    " Block cursor in normal mode and thin line in insert mode
    if exists('$TMUX')
        let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
        let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
    else
        let &t_SI = "\<Esc>]50;CursorShape=1\x7"
        let &t_EI = "\<Esc>]50;CursorShape=0\x7"
    endif

    function! SetColorscheme(...)
        let s:new_bg = system('cat ~/.darkmode') ==? "0" ? "light" : "dark"
        if &background !=? s:new_bg || ! exists('g:colors_name')
            let &background = s:new_bg
            let s:new_color = s:new_bg ==? "light" ? "solarized8" : "nord"
            silent! execute "normal! :color " . s:new_color . "\<cr>"
        endif
    endfunction
    call SetColorscheme()
    call timer_start(10000, "SetColorscheme", {"repeat": -1})

" Section: Utilities
" ----------------------
    " TODO: have the completers be parameters and return a complete function
    " that uses "closure" to capture them instead. this way you can define multiple aggregates
    " maybe parameterize # completions per completer and interleave
    function! MultiComplete(findstart, base)
        if a:findstart
            let g:findstarts = []
            let l:result = -3
            for l:Completer in g:multicomplete_completers
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

        " TODO: not sure why I get different values for getline()/virtcol() in this block versus the
        " block above for findstart. In any case, calling it in the block above gives the expected
        " value so that should be ok for now.
        " TODO: maybe interlaeve the results so top answer from all completers
        " are at the top
        let l:results = []
        let l:i = 0
        let l:replaceable_chars = split(g:line, '\zs')[g:findstart:g:col - 2]
        for l:Completer in g:multicomplete_completers
            let l:findstart = g:findstarts->get(l:i)
            if l:findstart >= 0
                let l:completer_results = l:Completer(a:findstart, a:base)[0:4] " 5 results should be fine
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

