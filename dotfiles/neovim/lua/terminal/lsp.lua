vim.diagnostic.config({
  virtual_text = {
    prefix = "",
  },
  update_in_insert = true,
  -- With this enabled, sign priorities will become: hint=11, info=12, warn=13, error=14
  severity_sort = true,
  float = {
    source = true,
    focusable = true,
    border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
    format = function(diagnostic)
      local result = diagnostic.message

      local code = diagnostic.code
      if code ~= nil then
        result = result .. string.format(" [%s]", code)
      end

      return result
    end,
  },
})

local bullet = "•"
local signs = { Error = bullet, Warn = bullet, Hint = bullet, Info = bullet }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl })
end

vim.keymap.set("n", "<S-l>", vim.diagnostic.open_float, { desc = "Show diagnostics" })
vim.keymap.set("n", "[l", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
vim.keymap.set("n", "]l", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
vim.keymap.set("n", "gi", function()
  require("telescope.builtin").lsp_implementations({ preview_title = "" })
end, { desc = "Go to implementation" })
vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "Show signature help" })
vim.keymap.set("n", "gt", function()
  require("telescope.builtin").lsp_type_definitions({ preview_title = "" })
end, { desc = "Go to type definition" })
vim.keymap.set("n", "gd", function()
  require("telescope.builtin").lsp_definitions({ preview_title = "" })
end, { desc = "Go to definition" })
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
vim.keymap.set("n", "ghi", function()
  require("telescope.builtin").lsp_incoming_calls({ preview_title = "" })
end, { desc = "Show incoming calls" })
vim.keymap.set("n", "gho", function()
  require("telescope.builtin").lsp_outgoing_calls({ preview_title = "" })
end, { desc = "Show outgoing calls" })
vim.keymap.set("n", "gn", vim.lsp.buf.rename, { desc = "Rename" })

-- TODO: When there is only one result, it doesn't add to the jumplist so I'm adding that here. I
-- should upstream this.
vim.keymap.set(
  "n",
  "gr",
  require("terminal.utilities").set_jump_before(function()
    require("telescope.builtin").lsp_references()
  end),
  { desc = "Go to reference" }
)

-- A language server that acts as a bridge between neovim's language server client and commandline
-- tools that don't support the language server protocol. It does this by transforming the output of
-- a commandline tool into the format specified by the language server protocol.
Plug("nvimtools/none-ls.nvim", {
  config = function()
    local null_ls = require("null-ls")
    local builtins = null_ls.builtins
    null_ls.setup({
      border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
      sources = {
        builtins.code_actions.shellcheck.with({
          filetypes = { "sh", "bash" },
        }),
        builtins.diagnostics.fish,
        builtins.diagnostics.markdownlint_cli2,
        builtins.diagnostics.markdownlint,
        builtins.diagnostics.actionlint,
      },
    })
  end,
})

Plug("aznhe21/actions-preview.nvim", {
  config = function()
    local actions_preview = require("actions-preview")
    actions_preview.setup({
      telescope = {},
    })
    vim.keymap.set(
      { "n", "v" },
      "ga",
      actions_preview.code_actions,
      { desc = "Choose code action" }
    )
  end,
})

Plug("neovim/nvim-lspconfig", {
  config = function()
    require("lspconfig.ui.windows").default_options.border =
      { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" }
  end,
})

Plug("kosayoda/nvim-lightbulb", {
  config = function()
    require("nvim-lightbulb").setup({
      autocmd = { enabled = true },
      -- Giving it a higher priority than diagnostics
      sign = {
        priority = 15,
        text = "",
        hl = "CodeActionSign",
      },
    })
  end,
})
