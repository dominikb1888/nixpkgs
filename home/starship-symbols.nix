{
  # Use nerd font symbols preset as base
  programs.starship.extras.presets.nerd_font_symbols = true;

  programs.starship.settings = {
    # Git status symbols (not in preset)
    git_status.format = "([$all_status$ahead_behind]($style) )";
    git_status.ahead = " ";
    git_status.behind = " ";
    git_status.diverged = "󰹹 ";
    git_status.conflicted = "󰅰 ";
    git_status.untracked = " ";
    git_status.modified = " ";
    git_status.staged = " ";
    git_status.renamed = " ";
    git_status.deleted = " ";
    git_status.stashed = " ";
  };
}
