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
