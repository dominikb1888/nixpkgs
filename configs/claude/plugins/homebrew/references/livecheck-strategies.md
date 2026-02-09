# Livecheck Strategies Reference

Detailed patterns for configuring `livecheck` blocks in Homebrew casks. Referenced from the main new-cask skill when configuring version checking.

## Choosing a Strategy

Use this decision tree to select the appropriate strategy:

1. **Does the app use Sparkle for auto-updates?** (Check for Sparkle framework or `SUFeedURL` in Info.plist)
   → Use `:sparkle`

2. **Is the download from GitHub releases?**
   → Try `:git` first (lower API overhead), then `:github_latest` only if `:git` doesn't work
   → GitHub rate-limits API requests, so prefer `:git` when possible

3. **Does the download URL redirect (e.g., `/latest` endpoint)?**
   → Use `:header_match`

4. **Is there a JSON feed (RELEASES.json, releases.json)?**
   → Use `:json`

5. **Is it an Electron app with `latest-mac.yml`?**
   → Use `:electron_builder`

6. **Can you scrape a download page or changelog?**
   → Use `:page_match`

7. **Nothing else works?**
   → Use `:extract_plist` as **last resort** (downloads artifact, excluded from autobumping)

## Strategy: `:sparkle`

Use for apps that self-update via the Sparkle framework. Find the appcast URL in the app's Info.plist (`SUFeedURL` key). This is the most common strategy for macOS apps.

```ruby
# Basic
livecheck do
  url "https://example.com/appcast.xml"
  strategy :sparkle
end

# Use short_version only
livecheck do
  url "https://example.com/appcast.xml"
  strategy :sparkle, &:short_version
end

# Use version only
livecheck do
  url "https://example.com/appcast.xml"
  strategy :sparkle, &:version
end

# Complex extraction
livecheck do
  url "https://example.com/appcast.xml"
  strategy :sparkle do |item|
    "#{item.short_version},#{item.version}"
  end
end
```

**Finding the appcast URL**:

```bash
# First, try the built-in helper
brew find-appcast "/Applications/Example.app"

# Or check the plist directly
defaults read "/Applications/Example.app/Contents/Info.plist" SUFeedURL
```

**If SUFeedURL isn't in the plist** but Sparkle framework exists, try common appcast locations relative to the download URL:

```bash
# If download is https://example.com/app-prod/App.dmg
# Try common appcast filenames at the same base URL
curl -sI "https://example.com/app-prod/appcast.xml" | head -1
curl -sI "https://example.com/app-prod/updates.xml" | head -1
```

Common appcast filenames: `appcast.xml`, `updates.xml`, `sparkle.xml`, `feed.xml`

Verify the URL returns valid XML before using it in livecheck.

## Strategy: `:github_latest`

Use for GitHub-hosted projects when `:git` strategy doesn't work. Try `:git` first (lower API overhead) - GitHub rate-limits API requests.

```ruby
# Basic - uses stable URL's GitHub repo
livecheck do
  url :stable
  strategy :github_latest
end

# Explicit URL
livecheck do
  url "https://github.com/owner/repo"
  strategy :github_latest
end

# With regex for tag format
livecheck do
  url :stable
  regex(/^v?(\d+(?:\.\d+)+)$/i)
  strategy :github_latest
end

# With block for complex extraction
livecheck do
  url :stable
  strategy :github_latest do |json, regex|
    json["tag_name"]&.sub(/^v/, "")
  end
end
```

**Note**: GitHub rate-limits API requests. Only use when `:git` strategy is insufficient.

## Strategy: `:header_match`

Use when the download URL is a `/latest` redirect that returns the actual version in the redirect location or filename.

**How it works**: Makes a HEAD request and extracts version from the `Location` header or `Content-Disposition` filename.

```ruby
# Basic - extracts version from redirect URL automatically
livecheck do
  url "https://example.com/download/latest"
  strategy :header_match
end

# With regex - when version format needs extraction
livecheck do
  url "https://example.com/download/latest"
  regex(/App[._-]v?(\d+(?:\.\d+)+)\.dmg/i)
  strategy :header_match
end

# With block - for complex version extraction
livecheck do
  url "https://example.com/download/latest"
  strategy :header_match do |headers|
    headers["location"][/v(\d+(?:\.\d+)+)/i, 1]
  end
end
```

**Architecture-specific livecheck**: When ARM and Intel have different version feeds:

```ruby
livecheck do
  url "https://example.com/#{arch}/latest"
  strategy :header_match
end
```

## Strategy: `:json`

Use when versions are published in a JSON feed (common for Electron apps with RELEASES.json).

```ruby
# Simple key access
livecheck do
  url "https://example.com/RELEASES.json"
  strategy :json do |json|
    json["version"]
  end
end

# Nested structure
livecheck do
  url "https://example.com/releases.json"
  strategy :json do |json|
    json["currentRelease"]
  end
end

# Array of releases - get latest
livecheck do
  url "https://example.com/api/releases"
  strategy :json do |json|
    json["releases"]&.first&.dig("version")
  end
end

# With regex filtering
livecheck do
  url "https://example.com/releases.json"
  regex(/^v?(\d+(?:\.\d+)+)$/i)
  strategy :json do |json, regex|
    json["versions"]&.map { |v| v["name"]&.[](regex, 1) }
  end
end
```

**Architecture-specific JSON feeds**:

```ruby
cask "example" do
  arch arm: "arm64", intel: "x64"

  # ... version/sha256 blocks ...

  livecheck do
    url "https://example.com/#{arch}/RELEASES.json"
    strategy :json do |json|
      json["currentRelease"]
    end
  end
end
```

## Strategy: `:page_match`

Use when version must be scraped from an HTML page (download pages, changelogs).

```ruby
# Basic with regex
livecheck do
  url "https://example.com/downloads/"
  regex(/href=.*?example[._-]v?(\d+(?:\.\d+)+)\.dmg/i)
  strategy :page_match
end

# With block for complex extraction
livecheck do
  url "https://example.com/releases/"
  strategy :page_match do |page|
    page.scan(/Version (\d+(?:\.\d+)+)/i).flatten
  end
end

# Multiple captures combined
livecheck do
  url "https://example.com/download"
  regex(%r{/(\d+)/App-(\d+(?:\.\d+)+)\.zip}i)
  strategy :page_match do |page, regex|
    match = page.match(regex)
    next if match.blank?
    "#{match[2]},#{match[1]}"
  end
end
```

## Strategy: `:git`

Use for Git repositories when checking tags. Lower API overhead than GitHub strategies. More common for formulae than casks.

```ruby
# Basic - matches version tags
livecheck do
  url :stable
  regex(/^v?(\d+(?:\.\d+)+)$/i)
  strategy :git
end

# With prefix in tags
livecheck do
  url "https://github.com/owner/repo.git"
  regex(/^release[._-]v?(\d+(?:\.\d+)+)$/i)
  strategy :git
end
```

## Strategy: `:electron_builder`

Use for Electron apps with `latest-mac.yml` update feeds.

```ruby
livecheck do
  url "https://example.com/releases/latest-mac.yml"
  strategy :electron_builder
end

# With block
livecheck do
  url "https://example.com/latest-mac.yml"
  strategy :electron_builder do |yaml|
    yaml["version"]
  end
end
```

## Strategy: `:extract_plist` (Last Resort)

Use only when no online source provides version information. This strategy downloads the artifact and extracts version from `.plist` files inside the app bundle.

**Warning**: Casks using this strategy are excluded from autobumping due to CI impact.

```ruby
# Basic - extracts from downloaded artifact
livecheck do
  url :url
  strategy :extract_plist
end

# With block - for specific bundle ID
livecheck do
  url :url
  strategy :extract_plist do |items|
    items["com.example.MyApp"].short_version
  end
end
```

## Regex Best Practices

### Common patterns

```ruby
# Version number (1.2.3, 1.2.3.4, etc.)
/(\d+(?:\.\d+)+)/

# Version with optional 'v' prefix
/v?(\d+(?:\.\d+)+)/

# Anchored for exact match
/^v?(\d+(?:\.\d+)+)$/

# In filename
/App[._-]v?(\d+(?:\.\d+)+)\.dmg/i

# In href attribute
/href=.*?app[._-]v?(\d+(?:\.\d+)+)\.t/i
```

### Guidelines

1. **Case insensitive** - Add `i` flag: `/pattern/i`
2. **Non-capturing groups** - Use `(?:...)` for grouping without capture
3. **Flexible separators** - Use `[._-]` between name and version
4. **Tarball extension** - Use `\.t` to match any tarball format
5. **Anchor when possible** - `^` and `$` prevent partial matches

## Debugging Livecheck

```bash
# Full debug output
brew livecheck --debug --cask <name>

# Just check if it works
brew livecheck --cask <name>
```

Debug output shows:

- URLs being checked
- Strategies being tried
- Regex matches
- Extracted versions

## Skip Livecheck

For casks where automated version checking is impossible:

```ruby
livecheck do
  skip "No version information available online"
end
```

Use sparingly - most casks should have working livechecks.
