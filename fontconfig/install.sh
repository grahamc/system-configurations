#!/bin/sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

# Install system configs
sudo install --compare --backup --suffix=.bak --owner=root --group=root --mode='u=rw,g=r,o=r' -D --verbose --no-target-directory ./fontconfig/local.conf /etc/fonts/local.conf
sudo install --compare --backup --suffix=.bak --owner=root --group=root --mode='u=rw,g=r,o=r' -D --verbose --no-target-directory ./fontconfig/10-nerd-font-symbols.conf /etc/fonts/conf.d/10-nerd-font-symbols.conf

# Enable the system configuration preset, this allows the files installed above to be read
SYSTEM_CONFIG_PRESET='/etc/fonts/conf.d/51-local.conf'
ln --force --symbolic --relative ../conf.avail/51-local.conf "$SYSTEM_CONFIG_PRESET"

# Register the fontconfig dtd in the xmlcatalog
DTD='/usr/share/xml/fontconfig/fonts.dtd'
CATALOG='/etc/xml/catalog'
if [ -f "$DTD" ]; then
  if [ -f "$CATALOG" ]; then
    sudo "$(which xmlcatalog)" --noout --add system "urn:fontconfig:fonts.dtd" "file://$DTD" "$CATALOG"
  else
    echo "ERROR: Could not find the xml catalog in $CATALOG." >&2
    exit 1
  fi
else
  echo "ERROR: Could not find the fontconfig dtd in $DTD." >&2
  exit 1
fi

# Rebuild the font information cache
fc-cache -r
