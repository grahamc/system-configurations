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
            require("aerial.navigation").select({ jump = false })
          end,
        },
        ["<LeftMouse>"] = [[<LeftMouse><Cmd>lua require('aerial.navigation').select({jump = false,})<CR>]],
      },
      lazy_load = true,
      nerd_font = true,
      show_guides = true,
      link_tree_to_folds = false,
    })
    vim.keymap.set(
      { "n" },
      "<M-o>",
      vim.cmd.AerialToggle,
      { silent = true, desc = "Symbol outline [minimap]" }
    )
    local aerial_group_id = vim.api.nvim_create_augroup("MyAerial", {})
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
          vim.api.nvim_set_hl(0, "OutlineTitle", { link = "BufferLineBufferSelected" })
          vim.api.nvim_set_hl(0, "OutlineBorder", { link = "BufferLineIndicatorSelected" })
        end
      end,
      group = aerial_group_id,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
      callback = function()
        if vim.o.filetype == "aerial" then
          vim.api.nvim_set_hl(0, "OutlineTitle", { link = "BufferLineBufferVisible" })
          vim.api.nvim_set_hl(0, "OutlineBorder", { link = "Ignore" })
        end
      end,
      group = aerial_group_id,
    })
  end,
})
