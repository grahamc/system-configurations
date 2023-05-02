# Get the class of the currently-focused window:
winClass = window.get_active_class().lower()

output = "<alt>+["
if "firefox" in winClass:
    output = "<ctrl>+["

keyboard.send_keys(output)