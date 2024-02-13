---@diagnostic disable: inject-field

Plug("stevearc/aerial.nvim", {
  config = function()
    AerialIsFolded = false
    local function aerial_fold_toggle()
      if AerialIsFolded then
        require("aerial.tree").open_all()
        AerialIsFolded = false
      else
        require("aerial.tree").close_all()
        AerialIsFolded = true
      end
    end
    require("aerial").setup({
      highlight_on_jump = false,
      highlight_on_hover = true,
      autojump = true,
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        max_width = 0.3,
        min_width = 0.2,
        default_direction = "right",
        placement = "edge",
        -- When the symbols change, resize the aerial window (within min/max constraints) to fit
        resize_to_content = true,
      },
      attach_mode = "global",
      keymaps = {
        ["<C-j>"] = false,
        ["<C-k>"] = false,
        ["<tab>"] = "actions.tree_toggle",
        ["<S-tab>"] = { callback = aerial_fold_toggle },
        ["<CR>"] = {
          callback = function()
            AerialIsExplicitJump = true
            require("aerial.navigation").select({})
            AerialIsExplicitJump = false
            IsLeavingAerial = false
          end,
        },
        ["<LeftMouse>"] = [[<LeftMouse><Cmd>lua require('aerial.navigation').select({jump = false,})<CR>]],
      },
      lazy_load = true,
      nerd_font = true,
      show_guides = true,
      link_tree_to_folds = false,
      post_jump_cmd = false,
      guides = {
        mid_item = "├─ ",
        last_item = "╰─ ",
        nested_top = "│ ",
      },
    })
    vim.keymap.set(
      { "n" },
      "<M-o>",
      vim.cmd.AerialToggle,
      { silent = true, desc = "Symbol outline [minimap]" }
    )
    local aerial_group_id = vim.api.nvim_create_augroup("MyAerial", {})
    local utils = require("terminal.utilities")
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.o.filetype == "aerial" then
          vim.opt_local.scrolloff = 0
          vim.wo.statuscolumn = " "
          -- I want to disable it, but you can't if it has a global value:
          -- https://github.com/neovim/neovim/issues/18660
          vim.opt_local.winbar = " "
          vim.b.minicursorword_disable = true
          vim.b.minicursorword_disable_permanent = true
          vim.b.minianimate_disable = true
          utils.set_persistent_highlights("outline", {
            OutlineTitle = "BufferLineBufferSelected",
            OutlineBorder = "BufferLineIndicatorSelected",
          })
        end
      end,
      group = aerial_group_id,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
      callback = function()
        if vim.o.filetype == "aerial" then
          utils.set_persistent_highlights("outline", {
            OutlineTitle = "BufferLineBufferVisible",
            OutlineBorder = "Ignore",
          })
        end
      end,
      group = aerial_group_id,
    })
  end,
})

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    if vim.bo.filetype ~= "aerial" then
      LastCursorPos = vim.api.nvim_win_get_cursor(0)
    else
      IsLeavingAerial = true
    end
  end,
})
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    if not AerialIsExplicitJump and vim.bo.filetype ~= "aerial" and IsLeavingAerial then
      IsLeavingAerial = false
      vim.api.nvim_win_set_cursor(0, LastCursorPos)
    end
  end,
})
