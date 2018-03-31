" Section: Settings
" ----------------------
    " stops vim from behaving in a strongly vi-compatible way
    set nocompatible

    " misc.
    set encoding=utf8
    syntax enable
    set mouse=a
    set backspace=indent,eol,start
    set linebreak
    set cursorline
    set pastetoggle=<F2>
    set ls=2
    set nu
    set relativenumber

    " tab setup
    set expandtab
    let tab_width = 4
    let &tabstop = tab_width
    let &shiftwidth = tab_width
    let &softtabstop = tab_width

    " when used together, searching is only case sensitive when
    " the query contains an uppercase letter
    set ignorecase
    set smartcase

    " persist undo history to disk
    let &undodir = "/Users/bigolu/.vim/undodir/"
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
    nnoremap <Leader>qa :qa<CR>
    nnoremap <Leader>x :x<CR>
    nnoremap <Leader>r :source $MYVIMRC<CR>
    nnoremap <Leader>t :set list!<CR>
    nnoremap <Leader>go :Goyo<CR>

    " remove all trailing whitespace
    nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

    " Shift line up or down
    noremap <C-u> ddp
    noremap <C-i> ddkkp

    " open :help in a new tab
    cnoreabbrev <expr> h
        \ getcmdtype() == ":" && getcmdline() == 'h' ? 'tab h' : 'h'
    cnoreabbrev <expr> help
        \ getcmdtype() == ":" && getcmdline() == 'help' ? 'tab h' : 'help'

" Section: Autocommands
" ---------------------
    if has("autocmd")
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
            autocmd BufEnter * match TabLineSel /\%81v.*/
        augroup END

        " Auto load/create Session when no cmdline args are specified
        augroup sessionManager
            autocmd VimEnter *
                \ let vimCommand = system("ps -o command= -p ".getpid()) |
                \ let vimArgs = split(vimCommand)[1:] |
                \ if len(vimArgs) == 0 |
                \   let sessionDir = "~/.vim/sessions/" |
                \   let sessionFile = expand(sessionDir.join(split(getcwd(), "/"), ".").".vim") |
                \   let sessionCmd = filereadable(sessionFile) ? "source " : "Obsession " |
                \   execute sessionCmd . sessionFile |
                \ fi
        augroup END
    endif

" Section: Plugins
" ------------------------------------
    filetype off
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#begin()

    Plugin 'VundleVim/Vundle.vim'
    Plugin 'sheerun/vim-polyglot'
    Plugin 'airblade/vim-gitgutter'
    Plugin 'bigolu/vim-colors-solarized'
    Plugin 'w0rp/ale'
    Plugin 'junegunn/goyo.vim'
    Plugin 'tpope/vim-surround'
    Plugin 'tpope/vim-commentary'
    Plugin 'bigolu/vim-tmux-navigator'
    Plugin 'tpope/vim-obsession'
    Plugin 'bigolu/tabline.vim'
    Plugin 'valloric/MatchTagAlways'
    let g:mta_filetypes = {
        \ 'html' : 1,
        \ 'xml' : 1,
        \ 'xhtml' : 1,
        \ 'jinja' : 1,
        \ 'javascript.jsx' : 1
    \}
    Plugin 'bigolu/nerdtree'
        let NERDTreeMouseMode=2
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
        set rtp+=/usr/local/opt/fzf
        let fzfFindLineCommand = 'rg '.$FZF_RG_OPTIONS
        let fzfFindFileCommand = 'rg '.$FZF_RG_OPTIONS.' --files'
        " recursive grep
        function! FindLineResultHandler(result)
            let resultTokens = split(a:result, ':')
            let filename = resultTokens[0]
            let lineNumber = str2nr(resultTokens[1], 10)
            execute "silent tabedit ".filename
            execute "".lineNumber
        endfunction
        command! -bang -nargs=* FindLine call
            \ fzf#vim#grep(
            \ fzfFindLineCommand.' '.shellescape(<q-args>).' | tr -d "\017"',
            \ 1,
            \ {'sink': function('FindLineResultHandler')},
            \ <bang>0)
        nnoremap <Leader>g :FindLine<CR>
        " recursive file search
        command! -bang -nargs=* FindFile call
            \ fzf#run(fzf#wrap({
            \ 'source': fzfFindFileCommand.' | tr -d "\017"',
            \ 'sink': 'tabedit'}))
        nnoremap <Leader>f :FindFile<CR>

    call vundle#end()
    filetype plugin indent on

" Section: Aesthetics
" ----------------------
    " set colorscheme based on env var exported from ~/.bashrc
    if $THEME_TYPE ==# "1"
        set background=light
        colorscheme solarized
    else
        " use bright grey comment color if `truecolor` is availible
        " else, use yellow
        if $COLORTERM =~ "truecolor" || $COLORTERM =~ "24bit"
            set termguicolors
            let g:nord_comment_brightness=20
            colorscheme nord
        else
            set background=dark
            colorscheme nord
            hi Comment ctermfg=3
        endif
    endif

    " status line
    set statusline=%{&ff}\ \ \ %Y\ \ \ %F%m%r%h%w%=%04l,%04v\ \ \ %L

    " a nice, thin vertical split line
    set fillchars=vert:│

    " characters to substitute for unprintable characters
    set listchars=tab:¬-,space:·

