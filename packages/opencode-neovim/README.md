# OpenCode Neovim pane

An OpenCode V2 CLI plugin with a separate `dotfiles.neovim.open` command.
`modules/dev.nix` binds it to **Ctrl+Space, then v**; **leader + e** remains
the built-in prompt editor.

The command launches plain `nvim` directly in a fresh persistent terminal at the
current session's directory, then opens and focuses OpenCode's terminal pane.
This is equivalent to `cd target/dir && nvim`, without opening a directory buffer.
It does not type commands into an existing shell or touch the chat prompt.
Existing terminal processes remain running. Quit Neovim with `:q` or `:wq`;
use **leader + Left** to focus the conversation, **leader + Right** to focus
the pane, and **leader + Down** to select between existing terminals.

This uses OpenCode 2.3.0's experimental persistent-PTY client API and native
`terminal.close` / `terminal.toggle` commands. Toggle refreshes the terminal
list and selects its newest entry; close hides a pane without killing it.
Close saves its selection asynchronously, so the plugin waits for the close
command to become inactive before toggling. The binding is a plugin option
(`options.bind`), not a custom entry in the native `keybinds` table, which
rejects unknown command IDs in this version.
Recheck that behavior when upgrading OpenCode. Repeated presses start fresh
editors rather than reusing an existing editor.

The package has no runtime dependencies. Its Nix build runs the unit tests;
they can also be run with `node --test packages/opencode-neovim/tui.test.mjs`.
