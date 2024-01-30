require("terminal.dap.configurations")

local function is_dapui_filetype(filetype)
  return vim.startswith(filetype, "dapui_") or filetype == "dap-repl"
end

Plug("Joakker/lua-json5")

Plug("mfussenegger/nvim-dap", {
  config = function()
    vim.fn.sign_define(
      "DapBreakpoint",
      { text = "󰏄", texthl = "DebugSign", linehl = "", numhl = "" }
    )
    vim.fn.sign_define(
      "DapBreakpointCondition",
      { text = "󰇼", texthl = "DebugSign", linehl = "", numhl = "" }
    )
    vim.fn.sign_define(
      "DapLogPoint",
      { text = "󱂅", texthl = "DebugSignLogPoint", linehl = "", numhl = "" }
    )
    vim.fn.sign_define(
      "DapBreakpointRejected",
      { text = "󰅜", texthl = "DebugSignRejected", linehl = "", numhl = "" }
    )
    vim.fn.sign_define(
      "DapStopped",
      { text = "", texthl = "DebugSignCurrentLine", linehl = "", numhl = "" }
    )

    -- load vscode debug config
    local dap_ext_vscode = require("dap.ext.vscode")
    dap_ext_vscode.json_decode = require("json5").parse
    dap_ext_vscode.load_launchjs()

    -- mappings/commands
    local dap = require("dap")
    ---@diagnostic disable-next-line: undefined-field
    vim.keymap.set("n", "<Leader>d", dap.toggle_breakpoint, {
      desc = "Toggle breakpoint",
    })
    vim.api.nvim_create_user_command("ConditionalBreakpoint", function()
      vim.ui.input({ prompt = "Condition: " }, function(condition)
        if not condition then
          return
        end
        ---@diagnostic disable-next-line: undefined-field
        dap.set_breakpoint(condition, nil, nil)
      end)
    end, {})
    vim.api.nvim_create_user_command("HitCountBreakpoint", function()
      vim.ui.input({ prompt = "Count: " }, function(count)
        if not count then
          return
        end
        ---@diagnostic disable-next-line: undefined-field
        dap.set_breakpoint(nil, count, nil)
      end)
    end, {})
    vim.api.nvim_create_user_command("LogBreakpoint", function()
      vim.ui.input(
        { prompt = "Log point message (interpolate variables with {brackets}): " },
        function(message)
          if not message then
            return
          end
          ---@diagnostic disable-next-line: undefined-field
          dap.set_breakpoint(nil, nil, message)
        end
      )
    end, {})
  end,
})

Plug("LiadOz/nvim-dap-repl-highlights", {
  config = function()
    require("nvim-dap-repl-highlights").setup()
  end,
})

Plug("theHamsta/nvim-dap-virtual-text", {
  config = function()
    require("nvim-dap-virtual-text").setup({})
  end,
})

Plug("nvim-telescope/telescope-dap.nvim", {
  config = function()
    require("telescope").load_extension("dap")
    local dap = require("telescope").extensions.dap

    local loaded_dapui = false
    vim.api.nvim_create_user_command("ListBreakpoints", function()
      require("telescope").extensions.dap.list_breakpoints({ preview_title = "" })
    end, {})
    vim.keymap.set("n", "<Leader>D", function()
      local is_dapui_open = vim
        .iter(vim.api.nvim_list_wins())
        :map(vim.api.nvim_win_get_buf)
        :map(function(buf)
          return vim.api.nvim_get_option_value("filetype", { buf = buf })
        end)
        :any(is_dapui_filetype)
      if is_dapui_open then
        require("dapui").close()
      else
        local is_dapui_suspended = vim
          .iter(vim.api.nvim_list_bufs())
          :map(function(buf)
            return vim.api.nvim_get_option_value("filetype", { buf = buf })
          end)
          :any(is_dapui_filetype)
        if is_dapui_suspended then
          require("dapui").open()
        else
          if not loaded_dapui then
            vim.fn["plug#load"]("nvim-dap-ui")
            loaded_dapui = true
          end
          dap.configurations({})
        end
      end
    end, {
      desc = "Toggle debugger",
    })
  end,
})

Plug("rcarriga/nvim-dap-ui", {
  on = {},
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    ---@diagnostic disable-next-line: undefined-field
    dap.listeners.after.event_initialized["dapui_config"] = dapui.open

    ---@diagnostic disable-next-line: missing-fields
    dapui.setup({
      ---@diagnostic disable-next-line: missing-fields
      controls = {
        icons = {
          disconnect = " ",
          pause = " ",
          play = " ",
          run_last = " ",
          step_back = " ",
          step_into = " ",
          step_out = " ",
          step_over = " ",
          terminate = " ",
        },
      },
      icons = {
        collapsed = " ",
        current_frame = " ",
        expanded = " ",
      },
      mappings = {
        expand = { "<Tab>", "<CR>", "<2-LeftMouse>" },
      },
    })

    local dapui_group = vim.api.nvim_create_augroup("MyDapUi", {})
    vim.api.nvim_create_autocmd("BufWinEnter", {
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if not is_dapui_filetype(vim.bo[buf].filetype) then
          return
        end
        local win = vim.fn.bufwinid(buf)
        vim.api.nvim_set_option_value("statuscolumn", "", { win = win })
      end,
      group = dapui_group,
    })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {
        "dapui_scopes",
        "dapui_breakpoints",
        "dapui_stacks",
        "dap-repl",
        "dapui_watches",
        "dapui_console",
      },
      callback = function()
        vim.b.minicursorword_disable = true
        vim.b.minicursorword_disable_permanent = true

        -- After I accept an autocomplete entry from nvim-cmp, buflisted gets set to true so
        -- this sets it back to false.
        if vim.bo.filetype == "dap-repl" then
          vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
            group = dapui_group,
            buffer = vim.api.nvim_get_current_buf(),
            callback = function()
              vim.bo.buflisted = false
            end,
          })
        end
      end,
      group = dapui_group,
    })
  end,
})
