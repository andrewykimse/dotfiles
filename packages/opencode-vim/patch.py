"""Extend the pinned upstream dialog branch without changing prompt mappings."""

import sys
from pathlib import Path

bundle = Path(sys.argv[1])
helper = Path(sys.argv[2]).read_text()
source = bundle.read_text()

# Match the normal-mode dialog gate too: fail loudly if an upstream update
# moves navigation outside this scope, rather than intercepting prompt input.
anchor = '''    if (kind === "dialog" && !vimee.isPending() && !mapped && state.mode() === "normal") {
      if (key === "<Tab>"'''
if source.count(anchor) != 1:
    raise SystemExit("opencode-vim dialog handler changed; review the selector patch")

replacement = '''    if (kind === "dialog" && !vimee.isPending() && !mapped && state.mode() === "normal") {
      if (handleSelectorNavigation(props.context, event, key))
        return;
      if (key === "<Tab>"'''
source = source.replace(anchor, replacement)
source += "\n" + helper.replace("export function", "function", 1)
bundle.write_text(source)
