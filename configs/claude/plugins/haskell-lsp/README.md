# Haskell LSP Plugin

Language server integration for Haskell files using [HLS](https://github.com/haskell/haskell-language-server) (Haskell Language Server).

## Requirements

- `haskell-language-server-wrapper` must be available in PATH (via global install, nix profile, or direnv)
- A `hie.yaml` in the project root (for multi-component projects using Stack or Cabal)

## Features

Provides Claude Code with LSP capabilities for `.hs` files:

- Type information on hover
- Go to definition
- Find references
- Diagnostics (type errors, warnings, HLint suggestions)
- Code completions

## Configuration

The plugin uses `.lsp.json` to configure the language server:

```json
{
  "haskell": {
    "command": "haskell-language-server-wrapper",
    "args": ["--lsp"],
    "extensionToLanguage": {
      ".hs": "haskell"
    }
  }
}
```

HLS automatically detects the project's build tool (Stack, Cabal) and GHC version from the project configuration.

## Usage

Once enabled, LSP features work automatically when editing Haskell files. Claude can use the LSP tool to query types, navigate definitions, find references, and see diagnostics.
