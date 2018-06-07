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
    let &undodir = '/Users/bigolu/.vim/undodir/'
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
    nnoremap <Leader>go :Goyo<CR>

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
    Plugin 'airblade/vim-gitgutter'
    Plugin 'bigolu/vim-colors-solarized'
    Plugin 'junegunn/goyo.vim'
    Plugin 'tpope/vim-surround'
    Plugin 'tpope/vim-commentary'
    Plugin 'bigolu/vim-tmux-navigator'
    Plugin 'tpope/vim-obsession'
    Plugin 'bigolu/tabline.vim'
    Plugin 'w0rp/ale'
        let g:ale_sign_error = '│'
        let g:ale_sign_warning = '│'
    Plugin 'valloric/MatchTagAlways'
        let g:mta_filetypes = {
            \ 'html' : 1,
            \ 'xml' : 1,
            \ 'xhtml' : 1,
            \ 'jinja' : 1,
            \ 'javascript.jsx' : 1
        \}
    Plugin 'bigolu/nerdtree'
        let g:NERDTreeMouseMode=2
        Plugin 'jistr/vim-nerdtree-tabs'
            nnoremap <Leader>nt :NERDTreeTabsToggle<CR>
    Plugin 'bigolu/nord-vim'
        let g:nord_italic = 1
        let g:nord_italic_comments = 1
    Plugin 'Valloric/YouCompleteMe'
        let g:ycm_python_binary_path = 'python'
        let g:ycm_rust_src_path = '~/.rustup/toolchains/
            \stable-x86_64-apple-darwin/lib/rustlib/src/rust/src'
        let g:ycm_autoclose_preview_window_after_completion = 1
    Plugin 'junegunn/fzf.vim'
        set runtimepath+=/usr/local/opt/fzf
        let g:fzfFindLineCommand = 'rg '.$FZF_RG_OPTIONS
        let g:fzfFindFileCommand = 'rg '.$FZF_RG_OPTIONS.' --files'
        " recursive grep
        function! FindLineResultHandler(result)
            let l:resultTokens = split(a:result, ':')
            let l:filename = l:resultTokens[0]
            let l:lineNumber = str2nr(l:resultTokens[1], 10)
            execute 'silent tabedit '.l:filename
            execute ''.l:lineNumber
        endfunction
        command! -bang -nargs=* FindLine call
            \ fzf#vim#grep(
            \ g:fzfFindLineCommand.' '.shellescape(<q-args>).' | tr -d "\017"',
            \ 1,
            \ {'sink': function('FindLineResultHandler')},
            \ <bang>0)
        nnoremap <Leader>g :FindLine<CR>
        " recursive file search
        command! -bang -nargs=* FindFile call
            \ fzf#run(fzf#wrap({
            \ 'source': g:fzfFindFileCommand.' | tr -d "\017"',
            \ 'sink': 'tabedit'}))
        nnoremap <Leader>f :FindFile<CR>

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

        " Highlight lines longer than 80 chars
        augroup highlightLongLines
            autocmd!
            autocmd BufEnter * match TabLineSel /\%82v.*/
        augroup END
    endif

" Section: Aesthetics
" ----------------------
    " set colorscheme based on env var exported from ~/.bashrc
    if $THEME_TYPE ==# '1'
        set background=light
        colorscheme solarized
    else
        set termguicolors
        let g:nord_comment_brightness=20
        colorscheme nord
    endif

    " statusline
    function! LinterStatus() abort
        let l:counts = ale#statusline#Count(bufnr(''))

        let l:all_errors = l:counts.error + l:counts.style_error
        let l:all_non_errors = l:counts.total - l:all_errors

        return l:counts.total == 0 ? 'OK' : printf(
        \   '%dW,%dE',
        \   l:all_non_errors,
        \   l:all_errors
        \)
    endfunction
    let &statusline = ' %{&ff}  [%Y]  %F%m%r%h%w%=%{LinterStatus()}   %04l,%04v   %L '

    set fillchars=vert:│
    set listchars=tab:¬-,space:·

