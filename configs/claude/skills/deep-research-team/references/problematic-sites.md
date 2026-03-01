# Problematic Sites Reference

Detailed workarounds for sites that fail with default Firecrawl scraping. The quick-reference
table in `researcher-prompt.md` covers the summary; this file has the full details.

Last verified: 2026-02-28.

## General Troubleshooting

Before consulting per-site workarounds, try these in order:

1. **Retry with `onlyMainContent: false`** -- Firecrawl's main-content detection is aggressive
   and strips article bodies on many sites (Future plc, Blogspot, GDPR-consent-heavy sites).
   This fixes most "returns only nav/sidebar" failures.
2. **Try `waitFor: 5000`** -- helps with JS-rendered SPAs (though less often than expected).
3. **Check for an API** -- many sites have JSON APIs that return cleaner data than scraping.
4. **Wayback Machine** -- `https://web.archive.org/web/{URL}` for archived/paywalled content.
5. **Exa summaries as last resort** -- when scraping fails entirely, Exa summaries provide
   at least a triage-quality summary of the page content.

## Firecrawl Policy-Blocked Sites

These sites are on Firecrawl's infrastructure blocklist. All proxy tiers fail with "we do not
support this site." No scraping workaround exists.

### Tom's Guide, ZDNET (Ziff Davis / Future plc network)

- **Failure:** Hard block before any HTTP request is made.
- **Workaround:** Exa summaries for triage. For deep content, check Wayback Machine. No
  Firecrawl approach works (plain, stealth, enhanced all fail identically).

### reddit.com (all subdomains)

- **Failure:** Firecrawl blocks all reddit.com domains including `old.reddit.com` and the
  Reddit JSON API (`/top.json`, etc.).
- **Workaround:** Two-step approach:
  1. **Discovery:** `firecrawl_search` with `site:reddit.com {query}` (uses Google's Reddit
     index, which is far better than Reddit's native search).
  2. **Content:** Reddit MCP tools (`get_post_comments`, `get_top_posts`, `get_reddit_post`).
- **Important:** Do NOT batch Reddit MCP calls with Exa/Firecrawl calls -- if one fails, it
  can cascade and kill sibling calls. Isolate Reddit MCP calls.

## `onlyMainContent` False Positives

These sites return HTTP 200 but Firecrawl's content detection strips the article body. Fix
by retrying with `onlyMainContent: false`.

### Future plc sites (Pocket-lint, iMore, TechRadar, PC Gamer, etc.)

- **Failure with `onlyMainContent: true`:** Returns 70-500 chars of skip-links, video player
  embeds, or "Submit a Thread" modals. Article body is stripped entirely.
- **With `onlyMainContent: false`:** Full article content returned (may be large, 60KB+).
- **Note:** Tom's Guide and ZDNET are also Future plc but are policy-blocked (see above).

### Blogspot / Google Blogger blogs

- **Failure with `onlyMainContent: true`:** Returns only the sidebar "Useful Links" section.
  Blog post feed is stripped as non-main content.
- **With `onlyMainContent: false`:** Full blog feed with titles, dates, summaries, and links.
- **Affected sites:** Google Workspace Updates blog, and other `*.blogspot.com` / Blogger sites.

### StorageReview

- **Failure with `onlyMainContent: true`:** Returns GDPR consent wall HTML (cookie consent
  modal rendered inline). Article content behind the overlay is stripped.
- **With `onlyMainContent: false`:** Full review with benchmark tables, specs, and images.

## Paywalled Sites

### Medium

- **Workaround:** `https://freedium-mirror.cfd/{FULL_MEDIUM_URL}` via Firecrawl scrape.
  Returns full article content including images.
- **Note:** The original `freedium.cfd` is dead (DNS failure). The mirror may have intermittent
  uptime. No proxy needed (1 credit).

### Consumer Reports

- **Free tier:** Category overview pages are accessible (`pagePayState: free` in metadata).
  Product names, images, and recent news articles are visible.
- **Paywalled:** Ratings pages load the full page structure but silently replace score numbers
  with "log in or sign up" prompts. No HTTP error, no redirect -- the paywall is invisible
  from a scraping perspective.
- **Workaround:** Note the gap. For product recommendations, use RTINGS (fully open),
  HouseFresh, or AirPurifierFirst as alternatives.

## Restricted Social / Content Platforms

### Twitter / X

- **x.com:** Behind auth walls, cannot be scraped.
- **Exa `category: "tweet"`:** Works for discovery (primary method).
- **xcancel.com / nitter mirrors:** Individual tweet URLs (`/status/{id}`) work in browsers
  but return 404 via Firecrawl headless scraping (the mirror detects and blocks non-browser
  clients). Stealth proxy does not help. **Profile/timeline pages work:**
  `https://xcancel.com/{username}` returns recent tweets and profile info (no proxy, 1 credit).
- **Bottom line:** You can discover tweets via Exa and browse user timelines via xcancel, but
  cannot access specific individual tweets by URL.

### LinkedIn

- Exa with `category: "people"` for public professional profiles.
- Direct LinkedIn page scraping is unreliable -- treat as effectively inaccessible.

## Sites That Actually Work (Previously Reported as Problematic)

These were reported as problematic in researcher feedback but work fine as of 2026-02-28:

| Site               | Status  | Notes                                                |
| ------------------ | ------- | ---------------------------------------------------- |
| npm package pages  | Works   | SSR'd, plain scrape gets full README + metadata      |
| APC/Schneider      | Works   | Redirects to se.com transparently; specs all present  |
| llm-stats.com      | Works   | Next.js SSR renders full leaderboard                 |
| RTINGS             | Works   | Fully open, no paywall; "Insider" only gates voting  |
| rfc-editor.org     | Works   | Returns full RFC (may be very large for long RFCs)   |

## API Workarounds

When scraping fails, these API endpoints return clean structured data:

| Use Case            | API Endpoint                                               | Notes                    |
| ------------------- | ---------------------------------------------------------- | ------------------------ |
| npm download stats  | `api.npmjs.org/downloads/point/last-week/{pkg}`            | 90 chars, clean JSON     |
| Discourse search    | `https://{domain}/search.json?q={query}`                   | Returns topic IDs        |
| Discourse topic     | Append `.json` to any topic URL                            | Full post content        |
| GitHub file content | `raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}` | Clean, no UI noise       |
| GitHub repo stats   | `gh api repos/{owner}/{repo}`                              | Stars, forks, last push  |
| arxiv full paper    | `arxiv.org/html/{paper-id}` (not `/abs/`)                  | Large for long papers    |
| arxiv metadata      | `export.arxiv.org/api/query?id_list={id}`                  | Structured XML           |
