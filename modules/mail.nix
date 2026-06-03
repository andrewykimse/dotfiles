{ pkgs, lib, config, ... }:
let
  accountsConf = pkgs.writeText "aerc-accounts.conf" ''
    [Gmail]
    source = imaps://andrewykim528%40gmail.com@imap.gmail.com:993
    source-cred-cmd = pass show email/gmail
    outgoing = smtps+plain://andrewykim528%40gmail.com@smtp.gmail.com:465
    outgoing-cred-cmd = pass show email/gmail
    from = Andrew Kim <andrewykim528@gmail.com>
    default = INBOX
    copy-to = [Gmail]/Sent Mail
    postpone = [Gmail]/Drafts
  '';
in
{
  home.packages = with pkgs; [ aerc w3m gnupg pass ];

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };

  # aerc requires accounts.conf to be 600 — copy it out of the Nix store
  home.activation.aercAccountsConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/aerc
    $DRY_RUN_CMD install -m 600 ${accountsConf} ${config.home.homeDirectory}/.config/aerc/accounts.conf
  '';

  xdg.configFile."aerc/aerc.conf".text = ''
    [general]
    default-save-path = ~/Downloads

    [compose]
    editor = nvim

    [ui]
    timestamp-format = 2006-01-02 15:04
    this-day-time-format = 15:04
    sidebar-width = 30

    [viewer]
    alternatives = text/plain,text/html
    header-layout = From,To|Cc,Date,Subject

    [filters]
    text/html = ${pkgs.w3m}/bin/w3m -T text/html -o display_link_number=1
    text/plain = colorize
  '';
}
