vim.o.linebreak = true
vim.o.breakat = " ^I"
vim.o.cursorline = true
vim.o.cursorlineopt = "number,screenline"
vim.o.wrap = true
-- chars to represent tabs and spaces when 'setlist' is enabled
vim.o.listchars = "tab:¬-,space:·"
vim.opt.fillchars:append("eob: ")

vim.cmd.colorscheme('ansi')

-- cursor
local function set_cursor()
  -- Block cursor in normal mode, thin line in insert mode, and underline in replace mode
  vim.o.guicursor =
    "n-v:block-blinkon0,i-c-ci-ve:ver25-blinkwait0-blinkon200-blinkoff200,r-cr-o:hor20-blinkwait0-blinkon200-blinkoff200"
end
local function reset_cursor()
  -- Reset terminal cursor to blinking bar.
  -- TODO: This won't be necessary once neovim starts doing this automatically.
  -- Issue: https://github.com/neovim/neovim/issues/4396
  vim.o.guicursor = "a:ver25-blinkwait0-blinkon200-blinkoff200"
end
set_cursor()
local cursor_group_id = vim.api.nvim_create_augroup("Cursor", {})
vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  callback = reset_cursor,
  group = cursor_group_id,
})
vim.api.nvim_create_autocmd({ "VimResume" }, {
  callback = set_cursor,
  group = cursor_group_id,
})

vim.defer_fn(function()
  vim.fn["plug#load"]("dressing.nvim")
end, 0)
Plug("stevearc/dressing.nvim", {
  on = {},
  config = function()
    require("dressing").setup({
      input = {
        enabled = true,
        default_prompt = "Input:",
        trim_prompt = false,
        border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        relative = "editor",
        prefer_width = 0.5,
        width = 0.5,
        max_width = 500,
      },
    })

    local dressing_group = vim.api.nvim_create_augroup("MyDressing", {})
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "DressingInput",
      group = dressing_group,
      callback = function()
        -- After I accept an autocomplete entry from nvim-cmp, buflisted gets set to true so
        -- this sets it back to false.
        vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
          group = dressing_group,
          buffer = vim.api.nvim_get_current_buf(),
          callback = function()
            vim.bo.buflisted = false
          end,
        })
      end,
    })
  end,
})
