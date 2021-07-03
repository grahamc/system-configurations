" Section: Helpers
" ------------------
let $VIMHOME = $HOME . '/.vim/'

function! MakeDirectory(path)
    execute 'silent !mkdir -p ' . a:path . ' > /dev/null 2>&1'
endfunction

function! FileExists(path)
    return !empty(glob(a:path))
endfunction

function! WeeklyPluginUpdate()
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
if !exists('g:vscode')
    let &ttymouse = has('mouse_sgr') ? 'sgr' : 'xterm2'
endif

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
nnoremap <C-p> :Commands<CR>

" wrap a function call in another function call.
" this is done by looking for a function call under the cursor and if found,
" wrapping it with parentheses and then going into
" insert mode so the wrapper function name can be typed
let @w='vicS)i'

" remove all trailing whitespace
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" Shift line up or down
nnoremap <C-u> :m .+1<CR>==
nnoremap <C-i> :m .-2<CR>==
vnoremap <C-u> :m '>+1<CR>gv=gv
vnoremap <C-i> :m '<-2<CR>gv=gv

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
if !FileExists('~/.vim/autoload/plug.vim')
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
Plug 'jiangmiao/auto-pairs'
Plug 'unkiwii/vim-nerdtree-sync'
    let g:nerdtree_sync_cursorline = 1
Plug 'michaeljsmith/vim-indent-object'
Plug 'ap/vim-css-color'
Plug 'KabbAmine/vCoolor.vim'
Plug 'tpope/vim-surround'
Plug 'machakann/vim-textobj-functioncall'
    let g:textobj_functioncall_no_default_key_mappings = 1
    xmap ic <Plug>(textobj-functioncall-i)
    omap ic <Plug>(textobj-functioncall-i)
    xmap ac <Plug>(textobj-functioncall-a)
    omap ac <Plug>(textobj-functioncall-a)
" some of the settings for ale need to be enabled before the plugin is loaded so
" I'm just putting all the settings first
let g:ale_fixers = {'*': ['prettier']}
let g:ale_fix_on_save = 1
let g:ale_completion_enabled = 1
let g:ale_completion_autoimport = 1
let g:ale_set_balloons = 1
inoremap <silent><expr> <Tab>
            \ pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <silent><expr> <S-Tab>
            \ pumvisible() ? "\<C-p>" : "\<S-TAB>"
    Plug 'dense-analysis/ale'
Plug 'tpope/vim-dispatch'
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-obsession'
Plug 'bigolu/tabline.vim'
Plug 'lifepillar/vim-solarized8'
Plug 'arcticicestudio/nord-vim'
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
Plug 'junegunn/fzf.vim'
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
Plug 'bigolu/nerdtree' | Plug 'jistr/vim-nerdtree-tabs'
    nnoremap <Leader>n :NERDTreeTabsToggle<CR>
    let g:NERDTreeMouseMode=2
call plug#end()

call WeeklyPluginUpdate()

" Section: Autocommands
" ---------------------
function! CleanNoNameEmptyBuffers()
    let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val) && empty(bufname(v:val)) && bufwinnr(v:val) < 0 && (getbufline(v:val, 1, "$") == [""])')
    if !empty(buffers)
        exe 'bd '.join(buffers, ' ')
    endif
endfunction
nnoremap <silent> <Leader>c :call CleanNoNameEmptyBuffers()<CR>

if has('autocmd')
    augroup restoreLastCursorPosition
        autocmd!
        autocmd BufReadPost *
                    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
                    \   exe "normal! g'\"" |
                    \ endif
    augroup END
    augroup nordOverrides
      autocmd!
      autocmd ColorScheme nord highlight Comment guifg=#6d7a96
    augroup END
    augroup solarizedOverrides
      autocmd!
    augroup END
    augroup cleanEmpryBuffers
      autocmd!
      " autocmd BufEnter * call CleanNoNameEmptyBuffers()
    augroup END
endif

" Section: Aesthetics
" ----------------------
set fillchars=vert:│
set listchars=tab:¬-,space:·
let &statusline = ' %Y %F%m%r%h%w%=%04l,%04v %L '
set signcolumn=yes

" Block cursor in normal mode and thin line in insert mode
if !exists('g:vscode')
    if exists('$TMUX')
      let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
      let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
    else
      let &t_SI = "\<Esc>]50;CursorShape=1\x7"
      let &t_EI = "\<Esc>]50;CursorShape=0\x7"
    endif
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

