import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { handleSelectorNavigation } from "./selector-navigation.mjs";

function fixture(ids = ["dialog.select.submit"]) {
  const calls = [];
  return {
    calls,
    context: {
      keymap: {
        commands: () => ids.map((id) => ({ id })),
        dispatch: (id) => calls.push(id),
      },
      ui: { dialog: { clear: () => calls.push("back") } },
    },
    event: {
      preventDefault: () => calls.push("prevent"),
      stopPropagation: () => calls.push("stop"),
    },
  };
}

test("l confirms the selected option", () => {
  const { calls, context, event } = fixture();
  assert.equal(handleSelectorNavigation(context, event, "l"), true);
  assert.deepEqual(calls, ["prevent", "stop", "dialog.select.submit"]);
});

test("h dismisses the selector without confirming", () => {
  const { calls, context, event } = fixture();
  assert.equal(handleSelectorNavigation(context, event, "h"), true);
  assert.deepEqual(calls, ["prevent", "stop", "back"]);
});

test("prompt and text-only dialogs keep h/l editing", () => {
  for (const id of ["prompt.submit", "dialog.prompt.submit"]) {
    const { calls, context, event } = fixture([id]);
    for (const key of ["h", "l"]) {
      assert.equal(handleSelectorNavigation(context, event, key), false);
    }
    assert.deepEqual(calls, []);
  }
});

test("other selector keys are untouched", () => {
  const { calls, context, event } = fixture();
  for (const key of ["j", "k", "g", "G", "<Esc>", "i"]) {
    assert.equal(handleSelectorNavigation(context, event, key), false);
  }
  assert.deepEqual(calls, []);
});

// Exercise the actual patched upstream branch, including its mode/context
// guards, without starting a terminal or loading a second OpenTUI renderer.
const bundlePath = process.env.OPENCODE_VIM_BUNDLE;
test("selectors open in normal mode regardless of the prompt mode", {
  skip: !bundlePath,
}, () => {
  const source = readFileSync(bundlePath, "utf8");
  const start = source.indexOf('    if (kind === "dialog" && dialogInput !== input)');
  const end = source.indexOf('    const mode = state.mode();', start);
  assert.ok(start >= 0 && end > start);
  const initialize = new Function("kind", "dialogInput", "input", "dialogVimee", "dialogState", "promptVim", "props", source.slice(start, end));

  for (const promptMode of ["normal", "insert", "visual", "visual-line"]) {
    for (const selector of [false, true]) {
      const input = {};
      const { context } = fixture([selector ? "dialog.select.submit" : "dialog.prompt.submit"]);
      for (const kind of ["dialog", "prompt"]) {
        for (const previousInput of [null, input, {}]) {
          const calls = [];
          initialize(kind, previousInput, input,
            { suspend: () => calls.push("suspend") },
            { setMode: (mode) => calls.push(mode) },
            { state: { mode: () => promptMode } }, { context });
          const changedDialog = kind === "dialog" && previousInput !== input;
          assert.deepEqual(calls, changedDialog ? ["suspend", selector ? "normal" : promptMode] : []);
        }
      }
    }
  }
});

test("upstream gate limits navigation to idle normal-mode selectors", {
  skip: !bundlePath,
}, () => {
  const source = readFileSync(bundlePath, "utf8");
  const start = source.indexOf('    if (kind === "dialog" && !vimee.isPending()');
  const end = source.indexOf('    if (kind === "prompt"', start);
  assert.ok(start >= 0 && end > start);
  const branch = new Function("kind", "vimee", "mapped", "state", "key", "props", "event", "handleSelectorNavigation", source.slice(start, end));

  for (const kind of ["dialog", "prompt"]) {
    for (const mode of ["normal", "insert", "visual", "visual-line"]) {
      for (const pending of [false, true]) {
        for (const mapped of [false, true]) {
          for (const key of ["h", "l"]) {
            const { calls, context, event } = fixture();
            branch(kind, { isPending: () => pending }, mapped, { mode: () => mode }, key, { context }, event, handleSelectorNavigation);
            const shouldHandle = kind === "dialog" && mode === "normal" && !pending && !mapped;
            assert.deepEqual(calls, shouldHandle ? ["prevent", "stop", key === "h" ? "back" : "dialog.select.submit"] : []);
          }
        }
      }
    }
  }
});
