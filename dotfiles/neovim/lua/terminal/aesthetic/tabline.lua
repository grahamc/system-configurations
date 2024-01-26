Plug("akinsho/bufferline.nvim", {
  config = function()
    local function close(buffer)
      local buffer_count = #vim.fn.getbufinfo({ buflisted = 1 })
      local window_count = vim.fn.winnr("$")
      local tab_count = vim.fn.tabpagenr("$")

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
      end
    end

    local close_icon = ""
    require("bufferline").setup({
      ---@diagnostic disable-next-line: missing-fields
      options = {
        ---@diagnostic disable-next-line: undefined-field
        numbers = function(context)
          return context.raise(context.ordinal)
        end,
        indicator = { style = "icon", icon = "" },
        close_icon = close_icon,
        close_command = close,
        buffer_close_icon = close_icon,
        separator_style = { "", "" },
        modified_icon = close_icon,
        offsets = {
          {
            filetype = "NvimTree",
            text = " FILE EXPLORER",
            text_align = "center",
            separator = true,
            highlight = "WidgetFill",
          },
          {
            filetype = "aerial",
            text = "󰙅 OUTLINE",
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
        ---@diagnostic disable: missing-fields
        fill = { ctermbg = "NONE", ctermfg = 15 },
        background = { ctermbg = "NONE", ctermfg = 15 },
        buffer_visible = { ctermbg = "NONE", ctermfg = 15 },
        buffer_selected = { ctermbg = 51, ctermfg = "NONE", italic = false, bold = false },
        duplicate = { ctermbg = "NONE", ctermfg = 15, italic = false },
        duplicate_selected = { ctermbg = 51, ctermfg = "None", italic = false },
        duplicate_visible = { ctermbg = "NONE", ctermfg = 15, italic = false },
        numbers = { ctermbg = "NONE", ctermfg = 15, italic = false },
        numbers_visible = { ctermbg = "NONE", ctermfg = 15, italic = false },
        numbers_selected = { ctermbg = 51, ctermfg = 6, italic = false },
        close_button = { ctermbg = "NONE", ctermfg = 15 },
        close_button_selected = { ctermbg = 51, ctermfg = "None" },
        close_button_visible = { ctermbg = "NONE", ctermfg = 15 },
        modified = { ctermbg = 51, ctermfg = 15 },
        modified_selected = { ctermbg = 51, ctermfg = "None" },
        modified_visible = { ctermbg = 51, ctermfg = "None" },
        tab = { ctermbg = 51, ctermfg = 15 },
        tab_selected = { ctermbg = 51, ctermfg = 6, underline = true },
        tab_separator = { ctermbg = 51, ctermfg = 51 },
        tab_separator_selected = { ctermbg = 51, ctermfg = 51 },
        tab_close = { ctermbg = 51, ctermfg = "NONE", bold = true },
        offset_separator = { ctermbg = "NONE", ctermfg = 15 },
        separator = { ctermfg = 1, ctermbg = 0 },
        separator_visible = { ctermfg = 2, ctermbg = 0 },
        separator_selected = { ctermfg = 3, ctermbg = 0 },
        indicator_selected = { ctermbg = "NONE", ctermfg = 51 },
        indicator_visible = { ctermbg = "NONE", ctermfg = 51 },
        trunc_marker = { ctermbg = "NONE", ctermfg = "NONE" },
      },
    })

    vim.keymap.set({ "n", "i" }, "<F7>", vim.cmd.BufferLineCyclePrev, { silent = true })
    vim.keymap.set({ "n", "i" }, "<F8>", vim.cmd.BufferLineCycleNext, { silent = true })

    -- Switch buffers with <Leader><tab number>
    for buffer_index = 1, 9 do
      vim.keymap.set("n", "<Leader>" .. buffer_index, function()
        require("bufferline").go_to(buffer_index, true)
      end)
    end

    vim.keymap.set("n", "<C-q>", function()
      close(vim.fn.bufnr())
    end, { silent = true })
    function BufferlineWrapper()
      ---@diagnostic disable-next-line: undefined-global
      local original = nvim_bufferline()
      local result = original
      local is_explorer_open = string.find(original, "")
      local is_outline_open = string.find(original, "󰙅")
      local is_tab_section_visible = string.find(original, "%%=%%#BufferLineTab")

      -- Right border for selected buffer
      result = string.gsub(
        result,
        -- I'm using a '-' here instead of a '*' so the match won't be greedy. This is needed
        -- because if I hover over a buffer to the right of the current buffer then this pattern
        -- would match the hovered x instead of the x for the current buffer.
        "BufferLineCloseButtonSelected.-"
          .. close_icon
          .. "%%X ",
        "%0%%#TabLineBorder#  ",
        1
      )

      -- left centerer for buffer list
      if is_explorer_open then
        result = string.gsub(result, "│", "%0%%#TabLineBorder#%%=", 1)
      else
        result = "%#TabLineBorder#%=" .. result
      end

      if is_tab_section_visible then
        -- left border
        result =
          string.gsub(result, "%%=%%#BufferLineTab", "%%=%%#TabLineBorder2#%%#BufferLineTab", 1)

        -- right border
        if is_outline_open then
          result = string.gsub(
            result,
            "│%%#OutlineTitle#",
            "%%#TabLineBorder#%%#BufferLineOffsetSeparator#%0",
            1
          )
        else
          result = result .. "%#TabLineBorder#"
        end
      end

      result = string.gsub(
        result,
        "  󰙅 OUTLINE  ",
        "%%#OutlineBorder#█%%#OutlineTitle#󰙅 OUTLINE%%#OutlineBorder#█",
        1
      )

      result = string.gsub(
        result,
        "   FILE EXPLORER  ",
        "%%#NvimTreeBorder#█%%#NvimTreeTitle# FILE EXPLORER%%#NvimTreeBorder#█",
        1
      )

      return result
    end
    vim.o.tabline = "%!v:lua.BufferlineWrapper()"
  end,
})
