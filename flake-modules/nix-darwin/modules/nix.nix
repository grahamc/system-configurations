{
  config,
  specialArgs,
  ...
}: let
  inherit (specialArgs) homeDirectory username;
in {
  nix = {
    useDaemon = true;

    settings = {
      trusted-users = [
        "root"
        username
      ];

      experimental-features = [
        "nix-command"
        "flakes"
        "repl-flake"
        "auto-allocate-uids"
      ];

      auto-allocate-uids = true;
    };

    # Use the nixpkgs in this flake in the system flake registry. By default, it pulls the
    # latest version of nixokgs-unstable.
    registry = {
      nixpkgs.flake = specialArgs.flakeInputs.nixpkgs;
    };
    nixPath = [
      {nixpkgs = "flake:nixpkgs";}
    ];
  };

  launchd.daemons.nix-gc = {
    environment.NIX_REMOTE = "daemon";
    serviceConfig.RunAtLoad = false;

    serviceConfig.StartCalendarInterval = [
      # once a month
      {
        Day = 1;
        Hour = 0;
        Minute = 0;
      }
    ];

    command = ''
      /bin/sh -c ' \
        export PATH="${config.nix.package}/bin:''$PATH"; \
        nix-env --profile /nix/var/nix/profiles/system --delete-generations +5; \
        nix-env --profile /nix/var/nix/profiles/default --delete-generations +5; \
        nix-env --profile /nix/var/nix/profiles/per-user/root/profile --delete-generations +5; \
        nix-env --profile ${homeDirectory}/.local/state/nix/profiles/home-manager --delete-generations +5; \
        nix-env --profile ${homeDirectory}/.local/state/nix/profiles/profile --delete-generations +5; \
        nix-collect-garbage --delete-older-than 180d; \
      '
    '';
  };
}
