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
set complete-=i
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
set nojoinspaces " Prevents inserting two spaces after punctuation on a join (J)
set shiftround " Round indent to multiple of shiftwidth (applies to < and >)
set autoread " Re-read file if it is changed by an external program

" turn off bell sound for completion
set belloff+=ctrlg

" show the completion [menu] even if there is only [one] suggestion
" by default, [no] suggestion is [select]ed
set completeopt+=menuone,noselect

" don't display messages related to completion
set shortmess+=c

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

" set backup directory
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
nnoremap <Leader>q :q<CR>
nnoremap <Leader>qa :qa<CR>
nnoremap <Leader>r :source $MYVIMRC<CR>
nnoremap <Leader>x :wqa<CR>
nnoremap <Leader>t :IndentLinesToggle<CR>
nnoremap <C-p> :Commands<CR>

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
nnoremap ∆ 10<C-e>
nnoremap ˚ 10<C-y>
vnoremap ∆ 10<C-e>
vnoremap ˚ 10<C-y>


" open :help in a new tab
cnoreabbrev <expr> h
    \ getcmdtype() == ":" && getcmdline() == 'h' ? 'tab h' : 'h'
cnoreabbrev <expr> help
    \ getcmdtype() == ":" && getcmdline() == 'help' ? 'tab h' : 'help'

" Section: Plugins
" ------------------------------------
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'Yggdroot/indentLine'
    let g:indentLine_char = '│'
    let g:indentLine_setColors = 0
Plugin 'tpope/vim-endwise'
Plugin 'mattn/emmet-vim'
    let g:user_emmet_leader_key='<C-e>'
    let g:user_emmet_mode='in'
Plugin 'alvan/vim-closetag'
Plugin 'Raimondi/delimitMate'
Plugin 'unkiwii/vim-nerdtree-sync'
    let g:nerdtree_sync_cursorline = 1
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
    let g:mucomplete#enable_auto_at_startup = 1
    let g:mucomplete#chains = {
	    \ 'typescriptreact': ['user', 'c-n', 'file'],
	    \ 'html': ['user', 'c-n', 'file']
	    \ }
Plugin 'dense-analysis/ale'
    let g:ale_fixers = {'*': ['prettier']}
    let g:ale_fix_on_save = 1
    let g:ale_completion_autoimport = 1
    let g:ale_set_balloons = 1
    " TODO: this could probably be its own plugin
    let g:multicomplete_completers = [function('ale#completion#OmniFunc'), function('emmet#completeTag')]
    function! MultiComplete(findstart, base)
        " TODO: what if the findstarts are different?
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
                    let l:result = max([l:result, l:completer_result])
                endif
            endfor
            return l:result
        endif

        " TODO: maybe interlaeve the results so top answer from all completers
        " are at the top
        let l:results = []
        let l:i = 0
        for l:Completer in g:multicomplete_completers
            if g:findstarts->get(l:i) >= 0
                call extend(l:results, l:Completer(a:findstart, a:base))
            endif
            let l:i = l:i + 1
        endfor
        return l:results
    endfunction
    set completefunc=MultiComplete
Plugin 'tpope/vim-dispatch'
Plugin 'sheerun/vim-polyglot'
" TODO: should just use native session api
Plugin 'tpope/vim-obsession'
" TODO: extract into vimrc
Plugin 'bigolu/tabline.vim'
Plugin 'lifepillar/vim-solarized8'
Plugin 'arcticicestudio/nord-vim'
" Plug 'christoomey/vim-tmux-navigator'
"     " If there's more than one tab open,
"     " change tabs instead of windows
"     function! TmuxNavigateVimTab(direction)
"       " save output of :tabs command into the '*' register
"       silent execute "redir @z | tabs | redir END"

"       " if the output of :tabs has the number 2 in it
"       " then there is more than one tab open
"       if @a =~ "Tab page 2"
"           if a:direction == "h"
"               execute "tabp"
"           else
"               execute "tabn"
"           endif
"       endif
"     endfunction
"     let g:tmux_navigator_no_mappings = 1
"     nnoremap <silent> <C-h> :call TmuxNavigateVimTab('h')<cr>
"     nnoremap <silent> <C-l> :call TmuxNavigateVimTab('l')<cr>
"     nnoremap <silent> <c-j> :TmuxNavigateDown<cr>
"     nnoremap <silent> <c-k> :TmuxNavigateUp<cr>
"     nnoremap <silent> <c-\> :TmuxNavigatePrevious<cr>
Plugin 'junegunn/fzf.vim'
    set runtimepath+=/usr/local/opt/fzf
    let g:fzfFindLineCommand = 'rg '.$FZF_RG_OPTIONS
    let g:fzfFindFileCommand = 'rg '.$FZF_RG_OPTIONS.' --files'
    " recursive grep
    function! FindLineResultHandler(result)
        let l:resultTokens = split(a:result, ':')
        let l:filename = l:resultTokens[0]
        let l:lineNumber = l:resultTokens[1]
        execute 'silent tabedit '.l:filename
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
        \ 'sink': 'tabedit'}))
    nnoremap <Leader>f :FindFile<CR>
Plugin 'bigolu/nerdtree'
    let g:NERDTreeMouseMode=2
    Plugin 'jistr/vim-nerdtree-tabs'
        nnoremap <Leader>n :NERDTreeTabsToggle<CR>

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
        silent! execute "source " . l:session_full_path
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
      autocmd VimEnter * call StartWorkspace()
    augroup END
endif

" Section: Aesthetics
" ----------------------
set fillchars=vert:│
set listchars=tab:¬-,space:·
let &statusline = ' %Y %F%m%r%h%w%=%04l,%04v %L '
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
call timer_start(1000, "SetColorscheme", {"repeat": -1})

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
