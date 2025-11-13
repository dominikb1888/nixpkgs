{ config, pkgs, ... }:

{
  # Git
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.git.enable
  # Aliases config in ./configs/git-aliases.nix
  programs.git.enable = true;

  programs.git.settings = {
    diff.colorMoved = "default";
    pull.rebase = true;
    push.autoSetupRemote = true;
    init.defaultBranch = "main";
  };

  programs.git.ignores = [
    ".DS_Store"
    ".env"
    ".nvim"
    ".nvim/*"
  ];

  programs.git.settings.user.email = config.home.user-info.email;
  programs.git.settings.user.name = config.home.user-info.fullName;

  # Enhanced diffs
  programs.delta.enable = true;
  programs.delta.enableGitIntegration = true;

  # GitHub CLI
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.gh.enable
  # Aliases config in ./gh-aliases.nix
  programs.gh = {
    enable = true;
    settings = {
      # Workaround for https://github.com/nix-community/home-manager/issues/4744
      # version = 1;
    };
  };

  programs.gh.settings.git_protocol = "ssh";
}
