-- autopairs and endwise don't work in vscode and I prefer vscode's autotag
if vim.g.vscode ~= nil then
  return
end

Plug("windwp/nvim-autopairs", {
  config = function()
    require("nvim-autopairs").setup({
      -- Don't add bracket pairs after quote.
      enable_afterquote = false,
    })
  end,
})

Plug("windwp/nvim-ts-autotag")

-- Automatically add closing keywords (e.g. function/endfunction in vimscript)
Plug("RRethy/nvim-treesitter-endwise", {
  config = function()
    -- this way endwise triggers on `o`
    vim.keymap.set("n", "o", "A<CR>", { remap = true })
  end,
})
