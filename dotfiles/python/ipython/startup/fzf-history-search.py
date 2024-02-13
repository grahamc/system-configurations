# pylint: disable=import-outside-toplevel
# pylint: disable=global-statement

# I took this from here: https://github.com/infokiller/config-public/blob/30984c5234c382b1b5eb097872a535458cd6ec70/.config/ipython/profile_default/startup/ext/fzf_history.py
# Changes:
# - Added a new Pygments style to color the history lines in the fzf preview (AnsiStyle)
# - The function that generates the fzf preview now returns an error string, if an error occurs

import datetime
import errno
import os
import sqlite3
import subprocess
import sys
import tempfile
import threading
from typing import Any, Callable, Generator, Tuple

import IPython

# This startup file is also used by `jupyter console`, which doesn't use prompt
# toolkit, and may fail importing it.
try:
    import prompt_toolkit
    from prompt_toolkit.keys import Keys

    _KeyPressEvent = prompt_toolkit.key_binding.key_processor.KeyPressEvent
except (ImportError, ValueError):
    pass

_ENCODED_NEWLINE = "␤"
_ENCODED_NEWLINE_HIGHLIGHT = "\x1b[93m"
_ENCODED_NEWLINE_HIGHLIGHT_RESET = "\x1b[0m"
_HIGHLIGHTED_ENCODED_NEWLINE = "{}{}{}".format(
    _ENCODED_NEWLINE_HIGHLIGHT, _ENCODED_NEWLINE, _ENCODED_NEWLINE_HIGHLIGHT_RESET
)

_FZF_PREVIEW_SCRIPT = """
echo {+n} > "%s"
cat -- "%s"
"""

_PYGMENTS_LEXER = None
_PYGMENTS_STYLE = None
_PYGMENTS_FORMATTER = None

# Time the entry was executed and the code executed.
HistoryEntry = Tuple[datetime.datetime, str]


def _load_pygments_objects():
    import pygments
    from pygments.style import Style
    from pygments.token import Token

    class AnsiStyle(Style):
        # TODO: These styles are copied from my 'ipython_config', but I should find a way to centralize the styles
        styles = {
            Token.Prompt: "",
            Token.PromptNum: " bold",
            Token.OutPrompt: "ansibrightyellow",
            Token.OutPromptNum: "ansibrightyellow bold",
            Token.Comment: "ansiwhite italic",
            Token.CommentPreproc: "noitalic",
            Token.Error: "ansired",
            Token.String: "ansigreen noitalic",
            Token.String.Interpol: "nobold",
            Token.String.Escape: "nobold",
            Token.Keyword: "ansicyan nobold",
            Token.Literal: "",
            Token.Name: "",
            Token.Name.Decorator: "ansicyan",
            Token.Name.Class: "ansicyan nobold",
            Token.Name.Function: "ansicyan",
            Token.Name.Builtin: "ansicyan",
            Token.Name.Namespace: "nobold",
            Token.Name.Exception: "nobold",
            Token.Name.Entity: "nobold",
            Token.Name.Tag: "nobold",
            Token.Number: "ansimagenta",
            Token.Operator: "ansiblue",
            Token.Operator.Word: "nobold",
            Token.Punctuation: "",
            Token.Escape: "",
            Token.ExecutingNode: "",
            Token.Generic: "",
            Token.Other: "",
            Token.Text: "",
            Token.Token: "",
        }

    global _PYGMENTS_LEXER, _PYGMENTS_STYLE, _PYGMENTS_FORMATTER

    try:
        _PYGMENTS_LEXER = pygments.lexers.get_lexer_by_name("ipython3")
    except pygments.lexers.ClassNotFound:
        _PYGMENTS_LEXER = pygments.lexers.get_lexer_by_name("python3")

    _PYGMENTS_STYLE = AnsiStyle

    try:
        _PYGMENTS_FORMATTER = pygments.formatters.get_formatter_by_name(
            "terminal256", style=_PYGMENTS_STYLE
        )
    except pygments.formatters.ClassNotFound:
        _PYGMENTS_FORMATTER = pygments.formatters.get_formatter_by_name(
            "terminal16m", style=_PYGMENTS_STYLE
        )


def _highlight_code(code: str) -> str:
    try:
        import pygments

        global _PYGMENTS_LEXER, _PYGMENTS_STYLE, _PYGMENTS_FORMATTER
        if _PYGMENTS_LEXER is None:
            _load_pygments_objects()
        return pygments.highlight(code, _PYGMENTS_LEXER, _PYGMENTS_FORMATTER)
    except Exception as e:
        return repr(e)


class _HistoryPreviewThread(threading.Thread):
    def __init__(
        self,
        fifo_input_path: str,
        fifo_output_path: str,
        history_getter: Callable[[int], Any],
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.fifo_input_path = fifo_input_path
        self.fifo_output_path = fifo_output_path
        self.history_getter = history_getter
        self.is_done = threading.Event()

    def run(self) -> None:
        while not self.is_done.is_set():
            with open(self.fifo_input_path) as fifo_input:
                while not self.is_done.is_set():
                    data = fifo_input.read()
                    if len(data) == 0:
                        break
                    indices = [int(s) for s in data.split()]
                    entries = [self.history_getter(i)[1] for i in indices]
                    code = "\n".join(entries)
                    highlighted_code = _highlight_code(code)
                    with open(self.fifo_output_path, "w") as fifo_output:
                        fifo_output.write(highlighted_code)

    def stop(self):
        self.is_done.set()
        with open(self.fifo_input_path, "w") as f:
            f.close()
        self.join()


def _extract_command(fzf_output):
    if not fzf_output.strip():
        return ""
    return fzf_output[fzf_output.index("|") + 1 :].strip()


def _encode_to_selection(code: str) -> str:
    code = code.strip()
    return code.replace("\n", _HIGHLIGHTED_ENCODED_NEWLINE)


def _decode_from_selection(code: str) -> str:
    return code.replace(_ENCODED_NEWLINE, "\n")


def _send_entry_to_fzf(entry: HistoryEntry, fzf):
    code = _encode_to_selection(entry[1])
    line = "{:%Y-%m-%d %H:%M:%S} | {}\n".format(entry[0], code).encode("utf-8")
    try:
        fzf.stdin.write(line)
    except IOError as e:
        if e.errno == errno.EPIPE:
            return


def _create_preview_fifos():
    fifo_dir = tempfile.mkdtemp(prefix="ipython_fzf_hist_")
    fifo_input_path = os.path.join(fifo_dir, "input")
    fifo_output_path = os.path.join(fifo_dir, "output")
    os.mkfifo(fifo_input_path)
    os.mkfifo(fifo_output_path)
    return fifo_input_path, fifo_output_path


def _create_fzf_process(initial_query, fifo_input_path, fifo_output_path):
    xdg_data_directory = os.environ.get(
        "XDG_DATA_HOME", f"{os.environ['HOME']}/.local/share"
    )
    fzf_history_directory = f"{xdg_data_directory}/fzf"
    fzf_history_file = f"{fzf_history_directory}/fzf-ipython-history.txt"
    subprocess.run(["mkdir", "-p", fzf_history_directory])
    subprocess.run(["touch", fzf_history_file])
    return subprocess.Popen(
        [
            "fzf",
            "--no-sort",
            "-n3..,..",
            "--with-nth=4..",
            "--tiebreak=index",
            f"--history={fzf_history_file}",
            "--exact",
            "--query={}".format(initial_query),
            "--preview-window=follow",
            "--preview={}".format(
                _FZF_PREVIEW_SCRIPT % (fifo_input_path, fifo_output_path)
            ),
        ],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
    )


def _get_history_from_connection(con) -> Generator[HistoryEntry, None, None]:
    session_to_start_time = {}
    for session, start_time in con.execute("SELECT session, start FROM sessions"):
        session_to_start_time[session] = start_time
    query = """
    SELECT session, source_raw FROM (
        SELECT session, source_raw, rowid FROM history ORDER BY rowid DESC
    )
    """
    for session, source_raw in con.execute(query):
        yield (session_to_start_time[session], source_raw)


def _get_command_history(files=None) -> Generator[HistoryEntry, None, None]:
    hist_manager = IPython.get_ipython().history_manager
    if not files:
        files = [hist_manager.hist_file]
    for file in files:
        # detect_types causes timestamps to be returned as datetime objects.
        con = sqlite3.connect(
            file,
            detect_types=sqlite3.PARSE_DECLTYPES | sqlite3.PARSE_COLNAMES,
            **hist_manager.connection_options,
        )
        for entry in _get_history_from_connection(con):
            yield entry
        con.close()


def select_history_line(event: _KeyPressEvent, history_files=None):
    fifo_input_path, fifo_output_path = _create_preview_fifos()
    fzf = _create_fzf_process(
        event.current_buffer.text, fifo_input_path, fifo_output_path
    )
    history = []
    preview_thread = _HistoryPreviewThread(
        fifo_input_path, fifo_output_path, lambda i: history[i]
    )
    preview_thread.start()
    for entry in _get_command_history(history_files):
        history.append(entry)
        _send_entry_to_fzf(entry, fzf)
    stdout, stderr = fzf.communicate()
    preview_thread.stop()
    if fzf.returncode == 0:
        lines = []
        for line in stdout.decode("utf-8").split("\n"):
            if not line.strip():
                continue
            lines.append(_decode_from_selection(_extract_command(line)))
        event.current_buffer.document = prompt_toolkit.document.Document(
            "\n".join(lines)
        )
    # The 130 error code is when the user exited fzf, which is not an error.
    elif fzf.returncode != 130:
        sys.stderr.write(str(stderr))


def _is_using_prompt_toolkit():
    return hasattr(IPython.get_ipython(), "pt_app")


if _is_using_prompt_toolkit():
    key_bindings = IPython.get_ipython().pt_app.key_bindings
    key_bindings.add(Keys.ControlR, filter=True)(select_history_line)
