-- vim:foldmethod=marker

-- undefined-global is for globals defined by mini.nvim and inject-field is so I can vim.b.*
---@diagnostic disable: undefined-global, inject-field

-- TODO: Not all of this should be on base
--
-- Dependencies: nvim-treesitter-textobjects
Plug("echasnovski/mini.nvim", {
  -- Load synchronously for cursor restoration
  sync = true,

  config = function()
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
    local spec_treesitter = require("mini.ai").gen_spec.treesitter

    require("mini.ai").setup({
      custom_textobjects = {
        d = spec_treesitter({ a = "@function.outer", i = "@function.inner" }),
        C = spec_treesitter({ a = "@conditional.outer", i = "@conditional.inner" }),
        s = spec_treesitter({ a = "@assignment.lhs", i = "@assignment.rhs" }),
      },
      silent = true,
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
    end)
    vim.keymap.set({ "n", "x" }, "[d", function()
      move_like_curly_brace("d", "left")
    end)
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
    end)
    vim.keymap.set({ "o", "x" }, "ai", function()
      run_without_indent_at_cursor(function()
        MiniIndentscope.textobject(true)
      end)
    end)
    vim.keymap.set({ "n", "x" }, "[i", function()
      run_without_indent_at_cursor(function()
        MiniIndentscope.move_cursor("top", false)
      end)
    end)
    vim.keymap.set({ "n", "x" }, "]i", function()
      run_without_indent_at_cursor(function()
        MiniIndentscope.move_cursor("bottom", false)
      end)
    end)

    local mini_group_id = vim.api.nvim_create_augroup("MyMiniNvim", {})

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
      pattern = { "man", "aerial", "help" },
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
    require("mini.surround").setup({
      n_lines = 50,
      search_method = "cover_or_next",
      silent = true,
    })
    -- }}}

    require("mini.misc").setup_restore_cursor({
      center = false,
    })

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
  end,
})
