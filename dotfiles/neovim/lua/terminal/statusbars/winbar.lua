Plug("Bekaboo/dropbar.nvim", {
  config = function()
    require("dropbar").setup({
      general = {
        update_interval = 100,
      },
    })
  end,
})
