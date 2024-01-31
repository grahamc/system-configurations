local function set_colorscheme()
  if vim.o.background == "dark" then
    vim.cmd.colorscheme("my_dark_theme")
  else
    vim.cmd.colorscheme("my_light_theme")
  end
end

-- My color scheme depends on this so I need to wait for it to load before I try loading my
-- color scheme.
Plug("rktjmp/lush.nvim", {
  -- I need this config to be applied earlier so you don't see a flash of the default color scheme
  -- and then mine.
  sync = true,

  config = function()
    set_colorscheme()
    vim.api.nvim_create_autocmd("OptionSet", {
      pattern = "background",
      callback = set_colorscheme,
      nested = true,
      group = vim.api.nvim_create_augroup("SetColorscheme", {}),
    })
  end,
})
