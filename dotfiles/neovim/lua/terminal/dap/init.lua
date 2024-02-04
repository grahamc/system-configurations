require("terminal.dap.configurations")

local function is_dapui_filetype(filetype)
  return vim.startswith(filetype, "dapui_") or filetype == "dap-repl"
end

local keymaps_to_restore = {}
local function add_hover_keymap()
  local function hover()
    if require("dap").session() ~= nil then
      local selection = require("utilities").get_visual_selection()
      if selection == "" then
        -- dap will default to <cexpr>
        selection = nil
      end
      require("dap.ui.widgets").hover(selection, {
        border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
      })
    end
  end
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    local keymaps = vim.api.nvim_buf_get_keymap(buf, "n")
    for _, keymap in pairs(keymaps) do
      if keymap.lhs == "K" then
        table.insert(keymaps_to_restore, keymap)
        vim.api.nvim_buf_del_keymap(buf, "n", "K")
      end
    end
  end
  vim.keymap.set({ "n", "x" }, "K", function()
    hover()
  end, { silent = true })
end

local function dapui_open()
  require("dapui").open()
  add_hover_keymap()
end

-- Taken from nvim-dap wiki.
-- TODO: I should upstream this since there are some edge cases they missed.
local function restore_keymaps()
  for _, keymap in pairs(keymaps_to_restore) do
    vim.keymap.set(
      keymap.mode,
      keymap.lhs,
      keymap.rhs or keymap.callback,
      { silent = keymap.silent == 1, expr = keymap.expr == 1, buffer = keymap.buffer }
    )
  end
  keymaps_to_restore = {}
end

local function dapui_close()
  require("dapui").close()
  restore_keymaps()
end

Plug("Joakker/lua-json5")

Plug("mfussenegger/nvim-dap", {
  config = function()
    vim.fn.sign_define(
      "DapBreakpoint",
      { text = "", texthl = "DebugSign", linehl = "", numhl = "" }
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

    -- Let you exit a DAP float the same way you would an LSP float
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "dap-float",
      callback = function()
        vim.keymap.set("n", "q", function()
          vim.cmd.quit()
        end, { buffer = true })
      end,
      group = vim.api.nvim_create_augroup("MyDap", {}),
    })

    -- Hook for adding configurations
    vim.api.nvim_exec_autocmds("User", { pattern = "DapConfigRegistration" })
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
    local dap_telescope = require("telescope").extensions.dap

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
        dapui_close()
      else
        local is_dapui_suspended = vim
          .iter(vim.api.nvim_list_bufs())
          :map(function(buf)
            return vim.api.nvim_get_option_value("filetype", { buf = buf })
          end)
          :any(is_dapui_filetype)
        if is_dapui_suspended then
          dapui_open()
        else
          if not loaded_dapui then
            vim.fn["plug#load"]("nvim-dap-ui")
            loaded_dapui = true
          end
          dap_telescope.configurations({})
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
    dap.listeners.after.event_initialized["dapui_config"] = dapui_open

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
      layouts = {
        {
          elements = {
            {
              id = "scopes",
              size = 0.25,
            },
            {
              id = "breakpoints",
              size = 0.25,
            },
            {
              id = "stacks",
              size = 0.25,
            },
            {
              id = "watches",
              size = 0.25,
            },
          },
          position = "left",
          size = 0.33,
        },
        {
          elements = {
            {
              id = "repl",
              size = 0.5,
            },
            {
              id = "console",
              size = 0.5,
            },
          },
          position = "bottom",
          size = 10,
        },
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
        -- this sets it back to false. TODO: I should see if nvim-cmp can do anything about this.
        if vim.tbl_contains({ "dap-repl", "dapui_scopes", "dapui_watches" }, vim.bo.filetype) then
          vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
            group = dapui_group,
            buffer = vim.api.nvim_get_current_buf(),
            callback = function()
              vim.bo.buflisted = false
            end,
          })
        end

        -- Mappings for debugger controls
        -- TODO: These functions aren't documented, I should see if they can be included in the
        -- public API.
        if vim.bo.filetype == "dap-repl" then
          local function run_in_non_dapui_window(fn, go_back)
            local non_dapui_window = vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(function(win)
              return not is_dapui_filetype(vim.bo[vim.api.nvim_win_get_buf(win)].filetype)
            end)

            if non_dapui_window == nil then
              vim.notify("Unable to find a non-dapUI window", vim.log.levels.ERROR)
              return
            end

            local current_win = vim.api.nvim_get_current_win()
            vim.api.nvim_set_current_win(non_dapui_window)
            fn()
            if go_back then
              vim.api.nvim_set_current_win(current_win)
            end
          end

          vim.keymap.set("n", "h", _G._dapui.step_back, {
            desc = "Step back",
            buffer = true,
          })
          vim.keymap.set("n", "j", _G._dapui.step_into, {
            desc = "Step into",
            buffer = true,
          })
          vim.keymap.set("n", "k", _G._dapui.step_out, {
            desc = "Step out",
            buffer = true,
          })
          vim.keymap.set("n", "l", _G._dapui.step_over, {
            desc = "Step over",
            buffer = true,
          })
          vim.keymap.set("n", "<CR>", function()
            run_in_non_dapui_window(_G._dapui.play)
          end, {
            desc = "Play",
            buffer = true,
          })
          vim.keymap.set("n", "<C-r>", function()
            run_in_non_dapui_window(_G._dapui.run_last, true)
          end, {
            desc = "Run last",
            buffer = true,
          })
          vim.keymap.set("n", "<C-c>", _G._dapui.terminate, {
            desc = "Stop",
            buffer = true,
          })
          vim.keymap.set("n", "<C-d>", _G._dapui.disconnect, {
            desc = "Disconnect",
            buffer = true,
          })
        end
      end,
      group = dapui_group,
    })
  end,
})
