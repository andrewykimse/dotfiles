// Called only by the upstream Vim handler's idle, unmapped, normal-mode
// dialog branch. Never intercept prompt editing, insert mode, or questions.
export function handleSelectorNavigation(context, event, key) {
  if (key !== "h" && key !== "l") return false;
  if (!context.keymap.commands().some((command) => command.id === "dialog.select.submit")) {
    return false;
  }

  event.preventDefault();
  event.stopPropagation();
  if (key === "h") {
    context.ui.dialog.clear();
  } else {
    context.keymap.dispatch("dialog.select.submit");
  }
  return true;
}
