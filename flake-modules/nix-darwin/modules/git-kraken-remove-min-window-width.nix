# Remove GitKraken minimum window width. Source:
# https://github.com/adrianjagielak/gitkraken-multiple-instances-enabler/blob/2c11b524e2de34751996bd00726e8c61b86a101b/README.md
# node has to be on the PATH because `npx` requires `node` to be on the PATH
pkgs: ''
  PATH="${pkgs.nodejs}/bin:$PATH"
  # Create a backup of app.asar
  cp \
    /Applications/GitKraken.app/Contents/Resources/app.asar \
    /Applications/GitKraken.app/Contents/Resources/app-backup.asar
  # Unpack app.asar
  npx --yes electron/asar extract \
    /Applications/GitKraken.app/Contents/Resources/app.asar \
    /Applications/GitKraken.app/Contents/Resources/app-extracted
  # Remove window width restriction. Unlike the original script, I don't pass
  # an argument to `-i` because I'm using GNU sed
  ${pkgs.gnused}/bin/sed -i 's/minWidth:1024,/minWidth:100,/g' \
    /Applications/GitKraken.app/Contents/Resources/app-extracted/src/main/static/main.bundle.js
  # Re-pack app.asar
  npx --yes electron/asar pack \
    /Applications/GitKraken.app/Contents/Resources/app-extracted \
    /Applications/GitKraken.app/Contents/Resources/app-patched.asar
  # Replace app.asar with patched app-patched.asar
  mv \
    /Applications/GitKraken.app/Contents/Resources/app-patched.asar \
    /Applications/GitKraken.app/Contents/Resources/app.asar
  # Cleanup (deleting extracted copy of app)
  rm -rf /Applications/GitKraken.app/Contents/Resources/app-extracted
''
