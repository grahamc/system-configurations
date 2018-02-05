" Section: General Settings
" ----------------------
    " stops vim from behaving in a strongly vi-compatible way
    set nocompatible

    syntax enable
    set ruler
    set mouse=a
    set backspace=indent,eol,start
    set linebreak
    set cursorline
    set pastetoggle=<F2>
    set encoding=utf8

    " tab setup
    let tab_width = 4
    set expandtab
    let &tabstop = tab_width
    let &shiftwidth = tab_width
    let &softtabstop = tab_width

    " when used together, searching is only case sensitive when
    " the query contains an uppercase letter
    set ignorecase
    set smartcase

    " persist undo history to disk
    let &undodir = "~/.vim/undodir"
    set undofile

    " open new panes to the right and bottom respectively
    set splitright
    set splitbelow
    
    " enable mouse mode while in tmux
    let &ttymouse = has("mouse_sgr") ? "sgr" : "xterm2"

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

    Plugin 'VundleVim/Vundle.vim'
    Plugin 'jiangmiao/auto-pairs'
    Plugin 'sheerun/vim-polyglot'
    Plugin 'arcticicestudio/nord-vim'
    Plugin 'w0rp/ale'
    Plugin 'airblade/vim-gitgutter'
    Plugin 'bigolu/vim-tmux-navigator'
    Plugin 'bigolu/nerdtree'
        let NERDTreeMouseMode=3
        Plugin 'jistr/vim-nerdtree-tabs'
            nnoremap <Leader>nt :NERDTreeTabsToggle<CR>
    Plugin 'Valloric/YouCompleteMe'
        let g:ycm_python_binary_path = 'python3'
        let g:ycm_rust_src_path = '~/.rustup/toolchains/stable-x86_64-apple-darwin/lib/rustlib/src/rust/src'

    call vundle#end()
    filetype plugin indent on

" Section: Aesthetics
" -------------------
    
    " comment color
    if $COLORTERM =~ "truecolor" || $COLORTERM =~ "24bit"
      set termguicolors
      let g:nord_comment_brightness=20
      colorscheme nord
    else
      colorscheme nord
      hi Comment ctermfg=3
    endif

    " set vertical split bar to '|'
    set fillchars=vert:│
    hi VertSplit ctermbg=NONE guibg=NONE

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

