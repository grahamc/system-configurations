local function is_current_buffer_too_big_to_highlight()
  local max_filesize = 100 * 1024 -- 100 KB
  -- I make sure to use something that gets the size of the buffer and not file because I
  -- may be editing a file that isn't stored locally e.g. `nvim <url>`
  return vim.fn.wordcount().bytes > max_filesize
end

Plug("nvim-treesitter/nvim-treesitter", {
  -- To avoid a flash of the document without syntax highlighting
  sync = IsRunningInTerminal,
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require("nvim-treesitter.configs").setup({
      auto_install = false,
      highlight = {
        enable = IsRunningInTerminal,
        additional_vim_regex_highlighting = false,
        disable = function(_, _)
          return is_current_buffer_too_big_to_highlight()
        end,
      },
      incremental_selection = {
        enable = false,
      },
      indent = {
        enable = false,
      },
      matchup = {
        enable = true,
        disable_virtual_text = true,
        include_match_words = true,
      },
      endwise = {
        enable = true,
      },
      autotag = {
        enable = IsRunningInTerminal,
      },
    })
  end,
})

-- Disable TS parsers bundled with neovim since they won't respect my rules for enabling
-- TS highlighting that I set in nvim-treesitter. Plus I already have the bundled parsers so these
-- are redundant.
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    vim.treesitter.stop()
  end,
})

if IsRunningInTerminal then
  -- Enable syntax highlighting for filetypes without treesitter parsers
  vim.cmd.syntax("manual")
  local filetypes_with_syntax_support = vim.fn.getcompletion("", "syntax") or {}
  vim.api.nvim_create_autocmd("FileType", {
    callback = function()
      if
        not require("nvim-treesitter.parsers").has_parser()
        and not is_current_buffer_too_big_to_highlight()
        and vim.tbl_contains(filetypes_with_syntax_support, vim.bo.filetype)
      then
        vim.bo.syntax = "ON"
      end
    end,
  })
end

Plug("IndianBoy42/tree-sitter-just")

vim.defer_fn(function()
  vim.fn["plug#load"]("nvim-treesitter-context")
end, 0)
Plug("nvim-treesitter/nvim-treesitter-context", {
  on = {},
  config = function()
    require("treesitter-context").setup({
      line_numbers = false,
    })
    vim.keymap.set({ "n", "x" }, "[s", function()
      require("treesitter-context").go_to_context(vim.v.count1)
    end, { silent = true })
    vim.keymap.set(
      "n",
      [[\s]],
      vim.cmd.TSContextToggle,
      { desc = "Toggle sticky scroll [context]" }
    )
  end,
})
