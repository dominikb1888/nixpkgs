# Claude Code configuration with hybrid settings and 1MCP aggregator.
#
# This module:
# - Adds shell alias with --mcp-config flag (Homebrew installs the binary)
# - Runs 1MCP LaunchAgent to aggregate all MCP servers
# - Symlinks config directories from configs/claude/ for live editing
#
# Settings architecture:
# - managed-settings.json (Nix-generated at /Library/Application Support/ClaudeCode/):
#   Path-dependent settings needing nixConfigDirectory. See darwin/claude-managed-settings.nix.
# - settings.json (symlinked from configs/claude/): All other settings. Edit without rebuild.
#
# MCP architecture:
# - Server definitions: configs/claude/1mcp.json (symlinked to ~/.config/1mcp/mcp.json)
# - 1MCP runs as a LaunchAgent; both CLI and Desktop connect to localhost:3050
# - Secrets: 1Password Environment at ~/.claude/secrets.env
{
  config,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  inherit (config.home.user-info) nixConfigDirectory;
  claudeDir = "${nixConfigDirectory}/configs/claude";

  # Path where the MCP config will be generated
  mcpConfigPath = "${config.home.homeDirectory}/.claude/mcp.json";

  # 1MCP server port (default 3050 to avoid conflicts with common dev servers)
  mcpPort = "3050";

  # GUI apps don't inherit shell PATH, so we build it from nix-darwin config
  # Expand $HOME and $USER since JSON doesn't support shell variables
  desktopPath =
    builtins.replaceStrings [ "$HOME" "$USER" ] [ config.home.homeDirectory config.home.username ]
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

  # CLI MCP config - connects to 1MCP via SSE
  cliMcpConfig.mcpServers."1mcp" = {
    type = "sse";
    url = "http://localhost:${mcpPort}/sse";
  };

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
    preferences = {
      chromeExtensionEnabled = true;
      quickEntryDictationShortcut = "capslock";
    };
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

in
{
  # Shell alias adds --mcp-config flag (Homebrew installs the binary via cask)
  home.shellAliases.claude = "claude --mcp-config ${mcpConfigPath}";

  # 1MCP server config (symlinked for live editing)
  xdg.configFile."1mcp/mcp.json".source = mkOutOfStoreSymlink "${claudeDir}/1mcp.json";

  home.file = {
    # Generated configs (point CLI/Desktop to 1MCP)
    ".claude/mcp.json".source = toFormattedJSON cliMcpConfig;
    "Library/Application Support/Claude/claude_desktop_config.json".source =
      toFormattedJSON desktopConfig;

    # Symlinked for live editing (no rebuild needed)
    ".claude/settings.json".source = mkOutOfStoreSymlink "${claudeDir}/settings.json";
    ".claude/CLAUDE.md".source = mkOutOfStoreSymlink "${claudeDir}/CLAUDE.md";
    ".claude/commands".source = mkOutOfStoreSymlink "${claudeDir}/commands";
    ".claude/skills".source = mkOutOfStoreSymlink "${claudeDir}/skills";
    ".claude/agents".source = mkOutOfStoreSymlink "${claudeDir}/agents";
    ".claude/rules".source = mkOutOfStoreSymlink "${claudeDir}/rules";
    ".claude/hooks".source = mkOutOfStoreSymlink "${claudeDir}/hooks";
    ".claude/statusline.sh".source = mkOutOfStoreSymlink "${claudeDir}/statusline.sh";
  };

  # 1MCP LaunchAgent - keeps the aggregator running when secrets are available
  # Uses PathState to only run when 1Password has mounted the secrets file
  launchd.agents."1mcp" = {
    enable = true;
    config = {
      Label = "com.malo.1mcp";
      ProgramArguments = [ "${start1mcp}" ];
      KeepAlive = {
        PathState = {
          "${config.home.homeDirectory}/.claude/secrets.env" = true;
        };
      };
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/1mcp.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/1mcp.error.log";
      EnvironmentVariables = {
        PATH = desktopPath;
      };
    };
  };
}
