" vim:foldmethod=marker

" Exit if we are not running inside vscode
if !exists('g:vscode')
  finish
endif

nnoremap <Leader>x :Wqall<CR>
nnoremap <silent> <Leader>w :Wall<CR>
nnoremap <silent> <Leader>q :Quit<CR>
nmap <Leader><Bar> <C-w>v
nmap <Leader>- <C-w>s
nnoremap <silent> <Leader>f :Find<CR>
nnoremap <silent> <Leader>g :call VSCodeNotify("workbench.action.findInFiles")<CR>

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
