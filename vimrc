" Section: Helpers
" ------------------
    let $VIMHOME = $HOME . '/.vim/'
    let g:session_dir = $VIMHOME . 'sessions/'

    function! MakeDirectory(path)
        execute 'silent !mkdir -p ' . a:path . ' > /dev/null 2>&1'
    endfunction

" Section: Settings
" ----------------------
    " misc.
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
    set complete=.,w,b,i
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
    set pumwidth=30 " increase autocompletion menu width
    set lazyredraw " don't redraw the page during the execution of a macro, only redraw once at the end of execution
    set foldmethod=syntax
    set foldopen=all
    set dictionary+=/usr/share/dict/words
    set foldlevel=20
    set breakindent
    set scrolloff=10
    set wrap
    set updatetime=1000

    " add "-" to keyword character set to get autocompletion of css class names
    set iskeyword+=-

    " autocomplete
    let g:Emmet_completer_with_menu =
            \ { findstart, base -> findstart ?
                \ emmet#completeTag(findstart, base) :
                \ map(
                    \ emmet#completeTag(findstart, base),
                    \ "{'word': v:val, 'menu': repeat(' ', &l:pumwidth - 13) . '[emmet]'}"
                \ )
            \ }
    let g:multicomplete_completers = [function('ale#completion#OmniFunc')]
    set completefunc=ale#completion#OmniFunc

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
    let g:swapfile_dir = $VIMHOME . 'swapfile_dir/'
    call MakeDirectory(g:swapfile_dir)
    let &directory = g:swapfile_dir

    " persist undo history to disk
    let g:undo_dir = $VIMHOME . 'undo_dir/'
    call MakeDirectory(g:undo_dir)
    let &undodir = g:undo_dir
    set undofile

    " set backup director
    let g:backup_dir = $VIMHOME . 'backup_dir/'
    call MakeDirectory(g:backup_dir)
    let &backupdir = g:backup_dir

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
    nnoremap <Leader>\ :nohl<CR>
    nnoremap <Leader>w :wa<CR>
    " nnoremap <Leader>qa :qa<CR>
    nnoremap <Leader>r :source $MYVIMRC<CR>
    nnoremap <Leader>x :wqa<CR>
    nnoremap <Leader>i :IndentLinesToggle<CR>

    " Map the output of these key combinations to their actual names
    " since it is obvious what keys produced these symbols/escape-sequences
    " WARNING: When doing this you should turn off any plugin that
    " automatically adds closing braces since it might accidentally
    " add a closing brace to an escape sequence
    nmap ¬ <a-l>
    nmap ˙ <a-h>
    nmap ∆ <a-j>
    nmap ˚ <a-k>
    nmap [1;2D <S-Left>
    nmap [1;2C <S-Right>
    nmap [1;2B <S-Down>
    nmap [1;2A <S-Up>
    nmap [1;5D <C-Left>
    nmap [1;5C <C-Right>
    nmap [1;5B <C-Down>
    nmap [1;5A <C-Up>

    " buffer navigation
    noremap <S-Left> :bp<CR>
    noremap <S-Right> :bn<CR>

    " tab navigation
    nnoremap <S-Down> :tabprevious<CR>
    nnoremap <S-Up> :tabnext<CR>
    
    " wrap a function call in another function call.
    " this is done by looking for a function call under the cursor and if found,
    " wrapping it with parentheses and then going into
    " insert mode so the wrapper function name can be typed
    let @w='vicS)i'

    " remove all trailing whitespace
    nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

    " Shift line up or down
    " nnoremap ∆ :m .+1<CR>==
    " nnoremap ˚ :m .-2<CR>==
    " vnoremap ∆ :m '>+1<CR>gv=gv
    " vnoremap ˚ :m '<-2<CR>gv=gv

    " move ten lines at a time by holding ctrl and a directional key
    nnoremap <C-h> 10h
    nnoremap <C-j> 10j
    nnoremap <C-k> 10k
    vnoremap <C-j> 10j
    nnoremap <C-l> 10l
    vnoremap <C-h> 10h
    vnoremap <C-k> 10k
    vnoremap <C-l> 10l

    " scroll ten lines at a time by holding ctrl and a directional key
    " nnoremap <a-j> 10<C-e>
    " nnoremap <a-k> 10<C-y>
    " vnoremap <a-j> 10<C-e>
    " vnoremap <a-k> 10<C-y>

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
    nnoremap <Leader>z :call UnrolMe()<CR>

    nnoremap \| :vsplit<CR>
    nnoremap _ :split<CR>

" Section: Plugins
" ------------------------------------
    " set the runtime path to include Vundle and initialize
    set rtp+=~/.vim/bundle/Vundle.vim
    " alternatively, pass a path where Vundle should install plugins
    "call vundle#begin('~/some/path/here')
    call vundle#begin()

    " let Vundle manage Vundle, required
    Plugin 'VundleVim/Vundle.vim'

    Plugin 'mhinz/vim-sayonara'
        nnoremap <leader>Q :Sayonara<cr>
        nnoremap <leader>q :Sayonara!<cr>
    Plugin 'bagrat/vim-buffet'
    Plugin 'AndrewRadev/splitjoin.vim'
        let g:splitjoin_split_mapping = ''
        let g:splitjoin_join_mapping = ''
        nnoremap sj :SplitjoinSplit<cr>
        nnoremap sk :SplitjoinJoin<cr>
    Plugin 'mhinz/vim-signify'
    Plugin 'kana/vim-textobj-user'
    Plugin 'kana/vim-textobj-function'
    Plugin 'thinca/vim-textobj-function-javascript'
    Plugin 'haya14busa/vim-textobj-function-syntax'
    Plugin 'Yggdroot/indentLine'
        let g:indentLine_char = '▏'
        let g:indentLine_setColors = 0
        let g:indentLine_enabled = 0
    Plugin 'tpope/vim-endwise'
    Plugin 'mattn/emmet-vim'
        inoremap <C-e> <Esc>:call emmet#expandAbbr(0, "")<CR>
        nnoremap <C-e> :call emmet#expandAbbr(0, "")<CR>
    Plugin 'alvan/vim-closetag'
    "Plugin 'Raimondi/delimitMate'
    Plugin 'michaeljsmith/vim-indent-object'
    Plugin 'ap/vim-css-color'
    Plugin 'KabbAmine/vCoolor.vim'
    Plugin 'tpope/vim-surround'
    Plugin 'machakann/vim-textobj-functioncall'
        let g:textobj_functioncall_no_default_key_mappings = 1
        xmap ic <Plug>(textobj-functioncall-i)
        omap ic <Plug>(textobj-functioncall-i)
        xmap ac <Plug>(textobj-functioncall-a)
        omap ac <Plug>(textobj-functioncall-a)
    Plugin 'lifepillar/vim-mucomplete'
        let g:mucomplete#completion_delay = 300
        let g:mucomplete#always_use_completeopt = 1
        let g:mucomplete#enable_auto_at_startup = 1
        let g:mucomplete#chains = {
                    \ 'default': ['path', 'user', 'c-n', 'omni', 'dict'],
                    \ 'vim': ['path', 'user', 'c-n', 'omni', 'dict']
                    \ }
        let g:mucomplete#no_mappings = 1
        imap <tab> <plug>(MUcompleteFwd)
	      imap <s-tab> <plug>(MUcompleteBwd)
        inoremap <silent> <plug>(MUcompleteFwdKey) <C-j>
        imap <C-j> <plug>(MUcompleteCycFwd)
        inoremap <silent> <plug>(MUcompleteBwdKey) <C-h>
        imap <C-h> <plug>(MUcompleteCycBwd)
    Plugin 'dense-analysis/ale'
        let g:ale_lint_on_enter = 0
        let g:ale_lint_on_text_changed = "always"
        let g:ale_lint_delay = 500
        let g:ale_rename_tsserver_find_in_comments = 1
        let g:ale_lsp_suggestions = 1
        let g:ale_lsp_show_message_severity = "warning"
        let g:ale_lint_on_insert_leave = 0
        let g:ale_lint_on_filetype_changed = 0
        let g:ale_lint_on_save = 0
        let g:ale_default_navigation = "buffer"
        let g:ale_completion_max_suggestions = 5
        let g:ale_completion_tsserver_remove_warnings = 1
        let g:ale_fix_on_save = 1
        let g:ale_completion_autoimport = 1
        let g:ale_set_balloons = 1
        let g:ale_fixers = {'*': ['prettier']}
    Plugin 'tpope/vim-dispatch'
    Plugin 'sheerun/vim-polyglot'
    Plugin 'tpope/vim-obsession'
    Plugin 'lifepillar/vim-solarized8'
    Plugin 'arcticicestudio/nord-vim'
    Plugin 'christoomey/vim-tmux-navigator'
        let g:tmux_navigator_no_mappings = 1
        nnoremap <C-Left> :TmuxNavigateLeft<cr>
        nnoremap <C-Right> :TmuxNavigateRight<cr>
        nnoremap <C-Down> :TmuxNavigateDown<cr>
        nnoremap <C-Up> :TmuxNavigateUp<cr>
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
        inoremap <C-@> :Commands<CR>
    Plugin 'preservim/nerdtree'
        let g:NERDTreeMouseMode=2
        let g:NERDTreeWinPos="right"
        let g:NERDTreeShowHidden=1
        Plugin 'jistr/vim-nerdtree-tabs'
            nnoremap <Leader>n :NERDTreeTabsToggle<CR>
        Plugin 'unkiwii/vim-nerdtree-sync'
            let g:nerdtree_sync_cursorline = 1

    call vundle#end()            " required for Vundle 
    filetype plugin indent on    " required for Vundle 

" Section: Autocommands
" ---------------------
    function! CleanNoNameEmptyBuffers()
        let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val) && empty(bufname(v:val)) && bufwinnr(v:val) < 0 && (getbufline(v:val, 1, "$") == [""])')
        if !empty(buffers)
            exe 'bd '.join(buffers, ' ')
        endif
    endfunction
    nnoremap <silent> <Leader>c :call CleanNoNameEmptyBuffers()<CR>

    function! StartWorkspace()
        if argc() == 0
            let l:session_name =  substitute($PWD, "/", ".", "g") . ".vim"
            let l:session_full_path = g:session_dir . l:session_name
            let l:session_cmd = empty(glob(l:session_full_path)) ? "Obsess " : "source "
            execute l:session_cmd . l:session_full_path
        endif
    endfunction

    if has('autocmd')
        augroup restoreLastCursorPosition
            autocmd!
            autocmd BufReadPost *
                        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
                        \   exe "normal! g'\"" | exe "normal! zz" |
                        \ endif
        augroup END
        augroup nordOverrides
            autocmd!
            autocmd ColorScheme nord highlight Comment guifg=#6d7a96
        augroup END
        augroup solarizedOverrides
            autocmd!
        augroup END
        " for some reason there is an ftplugin that is bundled with vim that
        " sets the textwidth to 78 if it is currently 0. This sets it back to 0
        augroup resetTextWidth
            autocmd!
            autocmd FileType * :set tw=0
        augroup END
        augroup RestoreOrCreateNewWorkspace
            autocmd!
            autocmd VimEnter * nested call StartWorkspace()
        augroup END
        augroup SetDefaultOmniFunc
            autocmd!
            autocmd Filetype *
                \	if &omnifunc == "" |
                \		setlocal omnifunc=syntaxcomplete#Complete |
                \	endif
        augroup END
        augroup MUCompleteConfig
            autocmd!
            " allow the use of mucomplete_current_method which returns a short
            " string denoting the currently active completion method, to be
            " used in a statusline
            autocmd Filetype * execute "MUcompleteNotify 3"
        augroup END
        augroup SetVimFoldMethod
            autocmd!
            autocmd Filetype vim execute "setlocal foldmethod=indent"
        augroup END
        augroup UnderlineCurrentLine
            autocmd!
            autocmd Filetype * execute "hi clear CursorLine"
            autocmd Filetype * execute "hi CursorLine gui=underline cterm=underline"
        augroup END
        augroup StyleMatchParen
            autocmd!
            autocmd VimEnter * execute "hi MatchParen ctermbg=blue guibg=lightblue"
        augroup END
        augroup OpenPrevTabAfterTabClose
            autocmd!
            autocmd TabEnter * let g:last_tab_number = tabpagenr()
            autocmd TabClosed * 
                \	if g:last_tab_number < tabpagenr('$') + 1 |
                \		execute "tabprev" |
                \	endif
        augroup END
        augroup TypescriptFunctionObject
            " "vim-textobj-function-javascript works pretty
            " well for typescript so this will enable it
            autocmd!
            autocmd FileType typescriptreact,typescript let b:textobj_function_select = function('textobj#function#javascript#select')
        augroup END
    endif

" Section: Aesthetics
" ----------------------
    fun! MU()
        return get(g:mucomplete#msg#short_methods,
        \        get(g:, 'mucomplete_current_method', ''), '')
    endf
    set fillchars=vert:│
    set listchars=tab:¬-,space:·
    let &statusline = ' %Y %F %{MU()}%m%r%h%w%=%04l,%04v %L '
    set signcolumn=yes

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

    " function SmoothScroll(scroll_direction, n_scroll)
    "     let n_scroll = a:n_scroll
    "     if a:scroll_direction == 1
    "         let scrollaction="\<C-y>"
    "     else 
    "         let scrollaction="\<C-e>"
    "     endif
    "     exec "normal " . scrollaction
    "     redraw
    "     let counter=1
    "     while counter<&scroll*n_scroll
    "         let counter+=1
    "         sleep 10m " ms per line
    "         redraw
    "         exec "normal " . scrollaction
    "     endwhile
    " endfunction
    " 
    " " smoothly scroll the screen for some scrolling operations
    " nnoremap <C-U> :call SmoothScroll(1,1)<cr>
    " nnoremap <C-D> :call SmoothScroll(2,1)<cr>
    " nnoremap <C-B> :call SmoothScroll(1,2)<cr>
    " nnoremap <C-F> :call SmoothScroll(2,2)<cr>

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

