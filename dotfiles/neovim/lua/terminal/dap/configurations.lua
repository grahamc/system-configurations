Plug("mfussenegger/nvim-dap-python", {
  ["for"] = { "python" },
  config = function()
    local debugpy_package_name = "debugpy"
    local package_registry = require("mason-registry")

    local function is_debugpy_installed()
      return package_registry.is_installed(debugpy_package_name)
    end

    local function get_debugpy_path()
      if not is_debugpy_installed() then
        return ""
      end
      return package_registry.get_package(debugpy_package_name):get_install_path()
        .. "/venv/bin/python"
    end

    -- TODO: I want to use vim.ui.input() for the 'run with args config' so I can get
    -- autocomplete, but I can't since input() can't be run synchronously:
    --
    -- https://github.com/neovim/neovim/issues/24632
    local function setup_nvim_dap_python()
      require("dap-python").setup(get_debugpy_path())
    end

    local function on_debugpy_installed(fn)
      package_registry:on(
        "package:install:success",
        vim.schedule_wrap(function()
          if is_debugpy_installed() then
            fn()
          end
        end)
      )
    end

    local function is_debugpy_symlink_broken()
      ---@diagnostic disable-next-line: deprecated
      return vim.fn.file_readable(get_debugpy_path()) == 0
    end

    local function config_helper()
      if not is_debugpy_installed() then
        vim.notify(
          "Unable to configure nvim-dap-python because debugpy is not installed.",
          vim.log.levels.WARN
        )
        on_debugpy_installed(setup_nvim_dap_python)
        return
      end

      -- TODO: Workaround for Nix. Python virtualenvs use the canonical path of the base
      -- python. This is an issue for Nix because when I update my system and the old python gets
      -- garbage collected, it breaks any virtualenvs made against it. So here I let the user know
      -- so they can reinstall debugpy.
      --
      if is_debugpy_symlink_broken() then
        vim.notify(
          "Error: Unable to setup dap-python because the python symlink in debugpy's venv is broken. This is probably due to Nix garbage collection so reinstall through Mason to fix the link.",
          vim.log.levels.ERROR
        )
        on_debugpy_installed(setup_nvim_dap_python)
        return
      end

      setup_nvim_dap_python()
    end

    -- sometimes mason complains that it can't find debugpy if I look for it during startup or
    -- session restoration so I'll wait
    vim.defer_fn(config_helper, 1500)
  end,
})
