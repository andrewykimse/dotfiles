# OpenCode Vim selector navigation

This package extends `opencode-vim` 0.0.29 with `h` to dismiss a selector and
`l` to select its current option. Every newly focused selector starts in normal
mode, regardless of the prompt's mode. It uses OpenCode's native dialog APIs.

The handler runs inside the upstream normal-mode dialog branch only. Prompt
cursor motions, insert-mode search, visual mode, pending Vim operations, and
explicit custom mappings are unchanged. Text-only dialogs and question forms
are not affected. Back dismisses the current dialog; it does not add a history
stack to OpenCode's palettes. Switching a selector to insert mode for search
keeps that mode until another selector is focused.

`default.nix` pins the published npm bundle and both runtime dependencies.
OpenCode/OpenTUI peers come from the host. When updating upstream, review the
patch anchor and run the tests: the build deliberately fails if that anchor
changes. `selector-navigation.test.mjs` checks the helper and the actual patched
upstream branch, including prompt and insert-mode passthrough.

The shared configuration in `modules/dev.nix` loads this package instead of
the unpatched npm plugin. Gateway configuration and credentials are untouched.
