local wezterm = require 'wezterm'

local config = wezterm.config_builder()

-- I'd like to put 'monospace' here so Wezterm can use the monospace font that I set for my system, but Flatpak apps
-- can't access my font configuration file from their sandbox so for now I'll hardcode a font.
-- issue: https://github.com/flatpak/flatpak/issues/1563
config.font = wezterm.font('JetBrains Mono NL')

config.font_size = 10.5
config.underline_position = -8
config.cell_width = 1.04
config.line_height = 1.3
config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = .97
config.window_close_confirmation = 'NeverPrompt'
config.audible_bell = 'Disabled'
config.default_cursor_style = 'BlinkingBar'
config.bold_brightens_ansi_colors = false

config.color_schemes = {
  ['Biggs Nord'] = {
    -- Should match color0
    background = '#1d212b',
    -- Should match color7
    foreground = '#D8DEE9',

    -- Should match color 6
    cursor_bg = '#88C0D0',
    -- Should match background
    cursor_fg = '#1d212b',
    -- Should match color 6
    -- TODO: cursor_bg needs to be set to the same color in order for this to apply
    -- issue: https://github.com/wez/wezterm/issues/1494
    cursor_border = '#88C0D0',

    -- Should match color4
    selection_bg = '#81A1C1',
    -- Should match color0
    selection_fg = '#1d212b',

    -- Should match color5
    scrollbar_thumb = '#B48EAD',

    -- Should match color15
    split = '#626f89',

    ansi = {
      -- color 0
      '#1d212b',
      -- color 1
      '#BF616A',
      -- color 2
      '#A3BE8C',
      -- color 3
      '#EBCB8B',
      -- color 4
      '#81A1C1',
      -- color 5
      '#B48EAD',
      -- color 6
      '#88C0D0',
      -- color 7
      '#D8DEE9',
    },
    brights = {
      -- color 8
      '#2e3440',
      -- color 9
      '#BF616A',
      -- color 10
      '#A3BE8C',
      -- color 11
      '#d08770',
      -- color 12
      '#81A1C1',
      -- color 13
      '#B48EAD',
      -- color 14
      '#8FBCBB',
      -- color 15
      '#626f89',
    },

    indexed = {
      -- Floating windows in neovim
      [16] = '#12151f',
      -- For folded lines, should be darker than color 0
      [24] = '#2e3440',
      -- Floats
      [32] = '#1d2129',
      -- Background color for the non-emphasized part of a removed line in a git diff
      [17] = '#301a1f',
      -- Background color for the emphasized part of a removed line in a git diff
      [25] = '#803030',
      -- Background color for the non-emphasized part of an added line in a git diff
      [18] = '#12261e',
      -- Background color for the emphasized part of an added line in a git diff
      [26] = '#1d572c',
      -- Background color for a moved line in a git diff (source of move)
      [21] = '#60405a',
      -- Background color for a moved line in a git diff (destination of move)
      [22] = '#306a7b',
      -- String in neovim
      [50] = '#A3BE8C',
    },
  },

  ['Biggs Light Owl'] = {
    -- Should match color 0
    background = '#FFFFFF',
    -- Should match color 7
    foreground = '#403f53',

    -- Should match color 6
    cursor_bg = '#994cc3',
    -- Should match background
    cursor_fg = '#FFFFFF',
    -- Should match color 6
    -- TODO: cursor_bg needs to be set to the same color in order for this to apply
    -- issue: https://github.com/wez/wezterm/issues/1494
    cursor_border = '#994cc3',

    -- Should match color4
    selection_bg = '#288ed7',
    -- Should match color0
    selection_fg = '#FFFFFF',

    -- Should match color5
    scrollbar_thumb = '#2AA298',

    -- Should match color15
    split = '#979893',

    ansi = {
      -- color 0
      '#FFFFFF',
      -- color 1
      '#ee3d3b',
      -- color 2
      '#2AA298',
      -- color 3
      '#e9873a',
      -- color 4
      '#288ed7',
      -- color 5, swap this with color 6
      '#2AA298',
      -- color 6, swap this with color 5
      '#994cc3',
      -- color 7
      '#403f53',
    },
    brights = {
      -- color 8
      '#F0F0F0',
      -- color 9
      '#ee3d3b',
      -- color 10
      '#2AA298',
      -- color 11
      '#c96765',
      -- color 12
      '#288ed7',
      -- color 13, swap this with color 14
      '#2AA298',
      -- color 14, swap this with color 13
      '#d6438a',
      -- color 15
      '#979893',
    },

    indexed = {
      -- Floating windows in neovim
      [16] = '#efefef',
      -- For folded lines, should be darker than color 0
      [24] = '#e5e5e5',
      -- Floats
      [32] = '#f1f3f5',
      -- Background color for the non-emphasized part of a removed line in a git diff
      [17] = '#FFD7D7',
      -- Background color for the emphasized part of a removed line in a git diff
      [25] = '#FFAFAF',
      -- Background color for the non-emphasized part of an added line in a git diff
      [18] = '#D7FFD7',
      -- Background color for the emphasized part of an added line in a git diff
      [26] = '#96D596',
      -- Background color for a moved line in a git diff (source of move)
      [21] = '#e99ac0',
      -- Background color for a moved line in a git diff (destination of move)
      [22] = '#85dfd8',
      -- String in neovim
      [50] = '#c96765',
    },
  },
}

-- Change colorscheme automatically when the system changes
function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'Biggs Nord'
  else
    return 'Biggs Light Owl'
  end
end
wezterm.on('window-config-reloaded', function(window)
  local overrides = window:get_config_overrides() or {}
  local appearance = window:get_appearance()
  local scheme = scheme_for_appearance(appearance)
  if overrides.color_scheme ~= scheme then
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
  end
end)

return config
