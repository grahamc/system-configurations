local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Utilities
local function table_concat(t1,t2)
  for i=1,#t2 do
    t1[#t1+1] = t2[i]
  end
  return t1
end
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
local is_mac = string.find(wezterm.target_triple, 'darwin')

-- general
config.window_close_confirmation = 'NeverPrompt'
config.audible_bell = 'Disabled'
config.default_cursor_style = 'BlinkingBar'
config.bold_brightens_ansi_colors = false
config.disable_default_key_bindings = true
-- I had an issue where WezTerm would sometimes freeze when I input a key and I would have to input another key
-- to fix it, but setting this to false seems to fix that. Solution came from here:
-- https://www.reddit.com/r/commandline/comments/1621suy/help_issue_with_wezterm_and_vim_key_repeat/
config.use_ime = false

-- font
-- I'd like to put 'monospace' here so Wezterm can use the monospace font that I set for my system, but Flatpak apps
-- can't access my font configuration file from their sandbox so for now I'll hardcode a font.
-- issue: https://github.com/flatpak/flatpak/issues/1563
config.font = wezterm.font_with_fallback({'Iosevka Comfy Fixed', 'SymbolsNerdFontMono'})
config.underline_position = -9
config.font_size = 11.3
if is_mac then
  config.font_size = 14
end
config.line_height = 1.2
config.underline_thickness = "150%"

local my_colors_per_color_scheme = {
  ['Biggs Nord'] = {
    [0] = '#1d2129', [1] = '#BF616A', [2] = '#A3BE8C', [3] = '#EBCB8B', [4] = '#81A1C1', [5] = '#B48EAD', [6] = '#88C0D0', [7] = '#D8DEE9',
    [8] = '#78849b', [9] = '#BF616A', [10] = '#A3BE8C', [11] = '#d08770', [12] = '#81A1C1', [13] = '#B48EAD', [14] = '#8FBCBB', [15] = '#78849b',
    -- Floating windows in neovim
    [16] = '#181c24',
    [24] = '#2e3440',
    -- Background color for the non-emphasized and emphasized part of a removed line in a git diff
    [17] = '#301a1f', [25] = '#803030',
    -- Background color for the non-emphasized and emphasized part of an added line in a git diff
    [18] = '#12261e', [26] = '#1d572c',
    -- Background color for the source and destination of a moved line in a git diff
    [21] = '#60405a', [22] = '#306a7b',
    -- highlight color
    [51] = '#292e39',
    -- nvim-telescope border
    [52] = '#31353d',
    -- For folded lines
    [53] = '#232832',
  },

  ['Biggs Light Owl'] = {
    [0] = '#ffffff', [1] = '#ee3d3b', [2] = '#2AA298', [3] = '#e9873a', [4] = '#288ed7', [5] = '#994cc3', [6] = '#037A98', [7] = '#000000',
    [8] = '#979893', [9] = '#ee3d3b', [10] = '#2AA298', [11] = '#c96765', [12] = '#288ed7', [13] = '#d6438a', [14] = '#2AA298', [15] = '#808080',
    -- Floating windows in neovim
    [16] = '#f0f0f0',
    [24] = '#e5e5e5',
    -- Background color for the non-emphasized and emphasized part of a removed line in a git diff
    [17] = '#FFD7D7', [25] = '#FFAFAF',
    -- Background color for the non-emphasized and emphasized part of an added line in a git diff
    [18] = '#D7FFD7', [26] = '#96D596',
    -- Background color for the source and destination of a moved line in a git diff
    [21] = '#e99ac0', [22] = '#85dfd8',
    -- highlight color
    [51] = '#F0F0F0',
    -- nvim-telescope border
    [52] = '#d0d0d0',
    -- For folded lines
    [53] = '#f5f5f5',
  },
}
local dimmed_foreground_colors = {
  ['#000000'] = '#808080',
  ['#d8dee9'] = '#767c87',
}

local function create_color_schemes(colors_per_color_scheme)
  local color_schemes = {}

  for color_scheme_name, colors in pairs(colors_per_color_scheme) do
    -- Make a skeleton for the color scheme that we'll fill in below
    local color_scheme = {
      ['ansi'] = {},
      ['brights'] = {},
      ['indexed'] = {},
    }

    for index, color in pairs(colors) do
      if index == 0 then
        color_scheme['background'] = color
        color_scheme['cursor_fg'] = color_scheme['background']
        color_scheme['selection_fg'] = color
      elseif index == 3 then
        color_scheme['selection_bg'] = color
      elseif index == 5 then
        color_scheme['scrollbar_thumb'] = color
      elseif index == 7 then
        color_scheme['foreground'] = color
        color_scheme['cursor_border'] = color
        -- TODO: For `cursor_border` to work, `cursor_bg` needs to be set to the same color
        -- issue: https://github.com/wez/wezterm/issues/1494
        color_scheme['cursor_bg'] = color
      elseif index == 15 then
        color_scheme['split'] = color
      end

      if index >= 0 and index <= 7 then
        color_scheme['ansi'][index + 1] = color
      elseif index >= 8 and index <= 15 then
        color_scheme['brights'][index - 7] = color
      elseif index >= 16 then
        color_scheme['indexed'][index] = color
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
  -- This way I can hide the tab bar
  local foreground = background
  return {
    color_scheme = color_scheme_name,
    window_frame = {
      active_titlebar_bg = background,
      inactive_titlebar_bg = background,
      font_size = 17,
      font = wezterm.font { family = 'Iosevka Comfy Wide Duo', weight = 'Light' },
    },
    colors = {
      tab_bar = {
        background = background,
        active_tab = {
          bg_color = background,
          fg_color = foreground,
        },
        inactive_tab = {
          bg_color = background,
          fg_color = foreground,
        },
        active_tab_hover = {
          bg_color = background,
          fg_color = foreground,
        },
        inactive_tab_hover = {
          bg_color = background,
          fg_color = foreground,
        },
      },
    }
  }
end
local light_theme_config = create_theme_config('Biggs Light Owl')
local dark_theme_config = create_theme_config('Biggs Nord')

-- Change theme automatically when the system theme changes
local function get_theme_config_for_appearance(appearance)
  if appearance:find 'Dark' then
    return dark_theme_config
  else
    return light_theme_config
  end
end
wezterm.on('window-config-reloaded', function(window)
  if _G.reload_due_to_manual_theme_toggle then
    _G.reload_due_to_manual_theme_toggle = false
    return
  end

  local overrides = window:get_config_overrides() or {}
  local appearance = window:get_appearance()
  local theme_config = get_theme_config_for_appearance(appearance)
  merge_to_left(overrides, theme_config)
  window:set_config_overrides(overrides)
end)
-- Toggle theme with alt+c
wezterm.on('toggle-theme', function(window)
  local overrides = window:get_config_overrides() or {}
  if overrides.color_scheme == dark_theme_config.color_scheme then
    merge_to_left(overrides, light_theme_config)
  else
    merge_to_left(overrides, dark_theme_config)
  end

  _G.reload_due_to_manual_theme_toggle = true
  window:set_config_overrides(overrides)
end)

-- Title bar
config.use_fancy_tab_bar = true
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.show_new_tab_button_in_tab_bar = false
config.show_tab_index_in_tab_bar = false
-- TODO: I don't know why I need this
config.colors = {}
-- Update the status bar with the current window title
wezterm.on('update-status', function(window, pane)
  local effective_config = window:effective_config()
  local foreground_color = effective_config.color_schemes[effective_config.color_scheme].foreground
  if not window:is_focused() then
    -- Using `:lower()` since WezTerm does that to all the colors I set
    -- TODO: Dim the colors programmatically
    foreground_color = dimmed_foreground_colors[foreground_color:lower()]
  end

  local pane_title = pane:get_user_vars().title
  if string.find(pane_title, 'tmux') then
    pane_title = ' tmux'
  else
    pane_title = ' ' .. pane_title
  end

  local title = wezterm.format {
    { Foreground = { Color = foreground_color } },
    { Text = pane_title .. ' ' },
  }
  if is_mac then
    window:set_right_status(title)
  else
    window:set_left_status(title)
  end
end)

local keybinds = {
  {
    key = 'c',
    mods = 'ALT',
    action = wezterm.action.EmitEvent('toggle-theme')
  },
  {
    key = 'v',
    mods = 'SUPER',
    action = wezterm.action.PasteFrom('Clipboard')
  },

  -- Doing this since TMUX doesn't support extended keys anymore.
  -- issue: https://github.com/tmux/tmux/issues/2705
  {
    key = '[',
    mods = 'ALT',
    action = wezterm.action.SendKey {
      key = 'F10',
    },
  },
  {
    key = ']',
    mods = 'ALT',
    action = wezterm.action.SendKey {
      key = 'F12',
    },
  },
  {
    key = 'i',
    mods = 'CTRL',
    action = wezterm.action.SendKey {
      key = 'F9',
    },
  },
  {
    key = '[',
    mods = 'CTRL',
    action = wezterm.action.SendKey {
      key = 'F7',
    },
  },
  {
    key = ']',
    mods = 'CTRL',
    action = wezterm.action.SendKey {
      key = 'F8',
    },
  },
  {
    key = 'q',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentTab { confirm = false },
  },
}

local function generate_neovim_tab_navigation_keybinds()
  local result = {}
  for tab_number=1,9 do
    local tab_number_string = tostring(tab_number)

    local keybind = {
      key = tab_number_string,
      mods = 'CTRL',
      action = wezterm.action.Multiple {
        wezterm.action.SendKey {key = 'Space'},
        wezterm.action.SendKey {key = tab_number_string},
      },
    }

    table.insert(result, keybind)
  end

  return result
end

config.keys = table_concat(keybinds, generate_neovim_tab_navigation_keybinds())

return config
