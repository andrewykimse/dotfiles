{ ... }:
{
  # Determinate Nix already manages the daemon and /etc/nix/nix.conf;
  # letting nix-darwin manage Nix too would fight it for the same files.
  nix.enable = false;

  system.primaryUser = "andrewkim";
  system.stateVersion = 7;

  # nix-darwin doesn't manage macOS user accounts; this just records the
  # existing account so home-manager can read its home directory.
  users.users.andrewkim = {
    name = "andrewkim";
    home = "/Users/andrewkim";
  };

  # Preserve the existing manually-configured Touch ID sudo auth.
  security.pam.services.sudo_local.touchIdAuth = true;
}
