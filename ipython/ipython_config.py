c = get_config()

c.InteractiveShellApp.extensions = ['autoreload', 'storemagic']
c.TerminalIPythonApp.display_banner = False
c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.true_color = True
