#!/usr/bin/env fish

# Using `$()` inside double quotes, instead of just `()`, so the output isn't treated like an array and newlines are
# preserved.
#
# Using printf to remove trailing newlines since there will be multiple when the package doesn't have a
# longDescription.
#
# Using the newline in the printf format so we have one trailing newline to end the entire output.
printf "%s\n" "$(nix-env -qaA "nixpkgs."$argv --json --meta 2>/dev/null | jq -r '.[] | .name + " " + .meta.description, .meta.homepage, "", (.meta.longDescription // "" | rtrimstr("\n"))')"
