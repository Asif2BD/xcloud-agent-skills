# Changelog

All notable changes to the xCloud Public API skill are documented in this file.

## [Unreleased]

### Added

- **API coverage audit** (`docs/API-COVERAGE.md`): every documented endpoint
  cross-checked against the live OpenAPI (111 operations). Skills cover 108 of
  them; 3 live operations are undocumented (`PUT /sites/{uuid}/git`,
  `POST /sites/{uuid}/git/deploy`, `POST /servers/{uuid}/services/disable`) and 9
  documented `databases`/`database-users` operations are absent from the spec
  **and verified to return HTTP 404 on live servers (2026-06-29)** — now carrying
  a prominent "not available on the current public API" caveat in
  `reference/databases.md`. Clarifies that "117" is the skill-side count, not the
  API's 111-operation surface; ADR 0001 and the 2.0.0 note were corrected
  accordingly. All five smoke suites were run green against the live API
  (servers: 7 passed / 1 skipped for the `databases` 404 / 0 failed).
- **Minimal CI workflow** (`.github/workflows/ci.yml`): lints every shell script
  (`bash -n` + ShellCheck) and validates the JSON manifests on each push/PR, and
  runs the read-only smoke suites when an `XCLOUD_API_TOKEN` secret is configured
  (skips cleanly otherwise).

### Fixed

- **`xcloud:account` token revocation now matches the live API.** The skill
  documented `DELETE /user/tokens/{tokenId}` as a numeric id, but the API keys
  revocation by the token's `uuid` (live OpenAPI: `DELETE
  /user/tokens/{tokenUuid}`, `string`/`uuid`) and `GET /user/tokens` returns
  `uuid`. Corrected the endpoint, made the list example surface `uuid` (so the
  revoke flow is completable from list output), and fixed the matching note in
  `reference/conventions.md` and the skill pitfall.

### Changed

- **Smoke suites tolerate unsupported sub-resources.** A new `check_opt` helper
  treats `404` (and `422` "not supported") on optional, type-dependent
  sub-resources as **SKIP** instead of **FAIL** — applied to server `databases`,
  site `backups`/`cache`, the WordPress `pagespeed` latest scan, and site `ssl`.
  Summary lines now report passed/skipped/failed.
- **Removed non-standard SKILL.md frontmatter keys** (`version`/`author`/
  `license`) from all five skills — `name`/`description` only, per the SKILL.md
  schema. Version/author/license now have a single source of truth in
  `plugin.json`, avoiding drift across six files on each release.
- **Reconciled `requirements.txt`** with `.clawhubinfo.json`'s stated versions:
  `requests>=2.28.0`, `backoff>=2.2.0`.
- **Documented `XCLOUD_API_BASE_URL`** in `.env.example` (commented), so local /
  white-label hosts are discoverable without reading the source.
- **Public identity realigned to the skills.** The README now leads with the five
  `xcloud:*` skills, install, and usage; the Python SDK/CLI is reframed as a
  legacy `src/` track. `.clawhubinfo.json` bumped to `3.0.0`, its stale
  `api_info.version` corrected to the live API's `1.0.0`, and its
  features/badges/quick-start reframed from SDK-centric to skill-centric.

## [3.0.0] - 2026-06-16

### Changed (BREAKING)

- Renamed the plugin from `xcloud-public-api` to **`xcloud`**, and shortened each
  skill's name to its bare capability. Skills are now invoked as **`xcloud:servers`**,
  **`xcloud:sites`**, **`xcloud:ssl`**, **`xcloud:wordpress`**, and **`xcloud:account`**
  (previously `xcloud-public-api:xcloud-servers`, etc.).
- The plugin directory moved from `plugins/xcloud-public-api/` to `plugins/xcloud/`,
  and each skill directory was shortened to match (`skills/servers/`, `skills/sites/`,
  `skills/ssl/`, `skills/wordpress/`, `skills/account/`).
- **Breaking:** the skill IDs changed. Users must reinstall the plugin
  (`/plugin install xcloud`) and update any explicit skill references to the new
  `xcloud:<capability>` form. No behavior or coverage changed — names only.

## [2.0.0] - 2026-06-09

### Changed (BREAKING)

- Replaced the single `xcloud-public-api` skill with **five capability-domain
  skills**: `xcloud-servers`, `xcloud-sites`, `xcloud-wordpress`, `xcloud-ssl`,
  `xcloud-account`. The v1 single skill is preserved at the `v1.2.0` git tag.
- Skills are organized by **capability, not URL root**; each description declares
  what it does *not* own with `see xcloud-*` cross-links to keep trigger keywords
  from colliding. See `docs/adr/0001-capability-domain-skills.md`.

### Added

- Coverage expanded to a 117-operation skill surface (PHP versions, databases,
  firewall/fail2ban, cron, snapshots, services, vulnerabilities, PageSpeed,
  WordPress plugin/theme management, SSL certificate lifecycle, and more).
- Shared plugin layer: one `scripts/xcloud.sh` + `reference/{auth,conventions}.md`
  referenced by every skill via `${CLAUDE_PLUGIN_ROOT}` — no per-skill duplication.
- Per-skill `tests/smoke.sh`; large domains carry `reference/<sub-resource>.md`
  loaded on demand.
- Base URL is environment-driven (`XCLOUD_API_BASE_URL`) — local (`xcloud.test`)
  vs live (`app.xcloud.host`) needs no code change.

## [1.1.0] - 2026-04-22

### Added

#### Core SDK
- **xcloud_sdk.py**: Full-featured Python SDK for xCloud API
  - `XCloudAPI` class with 20+ methods
  - `XCloudDeployer` class for high-level automation
  - Support for all API endpoints (servers, sites, backups, SSH config, etc.)
  - Built-in error handling with exponential backoff
  - Rate limit management and retry logic

#### Async Helpers
- **xcloud_async.py**: Reliable async operation tracking
  - `AsyncPoller`: Poll operations until completion
  - `StateManager`: Persistent state tracking
  - `RateLimitManager`: Automatic rate limit backoff
  - `OperationBatcher`: Batch operations for efficiency
  - `DeploymentTracker`: Multi-step deployment tracking

#### CLI Tool
- **xcloud-cli.sh**: Command-line interface for interactive use
  - Server management (list, get, reboot)
  - Site management (create, backup, monitor, etc.)
  - Health checks and monitoring
  - Blueprint enumeration
  - Human-friendly output with color coding

#### Documentation
- **AGENT-SCENARIOS.md**: Real-world use cases for autonomous agents
  - Infrastructure automation (provisioning, deployment, backups)
  - Monitoring & analysis (capacity planning, DR, cost analysis)
  - Security checks (SSL monitoring, site health verification)
  - Operations (bulk updates, status reporting)
  - Error recovery and state persistence patterns
  
- **ERROR-HANDLING.md**: Comprehensive error recovery guide
  - 12+ error types covered (401, 429, 502, SSL, etc.)
  - Recovery code for each error
  - Testing commands
  - Quick reference table

#### Examples
- Deploy WordPress site with polling
- Monitor fleet health
- Backup all sites
- Competitor site monitoring template
- Health check with auto-recovery

### Changed

- Updated SKILL.md with cross-references to new documentation
- Updated README.md with installation instructions for SDK and CLI
- Updated plugin.json metadata (version 1.1.0)

### Technical Improvements

- **SDK Design**: High-level abstractions reduce boilerplate by 80%
- **Error Handling**: Exponential backoff, rate limit management, timeout handling
- **State Persistence**: Track long-running operations across invocations
- **Rate Limiting**: Automatic backoff prevents 429 errors
- **Polling**: Built-in timeout and interval management

### Breaking Changes

None. All existing curl examples and manual API usage continues to work.

---

## [1.0.0] - 2024

### Initial Release

- Original SKILL.md with xCloud Public API documentation
- curl examples for all major operations
- Authentication guide
- Rate limiting information
- Troubleshooting patterns (502 triage, etc.)
- README with installation instructions

