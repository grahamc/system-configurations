vim.diagnostic.config({
  signs = false,
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

vim.keymap.set(
  "n",
  "<S-l>",
  vim.diagnostic.open_float,
  { desc = "Diagnostic modal [lint,problem]" }
)
vim.keymap.set(
  "n",
  "[l",
  vim.diagnostic.goto_prev,
  { desc = "Previous diagnostic [last,lint,problem]" }
)
vim.keymap.set(
  "n",
  "]l",
  vim.diagnostic.goto_next,
  { desc = "Next diagnostic [last,lint,problem]" }
)
vim.keymap.set("n", "gi", function()
  require("telescope.builtin").lsp_implementations({ preview_title = "" })
end, { desc = "Implementation" })
vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "Show signature help" })
vim.keymap.set("n", "gt", function()
  require("telescope.builtin").lsp_type_definitions({ preview_title = "" })
end, { desc = "Type definition" })
vim.keymap.set("n", "gd", function()
  require("telescope.builtin").lsp_definitions({ preview_title = "" })
end, { desc = "Definition" })
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Declaration" })
vim.keymap.set("n", "ghi", function()
  require("telescope.builtin").lsp_incoming_calls({ preview_title = "" })
end, { desc = "Incoming call hierarchy" })
vim.keymap.set("n", "gho", function()
  require("telescope.builtin").lsp_outgoing_calls({ preview_title = "" })
end, { desc = "Outgoing call hierarchy" })
vim.keymap.set("n", "gn", vim.lsp.buf.rename, { desc = "Rename variable" })

-- TODO: When there is only one result, it doesn't add to the jumplist so I'm adding that here. I
-- should upstream this.
vim.keymap.set(
  "n",
  "gr",
  require("terminal.utilities").set_jump_before(function()
    require("telescope.builtin").lsp_references({ preview_title = "" })
  end),
  { desc = "References" }
)

-- Hide all semantic highlights
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  group = vim.api.nvim_create_augroup("DisableLspHighlights", {}),
  callback = function()
    local highlights = vim.fn.getcompletion("@lsp", "highlight") or {}
    for _, group in ipairs(highlights) do
      vim.api.nvim_set_hl(0, group, {})
    end
  end,
})

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
    vim.keymap.set({ "n", "v" }, "ga", actions_preview.code_actions, { desc = "Code actions" })
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

Plug("williamboman/mason-lspconfig.nvim", {
  config = function()
    local function run()
      require("mason-lspconfig").setup()
      local lspconfig = require("lspconfig")
      local folding_nvim = require("terminal.folds.folding-nvim")

      local on_attach = function(client, buffer_number)
        local methods = vim.lsp.protocol.Methods
        local buffer_keymap = vim.api.nvim_buf_set_keymap
        local keymap_opts = { noremap = true, silent = true }

        folding_nvim.on_attach()

        local isKeywordprgOverridable = vim.bo[buffer_number].filetype ~= "vim"
        if client.supports_method(methods.textDocument_hover) and isKeywordprgOverridable then
          buffer_keymap(buffer_number, "n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", keymap_opts)

          -- Change border of documentation hover window, See https://github.com/neovim/neovim/pull/13998.
          vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
            focusable = true,
            border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
          })
        end

        if client.supports_method(methods.textDocument_inlayHint) then
          -- vim.lsp.inlay_hint.enable(buffer_number, true)
          local function toggle_inlay_hints()
            vim.lsp.inlay_hint.enable(0, not vim.lsp.inlay_hint.is_enabled())
          end
          vim.keymap.set(
            "n",
            [[\i]],
            toggle_inlay_hints,
            { silent = true, desc = "Toggle inlay hints" }
          )
        end
      end

      local cmp_lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
      local folding_capabilities = folding_nvim.capabilities
      local capabilities = vim.tbl_deep_extend("error", cmp_lsp_capabilities, folding_capabilities)

      local server_config_handlers = {}
      local default_server_config = {
        capabilities = capabilities,
        on_attach = on_attach,
      }
      -- Default handler to be called for each installed server that doesn't have a dedicated handler.
      server_config_handlers[1] = function(server_name)
        lspconfig[server_name].setup(default_server_config)
      end
      -- server-specific handlers
      local server_specific_configs = require("terminal.lsp.server-settings").get(on_attach)
      for server_name, server_specific_config in pairs(server_specific_configs) do
        server_config_handlers[server_name] = function()
          lspconfig[server_name].setup(
            vim.tbl_deep_extend("force", default_server_config, server_specific_config)
          )
        end
      end
      require("mason-lspconfig").setup_handlers(server_config_handlers)

      -- Set the filetype of all the currently open buffers to trigger a 'FileType' event for each
      -- buffer so nvim_lsp has a chance to attach to any buffers that were openeed before it was
      -- configured. This way I can load nvim_lsp asynchronously.
      local buffer = vim.api.nvim_get_current_buf()
      vim.cmd([[
          silent! bufdo silent! lua vim.bo.filetype = vim.bo.filetype
      ]])
      vim.cmd.b(buffer)
    end

    -- mason.nvim needs to run it's config first so this will ensure that happens.
    vim.defer_fn(run, 0)
  end,
})
