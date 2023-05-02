# Get the class of the currently-focused window:
#winClass = window.get_active_class().lower()

#output = "<ctrl>+]"
# only enabling for firefox because it causes issues with wezterm and I don't know
# how to exclude a program
#if "firefox" in winClass:
#    output = "<ctrl>+<tab>"
keyboard.send_keys("<ctrl>+<tab>")