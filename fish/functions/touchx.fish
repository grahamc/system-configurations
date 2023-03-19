function touchx
    set filename "$argv"
    touch "$filename"
    chmod +x "$filename"
end
