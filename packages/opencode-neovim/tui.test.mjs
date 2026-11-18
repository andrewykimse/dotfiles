import assert from "node:assert/strict";
import test from "node:test";
import plugin, { commandID } from "./tui.mjs";

function fixture() {
  const calls = [];
  let route = { type: "session", sessionID: "ses_test" };
  let layer;
  const api = {
    ui: {
      router: { current: () => route },
      dialog: { clear: () => calls.push(["clear"]) },
      toast: { show: (toast) => calls.push(["toast", toast]) },
    },
    keymap: {
      layer: (factory) => { layer = factory; },
      commands: () => [{ id: "terminal.toggle" }],
      dispatch: (id) => { calls.push(["dispatch", id]); },
    },
    client: {
      session: { get: async () => ({ location: { directory: "/project with spaces" } }) },
      experimental: { persistentPty: {
        create: async (input) => { calls.push(["create", input]); return { id: "pty_test" }; },
      } },
    },
  };
  const dispose = plugin.setup(api);
  return {
    api, calls, dispose,
    setRoute: (next) => { route = next; },
    layer: () => layer(),
    open: () => layer().commands[0].run(),
  };
}

test("registers a separate, session-scoped command", () => {
  const f = fixture();
  assert.equal(f.layer().mode, "global");
  assert.equal(f.layer().enabled, true);
  assert.equal(f.layer().commands[0].id, commandID);
  assert.equal(f.layer().commands[0].bind, "<leader>v");
  assert.notEqual(commandID, "prompt.editor");
  f.setRoute({ type: "home" });
  assert.equal(f.layer().enabled, false);
});

test("waits for an existing pane to hide before toggling", async () => {
  const f = fixture();
  let visible = true;
  f.api.keymap.commands = () => [
    { id: "terminal.toggle" }, { id: "terminal.close", enabled: visible },
  ];
  f.api.keymap.dispatch = (id) => {
    f.calls.push(["dispatch", id]);
    if (id === "terminal.close") setTimeout(() => { visible = false; }, 20);
    if (id === "terminal.toggle") assert.equal(visible, false);
  };
  await f.open();
  assert.deepEqual(f.calls.at(-1), ["dispatch", "terminal.toggle"]);
});

test("allows configuring the binding through plugin options", () => {
  const f = fixture();
  f.api.options = { bind: "<leader>o" };
  assert.equal(f.layer().commands[0].bind, "<leader>o");
});

test("starts plain Neovim with no file arguments in the session directory", async () => {
  const f = fixture();
  await f.open();
  assert.deepEqual(f.calls, [
    ["create", {
      sessionID: "ses_test", command: "nvim", args: [],
      cwd: "/project with spaces", title: "Neovim", env: {},
    }],
    ["clear"],
    ["dispatch", "terminal.close"],
    ["dispatch", "terminal.toggle"],
  ]);
});

test("does nothing outside a session", async () => {
  const f = fixture();
  f.setRoute({ type: "home" });
  await f.open();
  assert.deepEqual(f.calls, []);
});

test("ignores duplicate presses during startup", async () => {
  const f = fixture();
  let finish;
  f.api.client.session.get = () => new Promise((resolve) => { finish = resolve; });
  const opening = f.open();
  await f.open();
  finish({ location: { directory: "/project" } });
  await opening;
  assert.equal(f.calls.filter(([type]) => type === "create").length, 1);
});

test("reports startup failures and permits a retry", async () => {
  const f = fixture();
  f.api.client.experimental.persistentPty.create = async () => { throw new Error("nvim not found"); };
  await f.open();
  await f.open();
  assert.equal(f.calls.length, 2);
  assert.equal(f.calls[0][0], "toast");
  assert.equal(f.calls[0][1].message, "nvim not found");
});

test("does not create an orphan editor when terminal support is unavailable", async () => {
  const f = fixture();
  f.api.keymap.commands = () => [];
  await f.open();
  assert.equal(f.calls.length, 1);
  assert.equal(f.calls[0][0], "toast");
});

test("does not fall back to the wrong directory", async () => {
  const f = fixture();
  f.api.client.session.get = async () => ({ location: {} });
  await f.open();
  assert.equal(f.calls.length, 1);
  assert.equal(f.calls[0][0], "toast");
});

test("does not steal focus after switching sessions", async () => {
  const f = fixture();
  f.api.client.experimental.persistentPty.create = async (input) => {
    f.calls.push(["create", input]);
    f.setRoute({ type: "session", sessionID: "ses_other" });
  };
  await f.open();
  assert.equal(f.calls.length, 1);
  assert.equal(f.calls[0][0], "create");
});

test("stops pending startup after plugin disposal", async () => {
  const f = fixture();
  f.api.client.session.get = async () => {
    f.dispose();
    return { location: { directory: "/project" } };
  };
  await f.open();
  assert.deepEqual(f.calls, []);
});
