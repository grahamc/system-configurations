-- Add icons to the gutter to represent version control changes (e.g. new lines,
-- modified lines, etc.)
Plug("mhinz/vim-signify", {
  config = function()
    -- Make `[c` and `]c` wrap around. Taken from here:
    -- https://github.com/mhinz/vim-signify/issues/239#issuecomment-305499283
    vim.cmd([[
        function! s:signify_hunk_next(count) abort
          let oldpos = getcurpos()
          silent! call sy#jump#next_hunk(a:count)
          if getcurpos() == oldpos
            silent! call sy#jump#prev_hunk(9999)
          endif
        endfunction

        function! s:signify_hunk_prev(count) abort
          let oldpos = getcurpos()
          silent! call sy#jump#prev_hunk(a:count)
          if getcurpos() == oldpos
            silent! call sy#jump#next_hunk(9999)
          endif
        endfunction

        nnoremap <silent> <expr> <plug>(sy-hunk-next) &diff
              \ ? ']c'
              \ : ":\<c-u>call <sid>signify_hunk_next(v:count1)\<cr>"
        nnoremap <silent> <expr> <plug>(sy-hunk-prev) &diff
              \ ? '[c'
              \ : ":\<c-u>call <sid>signify_hunk_prev(v:count1)\<cr>"

        nmap ]c <plug>(sy-hunk-next)
        nmap [c <plug>(sy-hunk-prev)
    ]])
  end,
})
vim.g.signify_priority = 1
vim.g.signify_sign_show_count = 0
