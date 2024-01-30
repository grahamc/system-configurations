{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
}:
rustPlatform.buildRustPackage rec {
  pname = "lua-json5";
  version = "unstable-2023-10-02";

  src = fetchFromGitHub {
    owner = "Joakker";
    repo = "lua-json5";
    rev = "014fcab8093b48b3932dd0d51ae2d98bbb578d67";
    hash = "sha256-ctLPZzu/lQkVsm+8edE4NsIVUPkr4iTqmPZsCW7GHzY=";
  };

  cargoHash = "sha256-Q9yvkz4cAES6LQZEcWMlyc0fgJoCgDoscLeAIBc/hVw=";

  nativeBuildInputs = [
    pkg-config
  ];

  meta = with lib; {
    description = "A json5 parser for luajit";
    homepage = "https://github.com/Joakker/lua-json5";
    license = licenses.mit;
    maintainers = with maintainers; [];
    mainProgram = "lua-json5";
  };
}
