" Section: Helpers
" ------------------
    let $VIMHOME = $HOME . '/.vim/'

    function! MakeDirectory(path)
        execute 'silent !mkdir -p ' . a:path . ' > /dev/null 2>&1'
    endfunction

    function! FileExists(path)
        return !empty(glob(a:path))
    endfunction

    function! PeriodicPluginUpdate()
        let l:last_update_path = $VIMHOME . 'lastupdate'
        let l:week_in_seconds = 604800
        let l:last_update = FileExists(l:last_update_path)
            \ ? system('date +%s -r ' . l:last_update_path)
            \ : 0
        let l:current_time = system('date +%s')
        let l:time_passed = l:current_time - l:last_update

        if l:time_passed > l:week_in_seconds
            autocmd VimEnter * PlugUpdate
            execute 'silent !touch ' . l:last_update_path
        endif
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

    " set swapfile directory
    let g:swapfile_dir = $VIMHOME . 'swapfile_dir/'
    call MakeDirectory(g:swapfile_dir)
    let &directory = g:swapfile_dir

    " persist undo history to disk
    let g:undo_dir = $VIMHOME . 'undo_dir/'
    call MakeDirectory(g:undo_dir)
    let &undodir = g:undo_dir
    set undofile

    " set backup directory
    let g:backup_dir = $VIMHOME . 'backup_dir/'
    call MakeDirectory(g:backup_dir)
    let &backupdir = g:backup_dir

    " tab setup
    set expandtab
    let g:tab_width = 4
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
    if !FileExists('~/.vim/autoload/plug.vim')
        silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
            \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
    endif

    call plug#begin()
        Plug 'sheerun/vim-polyglot'
        Plug 'tpope/vim-obsession'
        Plug 'maxboisvert/vim-simple-complete'
        Plug 'bigolu/vim-tmux-navigator'
        Plug 'bigolu/vim-colors-solarized'
        Plug 'bigolu/nerdtree', { 'on': 'NERDTreeTabsToggle' } | Plug 'jistr/vim-nerdtree-tabs'
            let g:NERDTreeMouseMode=2
            nnoremap <Leader>nt :NERDTreeTabsToggle<CR>
    call plug#end()

    call PeriodicPluginUpdate()

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
