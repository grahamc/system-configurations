local M = {}

function M.set_jump_before(fn)
  return function(...)
    vim.cmd([[
      normal! m'
    ]])
    fn(...)
  end
end

-- Some highlights don't exist in the colorscheme so when I switch they would be erased.
-- This will retain them.
local id_map = {}
function M.set_persistent_highlights(key, highlights)
  local function helper()
    vim.iter(highlights):each(function(from, to)
      vim.api.nvim_set_hl(0, from, { link = to })
    end)
  end
  helper()
  if id_map[key] ~= nil then
    vim.api.nvim_del_autocmd(id_map[key])
  end
  id_map[key] = vim.api.nvim_create_autocmd("ColorScheme", { callback = helper })
end

return M
