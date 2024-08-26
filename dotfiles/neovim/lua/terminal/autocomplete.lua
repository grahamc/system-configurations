vim.o.complete = ".,w,b,u"
vim.o.pumheight = 6
vim.o.completeopt = "menu,popup,fuzzy,noselect"

-- Should be idempotent since it may be called mutiple times for the same
-- buffer. For example, it could get called again if a server registers
-- another capability dynamically.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local methods = vim.lsp.protocol.Methods

    -- Enable completion
    if client.supports_method(methods.textDocument_completion) then
      vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
    end
  end,
})

local function keymap(lhs, rhs, opts, mode)
  opts = type(opts) == "string" and { desc = opts } or opts
  mode = mode or "n"
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function feedkeys(keys)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys, true, false, true),
    "n",
    true
  )
end

local function is_completion_menu_open()
  return tonumber(vim.fn.pumvisible()) ~= 0
end

local is_cursor_preceded_by_nonblank_character = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0
    and vim.api
        .nvim_buf_get_lines(0, line - 1, line, true)[1]
        :sub(col, col)
        :match("%s")
      == nil
end

function MyEnter()
  return is_completion_menu_open() and vim.api.nvim_replace_termcodes("<C-y>", true, false, true) or require'nvim-autopairs'.completion_confirm()
end
vim.api.nvim_set_keymap(
  'i',
  '<CR>',
  "v:lua.MyEnter()",
  { expr = true, noremap = true }
)

keymap("<Tab>", function()
  if is_completion_menu_open() then
    -- Select next entry
    feedkeys("<C-n>")
  elseif is_cursor_preceded_by_nonblank_character() then
    local is_any_lsp_server_running = next(vim.lsp.get_clients({ bufnr = 0 }))
    if is_any_lsp_server_running then
      vim.lsp.completion.trigger()
    else
      -- Buffer complete
      feedkeys("<C-n>")
    end
  else
    feedkeys("<Tab>")
  end
end, { desc = "Trigger/select next completion" }, "i")

keymap("<S-Tab>", function()
  return is_completion_menu_open() and "<C-p>" or "<S-Tab>"
end, {desc = "Select last completion", expr = true,}, "i")

keymap("<C-f>", "<C-x><C-f>", { desc = "File completion" }, "i")
