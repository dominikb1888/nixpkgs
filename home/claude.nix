# Claude Code configuration with hybrid settings and 1MCP aggregator.
#
# This module:
# - Adds shell alias with --mcp-config flag (Homebrew installs the binary)
# - Runs 1MCP LaunchAgent to aggregate all MCP servers (macOS only)
# - Symlinks config directories from configs/claude/ for live editing
#
# Settings architecture:
# - managed-settings.json (Nix-generated at /Library/Application Support/ClaudeCode/):
#   Path-dependent settings needing nixConfigDirectory. See darwin/claude-managed-settings.nix.
# - settings.json (symlinked from configs/claude/): All other settings. Edit without rebuild.
#
# MCP architecture:
# - Server definitions: configs/claude/1mcp.json (symlinked to ~/.config/1mcp/mcp.json)
# - 1MCP runs as a LaunchAgent (macOS); both CLI and Desktop connect to localhost:3050
# - Secrets: 1Password Environment at ~/.claude/secrets.env
{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  inherit (config.home) homeDirectory;
  inherit (config.home.user-info) nixConfigDirectory;
  inherit (pkgs.stdenv) isDarwin;

  claudeDir = "${nixConfigDirectory}/configs/claude";

  # Configuration ----------------------------------------------------------------------------------
  # Edit these values to customize your setup. Everything below is implementation.

  # External skills from skills.sh, installed via activation script.
  # Add entries here, then `nh darwin switch` to reconcile.
  # Format: "owner/repo --skill skill-name"
  externalSkills = [
    "anthropics/skills --skill pdf"
  ];

  # 1MCP server port (default 3050 to avoid conflicts with common dev servers)
  mcpPort = "3050";

  # Claude Desktop app preferences (macOS only)
  desktopPreferences = {
    chromeExtensionEnabled = true;
    quickEntryDictationShortcut = "capslock";
  };

  # Implementation ---------------------------------------------------------------------------------

  mcpConfigPath = "${homeDirectory}/.claude/mcp.json";

  # CLI MCP config - connects to 1MCP via SSE
  cliMcpConfig.mcpServers."1mcp" = {
    type = "sse";
    url = "http://localhost:${mcpPort}/sse";
  };

  # Helper for human-readable JSON files
  toFormattedJSON =
    data:
    pkgs.runCommand "formatted.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
        passAsFile = [ "json" ];
        json = builtins.toJSON data;
      }
      ''
        jq . "$jsonPath" > $out
      '';

  # --- macOS-only (guarded by mkIf isDarwin; lazy evaluation prevents errors on Linux) ---

  # GUI apps don't inherit shell PATH, so we build it from nix-darwin config
  desktopPath =
    builtins.replaceStrings [ "$HOME" "$USER" ] [ homeDirectory config.home.username ]
      osConfig.environment.systemPath;

  # 1MCP launcher script - sources secrets and starts the aggregator
  start1mcp = pkgs.writeShellScript "start-1mcp" ''
    set -euo pipefail

    SECRETS_FILE="$HOME/.claude/secrets.env"

    # Source secrets from 1Password Environment (may be a named pipe from 1Password)
    if [[ -r "$SECRETS_FILE" ]]; then
      set -a
      # shellcheck source=/dev/null
      source "$SECRETS_FILE"
      set +a
    else
      echo "Warning: $SECRETS_FILE not found. MCP servers requiring secrets may fail." >&2
    fi

    # Add Nix paths for GUI app compatibility
    export PATH="$PATH:/run/current-system/sw/bin:$HOME/.nix-profile/bin"

    # Start 1MCP aggregator (uses default config at ~/.config/1mcp/mcp.json)
    exec npx -y @1mcp/agent --port ${mcpPort} --enable-async-loading
  '';

  # Desktop MCP config - uses proxy to connect to the running 1MCP LaunchAgent
  desktopConfig = {
    mcpServers."1mcp" = {
      command = "npx";
      args = [
        "-y"
        "@1mcp/agent"
        "proxy"
        "--url"
        "http://localhost:${mcpPort}/mcp"
      ];
      env.PATH = desktopPath;
    };
    preferences = desktopPreferences;
  };

in
lib.mkMerge [

  # Cross-platform configuration -------------------------------------------------------------------

  {
    # Shell alias adds --mcp-config flag (Homebrew installs the binary via cask)
    home.shellAliases.claude = "claude --mcp-config ${mcpConfigPath}";

    # 1MCP server config (symlinked for live editing)
    xdg.configFile."1mcp/mcp.json".source = mkOutOfStoreSymlink "${claudeDir}/1mcp.json";

    home.file = {
      # Generated CLI config (points to 1MCP)
      ".claude/mcp.json".source = toFormattedJSON cliMcpConfig;

      # Symlinked for live editing (no rebuild needed)
      ".claude/settings.json".source = mkOutOfStoreSymlink "${claudeDir}/settings.json";
      ".claude/CLAUDE.md".source = mkOutOfStoreSymlink "${claudeDir}/CLAUDE-USER.md";
      ".claude/commands".source = mkOutOfStoreSymlink "${claudeDir}/commands";
      ".claude/skills".source = mkOutOfStoreSymlink "${claudeDir}/skills";
      ".claude/agents".source = mkOutOfStoreSymlink "${claudeDir}/agents";
      ".claude/rules".source = mkOutOfStoreSymlink "${claudeDir}/rules";
      ".claude/hooks".source = mkOutOfStoreSymlink "${claudeDir}/hooks";
      ".claude/statusline.sh".source = mkOutOfStoreSymlink "${claudeDir}/statusline.sh";
    };

    # External skills ------------------------------------------------------------------------------

    # Nuke and repave on each activation. Uses direct file removal instead of `skills remove`
    # (which has interactive TUI prompts that hang under home-manager's non-interactive activation).
    home.activation.installClaudeSkills =
      let
        npx = "${pkgs.nodejs}/bin/npx";
        skillsDir = "${homeDirectory}/.claude/skills";
        agentsDir = "${homeDirectory}/.agents/skills";
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        export PATH="${pkgs.nodejs}/bin:${pkgs.git}/bin:$PATH"
        export DISABLE_TELEMETRY=1
        echo "Reconciling Claude Code skills from skills.sh..."
        # Remove external skill symlinks (pointing into ~/.agents/) and their cloned sources
        ${pkgs.findutils}/bin/find "${skillsDir}" -maxdepth 1 -type l -lname '*/\.agents/*' -delete 2>/dev/null || true
        rm -rf "${agentsDir}" 2>/dev/null || true
        ${lib.concatMapStringsSep "\n        " (
          s: "run --silence ${npx} -y skills add ${s} -g -a claude-code -y || true"
        ) externalSkills}
      '';
  }

  # macOS-only configuration -----------------------------------------------------------------------

  (lib.mkIf isDarwin {
    # Desktop app config (points to 1MCP via proxy for GUI PATH compatibility)
    home.file."Library/Application Support/Claude/claude_desktop_config.json".source =
      toFormattedJSON desktopConfig;

    # 1MCP LaunchAgent - keeps the aggregator running when secrets are available
    # Uses PathState to only run when 1Password has mounted the secrets file
    launchd.agents."1mcp" = {
      enable = true;
      config = {
        Label = "com.malo.1mcp";
        ProgramArguments = [ "${start1mcp}" ];
        KeepAlive = {
          PathState = {
            "${homeDirectory}/.claude/secrets.env" = true;
          };
        };
        StandardOutPath = "${homeDirectory}/Library/Logs/1mcp.log";
        StandardErrorPath = "${homeDirectory}/Library/Logs/1mcp.error.log";
        EnvironmentVariables = {
          PATH = desktopPath;
        };
      };
    };
  })
]
