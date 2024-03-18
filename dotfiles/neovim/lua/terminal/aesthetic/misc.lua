vim.o.linebreak = true
vim.o.breakat = " ^I"
vim.o.cursorline = true
vim.o.cursorlineopt = "number,screenline"
vim.o.wrap = true
-- chars to represent tabs and spaces when 'setlist' is enabled
vim.o.listchars = "tab:¬-,space:·"
vim.opt.fillchars:append("eob: ")

Plug("nvim-tree/nvim-web-devicons")

Plug("yamatsum/nvim-nonicons", {
  config = function()
    require("nvim-nonicons").setup({
      devicons = {
        override = false,
      },
    })
  end,
})

-- A backdrop for floats
Plug("levouh/tint.nvim", {
  config = function()
    require("tint").setup({
      tint_background_colors = true,
      highlight_ignore_patterns = { "Status.*" },
      transforms = {
        function(_, _, _, info)
          local decimal = vim.api.nvim_get_hl(0, { name = "t_0" }).fg
          local hex = require("tint.colors").get_hex(decimal)
          local r, g, b = require("tint.colors").hex_to_rgb(hex)
          -- source:
          -- https://learn.microsoft.com/en-us/answers/questions/1497116/how-to-find-if-a-given-color-is-dark-or-light
          local is_light = ((0.2126 * r) + (0.7152 * g) + (0.0722 * b)) > 128
          local has_bg_or_fg_matches_terminal_bg = string.find(info.hl_group_name, "Virtual")
            or (vim.api.nvim_get_hl(0, { name = info.hl_group_name }).fg == decimal)
          return unpack(vim
            .iter({ r, g, b })
            :map(function(v)
              return has_bg_or_fg_matches_terminal_bg and v or (is_light and (v - 10) or (v + 5))
            end)
            :totable())
        end,
      },
    })

    -- I only want inactive windows dimmed when we're in a float.
    vim.api.nvim_create_autocmd({ "WinEnter" }, {
      callback = function()
        local floating = vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative ~= ""
        if floating then
          vim.iter(vim.fn.getwininfo() or {}):each(function(w)
            if vim.api.nvim_win_get_config(w.winid).relative == "" then
              require("tint").tint(w.winid)
            end
          end)
        else
          vim.iter(vim.fn.getwininfo() or {}):each(function(w)
            require("tint").untint(w.winid)
          end)
        end
      end,
    })

    vim.api.nvim_create_autocmd({ "ColorScheme" }, {
      callback = function()
        -- Fix
        require("tint").disable()
        vim.cmd.redraw()

        -- Fix treesitter context
        vim.cmd.TSContextToggle()
        vim.cmd.TSContextToggle()
      end,
    })
  end,
})
