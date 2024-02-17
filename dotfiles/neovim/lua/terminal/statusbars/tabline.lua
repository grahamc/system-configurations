vim.o.showtabline = 2

Plug("akinsho/bufferline.nvim", {
  config = function()
    local wipeout = require("mini.bufremove").wipeout
    local function close(buffer)
      -- If the buffer is open in another window, don't close it.
      local buffer_window_count = #vim.fn.win_findbuf(buffer)
      if buffer_window_count > 1 then
        vim.notify("Can't close buffer, it's open in another window", vim.log.levels.INFO)
        return
      end

      local buffer_count = #vim.fn.getbufinfo({ buflisted = 1 })
      local tab_count = vim.fn.tabpagenr("$")

      local function is_not_float(window)
        return vim.api.nvim_win_get_config(window).relative == ""
      end
      local window_count = #vim.tbl_filter(is_not_float, vim.api.nvim_list_wins())

      -- If this is the last tab, window, and buffer, exit vim
      --
      -- the nvim-tree window shouldn't count towards the window count
      local is_last_window = window_count == 1
        or (window_count == 2 and require("nvim-tree.api").tree.is_visible())
      if tab_count == 1 and is_last_window and buffer_count == 1 then
        -- Using `quitall` instead of quit so if nvim-tree is open it closes both windows.
        vim.cmd([[
          confirm qall
        ]])
        return
      end

      wipeout(buffer)
    end

    local close_icon = " "
    local explorer_icon = " "
    local explorer_title = explorer_icon .. " FILE EXPLORER"
    local outline_icon = " "
    local outline_title = outline_icon .. " OUTLINE"
    local test_icon = " "
    local test_title = test_icon .. " TESTS"
    local task_icon = "󰄵 "
    local task_title = task_icon .. " TASKS"
    require("bufferline").setup({
      options = {
        numbers = function(context)
          ---@diagnostic disable-next-line: undefined-field
          return context.raise(context.ordinal)
        end,
        indicator = { style = "icon", icon = "" },
        close_icon = close_icon,
        close_command = close,
        buffer_close_icon = close_icon,
        separator_style = { "", "" },
        -- Since I can't disable the modified icon, I'll make it look like the close icon
        modified_icon = close_icon,
        offsets = {
          {
            filetype = "NvimTree",
            text = explorer_title,
            text_align = "center",
            separator = true,
            highlight = "WidgetFill",
          },
          {
            filetype = "aerial",
            text = outline_title,
            text_align = "center",
            separator = true,
            highlight = "WidgetFill",
          },
          {
            filetype = "neotest-summary",
            text = test_title,
            text_align = "center",
            separator = true,
            highlight = "WidgetFill",
          },
          {
            filetype = "OverseerList",
            text = task_title,
            text_align = "center",
            separator = true,
            highlight = "WidgetFill",
          },
        },
        hover = {
          enabled = true,
          delay = 50,
          reveal = { "close" },
        },
        themable = true,
        max_name_length = 100,
        max_prefix_length = 100,
        tab_size = 1,
        custom_filter = function(buf_number, _)
          -- filter out file types you don't want to see
          if vim.bo[buf_number].filetype ~= "qf" then
            return true
          end
          return false
        end,
        show_buffer_icons = false,
      },
    })

    vim.keymap.set(
      { "n", "i" },
      "<F7>",
      vim.cmd.BufferLineCyclePrev,
      { silent = true, desc = "Previous file [last,tab]" }
    )
    vim.keymap.set(
      { "n", "i" },
      "<F8>",
      vim.cmd.BufferLineCycleNext,
      { silent = true, desc = "Next file [tab]" }
    )

    -- Switch buffers with <Leader><tab number>
    for buffer_index = 1, 9 do
      vim.keymap.set("n", "<Leader>" .. buffer_index, function()
        require("bufferline").go_to(buffer_index, true)
      end, {
        desc = "File #" .. buffer_index .. " [tab]",
      })
    end

    vim.keymap.set("n", "<C-q>", function()
      close(vim.fn.bufnr())
    end, { silent = true, desc = "Close file [tab]" })
    function BufferlineWrapper()
      local original = nvim_bufferline()
      local escape_percent = require("base.utilities").escape_percent
      local result = original
      local is_explorer_open = string.find(original, explorer_icon)
      local is_outline_open = string.find(original, outline_icon)
      local is_tasks_open = string.find(original, task_icon)
      local is_tests_open = string.find(original, test_icon)
      local tab_highlight_escaped = "%%#BufferLineTab"
      local tab_highlight_and_aligner_escaped = "%%=" .. tab_highlight_escaped
      local is_tab_section_visible = string.find(original, tab_highlight_and_aligner_escaped)
      local left_border = ""
      local right_border = ""
      local left_border_with_padding = left_border .. "█"
      local right_border_with_padding = "█" .. right_border
      -- hardcoding the lengths since I need Lua's utf8 library to get the visible length, but
      -- neovim doesn't have it
      local left_border_with_padding_length = 2
      local right_border_with_padding_length = 2
      local selected_border_highlight = "%#BufferLineIndicatorSelected#"
      local right_border_with_selected_highlight = selected_border_highlight .. right_border

      local function inject_right_border_for_selected_buffer(pattern_left, pattern_right)
        result = string.gsub(
          result,
          pattern_left
            -- I'm using a '-' here instead of a '*' so the match won't be greedy. This is needed
            -- because if I hover over a buffer to the right of the current buffer then this pattern
            -- would match the hovered x instead of the x for the current buffer.
            .. "(.-)"
            .. pattern_right
            -- add a space to the pattern, but not the replacement, so I can remove the space that
            -- bufferline adds to the right side
            .. " ",
          pattern_left
            .. "%1"
            .. pattern_right
            .. escape_percent(right_border_with_selected_highlight),
          1
        )
      end
      inject_right_border_for_selected_buffer("BufferLineCloseButtonSelected", close_icon .. "%%X")
      inject_right_border_for_selected_buffer("BufferLineModifiedSelected", close_icon)

      -- left centerer for buffer list
      if is_explorer_open or is_tasks_open or is_tests_open then
        result = string.gsub(result, "│", "%0%%=", 1)
      else
        result = "%=" .. result
      end

      if is_tab_section_visible then
        -- left border
        result = string.gsub(
          result,
          -- I'm using a '-' here instead of a '*' so the match won't be greedy. This way I get the
          -- first separator.
          --
          -- The second '.-' is the for the word "Selected" which may be there. I have to use a '-'
          -- so I get the first occurence of the highlight
          "(.-)%%#BufferLineTabSeparator(.-)#▕",
          "%1%%#BufferLineTabLeftBorder#" .. right_border,
          1
        )

        -- right border
        if is_outline_open then
          result = string.gsub(
            result,
            -- I use '.*' so I can get the last bar character, in case the explorer is also open
            "(.*)(│)",
            "%1"
              .. escape_percent(right_border_with_selected_highlight)
              .. "%%#BufferLineOffsetSeparator#%2",
            1
          )
        else
          result = string.gsub(
            result,
            -- I use '.*' so I can get the last close icon, not the one for the current buffer.
            "(.*)"
              .. close_icon
              .. " ",
            "%1" .. close_icon .. escape_percent(right_border_with_selected_highlight),
            1
          )
        end
      end

      local outline_border_highlight_escaped = "%%#OutlineBorder#"
      result = string.gsub(
        result,
        string.rep(" ", left_border_with_padding_length)
          .. outline_title
          .. string.rep(" ", right_border_with_padding_length),
        outline_border_highlight_escaped
          .. left_border_with_padding
          .. "%%#OutlineTitle#"
          .. outline_title
          .. outline_border_highlight_escaped
          .. right_border_with_padding
          .. "%%#WidgetFill#",
        1
      )

      local explorer_border_highlight_escaped = "%%#ExplorerBorder#"
      result = string.gsub(
        result,
        string.rep(" ", left_border_with_padding_length)
          .. explorer_title
          .. string.rep(" ", right_border_with_padding_length),
        explorer_border_highlight_escaped
          .. left_border_with_padding
          .. "%%#ExplorerTitle#"
          .. explorer_title
          .. explorer_border_highlight_escaped
          .. right_border_with_padding
          .. "%%#WidgetFill#",
        1
      )

      local test_border_highlight_escaped = "%%#TestBorder#"
      result = string.gsub(
        result,
        string.rep(" ", left_border_with_padding_length)
          .. test_title
          .. string.rep(" ", right_border_with_padding_length),
        test_border_highlight_escaped
          .. left_border_with_padding
          .. "%%#TestTitle#"
          .. test_title
          .. test_border_highlight_escaped
          .. right_border_with_padding
          .. "%%#WidgetFill#",
        1
      )

      local task_border_highlight_escaped = "%%#TaskBorder#"
      result = string.gsub(
        result,
        string.rep(" ", left_border_with_padding_length)
          .. task_title
          .. string.rep(" ", right_border_with_padding_length),
        task_border_highlight_escaped
          .. left_border_with_padding
          .. "%%#TaskTitle#"
          .. task_title
          .. task_border_highlight_escaped
          .. right_border_with_padding
          .. "%%#WidgetFill#",
        1
      )

      return result
    end
    vim.o.tabline = "%!v:lua.BufferlineWrapper()"

    -- bufferline.nvim doesn't provide a way to define highlights yourself, instead you specify
    -- colors in the config. This a problem because I won't be able to update the colors when I
    -- switch to light/dark mode. So here I'm overriding bufferline's highlights and linking them to
    -- colors defined in my color schemes. This way when the color scheme changes, bufferline will
    -- update too.
    local function set_highlights()
      vim.api.nvim_set_hl(0, "BufferLineBackground", { link = "MyBufferLineBackground" })
      vim.api.nvim_set_hl(0, "BufferLineFill", { link = "MyBufferLineFill" })
      vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { link = "MyBufferLineBufferVisible" })
      vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { link = "MyBufferLineBufferSelected" })
      vim.api.nvim_set_hl(0, "BufferLineDuplicate", { link = "MyBufferLineDuplicate" })
      vim.api.nvim_set_hl(
        0,
        "BufferLineDuplicateSelected",
        { link = "MyBufferLineDuplicateSelected" }
      )
      vim.api.nvim_set_hl(
        0,
        "BufferLineDuplicateVisible",
        { link = "MyBufferLineDuplicateVisible" }
      )
      vim.api.nvim_set_hl(0, "BufferLineNumbers", { link = "MyBufferLineNumbers" })
      vim.api.nvim_set_hl(0, "BufferLineNumbersVisible", { link = "MyBufferLineNumbersVisible" })
      vim.api.nvim_set_hl(0, "BufferLineNumbersSelected", { link = "MyBufferLineNumbersSelected" })
      vim.api.nvim_set_hl(0, "BufferLineCloseButton", { link = "MyBufferLineCloseButton" })
      vim.api.nvim_set_hl(
        0,
        "BufferLineCloseButtonSelected",
        { link = "MyBufferLineCloseButtonSelected" }
      )
      vim.api.nvim_set_hl(
        0,
        "BufferLineCloseButtonVisible",
        { link = "MyBufferLineCloseButtonVisible" }
      )
      vim.api.nvim_set_hl(0, "BufferLineModified", { link = "MyBufferLineModified" })
      vim.api.nvim_set_hl(0, "BufferLineModifiedVisible", { link = "MyBufferLineModifiedVisible" })
      vim.api.nvim_set_hl(
        0,
        "BufferLineModifiedSelected",
        { link = "MyBufferLineModifiedSelected" }
      )
      vim.api.nvim_set_hl(0, "BufferLineTab", { link = "MyBufferLineTab" })
      vim.api.nvim_set_hl(0, "BufferLineTabSelected", { link = "MyBufferLineTabSelected" })
      vim.api.nvim_set_hl(0, "BufferLineTabSeparator", { link = "MyBufferLineTabSeparator" })
      vim.api.nvim_set_hl(
        0,
        "BufferLineTabSeparatorSelected",
        { link = "MyBufferLineTabSeparatorSelected" }
      )
      vim.api.nvim_set_hl(0, "BufferLineTabClose", { link = "MyBufferLineTabClose" })
      vim.api.nvim_set_hl(0, "BufferLineOffsetSeparator", { link = "MyBufferLineOffsetSeparator" })
      vim.api.nvim_set_hl(
        0,
        "BufferLineIndicatorSelected",
        { link = "MyBufferLineIndicatorSelected" }
      )
      vim.api.nvim_set_hl(
        0,
        "BufferLineIndicatorVisible",
        { link = "MyBufferLineIndicatorVisible" }
      )
      vim.api.nvim_set_hl(0, "BufferLineTruncMarker", { link = "MyBufferLineTruncMarker" })
    end
    set_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = { "my_light_theme", "my_dark_theme" },
      callback = set_highlights,
      group = vim.api.nvim_create_augroup("MyBufferLine", {}),
    })
  end,
})
