{
  # Starship Prompt
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.starship.enable
  programs.starship.enable = true;

  programs.starship.settings = {
    # See docs here: https://starship.rs/config/
    # Symbols config configured ./starship-symbols.nix.
    add_newline = false;
    directory.fish_style_pwd_dir_length = 1; # turn on fish directory truncation
    directory.truncation_length = 2; # number of directories not to truncate
    gcloud.disabled = true; # annoying to always have on
    hostname.style = "bold green"; # don't like the default
    line_break.disabled = true;
    character.success_symbol = " [❯](bold #a9b1d6)[❯](bold #9ece6a)[❯](bold #a9b1d6)";     # The "success_symbol" segment is being set to "➜" with the color "bold green"
    character.error_symbol = " [❯](bold #a9b1d6)[❯](bold #f7768e)[❯](bold #a9b1d6)";
    character.vicmd_symbol = " [V](bold #7dcfff) ";

    cmd_duration.min_time = 500;
    cmd_duration.format = "[$duration](bold #c0caf5)";
    memory_usage.disabled = true; # because it includes cached memory it's reported as full a lot
    username.style_user = "bold blue"; # don't like the default
  };
}
