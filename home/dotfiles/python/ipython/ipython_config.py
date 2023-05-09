from IPython.terminal.prompts import Token

c = get_config()

c.InteractiveShellApp.extensions = ['autoreload', 'storemagic']
c.TerminalIPythonApp.display_banner = False
c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.highlighting_style = 'bw'
c.TerminalInteractiveShell.highlighting_style_overrides = {
    Token.Prompt: '',
    Token.PromptNum: ' bold',
    Token.OutPrompt: 'ansibrightyellow',
    Token.OutPromptNum: 'ansibrightyellow bold',
    Token.Comment: 'ansiwhite italic',
    Token.CommentPreproc: 'noitalic',
    Token.Error: 'ansired',
    Token.String: 'ansigreen noitalic',
    Token.String.Interpol: "nobold",
    Token.String.Escape: "nobold",
    Token.Keyword: 'ansicyan nobold',
    Token.Literal: '',
    Token.Name: '',
    Token.Name.Decorator: 'ansicyan',
    Token.Name.Class: 'ansicyan nobold',
    Token.Name.Function: 'ansicyan',
    Token.Name.Builtin: 'ansicyan',
    Token.Name.Namespace: "nobold",
    Token.Name.Exception: "nobold",
    Token.Name.Entity: "nobold",
    Token.Name.Tag: "nobold",
    Token.Number: 'ansimagenta',
    Token.Operator: 'ansiblue',
    Token.Operator.Word: "nobold",
    Token.Punctuation: '',
    Token.Escape: '',
    Token.ExecutingNode: '',
    Token.Generic: '',
    Token.Other: '',
    Token.Text: '',
    Token.Token: '',
}
