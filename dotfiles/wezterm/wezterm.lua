local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Utilities
local function merge_to_left(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == "table") and (type(t1[k] or false) == "table") then
      merge_to_left(t1[k], t2[k])
    else
      t1[k] = v
    end
  end
  return t1
end
local is_mac = string.find(wezterm.target_triple, "darwin")
local CustomEvent = {
  ThemeChanged = "theme-changed",
  SystemAppearanceChanged = "system-appearance-changed",
}

-- general
config.window_close_confirmation = "NeverPrompt"
config.audible_bell = "Disabled"
config.default_cursor_style = "BlinkingBar"
config.bold_brightens_ansi_colors = false
config.disable_default_key_bindings = true
-- I had an issue where WezTerm would sometimes freeze when I input a key and I
-- would have to input another key to fix it, but setting this to false seems to
-- fix that. Solution came from here:
-- https://www.reddit.com/r/commandline/comments/1621suy/help_issue_with_wezterm_and_vim_key_repeat/
config.use_ime = false
config.enable_kitty_keyboard = true
config.enable_kitty_graphics = true
config.automatically_reload_config = false
config.window_padding = {
  left = "0.5cell",
  right = "0.5cell",
  top = "0.5cell",
  bottom = "0.5cell",
}
config.term = "wezterm"
config.inactive_pane_hsb = {
  saturation = 1,
  brightness = 1,
}

-- font
-- Per the recommendation in the mini.icons readme
config.allow_square_glyphs_to_overflow_width = "Always"
local function font_with_icon_fallbacks(font)
  return wezterm.font_with_fallback({ font, "SymbolsNerdFontMono" })
end
local handwriting_font = "Monaspace Radon"
-- For Linux, I'd like to put 'monospace' here so Wezterm can use the monospace
-- font that I set for my system, but Flatpak apps can't access my font
-- configuration file from their sandbox so for now I'll hardcode a font.
--
-- issue: https://github.com/flatpak/flatpak/issues/1563
config.font = font_with_icon_fallbacks("Hack")
config.font_rules = {
  {
    intensity = "Normal",
    italic = true,
    font = font_with_icon_fallbacks(handwriting_font),
  },
  {
    intensity = "Bold",
    italic = true,
    font = font_with_icon_fallbacks({
      family = handwriting_font,
      weight = "Bold",
    }),
  },
}
if is_mac then
  config.font_size = 13.5
  config.line_height = 1.5
  config.underline_position = "400%"
else
  config.font_size = 11.3

  -- TODO: I want this to be the same as macOS, but the font gets cut off when I
  -- try.
  config.line_height = 1.25

  -- TODO: I want this to be the same as macOS, but the underline doesn't show
  -- up when I try.
  config.underline_position = "200%"
end
config.underline_thickness = "150%"

-- SYNC: terminal-color-palettes
local my_colors_per_color_scheme = {
  ["Biggs Nord"] = {
    [0] = "#1d2129",
    [1] = "#BF616A",
    [2] = "#A3BE8C",
    [3] = "#EBCB8B",
    [4] = "#81A1C1",
    [5] = "#B48EAD",
    [6] = "#88C0D0",
    [7] = "#D8DEE9",
    [8] = "#78849b",
    [9] = "#BF616A",
    [10] = "#A3BE8C",
    [11] = "#d08770",
    [12] = "#81A1C1",
    [13] = "#B48EAD",
    [14] = "#8FBCBB",
    [15] = "#78849b",
  },

  ["Biggs Light Owl"] = {
    [0] = "#ffffff",
    [1] = "#cf222e",
    [2] = "#116329",
    [3] = "#e9873a",
    [4] = "#0969da",
    [5] = "#8250df",
    [6] = "#1b7c83",
    [7] = "#1f2328",
    [8] = "#808080",
    [9] = "#a40e26",
    [10] = "#1a7f37",
    [11] = "#c96765",
    [12] = "#218bff",
    [13] = "#a475f9",
    [14] = "#3192aa",
    [15] = "#808080",
  },
}

local tab_colors_per_color_scheme = {
  ["Biggs Nord"] = {
    background = "#2c3038",
  },

  ["Biggs Light Owl"] = {
    background = "#eceef1",
  },
}

local function create_color_schemes(colors_per_color_scheme)
  local color_schemes = {}

  for color_scheme_name, colors in pairs(colors_per_color_scheme) do
    -- Make a skeleton for the color scheme that we'll fill in below
    local color_scheme = {
      ["ansi"] = {},
      ["brights"] = {},
    }

    for index, color in pairs(colors) do
      if index == 0 then
        color_scheme["background"] = color
        color_scheme["cursor_fg"] = color_scheme["background"]
        color_scheme["selection_fg"] = color
      elseif index == 7 then
        color_scheme["foreground"] = color
        color_scheme["selection_bg"] = color
        color_scheme["scrollbar_thumb"] = color
        color_scheme["cursor_border"] = color
        -- TODO: For `cursor_border` to work, `cursor_bg` needs to be set to the
        -- same color
        -- issue: https://github.com/wez/wezterm/issues/1494
        color_scheme["cursor_bg"] = color
      elseif index == 8 then
        color_scheme["split"] = color
      end

      if index >= 0 and index <= 7 then
        color_scheme["ansi"][index + 1] = color
      elseif index >= 8 and index <= 15 then
        color_scheme["brights"][index - 7] = color
      end
    end

    color_schemes[color_scheme_name] = color_scheme
  end

  return color_schemes
end
config.color_schemes = create_color_schemes(my_colors_per_color_scheme)

local function create_theme_config(color_scheme_name)
  local color_scheme = config.color_schemes[color_scheme_name]
  local background = color_scheme.background
  local foreground = color_scheme.foreground
  local tab_colors = tab_colors_per_color_scheme[color_scheme_name]
  return {
    color_scheme = color_scheme_name,
    window_frame = {
      active_titlebar_bg = tab_colors.background,
      inactive_titlebar_bg = tab_colors.background,
    },
    colors = {
      tab_bar = {
        background = tab_colors.background,
        active_tab = {
          bg_color = background,
          fg_color = foreground,
        },
        inactive_tab = {
          bg_color = tab_colors.background,
          fg_color = foreground,
        },
        inactive_tab_hover = {
          bg_color = tab_colors.background,
          fg_color = color_scheme.ansi[7],
        },
        new_tab = {
          bg_color = tab_colors.background,
          fg_color = foreground,
        },
        new_tab_hover = {
          bg_color = tab_colors.background,
          fg_color = color_scheme.ansi[7],
        },
      },
    },
  }
end
local Theme = {
  Dark = {
    as_string = "dark",
    config = create_theme_config("Biggs Nord"),
  },
  Light = {
    as_string = "light",
    config = create_theme_config("Biggs Light Owl"),
  },
}
Theme.for_system_appearance = function(appearance)
  if appearance:find("Dark") then
    return Theme.Dark
  else
    return Theme.Light
  end
end
Theme.from_window = function(window)
  local overrides = window:get_config_overrides() or {}
  if Theme.Light.config.color_scheme == overrides.color_scheme then
    return Theme.Light
  else
    return Theme.Dark
  end
end
Theme.inverse = function(theme)
  if theme == Theme.Dark then
    return Theme.Light
  else
    return Theme.Dark
  end
end

local function set_theme(window, theme)
  local overrides = window:get_config_overrides() or {}
  merge_to_left(overrides, theme.config)
  window:set_config_overrides(overrides)
  wezterm.emit(CustomEvent.ThemeChanged, theme)
end

-- Change theme automatically when the system theme changes
--
-- There is no event for when the system appearance changes. Instead, when the
-- appearance changes, the 'window-config-reloaded' event is fired. To get
-- around this, I keep track of the current system appearance fire my own event
-- when I detect a change.
local current_system_appearance = nil
wezterm.on("window-config-reloaded", function(window)
  local new_system_appearance = wezterm.gui.get_appearance()
  if current_system_appearance ~= new_system_appearance then
    current_system_appearance = new_system_appearance
    wezterm.emit(
      CustomEvent.SystemAppearanceChanged,
      window,
      current_system_appearance
    )
  end
end)
wezterm.on(CustomEvent.SystemAppearanceChanged, function(window, new_appearance)
  set_theme(window, Theme.for_system_appearance(new_appearance))
end)

-- Decorations
local decorations = "INTEGRATED_BUTTONS|RESIZE"
if is_mac then
  -- disable this since it may affect performance:
  -- https://github.com/wez/wezterm/issues/2669#issuecomment-1411507194
  decorations = decorations .. "|MACOS_FORCE_DISABLE_SHADOW"
end
config.window_decorations = decorations
config.show_new_tab_button_in_tab_bar = true
config.show_tab_index_in_tab_bar = true
-- TODO: I don't know why I need this
config.colors = {}

local paste_keybind = nil
if is_mac then
  paste_keybind = {
    key = "v",
    mods = "SUPER",
    action = wezterm.action.PasteFrom("Clipboard"),
  }
else
  paste_keybind = {
    key = "Insert",
    mods = "SHIFT",
    action = wezterm.action.PasteFrom("Clipboard"),
  }
end

config.keys = {
  paste_keybind,
  {
    key = "q",
    mods = "CMD",
    action = wezterm.action.QuitApplication,
  },
  {
    key = "r",
    mods = "ALT|SHIFT",
    action = wezterm.action.ReloadConfiguration,
  },
  {
    key = "/",
    mods = "ALT",
    action = wezterm.action.ActivateCommandPalette,
  },
  {
    key = "-",
    mods = "ALT",
    action = wezterm.action.SplitPane({ direction = "Down" }),
  },
  {
    key = "\\",
    mods = "ALT",
    action = wezterm.action.SplitPane({ direction = "Right" }),
  },
  {
    key = "q",
    mods = "ALT",
    action = wezterm.action.CloseCurrentPane({ confirm = false }),
  },
  {
    key = "q",
    mods = "ALT|SHIFT",
    action = wezterm.action.CloseCurrentTab({ confirm = false }),
  },
  {
    key = "Backspace",
    mods = "ALT",
    action = wezterm.action.ActivateLastTab,
  },
  {
    key = "t",
    mods = "ALT",
    action = wezterm.action.SpawnTab("CurrentPaneDomain"),
  },
  {
    key = "[",
    mods = "ALT",
    action = wezterm.action.ActivateTabRelative(-1),
  },
  {
    key = "]",
    mods = "ALT",
    action = wezterm.action.ActivateTabRelative(1),
  },
  {
    key = "m",
    mods = "ALT",
    action = wezterm.action.TogglePaneZoomState,
  },
  {
    key = "{",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ScrollToPrompt(-1),
  },
  { key = "}", mods = "CTRL|SHIFT", action = wezterm.action.ScrollToPrompt(1) },

  -- TODO: fish added support for the kitty keyboard protocol, but it will be part of
  -- the v4.0 release. Have to use this until then:
  -- https://github.com/fish-shell/fish-shell/commit/8bf8b10f685d964101f491b9cc3da04117a308b4
  --
  -- TODO: fzf doesn't support `ctrl-[`. There's an issue open for supporting
  -- the kitty keyboard protocol though:
  -- https://github.com/junegunn/fzf/issues/3208
  {
    key = "[",
    mods = "CTRL",
    action = wezterm.action.SendKey({
      key = "F7",
    }),
  },
  {
    key = "]",
    mods = "CTRL",
    action = wezterm.action.SendKey({
      key = "F8",
    }),
  },
}
for i = 1, 9 do
  -- CTRL+ALT + number to activate that tab
  table.insert(config.keys, {
    key = tostring(i),
    mods = "ALT",
    action = wezterm.action.ActivateTab(i - 1),
  })
end

-- Source: https://github.com/numToStr/Navigator.nvim/wiki/WezTerm-Integration
local function isVimRunningInPane(pane)
  -- get_foreground_process_name On Linux, macOS and Windows,
  -- the process can be queried to determine this path. Other operating systems
  -- (notably, FreeBSD and other unix systems) are not currently supported
  local name = pane:get_foreground_process_name()
  local pane_name_matches_vim = (name ~= nil and name:find("n?vim") ~= nil)
    or pane:get_title():find("n?vim") ~= nil
  if pane_name_matches_vim then
    return true
  end

  local tty = pane:get_tty_name()
  if tty == nil then
    return false
  end
  local success, _stdout, _stderr = wezterm.run_child_process({
    "sh",
    "-c",
    "ps -o state= -o comm= -t"
      .. wezterm.shell_quote_arg(tty)
      .. " | "
      .. "grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?)(diff)?$'",
  })
  if success then
    return true
  end

  return false
end
local function conditionalActivatePane(
  window,
  pane,
  pane_direction,
  vim_direction
)
  if isVimRunningInPane(pane) then
    window:perform_action(
      -- This should match the keybinds you set in Neovim.
      wezterm.action.SendKey({ key = vim_direction, mods = "ALT" }),
      pane
    )
  else
    window:perform_action(
      wezterm.action.ActivatePaneDirection(pane_direction),
      pane
    )
  end
end
wezterm.on("ActivatePaneDirection-right", function(window, pane)
  conditionalActivatePane(window, pane, "Right", "l")
end)
wezterm.on("ActivatePaneDirection-left", function(window, pane)
  conditionalActivatePane(window, pane, "Left", "h")
end)
wezterm.on("ActivatePaneDirection-up", function(window, pane)
  conditionalActivatePane(window, pane, "Up", "k")
end)
wezterm.on("ActivatePaneDirection-down", function(window, pane)
  conditionalActivatePane(window, pane, "Down", "j")
end)
table.insert(config.keys, {
  key = "h",
  mods = "ALT",
  action = wezterm.action.EmitEvent("ActivatePaneDirection-left"),
})
table.insert(config.keys, {
  key = "j",
  mods = "ALT",
  action = wezterm.action.EmitEvent("ActivatePaneDirection-down"),
})
table.insert(config.keys, {
  key = "k",
  mods = "ALT",
  action = wezterm.action.EmitEvent("ActivatePaneDirection-up"),
})
table.insert(config.keys, {
  key = "l",
  mods = "ALT",
  action = wezterm.action.EmitEvent("ActivatePaneDirection-right"),
})

config.mouse_bindings = {
  -- clear selection on mouse-up
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.Multiple({
      wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor("Clipboard"),
      wezterm.action.ClearSelection,
    }),
  },

  -- see last command output in vim
  {
    event = { Down = { streak = 2, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.Multiple({
      wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
      wezterm.action.CopyTo("ClipboardAndPrimarySelection"),
      wezterm.action.ClearSelection,
      wezterm.action.SendString("pbpaste | nvim\r"),
    }),
  },
}

return config
