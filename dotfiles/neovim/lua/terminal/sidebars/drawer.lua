Plug("folke/trouble.nvim", {
  config = function()
    require("trouble").setup({
      height = math.floor(vim.o.lines * 0.25),
      icons = false,
      fold_open = "",
      fold_closed = "",
      padding = false,
      action_keys = {
        jump = { "<cr>", "<2-leftmouse>" }, -- jump to the diagnostic or open / close folds
        open_split = { "<c-h>" },
        open_vsplit = { "<c-v>" },
        open_tab = { "<c-t>" },
        jump_close = {},
        toggle_preview = "p",
        open_code_href = "U",
        close_folds = { "zM" }, -- close all folds
        open_folds = { "zR" }, -- open all folds
        toggle_fold = { "<Tab>" }, -- toggle fold of current file
      },
      multiline = false,
      indent_lines = false,
      win_config = {
        border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
        style = "minimal",
      },
      auto_close = false,
      auto_fold = false,
      auto_jump = {
        "lsp_definitions",
        "lsp_references",
        "lsp_implementations",
        "lsp_type_definitions",
      },
      include_declaration = {
        "lsp_references",
        "lsp_implementations",
        "lsp_definitions",
        "lsp_type_definitions",
      },
      signs = {
        error = "",
        warning = "",
        hint = "",
        information = "",
        other = "",
      },
    })

    -- TODO: Would like to to see support for other lsp types like call hierarchies
    vim.keymap.set("n", "<M-d>", function()
      vim.cmd.TroubleToggle("workspace_diagnostics")
    end, {
      desc = "Diagnostics [lints,problems]",
    })
    vim.keymap.set("n", "gd", function()
      vim.cmd.TroubleToggle("lsp_definitions")
    end, {
      desc = "Definitions",
    })
    vim.keymap.set("n", "gt", function()
      vim.cmd.TroubleToggle("lsp_type_definitions")
    end, {
      desc = "Type definitions",
    })
    vim.keymap.set("n", "gi", function()
      vim.cmd.TroubleToggle("lsp_implementations")
    end, {
      desc = "Implementations",
    })
    -- TODO: When there is only one result, it doesn't add to the jumplist so I'm adding that
    -- here. I should upstream this.
    vim.keymap.set(
      "n",
      "gr",
      require("terminal.utilities").set_jump_before(function()
        vim.cmd.TroubleToggle("lsp_references")
      end),
      { desc = "References" }
    )

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("bigolu/trouble.nvim", {}),
      pattern = "Trouble",
      callback = function()
        vim.keymap.set("n", "<S-tab>", function()
          local has_open_fold = vim
            .iter(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true }))
            :any(function(mark)
              return mark[4].hl_group == "TroubleIndent"
            end)
          return has_open_fold and "zM" or "zR"
        end, { desc = "Toggle all folds", buffer = true, remap = true, expr = true })
      end,
    })
  end,
})
