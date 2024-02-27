#!/usr/bin/env python

import sys
import subprocess
from urllib.parse import urlparse

# NOTE: Characters I removed: '()
VALID_URL_CHARS = (
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&*+,;="
)
MOUSE_PROGRAMS = ["vim", "nvim", "edit"]


def main():
    # The x and y are 0-indexed
    mouse_x = int(sys.argv[1])
    mouse_y = int(sys.argv[2])
    pane_command = sys.argv[3]
    scroll_position = sys.argv[4]
    scroll_position = int(scroll_position) if scroll_position != "" else 0
    mouse_y = mouse_y - scroll_position
    mouse_url = sys.argv[5]
    terminal_width = int(sys.argv[6])

    # If the program in the current pane grabbed the mouse, don't open any links. The
    # program in the pane should do it.
    #
    # TODO: I should check if the program running in the current pane has 'grabbed' the
    # mouse like kitty does.  For now I'll check for specific programs that I know grab
    # the mouse
    if pane_command in MOUSE_PROGRAMS:
        return

    if mouse_url != "":
        # tmux already extracted a url so just open it
        open_url(mouse_url)
        return

    top_lines = subprocess.check_output(
        ["tmux", "capture-pane", "-p", "-S", str(mouse_y - 20), "-E", str(mouse_y)],
        text=True,
    ).split("\n")[:-1]
    bottom_lines = subprocess.check_output(
        ["tmux", "capture-pane", "-p", "-S", str(mouse_y + 1), "-E", str(mouse_y + 20)],
        text=True,
    ).split("\n")
    mouse_y = len(top_lines) - 1
    pane_lines = top_lines + bottom_lines

    # The mouse isn't over a character so it can't be a url
    if not is_in_bounds(len(pane_lines), mouse_y) or not is_in_bounds(
        len(pane_lines[mouse_y]), mouse_x
    ):
        return

    # The mouse isn't over a valid url character so it can't be a url
    if not is_valid_url_char(pane_lines[mouse_y][mouse_x]):
        return

    # build and validate url
    left = expand(pane_lines, mouse_x, mouse_y, True, terminal_width)[::-1]
    left.append(pane_lines[mouse_y][mouse_x])
    right = expand(pane_lines, mouse_x, mouse_y, False, terminal_width)
    potential_url = "".join(left + right)
    result = urlparse(potential_url)
    if result.scheme == "":
        return

    open_url(potential_url)


def open_url(url):
    subprocess.run(["open", url], stdout=subprocess.DEVNULL, stdin=subprocess.DEVNULL)


def expand(lines, start_x, start_y, left, terminal_width):
    result = []
    x = start_x
    y = start_y
    step = -1 if left else 1
    x = x + step
    while is_in_bounds(len(lines), y):
        while is_in_bounds(len(lines[y]), x):
            char = lines[y][x]
            if not is_valid_url_char(char):
                return result
            result.append(lines[y][x])
            x = x + step
        y = y + step
        if is_in_bounds(len(lines), y):
            if left:
                # Don't continue expanding unless the line we're currently on extends to
                # the end of the screen, which suggests it wrapped.
                if len(lines[y]) != terminal_width:
                    break
            else:
                # Don't continue expanding unless the last line we were on hit the end
                # of the screen, which suggests it wrapped.
                if len(lines[y - step]) != terminal_width:
                    break
            x = len(lines[y]) - 1 if left else 0

    return result


def is_in_bounds(max, num):
    return num >= 0 and num < max


def is_valid_url_char(char):
    return char in VALID_URL_CHARS


if __name__ == "__main__":
    main()
