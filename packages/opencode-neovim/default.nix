{ pkgs }:
pkgs.runCommand "dotfiles-opencode-neovim-0.1.0" {
  nativeBuildInputs = [ pkgs.nodejs ];
} ''
  mkdir -p "$out"
  cp ${./package.json} "$out/package.json"
  cp ${./tui.mjs} "$out/tui.mjs"
  cp ${./tui.test.mjs} tui.test.mjs
  cp ${./tui.mjs} tui.mjs
  node --test tui.test.mjs
  node --check "$out/tui.mjs"
''
