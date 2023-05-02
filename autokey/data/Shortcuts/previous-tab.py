# Get the class of the currently-focused window:
winClass = window.get_active_class().lower()

output = "<ctrl>+["
if "firefox" in winClass:
    output = "<ctrl>+<shift>+<tab>"

keyboard.send_keys(output)