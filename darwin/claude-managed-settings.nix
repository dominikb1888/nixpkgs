# Claude Code managed settings for system-wide configuration.
#
# This module creates managed-settings.json at /Library/Application Support/ClaudeCode/
# which has the highest precedence in Claude Code's settings hierarchy.
#
# Only path-dependent settings that need nixConfigDirectory interpolation belong here.
# All other settings go in the user-editable ~/.claude/settings.json (symlinked from configs/claude/).
{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config.users.primaryUser) nixConfigDirectory;

  claudeDir = "${nixConfigDirectory}/configs/claude";

  # Settings that require machine-specific path interpolation
  managedSettings = {
    additionalDirectories = [ nixConfigDirectory ];
    permissions.allow = [
      "Edit(${nixConfigDirectory}/**)"
      "Write(${nixConfigDirectory}/**)"
    ];
    extraKnownMarketplaces.malos-plugins.source = {
      source = "directory";
      path = "${claudeDir}/plugins";
    };
  };

  managedSettingsFile = pkgs.writeText "claude-managed-settings.json" (
    builtins.toJSON managedSettings
  );
in
{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "setting up Claude Code managed settings..."
    mkdir -p "/Library/Application Support/ClaudeCode"
    ln -sf "${managedSettingsFile}" "/Library/Application Support/ClaudeCode/managed-settings.json"
  '';
}
