-- vim:foldmethod=marker

-- undefined-global is for globals defined by mini.nvim and inject-field is so I can vim.b.*
---@diagnostic disable: inject-field

-- TODO: Not all of this should be in base
--
-- Dependencies: nvim-treesitter-textobjects
Plug("echasnovski/mini.nvim", {
  -- Load synchronously for cursor restoration
  sync = true,

  config = function()
    local mini_group_id = vim.api.nvim_create_augroup("MyMiniNvim", {})

    -- comment {{{
    require("mini.comment").setup({
      options = {
        ignore_blank_line = true,
      },

      mappings = {
        textobject = "ic",
      },
    })
    -- }}}

    --- ai {{{
    local ai = require("mini.ai")
    local spec_treesitter = ai.gen_spec.treesitter
    local spec_pair = ai.gen_spec.pair

    ai.setup({
      custom_textobjects = {
        d = spec_treesitter({ a = "@function.outer", i = "@function.inner" }),
        f = spec_treesitter({ a = "@call.outer", i = "@call.inner" }),
        -- TODO: @parameter.outer should include the space after the parameter delimiter
        a = spec_treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
        C = spec_treesitter({ a = "@conditional.outer", i = "@conditional.inner" }),
        -- TODO: would be great if this worked on key/value pairs as well
        s = spec_treesitter({ a = "@assignment.lhs", i = "@assignment.rhs" }),

        -- Whole buffer
        g = function()
          local from = { line = 1, col = 1 }
          local to = {
            line = vim.fn.line("$"),
            col = math.max(vim.fn.getline("$"):len(), 1),
          }
          return { from = from, to = to }
        end,

        -- For markdown
        ["*"] = spec_pair("*", "*", { type = "greedy" }),
        ["_"] = spec_pair("_", "_", { type = "greedy" }),

        -- For lua
        ["]"] = spec_pair("[", "]", { type = "greedy" }),

        -- For Nix
        ["'"] = spec_pair("'", "'", { type = "greedy" }),
      },

      silent = true,

      -- If I still want to select next/last I can use around_{next,last} textobjects
      search_method = "cover",

      -- Number of lines within which textobject is searched
      n_lines = 100,
    })

    local function move_like_curly_brace(id, direction)
      local old_position = vim.api.nvim_win_get_cursor(0)
      MiniAi.move_cursor(direction, "a", id, {
        search_method = (direction == "left") and "cover_or_prev" or "cover_or_next",
      })
      local new_position = vim.api.nvim_win_get_cursor(0)
      local has_cursor_moved = old_position[0] ~= new_position[0]
        or old_position[1] ~= new_position[1]
      if has_cursor_moved then
        vim.cmd(string.format([[normal! %s]], direction == "left" and "k" or "j"))
      end
    end

    vim.keymap.set({ "n", "x" }, "]d", function()
      move_like_curly_brace("d", "right")
    end, {
      desc = "Next function declaration",
    })
    vim.keymap.set({ "n", "x" }, "[d", function()
      move_like_curly_brace("d", "left")
    end, {
      desc = "Last function declaration",
    })
    --}}}

    -- operators {{{
    require("mini.operators").setup({
      evaluate = { prefix = "" },
      multiply = { prefix = "" },
      replace = { prefix = "" },
      exchange = { prefix = "gx" },
      sort = { prefix = "so" },
    })
    -- }}}

    -- indentscope {{{
    require("mini.indentscope").setup({
      mappings = {
        object_scope = "iI",
        object_scope_with_border = "aI",
        goto_top = "[I",
        goto_bottom = "]I",
      },
      symbol = "┊",
    })
    vim.g.miniindentscope_disable = true

    local new_opts = {
      options = { indent_at_cursor = false },
    }
    local function run_without_indent_at_cursor(fn)
      local old_opts = vim.b.miniindentscope_config
      if old_opts ~= nil then
        vim.b.miniindentscope_config = vim.tbl_deep_extend("force", old_opts, new_opts)
      else
        vim.b.miniindentscope_config = new_opts
      end
      fn()
      vim.b.miniindentscope_config = old_opts
    end

    vim.keymap.set({ "o", "x" }, "ii", function()
      run_without_indent_at_cursor(MiniIndentscope.textobject)
    end, {
      desc = "Inside indent of line",
    })
    vim.keymap.set({ "o", "x" }, "ai", function()
      run_without_indent_at_cursor(function()
        MiniIndentscope.textobject(true)
      end)
    end, {
      desc = "Around indent of line",
    })
    vim.keymap.set({ "n", "x" }, "[i", function()
      run_without_indent_at_cursor(function()
        MiniIndentscope.move_cursor("top", false)
      end)
    end, {
      desc = "Start of indent of line",
    })
    vim.keymap.set({ "n", "x" }, "]i", function()
      run_without_indent_at_cursor(function()
        MiniIndentscope.move_cursor("bottom", false)
      end)
    end, {
      desc = "End of indent of line",
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "python", "yaml" },
      callback = function()
        vim.b.miniindentscope_config = {
          options = {
            border = "top",
          },
        }
      end,
      group = mini_group_id,
    })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "man", "aerial", "help", "dropbar_menu" },
      callback = function()
        vim.b.miniindentscope_disable = true
        vim.b.miniindentscope_disable_permanent = true
      end,
      group = mini_group_id,
    })
    -- TODO: I want to disable this per window, but mini only supports disabling per buffer
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "*",
      callback = function()
        if not vim.b.miniindentscope_disable_permanent then
          vim.b.miniindentscope_disable = false
        end
      end,
      group = mini_group_id,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
      pattern = "*",
      callback = function()
        vim.b.miniindentscope_disable = true
      end,
      group = mini_group_id,
    })
    -- }}}

    -- surround {{{
    local open_braces = {
      ["["] = "]",
      ["("] = ")",
      ["<"] = ">",
      ["{"] = "}",
      ["'"] = "'",
      ['"'] = '"',
    }
    local close_braces = {
      ["]"] = "[",
      [")"] = "(",
      [">"] = "<",
      ["}"] = "{",
    }
    local function get_braces(char)
      if open_braces[char] then
        return { char, open_braces[char] }
      elseif close_braces[char] then
        return { close_braces[char], char }
      else
        return nil
      end
    end
    require("mini.surround").setup({
      n_lines = 50,
      search_method = "cover",
      silent = true,
      custom_surroundings = {
        -- Search for two of the input char, d for double. Helpful for lua and Nix
        ["d"] = {
          input = function()
            local char = MiniSurround.user_input("Char")
            if char == nil or char == "" then
              return nil
            end
            local braces = get_braces(char)
            if braces == nil then
              return nil
            end
            return { string.rep("%" .. braces[1], 2) .. "().-()" .. string.rep("%" .. braces[2], 2) }
          end,
          output = function()
            local char = MiniSurround.user_input("Char")
            if char == nil or char == "" then
              return nil
            end
            local braces = get_braces(char)
            if braces == nil then
              return nil
            end
            return {
              left = string.rep("%" .. braces[1], 2),
              right = string.rep("%" .. braces[2], 2),
            }
          end,
        },
      },
    })
    -- }}}

    -- misc {{{
    local misc = require("mini.misc")
    misc.setup_restore_cursor({
      center = false,
    })
    vim.keymap.set("n", "<Leader>m", function()
      if not IsMaximized then
        vim.api.nvim_create_autocmd("WinEnter", {
          once = true,
          group = mini_group_id,
          callback = function()
            vim.o.winhighlight = "NormalFloat:Normal"
          end,
        })
        misc.zoom(0, {
          anchor = "SW",
          row = 1,
          col = 1,
          height = vim.o.lines - 1,
        })
        IsMaximized = true
      else
        -- Set cursor in original window to that of the maximized window.
        -- TODO: I should upstream this
        local maximized_window_cursor_position = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_create_autocmd("WinEnter", {
          once = true,
          group = mini_group_id,
          callback = function()
            vim.api.nvim_win_set_cursor(0, maximized_window_cursor_position)
          end,
        })

        misc.zoom()
        IsMaximized = false
      end
    end, {
      desc = "Toggle maximize window",
    })

    -- }}}

    -- animate {{{
    require("mini.animate").setup({
      cursor = {
        timing = require("mini.animate").gen_timing.exponential({
          duration = 300,
          easing = "out",
          unit = "total",
        }),
      },
      resize = {
        enable = false,
      },
      scroll = {
        enable = false,
      },
      open = {
        enable = false,
      },
      close = {
        enable = false,
      },
    })
    -- }}}

    -- jump {{{
    require("mini.jump").setup({
      mappings = {
        repeat_jump = "",
      },
      delay = {
        highlight = 10000000,
        idle_stop = 10000000,
      },
    })
    -- }}}

    -- jump2d {{{
    require("mini.jump2d").setup({
      mappings = {
        start_jumping = ";",
      },

      view = {
        dim = true,
        n_steps_ahead = 0,
      },

      allowed_windows = {
        not_current = false,
      },

      silent = true,
    })
    -- }}}

    -- cursorword {{{
    require("mini.cursorword").setup()

    -- Don't highlight keywords
    vim.api.nvim_create_autocmd("CursorMoved", {
      pattern = "*",
      group = mini_group_id,
      callback = function()
        if vim.b.minicursorword_disable_permanent then
          return
        end

        local captures = vim.treesitter.get_captures_at_cursor()
        for _, capture in ipairs(captures) do
          if string.find(capture, "keyword") then
            vim.b.minicursorword_disable = true
            return
          end
        end
        vim.b.minicursorword_disable = false
      end,
    })
    -- }}}

    -- trailspace {{{
    vim.api.nvim_create_user_command("TrimTrailingWhitespace", function()
      require("mini.trailspace").trim()
    end, {})
    -- }}}

    -- bufremove {{{
    require("mini.bufremove").setup({
      set_vim_settings = false,
      silent = true,
    })
    -- }}}
  end,
})
