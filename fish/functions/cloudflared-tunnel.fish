function cloudflared-tunnel --description 'Run my cloudflare tunnel with the provided url' --argument-names url
    if test (count $argv) -eq 0
        set function_name (status current-function)
        echo -s \
            (set_color red) \
            "ERROR: You need to specify a port, e.g. '$function_name 8000'" >/dev/stderr
        return 1
    end
    cloudflared tunnel run --url "http://localhost:$url"
end
