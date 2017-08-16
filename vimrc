""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" This is Biggie's .vimrc, feel free to peruse at your leisure "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Section: General Settings
" ----------------------
    " stops vim from behaving in a strongly vi-compatible way
    " not setting this usually affects alot of other stuff
    set nocompatible

    " set vertical split bar to '|'
    set encoding=utf8
    set fillchars=vert:│
    autocmd ColorScheme * highlight VertSplit cterm=NONE ctermfg=Green ctermbg=NONE

    syntax enable " syntax highlighting
    set ruler " display line and column number on status bar
    set ls=2 " always have status line on
    set mouse=a " enable mouse
    set nu " show line numbers
    set backspace=indent,eol,start " deal with backspace nonsense
    set linebreak " wrap lines by word instead of character
    set cursorline " highlight current line
    set pastetoggle=<F2>

    " use system clipboard
    " for X-11 based systems (linux) use 'unnamedplus'
    " if you are on OSX or Windows use 'unnamed'
    " explanation here: http://vi.stackexchange.com/questions/84/how-can-i-copy-text-to-the-system-clipboard-from-vim
    " make sure vim is compiled with clipboard
    set clipboard=unnamed

    " # of spaces to use for indentation
    let tab_width = 4
    " when tab is used insert spaces instead
    set expandtab
    " width of an actual tab character
    execute "silent set tabstop=" . tab_width
    " size of an indent, in spaces
    execute "silent set shiftwidth=" . tab_width
    " I don't really understand this, but w/e ¯\_(ツ)_/¯
    execute "silent set softtabstop=" . tab_width

    " when used together, searching is only case sensitive when
    " the query contains an uppercase letter
    set ignorecase
    set smartcase

    " where vim saves the undo history for files
    let undo_dir = "~/.vim/undodir"
    " create dir to save undo histories
    execute "silent ! mkdir -p " . undo_dir
    " tell vim where to save undo histories
    execute " silent set undodir=" . undo_dir
    " persistent undo (save undo history after closing)
    set undofile

    " open new panes to the right and bottom respectively
    set splitright
    set splitbelow

" Section: Mappings
" -----------------
    let mapleader = "\<Space>" " Set leader key to <space> (default='\')

    " remove all trailing whitespace with <F5>
    nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

    inoremap jk <Esc>
    nnoremap <Leader><Leader> v
    nnoremap <Leader>\ :nohl<CR>
    nnoremap <Leader>w :w<CR>
    nnoremap <Leader>q :q<CR>
    nnoremap <Leader>x :x<CR>
    nnoremap <Leader>q :q<CR>

    " Shift line up or down
    noremap <C-u> ddp
    noremap <C-i> ddkkp

" Section: Plugins (Manager: Vundle)
" ------------------------------------
    filetype off " must be off while Vundle runs
    " set the runtime path to include Vundle and initialize
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#begin()

    Plugin 'VundleVim/Vundle.vim' " let Vundle manage Vundle, required
    Plugin 'jiangmiao/auto-pairs' " automplete for bracket, parens, etc...
    Plugin 'bigolu/vim-tmux-navigator' " navigate between vim panes, vim tabs, and tmux panes
    Plugin 'sheerun/vim-polyglot' " language pack
    Plugin 'joshdick/onedark.vim' " colorscheme
        let g:onedark_termcolors=16
    Plugin 'alvan/vim-closetag' " Auto-insert closing html tag
        let g:closetag_filenames = "*.html,*.xhtml,*.phtml,*.xml,*.jinja,*.html.mustache"
    Plugin 'airblade/vim-gitgutter' " show git diff in column bar
        set updatetime=1000 " wait time after typing stops before a plugin is triggered
    Plugin 'Valloric/MatchTagAlways' " html tag higlighting
        let g:mta_filetypes = {'html' : 1, 'xhtml' : 1, 'xml' : 1, 'jinja' : 1, 'html.mustache' : 1}
    Plugin 'scrooloose/nerdtree' " file explorer
        Plugin 'jistr/vim-nerdtree-tabs' " sync nerdtree across tabs
            nnoremap <Leader>nt :NERDTreeTabsToggle<CR>
    Plugin 'vim-airline/vim-airline' " cool status-line
        let g:airline_section_c = "%F" " include full file path
        Plugin 'vim-airline/vim-airline-themes' " status line colorschemes
    Plugin 'w0rp/ale'
        let g:ale_sign_error = '>>'
        let g:ale_sign_warning = '>'
        let g:ale_statusline_format = ['⨉ %d', '⚠ %d', '⬥ ok']
        set statusline+=%{ALEGetStatusLine()}
        highlight clear ALEErrorSign
        highlight clear ALEWarningSign
    Plugin 'maxboisvert/vim-simple-complete' " autocomplete
        " Enable tab key completion mapping
        let g:vsc_tab_complete = 1
        " supress newline when enter is pressed
        inoremap <expr> <CR> pumvisible() ? "\<C-Y>" : "\<CR>"
    Plugin 'junegunn/fzf'
        nnoremap <silent> <C-t> :FZF<CR>

    call vundle#end() " required
    filetype plugin indent on " auto-indentation based on filetype

" Section: Aesthetics
" -------------------
    " quality colorscheme
    colorscheme onedark

" Section: Autocommands
" ---------------------
    " Always restore last cursor position
    if has("autocmd")
        augroup restoreCursor
            autocmd!
            autocmd BufReadPost *
                        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
                        \   exe "normal! g'\"" |
                        \ endif
        augroup END
    endif
