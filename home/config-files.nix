{ config, lib, ... }:

{
  # https://docs.haskellstack.org/en/stable/yaml_configuration/#non-project-specific-config
  home.file.".stack/config.yaml".text = lib.generators.toYAML {} {
    templates = {
      scm-init = "git";
      params = {
        author-name = config.programs.git.settings.user.name;
        author-email = config.programs.git.settings.user.email;
        github-username = "dominikb1888";
      };
    };
    nix.enable = true;
  };

  # Stop `parallel` from displaying citation warning
  home.file.".parallel/will-cite".text = "";

  # Creates empty dotfile to remove terminal Last Login message
  home.file.".hushlogin".text = "";

}
