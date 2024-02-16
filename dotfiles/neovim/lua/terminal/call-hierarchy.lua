Plug("ldelossa/litee.nvim", {
  config = function()
    require("litee.lib").setup({
      notify = {
        -- TODO: There's no way to style the float so I'm disabling it. They should use vim.ui.notify()
        enabled = false,
      },
      panel = {
        panel_size = math.floor(vim.o.columns * 0.33),
      },
      tree = {
        icon_set = "nerd",
        icon_set_custom = {
          Collapsed = "",
          Expanded = "",
          IndentGuide = " ",
        },
      },
    })
  end,
})

Plug("ldelossa/litee-calltree.nvim", {
  config = function()
    require("litee.calltree").setup({
      map_resize_keys = false,
      on_open = "panel",
      keymaps = {
        jump = "<CR>",
        jump_split = "<C-h>",
        jump_vsplit = "<C-v>",
        jump_tab = "<C-t>",
        close = "q",
        help = "?",
        switch = "s",
        focus = "r",
        expand = "zo",
        collapse = "zc",

        -- you can't remove mapping so I'll set them to something I won't use
        close_panel_pop_out = "zza",
        details = "zzb",
        -- you can't control the hover float's styles so nevermind
        hover = "zzc",
        collapse_all = "zzd",
        hide = "zze",
      },
    })

    vim.keymap.set("n", "ghi", vim.lsp.buf.incoming_calls, { desc = "Incoming call hierarchy" })
    vim.keymap.set("n", "gho", vim.lsp.buf.outgoing_calls, { desc = "Outgoing call hierarchy" })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "calltree",
      callback = function()
        vim.b.minicursorword_disable = true
        vim.b.minicursorword_disable_permanent = true
        vim.keymap.set("n", "<Tab>", function()
          local is_expanded = vim.api.nvim_get_current_line():find("")
          return is_expanded and "zc" or "zo"
        end, { desc = "Toggle fold", buffer = true, remap = true, expr = true })
      end,
    })

    local jump_hls = vim
      .iter({ "LTSymbolJump", "LTSymbolJumpRefs" })
      :fold({}, function(acc, hl_name)
        acc[hl_name] = vim.api.nvim_get_hl(0, { name = hl_name })
        return acc
      end)
    vim.api.nvim_create_autocmd("WinEnter", {
      callback = function()
        if vim.bo.filetype == "calltree" then
          vim.o.guicursor = "n-v-c:block-LTCursor"
          vim.iter(jump_hls):each(function(key, value)
            vim.api.nvim_set_hl(0, key, value)
          end)
        end
      end,
    })
    vim.api.nvim_create_autocmd("WinLeave", {
      callback = function()
        if vim.bo.filetype == "calltree" then
          vim.iter(jump_hls):each(function(key, _)
            vim.cmd([[hi clear ]] .. key)
          end)
        end
      end,
    })
  end,
})
