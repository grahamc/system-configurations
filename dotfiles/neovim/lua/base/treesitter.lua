-- TODO: Some of this should only be configured when neovim is running in the terminal.
Plug("nvim-treesitter/nvim-treesitter", {
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require("nvim-treesitter.configs").setup({
      auto_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
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
        enable = true,
      },
    })

    local function maybe_set_treesitter_foldmethod()
      local foldmethod = vim.o.foldmethod
      local is_foldmethod_overridable = foldmethod ~= "manual"
        and foldmethod ~= "marker"
        and foldmethod ~= "diff"
        and foldmethod ~= "expr"
      if require("nvim-treesitter.parsers").has_parser() and is_foldmethod_overridable then
        vim.o.foldmethod = "expr"
        vim.o.foldexpr = "nvim_treesitter#foldexpr()"
      end
    end
    vim.api.nvim_create_autocmd({ "FileType" }, {
      callback = maybe_set_treesitter_foldmethod,
      group = vim.api.nvim_create_augroup("TreesitterFoldmethod", {}),
    })
  end,
})
