echo 'Are you sure want to install the fontconfig config? (y/n): '
read --prompt 'echo "> "' --nchars 1 response
if test "$response" != y
    return
end

sudo install --compare --backup --suffix=.bak --owner=root --group=root --mode='u=rw,g=r,o=r' -D --verbose --no-target-directory ./fontconfig/local.conf /etc/fonts/local.conf
