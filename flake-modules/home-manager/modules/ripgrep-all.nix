# TODO: Maybe upstream all the community adapters, make it an optional addition to the build
# https://github.com/phiresky/ripgrep-all/discussions/199
{pkgs, ...}: {
  home.packages = with pkgs; [
    # TODO: I should probably xdg-wrap the ripgrep in here too
    ripgrep-all
  ];

  repository.symlink = {
    xdg.executable = {
      "djvutorga".source = "ripgrep/djvutorga.bash";
    };

    # rga stores files according to the XDG Base Directory spec[1] on Linux and the Standard
    # Directories guidelines[2] on macOS:
    # [1]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    # [2]: https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html#//apple_ref/doc/uid/TP40010672-CH2-SW6
    home.file = {
      "${
        if pkgs.stdenv.isLinux
        then ".config"
        else "Library/Application Support"
      }/ripgrep-all/config.jsonc".source = "ripgrep/config.jsonc";
    };
  };
}
