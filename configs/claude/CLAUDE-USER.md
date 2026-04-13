# Malo's Global Claude Context

## Personal Context
Biographical info (job, preferences, interests) is auto-loaded from `~/.claude/rules/bio.md`.

For private details (phone, address, contact info), read `~/.claude/PRIVATE.md` when needed for tasks like filling forms or making reservations.

## Environment
- macOS with nix-darwin and Home Manager
- Nix config at `~/.config/nix-config`
- Claude Code config managed via Nix: `home/claude.nix` (settings, MCP servers) and `configs/claude/` (CLAUDE.md, rules, skills, agents, hooks, plugins)
- Fish shell with Starship prompt
- 1Password for secrets management

## Tools
- Ghostty terminal
- GitHub CLI (`gh`) for PRs and issues
- Ad-hoc commands: `nix run my#<pkg>` runs any nixpkgs package without installing;
  `nix develop my#<pkg> -c <cmd>` to access other binaries the package provides
- Opening URLs: use `open "URL"` in Bash (opens in Safari), not Chrome browser automation tools

## Nix Dev Shells

Tool environments available without installing globally. Use `nix develop my#<name>` to enter
a shell, or wrap a single command with `nix develop my#<name> -c <cmd>`.

- **`docx`** -- Python (defusedxml, lxml) + Node.js (docx via NODE_PATH) + pandoc + soffice
  (LibreOffice from Homebrew). Use for all Word document tasks.
- **`pdf`** -- Python (pypdf, pdfplumber, reportlab, pytesseract, pdf2image, Pillow, pandas)
  + CLI (poppler_utils, qpdf, tesseract, ghostscript). Use for all PDF tasks.

For multi-step work, enter the shell once rather than wrapping each command.

## Web Tools

**Use Exa and Firecrawl, not built-in WebSearch/WebFetch** (which are blocked by hook).
Load `/search-tips` for detailed guidance on query patterns, tool selection, and gotchas.

## Languages
- Primary: Nix, Haskell, TypeScript/JavaScript, Python
- Modern tooling: pnpm, uv, Stack

## Git Workflow
- Rebase-based (pull.rebase = true)
- SSH protocol for GitHub
- Commit messages: imperative mood, concise
- Tags are GPG-signed: always use `git tag -a <name> -m "message"` (lightweight tags fail)
- Only use `git -C <path>` when CWD is outside the target repo; git finds the repo root from any subdirectory

## Code Style
- Functional programming: strong types, immutability, composition
- These are strong preferences, not dogma—simplicity wins when trade-offs arise
- Nix: follow nixpkgs conventions
- Small, focused functions
- Avoid over-engineering
- Markdown tables: align columns with spaces so they render correctly in the user's editor. For items with long descriptions, use blockquotes or lists instead—tables with very long rows are hard to read
- Non-ASCII characters in files: write the actual character (ã, í, —, é, ñ). NEVER use `\uXXXX` escapes in markdown, plain text, or YAML — they write as six literal ASCII characters (e.g., `S\u00e3o Paulo`), not the intended character. `\u` escapes only work in contexts that parse them (JSON/Python/JS string literals)
- Curly quotes/apostrophes: Claude Code has a known bug normalizing `'` `'` `"` `"` to straight quotes in tool-call arguments. There is no `\u` escape workaround for plain text files. When curly quotes must be preserved, write the file via `python3 -c` or a Bash heredoc containing the actual character, or use HTML entities (`&rsquo;`, `&ldquo;`, etc.) if the output will be rendered as HTML/markdown

## Working Style

**ToolSearch before MCP tools:** Before using an MCP tool for the first time in a session, look it up with ToolSearch to see the correct parameter schema. Avoids wasted calls from guessing parameter formats.

**Use available tools:** When specialized agents or skills exist for a task (e.g., `plugin-dev:skill-development` for writing skills, `claude-code-guide` for Claude Code questions), use them rather than doing things from scratch.

**Project-local config first:** When looking for project-specific configuration (hooks, agents, skills, settings), check the project-local `.claude/` directory before `~/.claude/` (global).

**Give opinions:** When asked for a recommendation or what I think, provide a real answer with reasoning—don't just list options and ask which one.

**Clipboard handoff:** When we've finalized content you'll use elsewhere (drafts, URLs, code snippets, etc.), copy it to your clipboard with `pbcopy` so you can paste directly rather than selecting from terminal output.

**Todo lists for lists:** When working through a list of items (tasks, emails, files to review, etc.), always create a todo list to track progress. Don't wait to be asked—if there's a list, make a todo list.

**Batch questions:** When you have multiple questions to ask, use the AskUserQuestion tool rather than asking inline.

## Evolving Configuration
Proactively suggest improvements to Claude Code configuration based on our conversations:
- Preferences or patterns → CLAUDE.md (global or project-level)
- Repeated permission friction → settings.json allow rules
- Workflow automations → hooks, skills, agents, etc.
- Project-specific settings → project settings.json
- Tool integrations → MCP servers
- Anything else that would reduce friction or improve our collaboration

Propose changes rather than making them silently.
