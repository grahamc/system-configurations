local M = {}

function M.set_jump_before(fn)
  return function(...)
    vim.cmd([[
      normal! m'
    ]])
    fn(...)
  end
end

return M
