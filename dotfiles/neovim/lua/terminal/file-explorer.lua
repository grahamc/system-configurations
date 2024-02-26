Plug("kyazdani42/nvim-tree.lua", {
  config = function()
    local live_preview_enter_key_mapping = require("terminal.utilities").set_up_live_preview({
      id = "NvimTree",
      file_type = "NvimTree",
      set_up_once = false,
      on_select = require("nvim-tree.api").node.open.edit,
      get_bufnr = function()
        local node = require("nvim-tree.api").tree.get_node_under_cursor()
        if node == nil or node.absolute_path == nil then
          return nil
        end
        local path = node.absolute_path

        local is_directory = vim.fn.isdirectory(path) ~= 0
        local command =
          string.format([[file --mime-encoding %s | grep -q binary]], vim.fn.shellescape(path))
        local is_binary = vim.system({ "sh", "-c", command }):wait().code == 0
        if is_directory or is_binary then
          return nil
        end

        -- where background means the file won't be focused and it won't show up in my bufferline
        local function open_file_in_background(file)
          vim.cmd.badd(file)
          local buf = vim.fn.bufnr(file)
          vim.bo[buf].buflisted = false

          return buf
        end
        return (vim.fn.bufexists(path) ~= 0) and vim.fn.bufnr(path) or open_file_in_background(path)
      end,
    })

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
            -- TODO: Should see if upstream can provide an option to disable symlink icons just like
            -- `renderer.icons.show.file`. Or maybe this icon shouldn't show if that option is true,
            -- that seems to be how it works for `renderer.icons.show.folder`: symlink folder icons
            -- don't show if folder is false.
            symlink = "",
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

        live_preview_enter_key_mapping(buffer_number)
        vim.keymap.set("n", "h", "<BS>", { buffer = buffer_number, remap = true })
        vim.keymap.set("n", "l", "<CR>", { buffer = buffer_number, remap = true })
        -- Taken from base config
        vim.keymap.set("n", "<C-k>", "6k", { buffer = buffer_number, remap = true })
      end,
    })
    local nvim_tree_group_id = vim.api.nvim_create_augroup("MyNvimTree", {})
    local utils = require("terminal.utilities")
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.o.filetype == "NvimTree" then
          utils.set_persistent_highlights("explorer", {
            ExplorerTitle = "BufferLineBufferSelected",
            ExplorerBorder = "BufferLineIndicatorSelected",
          })
          vim.opt_local.cursorline = true
        end
      end,
      group = nvim_tree_group_id,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
      callback = function()
        if vim.o.filetype == "NvimTree" then
          utils.set_persistent_highlights("explorer", {
            ExplorerTitle = "BufferLineBufferVisible",
            ExplorerBorder = "Ignore",
          })
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

    vim.keymap.set(
      "n",
      "<M-e>",
      vim.cmd.NvimTreeFindFileToggle,
      { silent = true, desc = "Toggle file explorer [tree]" }
    )
  end,
})
