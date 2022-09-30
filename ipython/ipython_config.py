from IPython.terminal.prompts import Token

c = get_config()

c.InteractiveShellApp.extensions = ['autoreload', 'storemagic']
c.TerminalIPythonApp.display_banner = False
c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.highlighting_style = 'bw'
c.TerminalInteractiveShell.highlighting_style_overrides = {
    Token.Prompt: 'fg:',
    Token.PromptNum: 'fg: bold',
    Token.OutPrompt: 'fg:ansibrightyellow',
    Token.OutPromptNum: 'fg:ansibrightyellow bold',
    Token.Comment: 'fg:ansiwhite italic',
    Token.CommentPreproc: 'noitalic',
    Token.Error: 'fg:ansired',
    Token.String: 'fg:ansigreen noitalic',
    Token.String.Interpol: "nobold",
    Token.String.Escape: "nobold",
    Token.Keyword: 'fg:ansicyan nobold',
    Token.Literal: 'fg:',
    Token.Name: 'fg:',
    Token.Name.Decorator: 'fg:ansicyan',
    Token.Name.Class: 'fg:ansicyan nobold',
    Token.Name.Function: 'fg:ansicyan',
    Token.Name.Builtin: 'fg:ansicyan',
    Token.Name.Namespace: "nobold",
    Token.Name.Exception: "nobold",
    Token.Name.Entity: "nobold",
    Token.Name.Tag: "nobold",
    Token.Number: 'fg:ansimagenta',
    Token.Operator: 'fg:ansiblue',
    Token.Operator.Word: "nobold",
    Token.Punctuation: 'fg:',
    Token.Escape: 'fg:',
    Token.ExecutingNode: 'fg:',
    Token.Generic: 'fg:',
    Token.Other: 'fg:',
    Token.Text: 'fg:',
    Token.Token: 'fg:',
}
