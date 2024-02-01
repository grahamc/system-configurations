Plug("williamboman/mason.nvim", {
  config = function()
    require("mason").setup({
      ui = {
        width = 1,
        -- Ideally I'd use a function here so I could set it to '<screen_height> - 1', but this
        -- field doesn't support functions.
        height = 0.96,
        icons = {
          package_installed = "󰄳  ",
          package_pending = "  ",
          package_uninstalled = "󰝦  ",
        },
        keymaps = {
          toggle_package_expand = "<Tab>",
        },
      },
      log_level = vim.log.levels.DEBUG,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "mason",
      callback = function()
        vim.b.minicursorword_disable = true
        vim.b.minicursorword_disable_permanent = true
      end,
      group = vim.api.nvim_create_augroup("MyMason", {}),
    })
    vim.api.nvim_create_user_command("Tools", function()
      vim.cmd.Mason()
    end, { desc = "Manage external tooling such as language servers" })

    -- Store the number of packages that have an update available so I can put it in my statusline.
    local registry = require("mason-registry")
    local function maybe_set_update_flag(success, _)
      if success then
        _G.mason_update_available_count = _G.mason_update_available_count + 1
      end
    end
    local function set_mason_update_count()
      _G.mason_update_available_count = 0
      local packages = registry.get_installed_packages()
      for _, package in ipairs(packages) do
        package:check_new_version(maybe_set_update_flag)
      end
    end
    -- Update the registry first so we get the latest package versions.
    registry.update(function(was_successful, registry_sources_or_error)
      if not was_successful then
        vim.notify(
          "Failed to check for mason updates: " .. registry_sources_or_error,
          vim.log.levels.ERROR
        )
        return
      end
      set_mason_update_count()
    end)
    -- Set the count every time we update a package so it gets decremented accordingly.
    --
    -- TODO: This event also fires when a new package is installed, but we aren't interested in that
    -- event. This means we'll set the count more often than we need to.
    registry:on("package:install:success", vim.schedule_wrap(set_mason_update_count))
    -- Also set the count when a package is uninstalled in the event we uninstall the package that
    -- had an update.
    registry:on("package:uninstall:success", vim.schedule_wrap(set_mason_update_count))
  end,
})

-- To read/write config files the way the vscode extension does.
Plug("barreiroleo/ltex-extra.nvim")

Plug("b0o/SchemaStore.nvim")
