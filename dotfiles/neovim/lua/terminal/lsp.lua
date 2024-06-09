local methods = vim.lsp.protocol.Methods
local autocmd_group = vim.api.nvim_create_augroup("bigolu/lsp", {})

vim.diagnostic.config({
  signs = false,
  virtual_text = {
    prefix = "",
  },
  update_in_insert = true,
  -- With this enabled, sign priorities will become:
  -- hint=11, info=12, warn=13, error=14
  severity_sort = true,
  float = {
    source = true,
    focusable = true,
    border = { " ", " ", " ", " ", " ", " ", " ", " " },
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

  vim.api.nvim_set_option_value(
    "winhighlight",
    "NormalFloat:CmpDocumentationNormal,FloatBorder:CmpDocumentationBorder,CursorLine:NormalFloat",
    { win = winid }
  )

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
vim.keymap.set(
  "n",
  "]l",
  vim.diagnostic.goto_next,
  { desc = "Next diagnostic [lint,problem]" }
)
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Declaration" })
vim.keymap.set("n", "gn", vim.lsp.buf.rename, { desc = "Rename variable" })
vim.keymap.set(
  { "n", "v" },
  "ga",
  vim.lsp.buf.code_action,
  { desc = "Code actions" }
)

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
local function enhanced_float_handler(handler, on_open, on_close)
  return function(err, result, ctx, config)
    local bufnr, win_id = handler(
      err,
      result,
      ctx,
      vim.tbl_deep_extend("force", config or {}, {
        -- TODO: ask if this option could accept a function instead so it can
        -- respond to window resizes
        max_height = math.floor(vim.o.lines * 0.35),
        max_width = math.floor(vim.o.columns * 0.65),
        focusable = true,
        border = { " ", " ", " ", " ", " ", " ", " ", " " },
      })
    )
    if not bufnr or not win_id then
      return
    end

    vim.api.nvim_set_option_value("concealcursor", "nvic", { win = win_id })
    vim.api.nvim_set_option_value(
      "winhighlight",
      "NormalFloat:CmpDocumentationNormal,FloatBorder:CmpDocumentationBorder,CursorLine:NormalFloat",
      { win = win_id }
    )

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

Plug("b0o/SchemaStore.nvim")

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

Plug("neovim/nvim-lspconfig", {
  config = function()
    require("lspconfig.ui.windows").default_options.border =
      { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
    vim.api.nvim_create_user_command("LspServerConfigurations", function()
      vim.cmd.Help("lspconfig-all")
    end, {})
  end,
})

-- TODO: Ideally, I could just silence the error that comes up when nix isn't
-- installed. This way if the language server is available locally, I can still
-- use it. Maybe I should open an issue for that.
--
-- TODO: Maybe take the conform.nvim approach where I expect all LSPs to be
-- installed and I just specify priorities for each LSP. The fallback for every
-- file type will be lazy-lsp.
if vim.fn.executable("nix") == 1 then
  Plug("dundalek/lazy-lsp.nvim", {
    config = function()
      local code_lens_refresh_autocmd_ids_by_buffer = {}

      -- Should be idempotent since it may be called mutiple times for the same
      -- buffer. For example, it could get called again if a server registers
      -- another capability dynamically.
      local on_attach = function(client, buffer_number)
        local keymap_opts = { silent = true, buffer = buffer_number }
        local function buffer_keymap(mode, lhs, rhs, opts)
          vim.keymap.set(
            mode,
            lhs,
            rhs,
            vim.tbl_deep_extend("force", keymap_opts, opts or {})
          )
        end

        local isKeywordprgOverridable = vim.bo[buffer_number].filetype ~= "vim"
        if
          client.supports_method(methods.textDocument_hover)
          and isKeywordprgOverridable
        then
          buffer_keymap("n", "K", vim.lsp.buf.hover)
        end

        if client.supports_method(methods.textDocument_inlayHint) then
          local function toggle_inlay_hints()
            vim.lsp.inlay_hint.enable(
              not vim.lsp.inlay_hint.is_enabled(),
              { bufnr = 0 }
            )
          end
          buffer_keymap(
            "n",
            [[\i]],
            toggle_inlay_hints,
            { desc = "Toggle inlay hints" }
          )
        end

        if client.supports_method(methods.textDocument_signatureHelp) then
          buffer_keymap(
            "i",
            "<C-k>",
            vim.lsp.buf.signature_help,
            { desc = "Signature help" }
          )
        end

        if client.supports_method(methods.textDocument_codeLens) then
          local function create_refresh_autocmd()
            local refresh_autocmd_id =
              code_lens_refresh_autocmd_ids_by_buffer[buffer_number]
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
            local refresh_autocmd_id =
              code_lens_refresh_autocmd_ids_by_buffer[buffer_number]
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

          buffer_keymap(
            "n",
            "gl",
            vim.lsp.codelens.run,
            { desc = "Run code lens" }
          )
          buffer_keymap("n", [[\l]], function()
            local refresh_autocmd_id =
              code_lens_refresh_autocmd_ids_by_buffer[buffer_number]
            local is_refresh_autocmd_active = refresh_autocmd_id ~= -1
            if is_refresh_autocmd_active then
              delete_refresh_autocmd()
              vim.lsp.codelens.clear(client.id, buffer_number)
            else
              create_refresh_autocmd()
            end
          end, { desc = "Toggle code lenses" })
        end

        -- TODO: I try just calling diagnostic.reset in here, but it
        -- didn't work. It has to be called after the handler for
        -- textDocument_(publishD|d)iagnostic runs so in here we just queue up
        -- the bufs to disable.
        local is_buffer_outside_workspace = not vim.startswith(
          vim.api.nvim_buf_get_name(buffer_number),
          client.config.root_dir or vim.loop.cwd() or ""
        )
        if is_buffer_outside_workspace then
          vim.diagnostic.reset(nil, buffer_number)
          table.insert(BufsToDisableDiagnosticOnDiagnostic, buffer_number)
          table.insert(
            BufsToDisableDiagnosticOnPublishDiagnostic,
            buffer_number
          )
        end

        -- Quick way to disable diagnostic for a buffer
        buffer_keymap("n", [[\d]], function()
          vim.diagnostic.reset(nil, buffer_number)
        end, { desc = "Toggle diagnostics for buffer" })
      end

      -- TODO: Would be better if I could get the buffer the these diagnostics
      -- were for from the context, but it's not in there.
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
      local original_diagnostic_handler =
        vim.lsp.handlers[methods.textDocument_diagnostic]
      vim.lsp.handlers[methods.textDocument_diagnostic] = function(...)
        local toreturn = { original_diagnostic_handler(...) }

        vim.iter(BufsToDisableDiagnosticOnDiagnostic):each(function(b)
          vim.diagnostic.reset(nil, b)
        end)
        BufsToDisableDiagnosticOnDiagnostic = {}

        return unpack(toreturn)
      end

      -- When a server registers a capability dynamically, call on_attach again
      -- for the buffers attached to it.
      local original_register_capability =
        vim.lsp.handlers[methods.client_registerCapability]
      vim.lsp.handlers[methods.client_registerCapability] = function(
        err,
        res,
        ctx
      )
        local original_return_value =
          { original_register_capability(err, res, ctx) }

        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if client then
          vim
            .iter(vim.lsp.get_buffers_by_client_id(client.id))
            :each(function(buf)
              on_attach(client, buf)
            end)
        end

        return unpack(original_return_value)
      end

      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities()
      )

      -- local catalog = "/etc/xml/catalog"
      local efm_settings_by_filetype = {
        markdown = {
          {
            lintCommand = "markdownlint --stdin",
            lintFormats = { "%f:%l:%c %m", "%f:%l %m", "%f: %l: %m" },
            lintIgnoreExitCode = true,
            lintSource = "markdownlint",
            lintStdin = true,
          },
        },
        fish = {
          {
            lintCommand = "fish --no-execute '${INPUT}'",
            lintFormats = { "%.%#(line %l): %m" },
            lintSource = "fish",
            lintIgnoreExitCode = true,
          },
        },
      }
      local function map_to_lazy_lsp_format(server_list)
        local filetypes_by_server = vim
          .iter(server_list)
          :fold({}, function(acc, server)
            if server == "efm" then
              acc[server] = vim.tbl_keys(efm_settings_by_filetype)
            else
              acc[server] =
                require("lspconfig")[server].document_config.default_config.filetypes
            end
            return acc
          end)

        local servers_by_filetype = {}
        vim.iter(filetypes_by_server):each(function(server, filetypes)
          vim.iter(filetypes):each(function(filetype)
            local servers = servers_by_filetype[filetype]
            if servers == nil then
              servers = { server }
            else
              table.insert(servers, server)
            end
            servers_by_filetype[filetype] = servers
          end)
        end)

        return servers_by_filetype
      end
      require("lazy-lsp").setup({
        prefer_local = true,

        default_config = {
          capabilities = capabilities,
          on_attach = on_attach,
        },

        -- TODO: missing servers that I use: ast_grep, lemminx,
        -- emmet-language-server
        preferred_servers = map_to_lazy_lsp_format({
          "bashls",
          "cssls",
          "efm",
          "eslint",
          "gopls",
          "html",
          "jdtls",
          "jsonls",
          "ltex",
          "lua_ls",
          "marksman",
          "nil_ls",
          "pyright",
          "rust_analyzer",
          "taplo",
          "tsserver",
          "vimls",
          "yamlls",
          "zls",
        }),

        -- TODO: consider contributing some these settings to nvim-lspconfig
        --
        -- The JSON/YAML configuration came from here:
        -- https://www.arthurkoziel.com/json-schemas-in-neovim/
        configs = {
          jsonls = {
            settings = {
              json = {
                schemas = require("schemastore").json.schemas(),
                validate = { enable = true },
              },
            },
          },

          yamlls = {
            settings = {
              yaml = {
                schemas = require("schemastore").yaml.schemas(),
                -- For why this is needed see:
                -- https://github.com/b0o/SchemaStore.nvim?tab=readme-ov-file#usage
                schemaStore = {
                  enable = false,
                  url = "",
                },
              },
            },
          },

          -- TODO: Can't use this until lazy-lsp gets support for lemminx
          -- It won't be on macOS
          -- lemminx = (vim.fn.filereadable(catalog) == 0) and {} or {
          --   settings = {
          --     xml = {
          --       catalogs = {
          --         catalog,
          --       },
          --     },
          --   },
          -- },

          efm = {
            settings = {
              languages = efm_settings_by_filetype,
            },
            on_new_config = function(new_config)
              local nix_pkgs = { "efm-langserver", "markdownlint-cli", "fish" }
              new_config.cmd =
                require("lazy-lsp").in_shell(nix_pkgs, new_config.cmd)
            end,
          },
        },
      })

      -- re-trigger lsp attach so nvim-lsp-config has a chance to attach to any
      -- buffers that were opened before it was configured. This way I can load
      -- nvim-lsp-config asynchronously.
      --
      -- Set the filetype of all the currently open buffers to trigger a 'FileType' event for each
      -- buffer. This will trigger lsp attach
      vim.iter(vim.api.nvim_list_bufs()):each(function(buf)
        vim.bo[buf].filetype = vim.bo[buf].filetype
      end)
    end,
  })
end
