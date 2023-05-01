if not status is-interactive
    exit
end

# Since editing a single line script would be hard, I have the multi-line form below. This way I can make changes
# and fold it into a single line again. Some quirks to be aware of while working on this:
#   - Don't put a semicolon after `then` or `else`, it's invalid POSIX shell syntax.
#   - Don't add blank lines to the multi-line script because you may get an invalid result if you fold it by doing
#   'go to end of line, add a semicolon, append the line below to the current line'.
#   - TODO: You'll notice the first command is `:`. I added that because I noticed that the first command in the script
#   was not being evaluated so I made `:` the first command to get around that.

# :
# set -o errexit
# set -o nounset
# shell_dir="$HOME/.local/bin"
# shell_path="$shell_dir/biggs-shell"
# download_url="https://github.com/bigolu/dotfiles/releases/download/master/shell"
# if [ -f "$shell_path" ]; then
#   printf "Do you want to update your shell? (y/n): "
#   read -r response
#   if [ "$response" = y ]; then
#     if command -v curl; then
#       curl --fail --progress-bar --location "$download_url" --output "$shell_path"
#     else
#       wget --output-document "$shell_path" "$download_url"
#     fi
#     chmod +x "$shell_path"
#   fi
# else
#   mkdir -p "$shell_dir"
#   if command -v curl; then
#     curl --fail --progress-bar --location --time-cond "$shell_path" "$download_url" --output "$shell_path"
#   else
#     wget --output-document "$shell_path" "$download_url"
#   fi
#   chmod +x "$shell_path"
# fi
# "$shell_path"

function myssh --wraps ssh
    ssh -o RequestTTY=yes -o RemoteCommand='$SHELL -l -c '"'"'/bin/sh -c '"'"':; set -o errexit; set -o nounset; shell_dir="$HOME/.local/bin"; shell_path="$shell_dir/biggs-shell"; download_url="https://github.com/bigolu/dotfiles/releases/download/master/shell"; if [ -f "$shell_path" ]; then printf "Do you want to update your shell? (y/n): "; read -r response; if [ "$response" = y ]; then if command -v curl; then curl --fail --progress-bar --location "$download_url" --output "$shell_path"; else wget --output-document "$shell_path" "$download_url"; fi; chmod +x "$shell_path"; fi; else mkdir -p "$shell_dir"; if command -v curl; then curl --fail --progress-bar --location --time-cond "$shell_path" "$download_url" --output "$shell_path"; else wget --output-document "$shell_path" "$download_url"; fi; chmod +x "$shell_path"; fi; "$shell_path"'"''" $argv
end
