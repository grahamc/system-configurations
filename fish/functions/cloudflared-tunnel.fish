function cloudflared-tunnel --description 'Run my cloudflare tunnel with the provided url' --argument-names url
    cloudflared tunnel run --url "http://localhost:$url"
end
