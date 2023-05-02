# Get the class of the currently-focused window:
winClass = window.get_active_class().lower()

output = "<ctrl>+v"
if "wezterm" in winClass:
    output = "<super>+v"

keyboard.send_keys(output)