{ ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = "andrewkim";
      user.email = "andrewykimse@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  programs.gh = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
  };
}
