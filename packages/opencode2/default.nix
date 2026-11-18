{ pkgs }:
let
  version = "2.3.2";
  system = pkgs.stdenv.hostPlatform.system;
  target = {
    x86_64-linux = { name = "linux-x64"; hash = "sha256-hFRo41qlorV0lFoLlmdeZMYE9Sec7ZqnJFBo2MC29rs="; };
    aarch64-linux = { name = "linux-arm64"; hash = "sha256-kak3Ep79ro64wMUBiuUz+fNRF/Jv/ZpNH3pfnaHmkwY="; };
    aarch64-darwin = { name = "darwin-arm64"; hash = "sha256-gp+RF5pvQID1KNOmdWuH0umVPev7CgaKWb9HPS11Nak="; };
  }.${system} or (throw "opencode2: unsupported system ${system}");
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "opencode2";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opencode/cli-${target.name}/-/cli-${target.name}-${version}.tgz";
    inherit (target) hash;
  };

  nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
  buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.stdenv.cc.cc.lib ];

  # The binary is a compiled bundle with an embedded payload; stripping corrupts it.
  dontStrip = true;

  installPhase = ''
    install -Dm755 bin/opencode $out/bin/opencode2
  '';
}
