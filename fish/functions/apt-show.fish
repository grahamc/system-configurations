function apt-show --description "'apt show' with each section name highlighted, paged with less" --wraps 'apt show'
    # I supress stderr to remove the warning that apt prints out when you use apt
    # in a non-interactive shell
    apt show $argv 2>/dev/null | grep --color=always -E "(^[a-z|A-Z|-]*:|^)" | less
end
