#!/usr/bin/env python3

# I can remove this when trashy gets support for macOS, which is blocked by an issue with the library they use
# for accessing the trash: https://github.com/Byron/trash-rs/issues/8

import os
import sys
import subprocess

if len(sys.argv) > 1:
    files: list[str] = []
    for arg in sys.argv[1:]:
        if os.path.exists(arg):
            p = os.path.abspath(arg).replace("\\", "\\\\").replace('"', '\\"')
            files.append('the POSIX file "' + p + '"')
        else:
            sys.stderr.write("%s: %s: No such file or directory\n" % (sys.argv[0], arg))
    if len(files) > 0:
        cmd = [
            "osascript",
            "-e",
            'tell app "Finder" to move {' + ", ".join(files) + "} to trash",
        ]
        r = subprocess.call(cmd, stdout=open(os.devnull, "w"))
        sys.exit(r if len(files) == len(sys.argv[1:]) else 1)
else:
    sys.stderr.write(
        "usage: %s file(s)\n"
        "       move file(s) to Trash\n" % os.path.basename(sys.argv[0])
    )
    sys.exit(64)  # matches what rm does on my system
