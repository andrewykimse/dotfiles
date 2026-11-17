{ pkgs }:
let
  # Pin the published bundle and its two runtime dependencies. Host-provided
  # OpenCode/OpenTUI peers must not be installed as a second renderer instance.
  upstream = pkgs.fetchurl {
    url = "https://registry.npmjs.org/opencode-vim/-/opencode-vim-0.0.29.tgz";
    hash = "sha256-3que8c2VOVyOTxyl3bk8enYhT7YWSChaFNdRkAVvoSQ=";
  };
  vimee = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@vimee/core/-/core-0.3.0.tgz";
    hash = "sha256-pEZM/B3jcVCvUDdiObCi8Ly9u3gVeBM6k3I5/ALYHzU=";
  };
  diff = pkgs.fetchurl {
    url = "https://registry.npmjs.org/diff/-/diff-9.0.0.tgz";
    hash = "sha256-uJi/I8lVlGB1duJd3UAT8dUe0OhiqvBzKBWDDIeztY8=";
  };
in
pkgs.runCommand "opencode-vim-0.0.29-selector-navigation" {
  nativeBuildInputs = [ pkgs.python3 pkgs.nodejs ];
} ''
  mkdir -p "$out/node_modules/@vimee/core" "$out/node_modules/diff"
  tar -xzf ${upstream} --strip-components=1 -C "$out"
  tar -xzf ${vimee} --strip-components=1 -C "$out/node_modules/@vimee/core"
  tar -xzf ${diff} --strip-components=1 -C "$out/node_modules/diff"
  python3 ${./patch.py} "$out/dist/tui.js" ${./selector-navigation.mjs}
  cp ${./selector-navigation.mjs} selector-navigation.mjs
  cp ${./selector-navigation.test.mjs} selector-navigation.test.mjs
  OPENCODE_VIM_BUNDLE="$out/dist/tui.js" node --test selector-navigation.test.mjs
  node --check "$out/dist/tui.js"
''
