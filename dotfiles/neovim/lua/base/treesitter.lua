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
  end,
})
