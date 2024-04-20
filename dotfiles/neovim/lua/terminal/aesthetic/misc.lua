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
--
-- TODO: If this issue gets resolved, I won't have to do this for telescope:
-- https://github.com/nvim-telescope/telescope.nvim/issues/3020
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
          local has_bg_or_fg_matches_terminal_bg = string.find(
            info.hl_group_name,
            "Virtual"
          ) or (vim.api.nvim_get_hl(0, { name = info.hl_group_name }).fg == decimal)
          return unpack(vim
            .iter({ r, g, b })
            :map(function(v)
              return has_bg_or_fg_matches_terminal_bg and v
                or (is_light and (v - 10) or (v + 5))
            end)
            :totable())
        end,
      },
    })
    -- Fix for when I restore a session with mutiple windows in the current tab
    require("tint").disable()
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

    local function is_floating(win_id)
      return vim.api.nvim_win_get_config(win_id).relative ~= ""
    end

    local function is_transparent()
      -- TODO: use a more accurate check for transparency
      return not vim.opt_local.winhighlight:get()["NormalFloat"]
    end

    local function should_have_backdrop()
      return is_floating(vim.api.nvim_get_current_win()) and is_transparent()
    end

    local function get_non_floating_windows()
      return vim
        .iter(vim.fn.getwininfo() or {})
        :map(function(win)
          return win.winid
        end)
        :filter(function(win_id)
          return not is_floating(win_id)
        end)
        :totable()
    end

    local function add_backdrop()
      vim.iter(get_non_floating_windows()):each(require("tint").tint)
    end

    local function remove_backdrop()
      vim.iter(get_non_floating_windows()):each(require("tint").untint)
    end

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
      callback = function(_winenter_context)
        if should_have_backdrop() then
          add_backdrop()

          vim.api.nvim_create_autocmd({ "WinLeave" }, {
            once = true,
            callback = function(_winleave_context)
              remove_backdrop()
            end,
          })
        end
      end,
    })

    -- dressing.nvim sets `noautocmd` when opening its window so I can't use
    -- `WinEnter` to enable the tint
    --
    -- TODO: If this issue gets resolved, I can remove this:
    -- https://github.com/stevearc/dressing.nvim/issues/148
    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = "DressingInput",
      callback = function(_filetype_context)
        add_backdrop()

        -- Apparently `WinEnter` is not firing for the window we return to
        -- after closing dressing so instead I'll untint on `WinLeave` for the
        -- dressing window.
        vim.api.nvim_create_autocmd({ "WinLeave" }, {
          once = true,
          callback = function(_winleave_context)
            remove_backdrop()
          end,
        })
      end,
    })
  end,
})
