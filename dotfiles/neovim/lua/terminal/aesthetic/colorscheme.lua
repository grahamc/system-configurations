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
      callback = function()
        set_colorscheme()
        -- If certain windows are open, like the autocomplete window, not all the UI elements update
        -- when I switch color schemes so I'm forcing a redraw. I'm intentionally not doing the
        -- redraw in `set_colorscheme()` because it makes the UI look weird on startup.
        vim.cmd([[
          redraw!
        ]])
      end,
      nested = true,
      group = vim.api.nvim_create_augroup("SetColorscheme", {}),
    })
  end,
})
