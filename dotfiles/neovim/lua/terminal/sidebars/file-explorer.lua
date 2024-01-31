Plug("kyazdani42/nvim-tree.lua", {
  config = function()
    require("nvim-tree").setup({
      hijack_cursor = true,
      sync_root_with_cwd = true,
      open_on_tab = true,
      update_focused_file = {
        enable = true,
      },
      git = {
        enable = false,
      },
      view = {
        signcolumn = "yes",
        width = {
          max = function()
            return math.floor(vim.o.columns * 0.30)
          end,
          -- Enough to fit the title text
          min = 45,
        },
        preserve_window_proportions = true,
      },
      renderer = {
        indent_markers = {
          enable = true,
          icons = {
            corner = " ",
            edge = " ",
            item = " ",
            bottom = " ",
          },
        },
        icons = {
          symlink_arrow = "   ",
          show = {
            file = false,
            folder = false,
          },
          glyphs = {
            folder = {
              arrow_closed = " ",
              arrow_open = " ",
            },
          },
        },
      },
      actions = {
        change_dir = {
          enable = false,
        },
        open_file = {
          window_picker = {
            enable = false,
          },
        },
      },
      on_attach = function(buffer_number)
        -- Set the default mappings
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(buffer_number)

        vim.keymap.set("n", "h", "<BS>", { buffer = buffer_number, remap = true })
        vim.keymap.set("n", "l", "<CR>", { buffer = buffer_number, remap = true })
        vim.keymap.set("n", "<Tab>", "<CR>", { buffer = buffer_number, remap = true })
        -- Taken from base config
        vim.keymap.set("n", "<C-k>", "6k", { buffer = buffer_number, remap = true })
      end,
    })
    vim.api.nvim_create_user_command("ExplorerToggle", function()
      vim.cmd.NvimTreeFindFileToggle()

      -- TODO: There seems to be a bug in v0.10 messing with WinSeparator. This fixes it.
      -- So far I've only noticed it with the nvim-tree window which is why I put the fix
      -- here.
      vim.cmd([[
        setlocal winhighlight=Normal:Normal
      ]])
    end, { desc = "Toggle the explorer window" })
    vim.keymap.set("n", "<M-e>", vim.cmd.ExplorerToggle, { silent = true })
    local nvim_tree_group_id = vim.api.nvim_create_augroup("MyNvimTree", {})
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.o.filetype == "NvimTree" then
          vim.api.nvim_set_hl(0, "ExplorerTitle", { link = "BufferLineBufferSelected" })
          vim.api.nvim_set_hl(0, "ExplorerBorder", { link = "BufferLineIndicatorSelected" })
          vim.opt_local.cursorline = true
        end
      end,
      group = nvim_tree_group_id,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
      callback = function()
        if vim.o.filetype == "NvimTree" then
          vim.api.nvim_set_hl(0, "ExplorerTitle", { link = "BufferLineBufferVisible" })
          vim.api.nvim_set_hl(0, "ExplorerBorder", { link = "Ignore" })
          vim.opt_local.cursorline = false
        end
      end,
      group = nvim_tree_group_id,
    })
    vim.api.nvim_create_autocmd("BufWinEnter", {
      callback = function()
        if vim.o.filetype == "NvimTree" then
          vim.opt_local.statuscolumn = ""
          -- I want to disable it, but you can't if it has a global value:
          -- https://github.com/neovim/neovim/issues/18660
          vim.opt_local.winbar = " "
        end
      end,
      group = nvim_tree_group_id,
    })
  end,
})
