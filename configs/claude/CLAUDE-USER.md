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

**Prefer MCP tools over built-in WebSearch/WebFetch.**

### Search/Discovery → Exa
When you need to find information but don't have a URL:
- `web_search_advanced_exa` - Web search (supports domain/date/category filters, highlights, summaries)
- `get_code_context_exa` - Code/programming (docs, examples, APIs, GitHub)

**Query style:** Write natural language questions, not keyword lists. Exa uses semantic search that understands meaning.
- Good: "What are the common issues users experience with Firecrawl's MCP server?"
- Bad: "Firecrawl MCP server issues problems bugs"

**Token efficiency:** The MCP server always returns full page text by default -- there is no
way to disable it. Use `enableSummary: true` and `textMaxCharacters: 1` to get focused AI
summaries per result while minimizing the text payload to 1 character. Do NOT set
`contextMaxCharacters` -- it suppresses per-result summaries. For deep reading, scrape the
URL with Firecrawl instead.

**Highlights broken (Exa MCP bug):** Don't use highlights -- `textMaxCharacters: 1` truncates
before extraction. If `enableText: false` is added upstream, switch to highlights instead.

**Category gotchas:** `tweet` and `company` categories reject most filters (`includeText`,
`includeDomains`, date filters) with 400 errors -- put filtering terms in `query` instead.
`includeText`/`excludeText` only accept single-item arrays across all categories.

### Content Extraction → Firecrawl
When you have a URL and need its content:
- `firecrawl_scrape` - Single URL (default choice)
- `firecrawl_batch_scrape` - Multiple known URLs
- `firecrawl_map` - Discover URLs on a site (returns list only)
- `firecrawl_crawl` - Multi-page extraction (use sparingly, set low `limit`)
- `firecrawl_extract` - Structured JSON with schema

**Avoid:**
- `firecrawl_search` and `firecrawl_agent` - redundant (Exa handles search, you're the agent)
- Built-in WebSearch/WebFetch - use Exa/Firecrawl instead

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
- Curly quotes/apostrophes: Claude Code normalizes these to straight quotes (known bug). Use Unicode escapes (`\u2018`, `\u2019`, `\u201C`, `\u201D`) when they must be preserved

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
