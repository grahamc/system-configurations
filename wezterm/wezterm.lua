local wezterm = require 'wezterm'

local config = wezterm.config_builder()

function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'Nord (base16)'
  else
    return 'Night Owlish Light'
  end
end

wezterm.on('window-config-reloaded', function(window, pane)
  local overrides = window:get_config_overrides() or {}
  local appearance = window:get_appearance()
  local scheme = scheme_for_appearance(appearance)
  if overrides.color_scheme ~= scheme then
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
  end
end)

config.window_background_opacity = 0.95

config.window_close_confirmation = 'NeverPrompt'

return config
