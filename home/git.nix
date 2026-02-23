{ config, ... }:

{
  # Git
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.git.enable
  # Aliases config in ./configs/git-aliases.nix
  programs.git.enable = true;

  programs.git.settings = {
    diff.colorMoved = "default";
    pull.rebase = true;
    push.autoSetupRemote = true;
    user.email = config.home.user-info.email;
    user.name = config.home.user-info.fullName;
  };

  programs.git.ignores = [
    "*~"
    ".DS_Store"
  ];

  # Enhanced diffs
  programs.delta.enable = true;
  programs.delta.enableGitIntegration = true;

  # Lazygit
  # https://github.com/jesseduffield/lazygit
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.lazygit.enable
  programs.lazygit.enable = true;
  programs.lazygit.settings = {
    git.pagers = [
      { pager = "delta --paging=never"; }
    ];
  };

  # GitHub CLI
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.gh.enable
  # Aliases config in ./gh-aliases.nix
  programs.gh.enable = true;
  programs.gh.settings.version = 1;
  programs.gh.settings.git_protocol = "ssh";
}
