# synchronize the two buffers where copied text can be stored
autocutsel -fork -selection CLIPBOARD
autocutsel -fork -selection PRIMARY

# start keybind daemon
xbindkeys
