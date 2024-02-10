Plug("stevearc/overseer.nvim", {
  config = function()
    -- nvim-dap needs to run it's config first so this will ensure that happens.
    vim.defer_fn(function()
      require("overseer").setup({
        strategy = {
          "toggleterm",
          close_on_exit = false,
          quit_on_exit = false,
          open_on_start = true,
        },
        auto_detect_success_color = false,
        task_list = {
          max_width = 0.33,
          -- sets minimum to the greater of these two values
          min_width = { 40, 0.33 },
          default_template_prompt = "allow",
          separator = "----------------------------------------",
          bindings = {
            ["?"] = "ShowHelp",
            ["g?"] = false,
            ["ga"] = "RunAction",
            ["<C-q>"] = "OpenQuickFix",
            ["q"] = "Close",
            ["<C-e>"] = "Edit",
            ["o"] = false,
            ["<CR>"] = false,
            ["<C-v>"] = false,
            ["<C-s>"] = false,
            ["<C-f>"] = false,
            ["p"] = false,
            ["<C-l>"] = false,
            ["<C-h>"] = false,
            ["L"] = false,
            ["H"] = false,
            ["["] = false,
            ["]"] = false,
            ["{"] = false,
            ["}"] = false,
            ["<C-k>"] = false,
            ["<C-j>"] = false,
          },
        },
        form = {
          border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
          win_opts = { winblend = 2 },
        },
        confirm = {
          border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
          win_opts = { winblend = 2 },
        },
        task_win = {
          border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
          win_opts = { winblend = 2 },
        },
        help_win = {
          border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
          win_opts = { winblend = 2 },
        },
        log = {
          {
            type = "notify",
            level = vim.log.levels.WARN,
          },
          {
            type = "file",
            filename = "overseer.log",
            level = vim.log.levels.WARN,
          },
        },
      })

      vim.keymap.set("n", "<M-S-t>", vim.cmd.OverseerToggle, {
        desc = "Open the task sidebar",
      })
      vim.keymap.set("n", "<Leader>t", vim.cmd.OverseerRun, {
        desc = "Run a task",
      })
      vim.keymap.set("n", "<Leader>T", function()
        local overseer = require("overseer")
        local tasks = overseer.list_tasks({ recent_first = true })
        if vim.tbl_isempty(tasks) then
          vim.notify("No tasks found", vim.log.levels.WARN)
        else
          overseer.run_action(tasks[1], "restart")
        end
      end, { desc = "Restart the most recent task [last]" })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "OverseerList",
        callback = function()
          vim.keymap.set("n", "o", vim.cmd.ToggleTerm, {
            desc = "Toggle task output window",
            buffer = true,
          })
        end,
      })

      local utils = require("terminal.utilities")
      vim.api.nvim_create_autocmd({ "WinEnter", "FileType" }, {
        callback = function()
          if vim.o.filetype == "OverseerList" then
            utils.set_persistent_highlights("tasks", {
              TaskTitle = "BufferLineBufferSelected",
              TaskBorder = "BufferLineIndicatorSelected",
            })
          end
        end,
      })
      vim.api.nvim_create_autocmd("WinLeave", {
        callback = function()
          if vim.o.filetype == "OverseerList" then
            utils.set_persistent_highlights("tasks", {
              TaskTitle = "BufferLineBufferVisible",
              TaskBorder = "Ignore",
            })
          end
        end,
      })
    end, 0)
  end,
})

-- Using this as a UI for overseer
Plug("akinsho/toggleterm.nvim", {
  config = function()
    require("toggleterm").setup({
      size = function(_)
        return math.floor(vim.o.lines * 0.30)
      end,
      shell = "fish",
      shade_terminals = false,
      on_open = function(_)
        vim.wo.winhighlight = ""

        vim.wo.signcolumn = "no"
        vim.wo.statuscolumn = ""
        vim.cmd.startinsert()

        local count = nil
        vim.wo.winbar, count = vim.wo.winbar:gsub(
          "%%{%%",
          '%%{%%"%%#TaskOutputBorder#█%%#TaskOutputTitle#  Task output%%#TaskOutputBorder#█ ".',
          1
        )
        if count == 0 then
          vim.notify(string.format([[Unable to modify task output winbar]]), vim.log.levels.WARN)
        end

        vim
          .iter(vim.api.nvim_list_wins())
          :filter(function(win)
            return win ~= vim.api.nvim_get_current_win()
          end)
          :filter(function(win)
            return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "toggleterm"
          end)
          :each(function(win)
            vim.api.nvim_win_close(win, false)
          end)
      end,
      winbar = {
        enabled = true,
        name_formatter = function(term)
          return term.name:gsub([[;#toggleterm.+]], "")
        end,
      },
    })

    local utils = require("terminal.utilities")
    vim.api.nvim_create_autocmd({ "WinEnter", "FileType" }, {
      callback = function()
        if vim.bo.filetype == "toggleterm" then
          utils.set_persistent_highlights("task-output", {
            TaskOutputTitle = "BufferLineBufferSelected",
            TaskOutputBorder = "BufferLineIndicatorSelected",
          })
        end
      end,
    })
    vim.api.nvim_create_autocmd({ "WinLeave" }, {
      callback = function()
        if vim.bo.filetype == "toggleterm" then
          utils.set_persistent_highlights("task-output", {
            TaskOutputTitle = "BufferLineBufferVisible",
            TaskOutputBorder = "Ignore",
          })
        end
      end,
    })
  end,
})
