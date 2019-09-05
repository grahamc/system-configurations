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
    set number
    set relativenumber

    " tab setup
    set expandtab
    let g:tab_width = 4
    let &tabstop = g:tab_width
    let &shiftwidth = g:tab_width
    let &softtabstop = g:tab_width

    " when used together, searching is only case sensitive when
    " the query contains an uppercase letter
    set ignorecase
    set smartcase

    " persist undo history to disk
    let &undodir = '/Users/bigmac/.vim/undodir/'
    set undofile

    " set dir for swp files
    set directory=$HOME/.vim/swapfiles//

    " open new panes to the right and bottom respectively
    set splitright
    set splitbelow

    " enable mouse mode while in tmux
    let &ttymouse = has('mouse_sgr') ? 'sgr' : 'xterm2'

" Section: Mappings
" -----------------
    let g:mapleader = "\<Space>"
    inoremap jk <Esc>
    nnoremap <Leader>\ :nohl<CR>
    nnoremap <Leader>w :wa<CR>
    nnoremap <Leader>q :q<CR>
    nnoremap <Leader>qa :qa<CR>
    nnoremap <Leader>r :source $MYVIMRC<CR>
    nnoremap <Leader>x :wqa<CR>
    nnoremap <Leader>t :set list!<CR>

    " remove all trailing whitespace
    nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

    " Shift line up or down
    noremap <C-o> ddkkp
    noremap <C-i> ddp

    " open :help in a new tab
    cnoreabbrev <expr> h
        \ getcmdtype() == ":" && getcmdline() == 'h' ? 'tab h' : 'h'
    cnoreabbrev <expr> help
        \ getcmdtype() == ":" && getcmdline() == 'help' ? 'tab h' : 'help'

" Section: Plugins
" ------------------------------------
    filetype off
    set runtimepath+=~/.vim/bundle/Vundle.vim
    call vundle#begin()
    Plugin 'VundleVim/Vundle.vim'
    Plugin 'sheerun/vim-polyglot'
    Plugin 'tpope/vim-obsession'
    Plugin 'maxboisvert/vim-simple-complete'
    Plugin 'bigolu/vim-tmux-navigator'
    Plugin 'bigolu/vim-colors-solarized'
    Plugin 'bigolu/nerdtree'
        let g:NERDTreeMouseMode=2
        Plugin 'jistr/vim-nerdtree-tabs'
            nnoremap <Leader>nt :NERDTreeTabsToggle<CR>
    call vundle#end()
    filetype plugin indent on

" Section: Autocommands
" ---------------------
    if has('autocmd')
        " Always restore last cursor position
        augroup restoreCursor
            autocmd!
            autocmd BufReadPost *
                        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
                        \   exe "normal! g'\"" |
                        \ endif
        augroup END
    endif

" Section: Aesthetics
" ----------------------
    set fillchars=vert:│
    set listchars=tab:¬-,space:·
    let &statusline = ' %{&ff}  [%Y]  %F%m%r%h%w%=%04l,%04v   %L '
    let &background = $THEME_TYPE ==# '1' ? 'light' : 'dark'
    colorscheme solarized
