" Section: General Settings
" ----------------------
    " stops vim from behaving in a strongly vi-compatible way
    set nocompatible

    syntax enable " syntax highlighting
    set ruler " display line and column number on status bar
    set mouse=a " enable mouse
    set backspace=indent,eol,start " deal with backspace nonsense
    set linebreak " wrap lines by word instead of character
    set cursorline " highlight current line
    set pastetoggle=<F2>
    set encoding=utf8

    " tab setup
    let tab_width = 2
    set expandtab
    execute "silent set tabstop=" . tab_width
    execute "silent set shiftwidth=" . tab_width
    execute "silent set softtabstop=" . tab_width

    " when used together, searching is only case sensitive when
    " the query contains an uppercase letter
    set ignorecase
    set smartcase

    " have vim save the undo history for files
    let undo_dir = "~/.vim/undodir"
    execute "silent ! mkdir -p " . undo_dir
    execute " silent set undodir=" . undo_dir
    set undofile

    " open new panes to the right and bottom respectively
    set splitright
    set splitbelow

" Section: Mappings
" -----------------
    let mapleader = "\<Space>"

    inoremap jk <Esc>
    nnoremap <Leader>\ :nohl<CR>
    nnoremap <Leader>w :wa<CR>
    nnoremap <Leader>q :q<CR>
    nnoremap <Leader>x :x<CR>

    " remove all trailing whitespace
    nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

    " Shift line up or down
    noremap <C-u> ddp
    noremap <C-i> ddkkp

" Section: Plugins
" ------------------------------------
    filetype off
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#begin()

    Plugin 'VundleVim/Vundle.vim' " let Vundle manage Vundle, required
    Plugin 'jiangmiao/auto-pairs' " automplete for bracket, parens, etc...
    Plugin 'sheerun/vim-polyglot' " language pack
    Plugin 'arcticicestudio/nord-vim' " colorscheme
    Plugin 'w0rp/ale' " linter
    Plugin 'airblade/vim-gitgutter' " show git diff in column bar
    Plugin 'maxboisvert/vim-simple-complete' " autocomplete
        " Enable tab key completion mapping
        let g:vsc_tab_complete = 1
        " supress newline when enter is pressed
        inoremap <expr> <CR> pumvisible() ? "\<C-Y>" : "\<CR>"
		Plugin 'scrooloose/nerdtree' " file explorer
        nnoremap <Leader>nt :NERDTreeTabsToggle<CR>
        Plugin 'jistr/vim-nerdtree-tabs' " sync nerdtree across tabs

    call vundle#end()
    filetype plugin indent on

" Section: Aesthetics
" -------------------
    " quality colorscheme
    colorscheme nord
    highlight Comment ctermfg=3

    " set vertical split bar to '|'
    set fillchars=vert:│
    autocmd ColorScheme * highlight VertSplit cterm=NONE ctermfg=Green ctermbg=NONE

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

