vim.o.showtabline = 2

Plug("akinsho/bufferline.nvim", {
  config = function()
    local function close(buffer)
      local buffer_count = #vim.fn.getbufinfo({ buflisted = 1 })
      local tab_count = vim.fn.tabpagenr("$")

      local function is_not_float(window)
        return vim.api.nvim_win_get_config(window).relative == ""
      end
      local window_count = #vim.tbl_filter(is_not_float, vim.api.nvim_list_wins())

      -- If the only other window in the tab page is nvim-tree, and only one tab is open, keep the
      -- window and switch to another buffer.
      if
        tab_count == 1
        and window_count == 2
        and require("nvim-tree.api").tree.is_visible()
        and buffer_count > 1
      then
        -- `bdelete` closes the window if the buffer is open in one so we have to switch to a
        -- different buffer first.
        vim.cmd.BufferLineCycleNext()
        vim.cmd("bdelete! " .. buffer)
        return
      end

      -- If this is the last window and tab, close the buffer and if that was the last buffer, close
      -- vim.
      if
        tab_count == 1
        and (
          window_count == 1 or (window_count == 2 and require("nvim-tree.api").tree.is_visible())
        )
      then
        local buffer_count_before_closing = buffer_count
        vim.cmd("bdelete! " .. buffer)
        if buffer_count_before_closing == 1 then
          -- Using `quitall` instead of quit so it closes both windows
          vim.cmd.quitall()
        end
        return
      end

      -- If the buffer is only open in the current window, close the buffer and window. Otherwise,
      -- just close the window.
      local buffer_window_count = #vim.fn.win_findbuf(buffer)
      if buffer_window_count == 1 then
        vim.cmd("b#")
        vim.cmd("bd#")
      else
        vim.notify("Can't close buffer, it's open in another window", vim.log.levels.INFO)
      end
    end

    local close_icon = " "
    local active_bg = vim.api.nvim_get_hl(0, { name = "StatusLine" }).bg
    local inactive_fg = vim.api.nvim_get_hl(0, { name = "Comment" }).fg
    -- I'm using the fg of Ignore because this color may get assigned to another fg so I need the
    -- actual hex value of the background, not "NONE", since "NONE" as an fg would resolve to the
    -- normal fg color.
    local inactive_bg = vim.api.nvim_get_hl(0, { name = "Ignore" }).fg
    local accent_fg = vim.api.nvim_get_hl(0, { name = "FloatTitle" }).fg
    local offset_separator_fg = vim.api.nvim_get_hl(0, { name = "WinSeparator" }).fg
    local explorer_icon = ""
    local explorer_title = explorer_icon .. " FILE EXPLORER"
    local outline_icon = "󰙅"
    local outline_title = outline_icon .. " OUTLINE"
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
      highlights = {
        fill = { bg = "NONE", fg = inactive_fg },
        background = { bg = "NONE", fg = inactive_fg },
        buffer_visible = { bg = "NONE", fg = inactive_fg },
        buffer_selected = { bg = active_bg, fg = "NONE", italic = false, bold = false },
        duplicate = { bg = "NONE", fg = inactive_fg, italic = false },
        duplicate_selected = { bg = active_bg, fg = "None", italic = false },
        duplicate_visible = { bg = "NONE", fg = inactive_fg, italic = false },
        numbers = { bg = "NONE", fg = inactive_fg, italic = false },
        numbers_visible = { bg = "NONE", fg = inactive_fg, italic = false },
        numbers_selected = { bg = active_bg, fg = accent_fg, italic = false },
        close_button = { bg = "NONE", fg = inactive_fg },
        close_button_selected = { bg = active_bg, fg = "None" },
        close_button_visible = { bg = "NONE", fg = inactive_fg },
        modified = { bg = "NONE", fg = inactive_bg },
        modified_visible = { bg = "NONE", fg = inactive_bg },
        modified_selected = { bg = active_bg, fg = "None" },
        tab = { bg = active_bg, fg = inactive_fg },
        tab_selected = { bg = active_bg, fg = accent_fg, underline = true },
        tab_separator = { bg = active_bg, fg = active_bg },
        tab_separator_selected = { bg = active_bg, fg = active_bg },
        tab_close = { bg = active_bg, fg = "NONE", bold = true },
        offset_separator = { bg = "NONE", fg = offset_separator_fg },
        indicator_selected = { bg = "NONE", fg = active_bg },
        indicator_visible = { bg = "NONE", fg = active_bg },
        trunc_marker = { bg = "NONE", fg = "NONE" },
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
      local escape_percent = require("utilities").escape_percent
      local result = original
      local is_explorer_open = string.find(original, explorer_icon)
      local is_outline_open = string.find(original, outline_icon)
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
      if is_explorer_open then
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
          "(.-)%%#BufferLineTabSeparator#▕",
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
          .. right_border_with_padding,
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
          .. right_border_with_padding,
        1
      )

      return result
    end
    vim.o.tabline = "%!v:lua.BufferlineWrapper()"
  end,
})
