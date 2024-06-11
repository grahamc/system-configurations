Plug("j-hui/fidget.nvim", {
  config = function()
    require("fidget").setup({
      progress = {
        ignore_done_already = true,
        suppress_on_insert = true,
        ignore = { "null-ls" },
        display = {
          render_limit = 1,
          done_ttl = 0.1,
          done_icon = "󰄬",
          done_style = "FidgetNormal",
          progress_style = "FidgetAccent",
          group_style = "FidgetAccent",
          icon_style = "FidgetIcon",
          progress_icon = { "dots" },
        },
      },
      notification = {
        view = {
          group_separator = "─────",
        },
        window = {
          normal_hl = "FidgetNormal",
          winblend = 0,
          zindex = 1,
        },
      },
    })
  end,
})

Plug("rcarriga/nvim-notify", {
  config = function()
    local notify = require("notify")
    ---@diagnostic disable-next-line: undefined-field
    notify.setup({
      stages = "fade",
      timeout = 2000,
      render = "wrapped-compact",
      max_width = math.floor(vim.o.columns * 0.35),
    })
    vim.notify = notify
  end,
})
