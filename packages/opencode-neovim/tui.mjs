export const commandID = "dotfiles.neovim.open";

export default {
  id: "dotfiles-neovim",
  setup(api) {
    let opening = false;
    let disposed = false;

    function paneVisible() {
      const close = api.keymap.commands().find((command) => command.id === "terminal.close");
      return close && (typeof close.enabled === "function" ? close.enabled() : close.enabled !== false);
    }

    function stillCurrent(sessionID) {
      const current = api.ui.router.current();
      return !disposed && current.type === "session" && current.sessionID === sessionID;
    }

    async function open() {
      const route = api.ui.router.current();
      if (disposed || opening || route.type !== "session") return;
      opening = true;
      try {
        if (!api.keymap.commands().some((command) => command.id === "terminal.toggle")) {
          throw new Error("This OpenCode server does not support terminal panes.");
        }
        const session = await api.client.session.get({ sessionID: route.sessionID });
        if (!session.location?.directory) {
          throw new Error("The session has no working directory.");
        }
        if (disposed) return;
        await api.client.experimental.persistentPty.create({
          sessionID: route.sessionID,
          command: "nvim",
          args: [],
          cwd: session.location.directory,
          title: "Neovim",
          env: {},
        });
        // Do not steal focus if the user switched sessions during startup.
        if (!stillCurrent(route.sessionID)) return;
        api.ui.dialog.clear();
        // Toggle selects the newest PTY after refreshing from the server.
        // Hide an existing pane first, without terminating its process.
        api.keymap.dispatch("terminal.close");
        // Native close persists its selection asynchronously. Wait until it
        // settles so toggle opens the new pane instead of hiding the old one.
        for (let attempt = 0; paneVisible(); attempt++) {
          if (attempt === 200) throw new Error("The existing terminal pane did not close.");
          await new Promise((resolve) => setTimeout(resolve, 10));
          if (!stillCurrent(route.sessionID)) return;
        }
        api.keymap.dispatch("terminal.toggle");
      } catch (error) {
        if (!disposed) {
          api.ui.toast.show({
            variant: "error",
            title: "Failed to open Neovim",
            message: error instanceof Error ? error.message : String(error),
          });
        }
      } finally {
        opening = false;
      }
    }

    api.keymap.layer(() => ({
      mode: "global",
      enabled: api.ui.router.current().type === "session",
      commands: [{
        id: commandID,
        bind: api.options?.bind ?? "<leader>v",
        title: "Open Neovim pane",
        group: "Session",
        palette: true,
        run: open,
      }],
    }));
    return () => { disposed = true; };
  },
};
