vim.o.linebreak = true
vim.o.breakat = " ^I"
vim.o.cursorline = true
vim.o.cursorlineopt = "number,screenline"
vim.o.wrap = true
-- chars to represent tabs and spaces when 'setlist' is enabled
vim.o.listchars = "tab:¬-,space:·"
vim.opt.fillchars:append("eob: ")

vim.defer_fn(function()
  vim.fn["plug#load"]("dressing.nvim")
end, 0)
Plug("stevearc/dressing.nvim", {
  on = {},
  config = function()
    require("dressing").setup({
      input = {
        enabled = true,
        default_prompt = "Input:",
        trim_prompt = false,
        border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        relative = "editor",
        prefer_width = 0.5,
        width = 0.5,
        max_width = 500,
      },
      select = {
        get_config = function(options)
          if options.kind == "legendary.nvim" then
            return {
              telescope = {
                -- favor entries that I've selected recently
                sorter = require("telescope.sorters").fuzzy_with_index_bias({}),
              },
            }
          end
        end,
      },
    })

    local dressing_group = vim.api.nvim_create_augroup("MyDressing", {})
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "DressingInput",
      group = dressing_group,
      callback = function()
        -- After I accept an autocomplete entry from nvim-cmp, buflisted gets set to true so
        -- this sets it back to false.
        vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
          group = dressing_group,
          buffer = vim.api.nvim_get_current_buf(),
          callback = function()
            vim.bo.buflisted = false
          end,
        })
      end,
    })
  end,
})

vim.defer_fn(function()
  vim.fn["plug#load"]("dressing.nvim")
end, 0)
Plug("stevearc/dressing.nvim", {
  on = {},
  config = function()
    require("dressing").setup({
      input = {
        enabled = true,
        default_prompt = "Input:",
        trim_prompt = false,
        border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        relative = "editor",
        prefer_width = 0.5,
        width = 0.5,
        max_width = 500,
      },
      select = {
        get_config = function(options)
          if options.kind == "legendary.nvim" then
            return {
              telescope = {
                -- favor entries that I've selected recently
                sorter = require("telescope.sorters").fuzzy_with_index_bias({}),
              },
            }
          end
        end,
      },
    })

    local dressing_group = vim.api.nvim_create_augroup("MyDressing", {})
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "DressingInput",
      group = dressing_group,
      callback = function()
        -- After I accept an autocomplete entry from nvim-cmp, buflisted gets set to true so
        -- this sets it back to false.
        vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
          group = dressing_group,
          buffer = vim.api.nvim_get_current_buf(),
          callback = function()
            vim.bo.buflisted = false
          end,
        })
      end,
    })
  end,
})

-- A backdrop for floats
--
-- TODO: If this issue gets resolved, I won't need a backdrop for dressing:
-- https://github.com/stevearc/dressing.nvim/issues/148
--
-- TODO: If this issue gets resolved, I need a backdrop for telescope:
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

    local function remove_backdrop_on_win_leave()
      vim.api.nvim_create_autocmd({ "WinLeave" }, {
        once = true,
        callback = function(_context)
          remove_backdrop()
        end,
      })
    end

    local function backdrop()
      add_backdrop()
      remove_backdrop_on_win_leave()
    end

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
      callback = function(_context)
        if should_have_backdrop() then
          backdrop()
        end
      end,
    })

    -- dressing.nvim sets `noautocmd` when opening its window so I can't use
    -- `WinEnter` to enable the tint
    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = "DressingInput",
      callback = function(_context)
        backdrop()
      end,
    })
  end,
})
