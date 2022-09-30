from IPython.terminal.prompts import Token

c = get_config()

c.InteractiveShellApp.extensions = ['autoreload', 'storemagic']
c.TerminalIPythonApp.display_banner = False
c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.highlighting_style = 'nord'
c.TerminalInteractiveShell.highlighting_style_overrides = {
    Token.Prompt: 'fg:',
    Token.PromptNum: 'fg: bold',
    Token.OutPrompt: 'fg:ansibrightyellow',
    Token.OutPromptNum: 'fg:ansibrightyellow bold',
    Token.Comment: 'fg:ansiwhite',
    Token.Error: 'fg:ansired',
    Token.String: 'fg:ansigreen',
    Token.Keyword: 'fg:ansicyan',
    Token.Literal: 'fg:',
    Token.Name: 'fg:',
    Token.Name.Decorator: 'fg:ansicyan',
    Token.Name.Class: 'fg:ansicyan',
    Token.Name.Function: 'fg:ansicyan',
    Token.Name.Builtin: 'fg:ansicyan',
    Token.Number: 'fg:ansimagenta',
    Token.Operator: 'fg:ansiblue',
    Token.Punctuation: 'fg:',
    Token.Escape: 'fg:',
    Token.ExecutingNode: 'fg:',
    Token.Generic: 'fg:',
    Token.Other: 'fg:',
    Token.Text: 'fg:',
    Token.Token: 'fg:',
}
