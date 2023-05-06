local wezterm = require 'wezterm'

local config = wezterm.config_builder()

-- I'd like to put 'monospace' here so Wezterm can use the monospace font that I set for my system, but Flatpak apps
-- can't access my font configuration file from their sandbox so for now I'll hardcode a font.
-- issue: https://github.com/flatpak/flatpak/issues/1563
config.font = wezterm.font_with_fallback({'JetBrains Mono NL'})
config.font_size = 10.5
config.underline_position = -9
config.cell_width = 1.04
config.line_height = 1.3
config.underline_thickness = "210%"
config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = .97
config.window_close_confirmation = 'NeverPrompt'
config.audible_bell = 'Disabled'
config.default_cursor_style = 'BlinkingBar'
config.bold_brightens_ansi_colors = false
config.disable_default_key_bindings = true
config.window_padding = {
  left = 0,
  right = 0,
}

local my_colors_per_color_scheme = {
  ['Biggs Nord'] = {
    [0] = '#1d212b', [1] = '#BF616A', [2] = '#A3BE8C', [3] = '#EBCB8B', [4] = '#81A1C1', [5] = '#B48EAD', [6] = '#88C0D0', [7] = '#D8DEE9',
    [8] = '#2e3440', [9] = '#BF616A', [10] = '#A3BE8C', [11] = '#d08770', [12] = '#81A1C1', [13] = '#B48EAD', [14] = '#8FBCBB', [15] = '#626f89',
    -- Floating windows in neovim
    [16] = '#12151f', [32] = '#1d2129',
    -- For folded lines
    [24] = '#2e3440',
    -- Background color for the non-emphasized and emphasized part of a removed line in a git diff
    [17] = '#301a1f', [25] = '#803030',
    -- Background color for the non-emphasized and emphasized part of an added line in a git diff
    [18] = '#12261e', [26] = '#1d572c',
    -- Background color for the source and destination of a moved line in a git diff
    [21] = '#60405a', [22] = '#306a7b',
    -- String in neovim
    [50] = '#A3BE8C',
  },

  ['Biggs Light Owl'] = {
    [0] = '#FFFFFF', [1] = '#ee3d3b', [2] = '#2AA298', [3] = '#e9873a', [4] = '#288ed7', [5] = '#2AA298', [6] = '#994cc3', [7] = '#403f53',
    [8] = '#F0F0F0', [9] = '#ee3d3b', [10] = '#2AA298', [11] = '#c96765', [12] = '#288ed7', [13] = '#2AA298', [14] = '#d6438a', [15] = '#979893',
    -- Floating windows in neovim
    [16] = '#efefef', [32] = '#f1f3f5',
    -- For folded lines
    [24] = '#e5e5e5',
    -- Background color for the non-emphasized and emphasized part of a removed line in a git diff
    [17] = '#FFD7D7', [25] = '#FFAFAF',
    -- Background color for the non-emphasized and emphasized part of an added line in a git diff
    [18] = '#D7FFD7', [26] = '#96D596',
    -- Background color for the source and destination of a moved line in a git diff
    [21] = '#e99ac0', [22] = '#85dfd8',
    -- Strings in neovim
    [50] = '#c96765',
  },
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
      elseif index == 6 then
        color_scheme['cursor_border'] = color
        -- TODO: For cursor_border to work, cursor_bg needs to be set to the same color
        -- issue: https://github.com/wez/wezterm/issues/1494
        color_scheme['cursor_bg'] = color
      elseif index == 7 then
        color_scheme['foreground'] = color
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
local light_color_scheme = 'Biggs Light Owl'
local dark_color_scheme = 'Biggs Nord'

-- Change color scheme automatically when the system changes
local function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return dark_color_scheme
  else
    return light_color_scheme
  end
end
wezterm.on('window-config-reloaded', function(window)
  if _G.reload_due_to_manual_color_scheme_toggle then
    _G.reload_due_to_manual_color_scheme_toggle = false
    return
  end

  local overrides = window:get_config_overrides() or {}
  local appearance = window:get_appearance()
  local scheme = scheme_for_appearance(appearance)
  if overrides.color_scheme ~= scheme then
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
  end
end)

-- Toggle color scheme with alt+c
wezterm.on('toggle-color-scheme', function(window)
  local overrides = window:get_config_overrides() or {}
  if overrides.color_scheme == dark_color_scheme then
    overrides.color_scheme = light_color_scheme
  else
    overrides.color_scheme = dark_color_scheme
  end

  _G.reload_due_to_manual_color_scheme_toggle = true
  window:set_config_overrides(overrides)
end)

local keybinds = {
  {
    key = 'c',
    mods = 'ALT',
    action = wezterm.action.EmitEvent('toggle-color-scheme')
  },
  {
    key = 'v',
    mods = 'CTRL|SHIFT',
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

local function table_concat(t1,t2)
  for i=1,#t2 do
    t1[#t1+1] = t2[i]
  end
  return t1
end

config.keys = table_concat(keybinds, generate_neovim_tab_navigation_keybinds())

return config
