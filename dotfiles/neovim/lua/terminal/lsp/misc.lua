local methods = vim.lsp.protocol.Methods
local autocmd_group = vim.api.nvim_create_augroup("bigolu/lsp", {})

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

local original_diagnostic_open_float = vim.diagnostic.open_float
vim.diagnostic.open_float = function(...)
  local _, winid = original_diagnostic_open_float(...)
  if winid == nil then
    return
  end

  IsDiagnosticFloatOpen = true
  vim.cmd.redrawstatus()

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(winid),
    once = true,
    callback = function()
      IsDiagnosticFloatOpen = false
      vim.cmd.redrawstatus()
    end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      if vim.api.nvim_get_current_win() == winid then
        IsInsideDiagnosticFloat = true
        vim.cmd.redrawstatus()
        vim.api.nvim_create_autocmd("WinLeave", {
          group = autocmd_group,
          once = true,
          callback = function()
            IsInsideDiagnosticFloat = false
            vim.cmd.redrawstatus()
          end,
        })
      end
    end,
  })
end

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
vim.keymap.set("n", "]l", vim.diagnostic.goto_next, { desc = "Next diagnostic [lint,problem]" })
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Declaration" })
vim.keymap.set("n", "gn", vim.lsp.buf.rename, { desc = "Rename variable" })

-- Hide all semantic highlights
vim.api.nvim_create_autocmd("ColorScheme", {
  group = autocmd_group,
  callback = function()
    local highlights = vim.fn.getcompletion("@lsp", "highlight") or {}
    for _, group in ipairs(highlights) do
      vim.api.nvim_set_hl(0, group, {})
    end
  end,
})

-- Handle server messages with vim.notify()
-- request's type is documented here:
-- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#window_showMessageRequest
vim.lsp.handlers[methods.window_showMessage] = function(_, request, context)
  local title = "LSP"
  local client = vim.lsp.get_client_by_id(context.client_id)
  if client ~= nil then
    title = title .. " | " .. client.name
  end
  local message = title .. "\n" .. request.message

  local level = vim.log.levels[({
    "ERROR",
    "WARN",
    "INFO",
    "DEBUG",
  })[request.type]]

  vim.notify(message, level)
end

-- A language server that acts as a bridge between neovim's language server client and commandline
-- tools that don't support the language server protocol. It does this by transforming the output of
-- a commandline tool into the format specified by the language server protocol.
Plug("gbprod/none-ls-shellcheck.nvim")
Plug("nvimtools/none-ls.nvim", {
  config = function()
    local null_ls = require("null-ls")
    -- When none-ls removes this source, this will add it back
    -- null_ls.register(require("none-ls-shellcheck.code_actions"))
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
      },
    })
  end,
})

Plug("aznhe21/actions-preview.nvim", {
  config = function()
    local actions_preview = require("actions-preview")
    actions_preview.setup({
      telescope = {
        preview_title = "",
      },
    })
    vim.keymap.set({ "n", "v" }, "ga", actions_preview.code_actions, { desc = "Code actions" })
  end,
})

Plug("neovim/nvim-lspconfig", {
  config = function()
    require("lspconfig.ui.windows").default_options.border =
      { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" }
    vim.api.nvim_create_user_command("LspServerConfigurations", function()
      vim.cmd.Help("lspconfig-all")
    end, {})
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
      local code_lens_refresh_autocmd_ids_by_buffer = {}

      -- Should be idempotent since it may be called mutiple times for the same buffer. For example,
      -- it could get called again if a server registers another capability dynamically.
      local on_attach = function(client, buffer_number)
        folding_nvim.on_attach()

        local keymap_opts = { silent = true, buffer = buffer_number }
        local function buffer_keymap(mode, lhs, rhs, opts)
          vim.keymap.set(mode, lhs, rhs, vim.tbl_deep_extend("force", keymap_opts, opts or {}))
        end

        local isKeywordprgOverridable = vim.bo[buffer_number].filetype ~= "vim"
        if client.supports_method(methods.textDocument_hover) and isKeywordprgOverridable then
          buffer_keymap("n", "K", function()
            vim.lsp.buf.hover()
          end)
        end

        if client.supports_method(methods.textDocument_inlayHint) then
          -- vim.lsp.inlay_hint.enable(buffer_number, true)
          local function toggle_inlay_hints()
            vim.lsp.inlay_hint.enable(0, not vim.lsp.inlay_hint.is_enabled())
          end
          buffer_keymap("n", [[\i]], toggle_inlay_hints, { desc = "Toggle inlay hints" })
        end

        if client.supports_method(methods.textDocument_signatureHelp) then
          buffer_keymap("i", "<C-k>", function()
            vim.lsp.buf.signature_help()
          end, { desc = "Signature help" })
        end

        if client.supports_method(methods.textDocument_codeLens) then
          local function create_refresh_autocmd()
            local refresh_autocmd_id = code_lens_refresh_autocmd_ids_by_buffer[buffer_number]
            if refresh_autocmd_id ~= -1 then
              vim.notify(
                "Not creating another code lens refresh autocmd since it doesn't look like the old one was removed. The id of the old one is: "
                  .. refresh_autocmd_id,
                vim.log.levels.ERROR
              )
              return
            end
            code_lens_refresh_autocmd_ids_by_buffer[buffer_number] = vim.api.nvim_create_autocmd(
              { "CursorHold", "InsertLeave" },
              {
                desc = "code lens refresh",
                callback = function()
                  vim.lsp.codelens.refresh({ bufnr = buffer_number })
                end,
                buffer = buffer_number,
              }
            )
          end

          local function delete_refresh_autocmd()
            local refresh_autocmd_id = code_lens_refresh_autocmd_ids_by_buffer[buffer_number]
            if refresh_autocmd_id == -1 then
              vim.notify(
                "Unable to to remove the code lens refresh autocmd because it's id was not found",
                vim.log.levels.ERROR
              )
              return
            end
            vim.api.nvim_del_autocmd(refresh_autocmd_id)
            code_lens_refresh_autocmd_ids_by_buffer[buffer_number] = -1
          end

          if code_lens_refresh_autocmd_ids_by_buffer[buffer_number] == nil then
            code_lens_refresh_autocmd_ids_by_buffer[buffer_number] = -1
            create_refresh_autocmd()
          end

          buffer_keymap("n", "gl", vim.lsp.codelens.run, { desc = "Run code lens" })
          buffer_keymap("n", [[\l]], function()
            local refresh_autocmd_id = code_lens_refresh_autocmd_ids_by_buffer[buffer_number]
            local is_refresh_autocmd_active = refresh_autocmd_id ~= -1
            if is_refresh_autocmd_active then
              delete_refresh_autocmd()
              vim.lsp.codelens.clear(client.id, buffer_number)
            else
              create_refresh_autocmd()
            end
          end, { desc = "Toggle code lenses" })
        end

        -- TODO: I try just calling diagnostic.reset in here, but it didn't work. It has to be
        -- called after the handler for textDocument_(publishD|d)iagnostic runs so in here we just
        -- queue up the bufs to disable.
        local is_buffer_outside_workspace = not vim.startswith(
          vim.api.nvim_buf_get_name(buffer_number),
          client.config.root_dir or vim.loop.cwd() or ""
        )
        if is_buffer_outside_workspace then
          vim.diagnostic.reset(nil, buffer_number)
          table.insert(BufsToDisableDiagnosticOnDiagnostic, buffer_number)
          table.insert(BufsToDisableDiagnosticOnPublishDiagnostic, buffer_number)
        end

        -- Quick way to disable diagnostic for a buffer
        buffer_keymap("n", [[\d]], function()
          vim.diagnostic.reset(nil, buffer_number)
        end, { desc = "Toggle diagnostics for buffer" })
      end

      -- TODO: Would be better if I could get the buffer the these diagnostics were for from the
      -- context, but it's not in there.
      BufsToDisableDiagnosticOnPublishDiagnostic = {}
      local original_publish_diagnostics_handler =
        vim.lsp.handlers[methods.textDocument_publishDiagnostics]
      vim.lsp.handlers[methods.textDocument_publishDiagnostics] = function(...)
        local toreturn = { original_publish_diagnostics_handler(...) }

        vim.iter(BufsToDisableDiagnosticOnPublishDiagnostic):each(function(b)
          vim.diagnostic.reset(nil, b)
        end)
        BufsToDisableDiagnosticOnPublishDiagnostic = {}

        return unpack(toreturn)
      end
      BufsToDisableDiagnosticOnDiagnostic = {}
      local original_diagnostic_handler = vim.lsp.handlers[methods.textDocument_diagnostic]
      vim.lsp.handlers[methods.textDocument_diagnostic] = function(...)
        local toreturn = { original_diagnostic_handler(...) }

        vim.iter(BufsToDisableDiagnosticOnDiagnostic):each(function(b)
          vim.diagnostic.reset(nil, b)
        end)
        BufsToDisableDiagnosticOnDiagnostic = {}

        return unpack(toreturn)
      end

      -- When a server registers a capability dynamically, call on_attach again for the buffers
      -- attached to it.
      local original_register_capability = vim.lsp.handlers[methods.client_registerCapability]
      vim.lsp.handlers[methods.client_registerCapability] = function(err, res, ctx)
        local original_return_value = { original_register_capability(err, res, ctx) }

        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if client then
          vim.iter(vim.lsp.get_buffers_by_client_id(client.id)):each(function(buf)
            on_attach(client, buf)
          end)
        end

        return unpack(original_return_value)
      end

      -- For clients that aren't managed by mason-lspconfig I need to call on_attach myself
      --
      -- TODO: maybe comment here in case others are having the same issue:
      -- https://github.com/pmizio/typescript-tools.nvim/issues/63
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client_id = args.data.client_id
          local client = vim.lsp.get_client_by_id(client_id)
          if client == nil then
            vim.notify(
              "[In LspAttach autocmd] Unable to find client with id: " .. client_id,
              vim.log.levels.ERROR
            )
            return
          end
          on_attach(client, args.buf)
        end,
      })

      local capability_overrides = vim.tbl_deep_extend(
        "error",
        folding_nvim.capabilities,
        require("cmp_nvim_lsp").default_capabilities(),
        {
          workspace = {
            -- TODO: File watcher is too slow, remove this when this issue is fixed:
            -- https://github.com/neovim/neovim/issues/23291
            didChangeWatchedFiles = { dynamicRegistration = false },
          },
        }
      )
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        capability_overrides
      )

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

      local function enhanced_float_handler(handler, on_open, on_close)
        return function(err, result, ctx, config)
          local bufnr, win_id = handler(
            err,
            result,
            ctx,
            vim.tbl_deep_extend("force", config or {}, {
              -- TODO: ask if this option could accept a function instead so it can respond to
              -- window resizes
              max_height = math.floor(vim.o.lines * 0.35),
              max_width = math.floor(vim.o.columns * 0.65),
              focusable = true,
              border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
            })
          )
          if not bufnr or not win_id then
            return
          end

          vim.api.nvim_set_option_value("concealcursor", "nvic", { win = win_id })

          on_open()
          vim.api.nvim_create_autocmd("WinClosed", {
            pattern = tostring(win_id),
            once = true,
            group = autocmd_group,
            callback = function()
              on_close()
            end,
          })

          vim.api.nvim_create_autocmd("WinEnter", {
            group = autocmd_group,
            callback = function()
              if vim.api.nvim_get_current_win() == win_id then
                IsInsideLspHoverOrSignatureHelp = true
                vim.cmd.redrawstatus()
                vim.api.nvim_create_autocmd("WinLeave", {
                  group = autocmd_group,
                  once = true,
                  callback = function()
                    IsInsideLspHoverOrSignatureHelp = false
                    vim.cmd.redrawstatus()
                  end,
                })
              end
            end,
          })
        end
      end
      vim.lsp.handlers[methods.textDocument_hover] = enhanced_float_handler(
        vim.lsp.handlers.hover,
        function()
          IsLspHoverOpen = true
          vim.cmd.redrawstatus()
        end,
        function()
          IsLspHoverOpen = false
          vim.cmd.redrawstatus()
        end
      )
      vim.lsp.handlers[methods.textDocument_signatureHelp] = enhanced_float_handler(
        vim.lsp.handlers.signature_help,
        function()
          IsSignatureHelpOpen = true
          vim.cmd.redrawstatus()
        end,
        function()
          IsSignatureHelpOpen = false
          vim.cmd.redrawstatus()
        end
      )

      -- re-trigger lsp attach so nvim_lsp has a chance to attach to any buffers that were openeed
      -- before it was configured. This way I can load nvim_lsp asynchronously.
      require("terminal.utilities").trigger_lsp_attach()
    end

    -- mason.nvim needs to run it's config first so this will ensure that happens.
    vim.defer_fn(run, 0)
  end,
})

Plug("antosha417/nvim-lsp-file-operations", {
  config = function()
    require("lsp-file-operations").setup({})
  end,
})
