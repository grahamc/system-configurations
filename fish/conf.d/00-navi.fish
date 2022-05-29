if not status is-interactive
    exit
end


# Load navi widget. The '00' in the beginning of the file name is to ensure tha this script is
# run before any others since part of loading navi is setting a keybind (ctrl+g) and
# that would overwrite one of my keybinds. By doing this first, navi's keybind will be
# the one that gets overwritten. Instead I'll use ctrl+/.
navi widget fish | source
bind \c_ _navi_smart_replace
