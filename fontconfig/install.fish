echo 'Installing configuration files...'
sudo install --compare --backup --suffix=.bak --owner=root --group=root --mode='u=rw,g=r,o=r' -D --verbose --no-target-directory ./fontconfig/local.conf /etc/fonts/local.conf
sudo install --compare --backup --suffix=.bak --owner=root --group=root --mode='u=rw,g=r,o=r' -D --verbose --no-target-directory ./fontconfig/10-nerd-font-symbols.conf /etc/fonts/conf.d/10-nerd-font-symbols.conf

echo 'Enabling the system configuration preset...'
if not test -f /etc/fonts/conf.d/51-local.conf
  ln --symbolic --relative ../conf.avail/51-local.conf /etc/fonts/conf.d/51-local.conf
end

echo 'Registering the fontconfig dtd in the xmlcatalog...'
set dtd '/usr/share/xml/fontconfig/fonts.dtd'
set catalog '/etc/xml/catalog'
if test -f "$dtd"
  if test -f "$catalog"
    sudo (which xmlcatalog) --noout --add system "urn:fontconfig:fonts.dtd" "file://$dtd" "$catalog"
  else
    echo -s (set_color red) "ERROR: Could not find the xml catalog in $catalog." (set_color normal) >/dev/stderr
  end
else
  echo -s (set_color red) "ERROR: Could not find the fontconfig dtd in $dtd." (set_color normal) >/dev/stderr
end

echo 'Reloading fontconfig configuration...'
fc-cache -r
