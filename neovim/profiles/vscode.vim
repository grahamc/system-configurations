" Exit if we are not running inside vscode
if !exists('g:vscode')
  finish
endif

lua << EOF
vim.keymap.set('', '<C-s>', '<Cmd>xa<CR>')
vim.keymap.set('', '<C-x>', '<Cmd>call VSCodeNotify("workbench.action.quit")<CR>')
EOF

" search
nnoremap <silent> <Leader>f :Find<CR>
nnoremap <silent> <Leader>g :call VSCodeNotify("workbench.action.findInFiles")<CR>
nnoremap <silent> <Leader>s :call VSCodeNotify("workbench.action.showAllSymbols")<CR>

" window
nmap <Leader><Bar> <C-w>v
nmap <Leader>- <C-w>s

" Folds
nnoremap <silent> <Tab> :call VSCodeNotify('editor.toggleFold')<CR>
function! FoldToggle()
  if !exists('g:is_folded')
    let g:is_folded = 0
  endif
if g:is_folded
    call VSCodeNotify('editor.unfoldAll')
    let g:is_folded = 0
  else
    call VSCodeNotify('editor.foldAll')
    let g:is_folded = 1
  endif
endfunction
nnoremap <silent> <S-Tab> :call FoldToggle()<CR>
function! MoveCursor(direction) abort
    if(reg_recording() == '' && reg_executing() == '')
        return 'g'.a:direction
    else
        return a:direction
    endif
endfunction
" TODO: These mappings allow me to move over folds without opening them. However, I won't be able to navigate through
" folds while creating a macro.
" source: https://github.com/vscode-neovim/vscode-neovim/issues/58#issuecomment-989481648
nmap <expr> j MoveCursor('j')
nmap <expr> k MoveCursor('k')
nnoremap [<Tab> :call VSCodeNotify('editor.gotoPreviousFold')<CR>
nnoremap ]<Tab> :call VSCodeNotify('editor.gotoNextFold')<CR>
xnoremap [<Tab> :call VSCodeNotify('editor.gotoPreviousFold')<CR>
xnoremap ]<Tab> :call VSCodeNotify('editor.gotoNextFold')<CR>

" comment
xmap gc  <Plug>VSCodeCommentary
nmap gc  <Plug>VSCodeCommentary
omap gc  <Plug>VSCodeCommentary
nmap gcc <Plug>VSCodeCommentaryLine

" language server
nnoremap [l :call VSCodeNotify('editor.action.marker.prev')<CR>
nnoremap ]l :call VSCodeNotify('editor.action.marker.next')<CR>
" Since vscode only has one hover action to show docs and lints I'll have my lint keybind also trigger hover
nmap <S-l> <S-k>
nnoremap ga :call VSCodeNotify('editor.action.quickFix')<CR>
nnoremap gi :call VSCodeNotify('editor.action.goToImplementation')<CR>
nnoremap gr :call VSCodeNotify('editor.action.goToReferences')<CR>
nnoremap gn :call VSCodeNotify('editor.action.rename')<CR>
nnoremap gt :call VSCodeNotify('editor.action.goToTypeDefinition')<CR>
nnoremap gd :call VSCodeNotify('editor.action.revealDefinition')<CR>
nnoremap gD :call VSCodeNotify('editor.action.revealDeclaration')<CR>
nnoremap gh :call VSCodeNotify('references-view.showCallHierarchy')<CR>
nnoremap ght :call VSCodeNotify('references-view.showTypeHierarchy')<CR>

" version control
nnoremap zv :call VSCodeNotify('editor.action.dirtydiff.next')<CR>
nnoremap ]c :call VSCodeNotify('workbench.action.editor.nextChange')<CR>
nnoremap [c :call VSCodeNotify('workbench.action.editor.previousChange')<CR>

" right click
nnoremap <Leader><Leader> :call VSCodeNotify('editor.action.showContextMenu')<CR>

" move forward in the jumplist
nnoremap <C-p> <C-i>

" resize panes
nnoremap <silent> <C-Left> :call VSCodeNotify('workbench.action.decreaseViewWidth')<CR>
nnoremap <silent> <C-Right> :call VSCodeNotify('workbench.action.increaseViewWidth')<CR>
nnoremap <silent> <C-Down> :call VSCodeNotify('workbench.action.decreaseViewHeight')<CR>
nnoremap <silent> <C-Up> :call VSCodeNotify('workbench.action.increaseViewHeight')<CR>
