-- vim:foldmethod=marker

-- Helpers {{{
-- tokenize a string using fish shell's tokenization rules and return an array with the tokens
--
-- TODO: There's a feature request for this so maybe let them know about this:
-- https://github.com/mfussenegger/nvim-dap/issues/629
local function tokenize(string)
  local result = vim.system({ "fish_tokenize", string }, { text = true }):wait()
  return vim.split(result.stdout, "\n")
end

local function get_args()
  return coroutine.create(function(dap_run_co)
    vim.ui.input({ prompt = "Arguments:" }, function(input)
      if input == nil then
        coroutine.resume(dap_run_co, require("dap").ABORT)
      end
      local args = tokenize(input)
      coroutine.resume(dap_run_co, args)
    end)
  end)
end

local function is_package_installed(package_name)
  local package_registry = require("mason-registry")
  return package_registry.is_installed(package_name)
end

local function get_package_install_path(package_name)
  local package_registry = require("mason-registry")
  return package_registry.get_package(package_name):get_install_path()
end

local function on_package_installed(name, fn)
  local package_registry = require("mason-registry")
  package_registry:on(
    "package:install:success",
    vim.schedule_wrap(function(pkg, _)
      if pkg.name == name then
        fn()
      end
    end)
  )
end

local function warn_package_not_installed(name)
  vim.notify(
    string.format("Unable to configure %s because %s was not found.", name, name),
    vim.log.levels.WARN
  )
end
-- }}}

-- Python {{{
Plug("mfussenegger/nvim-dap-python", {
  ["for"] = { "python" },
  config = function()
    local debugpy_package_name = "debugpy"

    local function replace_args_function()
      local dap = require("dap")
      local name = "Launch file with arguments"
      local run_with_args_config = vim.iter(dap.configurations.python):find(function(config)
        return config.name == name
      end)
      if run_with_args_config == nil then
        vim.notify("Unable to locate the dap-python configuration: " .. name, vim.log.levels.ERROR)
        return
      end
      run_with_args_config.args = get_args
    end

    local function get_debugpy_python_path()
      return get_package_install_path(debugpy_package_name) .. "/venv/bin/python"
    end

    local function add_configs()
      require("dap-python").setup(get_debugpy_python_path())
      replace_args_function()
    end

    local function is_debugpy_symlink_broken()
      ---@diagnostic disable-next-line: deprecated
      return vim.fn.file_readable(get_debugpy_python_path()) == 0
    end

    local function config_helper()
      if not is_package_installed(debugpy_package_name) then
        warn_package_not_installed(debugpy_package_name)
        on_package_installed(debugpy_package_name, add_configs)
        return
      end

      -- TODO: Workaround for Nix. Python virtualenvs use the canonical path of the base
      -- python. This is an issue for Nix because when I update my system and the old python gets
      -- garbage collected, it breaks any virtualenvs made against it. So here I let the user know
      -- so they can reinstall debugpy.
      --
      if is_debugpy_symlink_broken() then
        vim.notify(
          "Error: Unable to setup dap-python because the python symlink in debugpy's venv is broken. This is probably due to Nix garbage collection so reinstall it to fix the link.",
          vim.log.levels.WARN
        )
        on_package_installed(debugpy_package_name, add_configs)
        return
      end

      add_configs()
    end

    -- sometimes mason complains that it can't find debugpy if I look for it during startup or
    -- session restoration so I'll wait
    vim.defer_fn(config_helper, 1500)
  end,
})
-- }}}

-- Bash {{{
vim.api.nvim_create_autocmd("FileType", {
  once = true,
  pattern = "sh",
  group = vim.api.nvim_create_augroup("DapBashConfigs", {}),
  callback = function()
    local function helper()
      local bash_debug_adapter_package_name = "bash-debug-adapter"

      local function add_configs()
        local dap = require("dap")

        local bash_debug_adapter = vim.fn.exepath("bash-debug-adapter")
        dap.adapters.sh = {
          type = "executable",
          command = bash_debug_adapter,
        }

        local partial_configs = {
          {
            name = "Launch file",
            args = {},
          },
          {
            name = "Launch file with arguments",
            args = get_args,
          },
        }
        local function get_bashdb_lib_path()
          return get_package_install_path(bash_debug_adapter_package_name)
            .. "/extension/bashdb_dir"
        end
        local bashdb_lib_path = get_bashdb_lib_path()
        local shared_config = {
          program = "${file}",
          type = "sh",
          request = "launch",
          cwd = "${workspaceFolder}",
          pathBashdb = bashdb_lib_path .. "/bashdb",
          pathBashdbLib = bashdb_lib_path,
          pathBash = vim.fn.exepath("bash"),
          pathCat = vim.fn.exepath("cat"),
          pathMkfifo = vim.fn.exepath("mkfifo"),
          pathPkill = vim.fn.exepath("pkill"),
          env = {},
          -- For nvim-dap-repl-highlight. It tries to autodetect the TS parser to use based on
          -- filetype, but since the filetype for bash is sh, autodetection will fail.
          repl_lang = "bash",
        }
        local configs = vim
          .iter(partial_configs)
          :map(function(config)
            return vim.tbl_deep_extend("error", config, shared_config)
          end)
          :totable()
        dap.configurations.sh = configs
      end

      if not is_package_installed(bash_debug_adapter_package_name) then
        warn_package_not_installed(bash_debug_adapter_package_name)
        on_package_installed(bash_debug_adapter_package_name, add_configs)
        return
      end

      add_configs()
    end

    -- sometimes mason complains that it can't find things if I look during startup or
    -- session restoration so I'll wait
    vim.defer_fn(helper, 1500)
  end,
})
-- }}}
