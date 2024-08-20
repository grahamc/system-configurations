Plug("j-hui/fidget.nvim", {
  config = function()
    local fidget = require("fidget")
    fidget.setup({
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
          max_width = 40,
        },
      },
    })
    vim.notify = fidget.notify
  end,
})
