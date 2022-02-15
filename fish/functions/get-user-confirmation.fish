function get-user-confirmation --argument-names prompt_text
    echo -s $prompt_text ' (y/n):'
    read --prompt 'echo "> "' --nchars 1 response
    if test $response = y
        return 0
    end
    return 1
end
