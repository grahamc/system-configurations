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
    let $BASH_ENV = "~/.bashrc"
    set grepprg=rg\ --vimgrep
    set colorcolumn=80
    set ls=2

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

    " remove all trailing whitespace
    nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

    " Shift line up or down
    noremap <C-u> ddp
    noremap <C-i> ddkkp

    " open :help in a new tab
    cnoreabbrev <expr> h getcmdtype() == ":" && getcmdline() == 'h' ? 'tab h' : 'tab h'
    cnoreabbrev <expr> help getcmdtype() == ":" && getcmdline() == 'help' ? 'tab h' : 'tab h'


" Section: Plugins
" ------------------------------------
    filetype off
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#begin()

    Plugin 'VundleVim/Vundle.vim'
    Plugin 'sheerun/vim-polyglot'
    Plugin 'airblade/vim-gitgutter'
    Plugin 'bigolu/vim-tmux-navigator'
    Plugin 'altercation/vim-colors-solarized'
    Plugin 'arcticicestudio/nord-vim'
        let g:nord_italic = 1
        let g:nord_italic_comments = 1
    Plugin 'bigolu/nerdtree'
        let NERDTreeMouseMode=2
        Plugin 'jistr/vim-nerdtree-tabs'
            nnoremap <Leader>nt :NERDTreeTabsToggle<CR>
    Plugin 'Valloric/YouCompleteMe'
        let g:ycm_python_binary_path = 'python3'
        let g:ycm_rust_src_path = '~/.rustup/toolchains/
            \stable-x86_64-apple-darwin/lib/rustlib/src/rust/src'
        let g:ycm_autoclose_preview_window_after_completion = 1
    Plugin 'junegunn/fzf.vim'
        set rtp+=/usr/local/opt/fzf
        function! FindLineResultHandler(result)
            let filename = split(a:result, ':')[0]
            execute "silent tabedit ".filename
        endfunction
        command! -bang -nargs=* FindLine call
            \ fzf#vim#grep('rg --column --line-number --no-heading
            \ --fixed-strings --ignore-case --no-ignore --hidden --follow
            \ --glob "!.git/*" '.shellescape(<q-args>).'| tr -d "\017"', 1,
            \ {'sink': function('FindLineResultHandler')}, <bang>0)
        nnoremap <Leader>g :FindLine<CR>
        command! -bang -nargs=* FindFile call
            \ fzf#run(fzf#wrap({'source': 'rg --files --hidden --no-ignore
            \ --follow --ignore-case --glob "!.git/*" | tr -d "\017"',
            \ 'sink': 'tabedit'}))
        nnoremap <Leader>f :FindFile<CR>

    call vundle#end()
    filetype plugin indent on

" Section: Aesthetics
" -------------------
    " set colorscheme based on time of day
    if $IS_DAYTIME ==# "1"
        set background=light
        colorscheme solarized
    else
        " comment color
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
    
    " transparent gutter
    hi LineNR ctermbg=NONE guibg=NONE

    " underline current line as opposed to highlighting
    hi CursorLine cterm=underline ctermfg=NONE ctermbg=NONE guibg=NONE

    " set vertical split bar to '|'
    set fillchars=vert:│
    hi VertSplit ctermbg=NONE guibg=NONE

    " status line (mostly stolen)
    " https://www.linux.com/news/more-informative-status-line-vim
    set statusline=%{&ff}\ \ \ %Y\ \ \ %F%m%r%h%w%=%04l,%04v\ \ \ %L
    hi StatusLine guibg=#3B4252

    " tabline (mostly stolen): https://github.com/mkitt/tabline.vim
    function! Tabline()
      let s = ''
      for i in range(tabpagenr('$'))
        let tab = i + 1
        let winnr = tabpagewinnr(tab)
        let buflist = tabpagebuflist(tab)
        let bufnr = buflist[winnr - 1]
        let bufname = bufname(bufnr)
        let bufmodified = getbufvar(bufnr, "&mod")

        let s .= '%' . tab . 'T'
        let s .= tab == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#'
        let s .= bufname != '' ? fnamemodify(bufname, ':t') . ' '
            \ : '[No Name] '

        if bufmodified
          let s .= '[+] '
        endif

        if i < (tabpagenr('$') - 1)
            let s .= '%#TabLine#│ '
        endif
      endfor

      let s .= '%#TabLineFill#%=%999XX'
      return s
    endfunction
    set tabline=%!Tabline()
    hi TabLine ctermfg=NONE ctermbg=NONE
    hi TabLineFill ctermfg=NONE ctermbg=NONE
    hi TabLineSel ctermfg=NONE ctermbg=NONE guibg=#3B4252

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

